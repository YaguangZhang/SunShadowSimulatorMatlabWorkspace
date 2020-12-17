%SIMULATESUNSHADOW Find sun shadow based for the location and time of
%interest.
%
% Given a location of interest P, we will use the terrain elevation to
% determine the ground level, and build a LiDAR profile for P towards the
% sun's direction according to the time of interest. That LiDAR profile is
% compared with the direct path from P to the sun to determine whether the
% ground at P is in the sun shadow or not.
%
% Yaguang Zhang, Purdue, 11/24/2020

clear; clc; close all; dbstop if error;

% Locate the Matlab workspace and save the current filename.
cd(fileparts(mfilename('fullpath'))); addpath('libs');
curFileName = mfilename;

prepareSimulationEnv;

% Change PRESET to run the simulator for different areas.
%   - 'MSEE'
%     Area around Purdue MSEE building with manually labeled square
%     boundary.
SUPPORTED_PRESETS = {'MSEE'};
PRESET = 'MSEE';

assert(any(strcmp(SUPPORTED_PRESETS, PRESET)), ...
    ['Unsupported preset "', PRESET, '"!']);

%% Script Parameters

% The absolute path to the Lidar .las file. Currently supporting
% 'Tipp_Extended' (for ten counties in the WHIN are), 'IN' (all indiana)
% and '' (automatically pick the biggest processed set).
LIDAR_DATA_SET_TO_USE = '';

% The absolute path to save results.
switch PRESET
    case 'MSEE'
        pathToSaveResults = fullfile(ABS_PATH_TO_SHARED_FOLDER, ...
            'SunShadowSimulatorResults', 'Simulation_MSEE');
end

%% Simulation Configurations

% We will organize all the necessary configurations into a structure called
% simConfigs. User assigned configuration values are in
% SCREAMING_SNAKE_CASE, while parameters derived accordingly are in
% camelCase.
%   - A string label to identify this simulation.
simConfigs.CURRENT_SIMULATION_TAG = PRESET;

%   - The UTM (x, y) polygon boundary vertices representing the area of
%   interest for generating the coverage maps; note that it is possible to
%   use the region covered by the availabe LiDAR data set as the
%   corresponding area of interest.
switch PRESET
    case 'MSEE'
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST ...
            = constructUtmRectanglePolyMat(...
            [40.427515, -86.915579; ...
            40.431287, -86.909588]);
end

%   - The zone label to use in the UTM (x, y) system.
simConfigs.UTM_ZONE = '16 T';

%   - We will use this spacial resolution to construct the inspection
%   location grid for the area of interest.
simConfigs.GRID_RESOLUTION_IN_M = 0.5;

%   - The guaranteed spacial resolution for LiDAR profiles; a larger value
%   will decrease the simulation time and the simulation accuracy (e.g.,
%   small obstacles may get ingored).
simConfigs.MAX_ALLOWED_LIDAR_PROFILE_RESOLUATION_IN_M = 1.5;

%   - The guaranteed minimum number of LiDAR z (or possibly elevation)
%   elements in one terrain profile; this will ensure non-empty terrain
%   profiles.
simConfigs.MIN_NUM_OF_TERRAIN_SAMPLES_PER_PROFILE = 10;

%   - We will treat the sun as the TX and the location to inspect as the
%   RX. Accordingly, one can adjust the RX height in the simulator to
%   change the height of point to inspect (zero corresponds to the ground
%   level defined by the terrain elevation data). This could be useful if
%   one would like to do the simulation for something above the ground, or
%   if the terrain elevation data do not agree well with the LiDAR data in
%   terms of the ground elevation.
simConfigs.RX_HEIGHT_TO_INSPECT_IN_M = 0.1;

%   - For each location of interest, only a limited distance of the LiDAR
%   data will be inspected. Increase this parameter will increase the
%   computation needed for the simulation, but if this parameter is too
%   low, the accuracy of the simulation may decrease, too, especially for
%   the case when the sun is at a low angle (then a low obstacle far away
%   may still block the location of interest).
simConfigs.RADIUS_TO_INSPECT_IN_M = 1000;

%   - For adjusting the feedback frequency in parfor workers.
simConfigs.WORKER_MIN_PROGRESS_RATIO_TO_REPORT = 0.2;

%   - The time range of interest to inspect. This is specified in terms of
%   the local time in the UTM zone specified above. The times to inspect
%   are essentially constructed via something like:
%       inspectTimeStartInS:inspectTimeIntervalInS:inspectTimeEndInS
inspectTimeStart = datetime('1-Dec-2020 00:00:00');
inspectTimeEnd = datetime('7-Dec-2020 23:59:59');
inspectTimeIntervalInM = 60; % In minutes.

%% Configure the Simulation Accordingly

% Pre-assign LIDAR_DATA_SET_TO_USE based on the user's settings. We will
% verify this value later.
simConfigs.LIDAR_DATA_SET_TO_USE = LIDAR_DATA_SET_TO_USE;

% Convert GPS degrees to UTM coordinates for the specified zone.
utmstruct_speZone = defaultm('utm');
% Remove white space in the zone label.
utmstruct_speZone.zone ...
    = simConfigs.UTM_ZONE(~isspace(simConfigs.UTM_ZONE));
utmstruct_speZone.geoid = wgs84Ellipsoid;
utmstruct_speZone = defaultm(utmstruct_speZone);

deg2utm_speZone = @(lat, lon) mfwdtran(utmstruct_speZone, lat,lon);
utm2deg_speZone = @(x, y) minvtran(utmstruct_speZone, x, y);

% Store these functions in simConfigs.
simConfigs.deg2utm_speZone = deg2utm_speZone;
simConfigs.utm2deg_speZone = utm2deg_speZone;

% The time zone to use for the observer is derived from the UTM zone.
[~, zoneCenterLon] = simConfigs.utm2deg_speZone(500000,0);
simConfigs.timezone = -timezone(zoneCenterLon);

% Turn the diary logging function on.
dirToSaveDiary = fullfile(pathToSaveResults, 'diary.txt');
if ~exist(dirToSaveDiary, 'file')
    if ~exist(pathToSaveResults, 'dir')
        mkdir(pathToSaveResults)
    end
    fclose(fopen(dirToSaveDiary, 'w'));
end
diary(dirToSaveDiary);

%% Preprocessing LiDAR Data

% Make sure the chosen LiDAR dataset to use in the simulation is indeed
% available, and if it is not specified (LIDAR_DATA_SET_TO_USE = ''),
% default to the bigger LiDAR dataset that has been preprocessed before for
% better coverage.
[verifiedLidarDataSetToUse] = verifyLidarDataSetToUse( ...
    simConfigs.LIDAR_DATA_SET_TO_USE, ABS_PATH_TO_LIDAR);

dirToLidarFiles = fullfile(ABS_PATH_TO_LIDAR, ...
    'Lidar', verifiedLidarDataSetToUse);

% Preprocess .img LiDAR data. To make Matlab R2019b work, we need to remove
% preprocessIndianaLidarDataSet from path after things are done.
simConfigs.LIDAR_DATA_SET_TO_USE = verifiedLidarDataSetToUse;
addpath(fullfile(pwd, 'libs', 'lidar'));
[lidarFileRelDirs, lidarFileXYCoveragePolyshapes, ~] ...
    = preprocessIndianaLidarDataSet(dirToLidarFiles, ...
    deg2utm_speZone, utm2deg_speZone);
rmpath(fullfile(pwd, 'libs', 'lidar'));
lidarFileAbsDirs = cellfun(@(d) ...
    [dirToLidarFiles, strrep(d, '\', filesep)], ...
    lidarFileRelDirs, 'UniformOutput', false);

%% Simulation

disp(' ')
disp('    Conducting simulation ...')
disp(' ')

% EOF