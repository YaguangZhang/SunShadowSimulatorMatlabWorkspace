%SIMULATESUNSHADOW Find sun shadow based for the location and time of
%interest.
%
% Given a location of interest P (together with the time of interest), we
% will build a LiDAR profile from P towards the sun's direction (for
% obstacles that may block the sun for P). Then, that LiDAR profile is
% compared with the direct path from P to the sun to determine whether P is
% in the sun or not. Note that the height of P is determined by the
% specified LiDAR data set.
%
% The simulation settings and outputs are saved in struct variables
% simConfigs and simState, respectively. Please refer to the comments in
% this file for more details.
%
% Yaguang Zhang, Purdue, 01/09/2021

clear; clc; close all; dbstop if error;

% Locate the Matlab workspace and save the current filename.
cd(fileparts(mfilename('fullpath'))); cd(fullfile('..', '..'));
addpath('libs');
curFileName = mfilename;

prepareSimulationEnv;

% Change PRESET to run the simulator for different locations/areas of
% interest. Please refer to the Simulation Configurations section for the
% supported presets.
PRESET = 'INDOT_RoadShadow_US41_Loc_4';

%% Script Parameters

% The absolute path to the folder for saving the results.
folderToSaveResults = fullfile(ABS_PATH_TO_SHARED_FOLDER, ...
    'SunShadowSimulatorResults', ['Simulation_', PRESET]);

% The format to use for displaying datetime.
datetimeFormat = 'yyyy/mm/dd HH:MM:ss';

%% Simulation Configurations

% We will organize all the necessary configurations into a structure called
% simConfigs. User assigned configuration values are in
% SCREAMING_SNAKE_CASE, while parameters derived accordingly are in
% camelCase.
%   - A string label to identify this simulation.
simConfigs.CURRENT_SIMULATION_TAG = PRESET;

%   - The UTM (x, y)/GPS (lat, lon) polygon boundary vertices representing
%   the area of interest for generating the coverage maps; note that it is
%   possible to use the region covered by the available LiDAR data set as
%   the corresponding area of interest.
switch PRESET
    case 'GpsPts'
        simConfigs.LAT_LON_PTS_OF_INTEREST ...
            = [ ...
            ... % A point at southwest of MSEE building.
            40.428951, -86.913309];
        % The folder name under ABS_PATH_TO_LIDAR for fetching the LiDAR
        % data.
        %   - MSEE_Extended_NAD83_PointCloud
        %    - INDOT_RoadShadow_Community_NAD83_PointCloud_NoiseExcluded
        %   - INDOT_RoadShadow_SR35_NAD83_PointCloud_NoiseExcluded
        lidarDataSetToUse ...
            = 'MSEE_Extended_NAD83_PointCloud';
    case 'PurdueMseeBuilding_LasLidar'
        %   - A small area around MSEE building.
        %     [40.428951, -86.913309; 40.429744, -86.912143]
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST ...
            = constructUtmRectanglePolyMat(...
            [40.428951, -86.913309; 40.429744, -86.912143]);
        %   - We will use this spacial resolution to construct the
        %   inspection location grid for the area of interest.
        simConfigs.GRID_RESOLUTION_IN_M = 1;
        lidarDataSetToUse ...
            = 'MSEE_Extended_NAD83_PointCloud';
    case 'INDOT_RoadShadow_SR35_Loc_1'
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST ...
            = constructUtmRectanglePolyMat(...
            [41.159544, -86.602513; 41.160881, -86.602380]);
        simConfigs.GRID_RESOLUTION_IN_M = 3;
        lidarDataSetToUse ...
            = 'INDOT_RoadShadow_SR35_NAD83_PointCloud_NoiseExcluded';
    case 'INDOT_RoadShadow_SR35_Loc_2'
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST ...
            = constructUtmRectanglePolyMat(...
            [41.149882, -86.602565; 41.151179, -86.602380]);
        simConfigs.GRID_RESOLUTION_IN_M = 3;
        lidarDataSetToUse ...
            = 'INDOT_RoadShadow_SR35_NAD83_PointCloud_NoiseExcluded';
    case 'INDOT_RoadShadow_SR35_Loc_3'
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST ...
            = constructUtmRectanglePolyMat(...
            [41.142108, -86.602631; 41.143345, -86.602473]);
        simConfigs.GRID_RESOLUTION_IN_M = 3;
        lidarDataSetToUse ...
            = 'INDOT_RoadShadow_SR35_NAD83_PointCloud_NoiseExcluded';
    case 'INDOT_RoadShadow_SR35_Loc_4'
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST ...
            = constructUtmRectanglePolyMat(...
            [41.122760, -86.602805; 41.124215, -86.602661]);
        simConfigs.GRID_RESOLUTION_IN_M = 3;
        lidarDataSetToUse ...
            = 'INDOT_RoadShadow_SR35_NAD83_PointCloud_NoiseExcluded';
    case 'INDOT_RoadShadow_SR35_Loc_5'
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST ...
            = constructUtmRectanglePolyMat(...
            [41.107268, -86.602890; 41.108726, -86.602760]);
        simConfigs.GRID_RESOLUTION_IN_M = 3;
        lidarDataSetToUse ...
            = 'INDOT_RoadShadow_SR35_NAD83_PointCloud_NoiseExcluded';
    case 'INDOT_RoadShadow_SR35_Loc_6'
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST ...
            = constructUtmRectanglePolyMat(...
            [41.099605, -86.602935; 41.100983, -86.602784]);
        simConfigs.GRID_RESOLUTION_IN_M = 3;
        lidarDataSetToUse ...
            = 'INDOT_RoadShadow_SR35_NAD83_PointCloud_NoiseExcluded';
    case 'INDOT_RoadShadow_SR35_Loc_7'
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST ...
            = constructUtmRectanglePolyMat(...
            [41.130000, -86.602744; 41.131361, -86.602594]);
        simConfigs.GRID_RESOLUTION_IN_M = 3;
        lidarDataSetToUse ...
            = 'INDOT_RoadShadow_SR35_NAD83_PointCloud_NoiseExcluded';
    case 'INDOT_RoadShadow_US41_Loc_1'
        simConfigs.LAT_LON_BOUNDARY_OF_INTEREST = [39.568783, -87.371034;
            39.568989, -87.370522;
            39.569329, -87.369990;
            39.569666, -87.369665;
            39.569628, -87.369552;
            39.569383, -87.369766;
            39.569107, -87.370077;
            39.568880, -87.370508;
            39.568682, -87.370984;
            39.568783, -87.371034];
        simConfigs.GRID_RESOLUTION_IN_M = 3;
        lidarDataSetToUse ...
            = 'INDOT_RoadShadow_US41_Loc_1_NAD83_PointCloud_NoiseExcluded';
    case 'INDOT_RoadShadow_US41_Loc_2'
        simConfigs.LAT_LON_BOUNDARY_OF_INTEREST = [39.650872, -87.370571;
            39.651185, -87.370764;
            39.651859, -87.371727;
            39.651944, -87.371676;
            39.651305, -87.370750;
            39.651078, -87.370545;
            39.650872, -87.370463;
            39.650872, -87.370571];
        simConfigs.GRID_RESOLUTION_IN_M = 3;
        lidarDataSetToUse ...
            = 'INDOT_RoadShadow_US41_Loc_2_NAD83_PointCloud_NoiseExcluded';
    case 'INDOT_RoadShadow_US41_Loc_3'
        simConfigs.LAT_LON_BOUNDARY_OF_INTEREST = [39.691497, -87.352808;
            39.691848, -87.352125;
            39.692037, -87.351551;
            39.692129, -87.351119;
            39.691993, -87.351089;
            39.691896, -87.351561;
            39.691726, -87.352021;
            39.691499, -87.352436;
            39.691341, -87.352682;
            39.691497, -87.352808];
        simConfigs.GRID_RESOLUTION_IN_M = 3;
        lidarDataSetToUse ...
            = 'INDOT_RoadShadow_US41_Loc_3_NAD83_PointCloud_NoiseExcluded';
    case 'INDOT_RoadShadow_US41_Loc_4'
        simConfigs.LAT_LON_BOUNDARY_OF_INTEREST = [39.695320, -87.341380;
            39.695619, -87.340831;
            39.695548, -87.340760;
            39.695235, -87.341339;
            39.695320, -87.341380];
        simConfigs.GRID_RESOLUTION_IN_M = 3;
        lidarDataSetToUse ...
            = 'INDOT_RoadShadow_US41_Loc_4_NAD83_PointCloud_NoiseExcluded';
    case 'INDOT_RoadShadow_Community_Loc_1'
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST ...
            = constructUtmRectanglePolyMat(...
            [41.096616, -86.560437; 41.097695, -86.558927]);
        simConfigs.GRID_RESOLUTION_IN_M = 3;
        lidarDataSetToUse ...
            = 'INDOT_RoadShadow_Community_NAD83_PointCloud_NoiseExcluded';
    case 'INDOT_RoadShadow_Community_Loc_7'
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST ...
            = constructUtmRectanglePolyMat(...
            [41.096873, -86.556410; 41.097739, -86.554871]);
        simConfigs.GRID_RESOLUTION_IN_M = 3;
        lidarDataSetToUse ...
            = 'INDOT_RoadShadow_Community_NAD83_PointCloud_NoiseExcluded';
    otherwise
        error(['Unsupported preset "', PRESET, '"!'])
end

%   - The zone label to use in the UTM (x, y) system. Note: this will be
%   used for preprocessing the LiDAR data, too; so if it changes, the
%   history LiDAR data will become invalid.
simConfigs.UTM_ZONE = '16 T';

%   - The guaranteed spatial resolution for LiDAR profiles; a larger value
%   will decrease the simulation time and the simulation accuracy (e.g.,
%   small obstacles may get ignored).
simConfigs.MAX_ALLOWED_LIDAR_PROFILE_RESOLUTION_IN_M = 1.5;

%   - (TODO) The guaranteed minimum number of LiDAR z (or possibly
%   elevation) elements in one terrain profile; this will ensure non-empty
%   terrain profiles.
% simConfigs.MIN_NUM_OF_TERRAIN_SAMPLES_PER_PROFILE = 10;

%   - (TODO) We will treat the sun as the TX and the location to inspect as
%   the RX. Accordingly, one can adjust the RX height in the simulator to
%   change the height of point to inspect (zero corresponds to the surface
%   level defined by the LiDAR z data). This could be useful if one would
%   like to do the simulation for something above the ground.
% simConfigs.RX_HEIGHT_TO_INSPECT_IN_M = 0;

%   - For each location of interest, only a limited distance of the LiDAR
%   data will be inspected. Increase this parameter will increase the
%   computation needed for the simulation, but if this parameter is too
%   low, the accuracy of the simulation may decrease, too, especially for
%   the case when the sun is at a low angle (then a low obstacle far away
%   may still block the location of interest).
%     The length of the LiDAR profile needs to be chosen wisely because
%     obstacles could cause extremely long shadows at sunset/sunrise. Say
%     the sunshine duration is 12 hours/day and the sun location is
%     uniformly distributed in [0, 180] degrees, where 0 degree corresponds
%     to sunrise and 180 degrees corresponds to sunset. Then, if we would
%     like to allow inaccurate results for 15 min of sunshine right after
%     the sunrise and before the sunset, with a typical three-story
%     building (~10 m high), we would need a radius to inspect of r meters
%     such that:
%         arctand(10/r)*2/180 *12*60 = 15*2
%     We can get r here is around 152 meters:
%         r = 10/tand(15*2/60/12*180/2) = 152.5705
simConfigs.RADIUS_TO_INSPECT_IN_M = 150;

%   - For adjusting the feedback frequency.
simConfigs.MIN_PROGRESS_RATIO_TO_REPORT = 0.05;

%   - The time range of interest to inspect. The datetime for this is
%   specified in terms of the local time without a time zone. The time zone
%   will be derived from simConfigs.UTM_ZONE. The times to inspect are
%   essentially constructed via something like:
%       inspectTimeStartInS:inspectTimeIntervalInS:inspectTimeEndInS
simConfigs.LOCAL_TIME_START = datetime('14-Jan-2021 7:00:00');
simConfigs.LOCAL_TIME_END = datetime('14-Jan-2021 16:59:59');
simConfigs.TIME_INTERVAL_IN_M = 30; % In minutes.

%   - For the shadow location visualization video clip. For simplicity,
%   please make sure PLAYBACK_SPEED/FRAME_RATE is an integer.
simConfigs.FRAME_RATE = 30; % In FPS.
%   For example,
%       - Speed = 3600
%         1 hour in real time => 1 second in the video.
%       - Speed = 900
%         15 min in real time => 1 second in the video.
%       - Speed = 300
%         5 min in real time => 1 second in the video.
%       - Speed = 60
%         1 min in real time => 1 second in the video.
simConfigs.PLAYBACK_SPEED = 1800; % Relative to real time.

%% Derive Other Configurations Accordingly

% Turn the diary logging function on.
dirToSaveDiary = fullfile(folderToSaveResults, 'diary.txt');
if ~exist(dirToSaveDiary, 'file')
    if ~exist(folderToSaveResults, 'dir')
        mkdir(folderToSaveResults)
    end
    fclose(fopen(dirToSaveDiary, 'w'));
end
diary(dirToSaveDiary);

disp(' ')
disp(['    [', datestr(now, datetimeFormat), ...
    '] Configuring the simulation for PRESET ', PRESET, ' ...'])

% Save simConfigs if it is not yet done.
dirToSaveSimConfigs = fullfile(folderToSaveResults, 'simConfigs.mat');
if exist(dirToSaveSimConfigs, 'file')
    disp(['        [', datestr(now, datetimeFormat), ...
        '] The specified PRESET "', ...
        PRESET, '" has been processed before.'])
    disp(['        [', datestr(now, datetimeFormat), ...
        '] Loading history simConfigs ...'])
    histSimConfigs = load(dirToSaveSimConfigs);
    if ~isequaln(histSimConfigs.simConfigs, simConfigs)
        error(['[        ', datestr(now, datetimeFormat), ...
            '] The settings for this PRESET have changed!']);
    end
else
    % Note that the simConfigs saved now only contains user-specified
    % parameters.
    save(dirToSaveSimConfigs, 'simConfigs', '-v7.3');
end

% Pre-assign LIDAR_DATA_SET_TO_USE based on the user's settings.
simConfigs.LIDAR_DATA_SET_TO_USE = lidarDataSetToUse;

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

% The local datetimes to inspect.
simConfigs.localDatetimesToInspect = simConfigs.LOCAL_TIME_START ...
    :minutes(simConfigs.TIME_INTERVAL_IN_M) ...
    :simConfigs.LOCAL_TIME_END;

% The locations of interest to inspect.
if isfield(simConfigs, 'LAT_LON_BOUNDARY_OF_INTEREST')
    if isfield(simConfigs, 'UTM_X_Y_BOUNDARY_OF_INTEREST')
        error(['Boundry of interest was set ', ...
            'both in GPS (lat, lon) and UTM (x, y)!'])
    else
        [utmXsForBoundaryOfInterest, utmYsForBoundaryOfInterest] = ...
            simConfigs.deg2utm_speZone( ...
            simConfigs.LAT_LON_BOUNDARY_OF_INTEREST(:,1), ...
            simConfigs.LAT_LON_BOUNDARY_OF_INTEREST(:,2));
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST = ...
            [utmXsForBoundaryOfInterest, utmYsForBoundaryOfInterest];
    end
end
flagGpsPtsOfInterestSpecified ...
    = isfield(simConfigs, 'LAT_LON_PTS_OF_INTEREST');
flagAreaOfInterestSpecified ...
    = isfield(simConfigs, 'UTM_X_Y_BOUNDARY_OF_INTEREST');
% Only one way of specifying the locations to inspect is expected to be
% used.
if sum([flagGpsPtsOfInterestSpecified; flagAreaOfInterestSpecified])~=1
    error('Not able to consctruct the locations of interest!');
end

if flagGpsPtsOfInterestSpecified
    % If the GPS locations to inspect are set, we will use them directly.
    simConfigs.gridLatLonPts = simConfigs.LAT_LON_PTS_OF_INTEREST;
    
    [gridXs,gridYs] = simConfigs.deg2utm_speZone( ...
        simConfigs.gridLatLonPts(:,1), simConfigs.gridLatLonPts(:, 2));
    simConfigs.gridXYPts = [gridXs,gridYs];
elseif flagAreaOfInterestSpecified
    % If the area of interest is set, we will generate a grid to inspect
    % accordingly.
    gridMinX = min(simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,1));
    gridMaxX = max(simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,1));
    gridMinY = min(simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,2));
    gridMaxY = max(simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,2));
    
    gridResolutionInM = simConfigs.GRID_RESOLUTION_IN_M;
    
    gridXLabels = constructAxisGrid( ...
        mean([gridMaxX, gridMinX]), ...
        floor((gridMaxX-gridMinX)./gridResolutionInM), gridResolutionInM);
    gridYLabels = constructAxisGrid( ...
        mean([gridMaxY, gridMinY]), ...
        floor((gridMaxY-gridMinY)./gridResolutionInM), gridResolutionInM);
    [gridXs,gridYs] = meshgrid(gridXLabels,gridYLabels);
    
    % For reconstructing the grid in 2D if necessary.
    simConfigs.numOfPixelsForLongerSide = ...
        max(length(gridXLabels), length(gridYLabels));
    
    % Make sure there are no grid points out of the area of interest.
    boolsGridPtsToKeep = inpolygon(gridXs(:), gridYs(:), ...
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,1), ...
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,2));
    if ~all(boolsGridPtsToKeep)
        warning(['Not all the grid points generated ', ...
            'are in the are of interest!']);
    end
    simConfigs.gridXYPts = [gridXs(boolsGridPtsToKeep), ...
        gridYs(boolsGridPtsToKeep)];
    
    % Convert UTM (x, y) to (lat, lon).
    [gridLats, gridLons] = simConfigs.utm2deg_speZone( ...
        simConfigs.gridXYPts(:,1), simConfigs.gridXYPts(:,2));
    simConfigs.gridLatLonPts = [gridLats, gridLons];
end

disp(['    [', datestr(now, datetimeFormat), '] Done!'])

%% Preprocessing LiDAR Data
% Note: the first time of this may take a long time, depending on the size
% of the LiDAR data set, but (1) it supports recovery from interruptions,
% and (2) once we have gone through all the data once, loading the
% information would be very fast.

dirToLidarFiles = fullfile(ABS_PATH_TO_LIDAR, ...
    'Lidar', lidarDataSetToUse);

% Preprocess .las LiDAR data. To make Matlab R2019b work, we need to remove
% preprocessIndianaLidarDataSet from path after things are done.
addpath(fullfile(pwd, 'libs', 'lidar'));
[lidarFileRelDirs, lidarFileXYCoveragePolyshapes, ~] ...
    = preprocessIndianaLidarDataSetLas(dirToLidarFiles, ...
    deg2utm_speZone, utm2deg_speZone);
rmpath(fullfile(pwd, 'libs', 'lidar'));
lidarFileAbsDirs = cellfun(@(d) ...
    [dirToLidarFiles, strrep(d, '\', filesep)], ...
    lidarFileRelDirs, 'UniformOutput', false);

% Extra information on the LiDAR data set.
%   - The overall boundry for the area covered by the LiDAR data set in
%   UTM.
lidarFilesXYCoveragePolyshape ...
    = mergePolygonsForAreaOfInterest(lidarFileXYCoveragePolyshapes, 1);
%   - Centroids for the LiDAR files in UTM.
lidarFileXYCentroids ...
    = extractCentroidsFrom2DPolyCell(lidarFileXYCoveragePolyshapes);
%   - The .mat copies for the LiDAR data.
lidarMatFileAbsDirs = cellfun(@(d) regexprep(d, '\.las$', '.mat'), ...
    lidarFileAbsDirs, 'UniformOutput', false);

%% Simulation: Initialization

disp(' ')
disp(['    [', datestr(now, datetimeFormat), ...
    '] Conducting simulation ...'])

% The location for saving history results of simState, just in case any
% interruption happens.
dirToSaveSimState = fullfile(folderToSaveResults, 'simState.mat');
if exist(dirToSaveSimState, 'file')
    disp(['        [', datestr(now, datetimeFormat), ...
        '] The specified PRESET "', ...
        PRESET, '" has been processed before.'])
    disp(['        [', datestr(now, datetimeFormat), ...
        '] Loading history simState ...'])
    load(dirToSaveSimState, 'simState');
    disp(['        [', datestr(now, datetimeFormat), ...
        '] Done!'])
else
    disp(['        [', datestr(now, datetimeFormat), ...
        '] Initializing simState ...'])
    % Load history results if they are available. This is for recovery from
    % interruptions. We will save all simulation output in a struct
    % variable simState.
    %   - The number of grid locations to inspect.
    simState.numOfGridPts = size(simConfigs.gridLatLonPts, 1);
    %   - LiDAR z values for the grid points.
    % Temporarily disable the warning.
    warning('off', 'MATLAB:dispatcher:UnresolvedFunctionHandle');
    [simState.gridEles, simState.gridLidarZs, ~] ...
        = generateProfileSamps( ...
        [simConfigs.gridXYPts], simConfigs.utm2deg_speZone, ...
        lidarFileXYCentroids, lidarFileXYCoveragePolyshapes, ...
        lidarMatFileAbsDirs, 'both');
    % Reenable warning.
    warning('on', 'MATLAB:dispatcher:UnresolvedFunctionHandle');
    
    %   - The number of times to inspect.
    simState.numOfTimesToInspect ...
        = length(simConfigs.localDatetimesToInspect);
    
    %   - The integer labels for local days to inspect.
    %     During each local day, we do not need simulations during the
    %     night (before the sunrise and after the sunset). For this, we
    %     need to find the times to inspect that are in the same days. Note
    %     that we do not need time zone compensation here.
    simState.dayLabels = findgroups( ...
        localDatetime2UtmUnixTimeInS( ...
        dateshift(simConfigs.localDatetimesToInspect, 'Start', 'day'), 0));
    %   - The integer labels for local days to inspect.
    simState.numOfDays = max(simState.dayLabels);
    
    % Preassign storage for the simulation outputs. The sunrise and sunset
    % time for all grid locations will be stored as columns of cell
    % matrices, with each column being the results for one day. Note: for
    % convenience, we will convert them from fractional hours (which is the
    % output format of the SPA function) to datatime and store the results
    % in simState.
    [simState.sunriseDatetimes, simState.sunsetDatetimes] ...
        = deal(cell([simState.numOfGridPts, simState.numOfDays]));
    
    % The sun position information and the resultant uniform sun power
    % values are stored as columns of a huge matrix, corresponding to the
    % grid locations, with each column being the results for one local
    % datetime to inspect.
    %   - Topocentric azimuth angle (eastward from north) [0 to 360
    %   degrees].
    %     The angle formed by the projection of the direction of the sun on
    %     the horizontal plane.
    %   - Topocentric zenith angle [degrees].
    %     Note: Zenith  = 90 degrees - elevation angle
    %   - Uniform sun powers
    %     Ratios in [0,1], where 0 means in the shadow and 1 means direct
    %     sunshine (at a zenith of 90 degrees).
    [simState.sunAzis, simState.sunZens, simState.uniformSunPower] ...
        = deal(nan([simState.numOfGridPts, simState.numOfTimesToInspect]));
    
    % Generate a history file. Note that the simConfigs saved now contains
    % information derived from the parameters set by the users.
    save(dirToSaveSimState, 'simConfigs', 'simState', '-v7.3');
    disp(['        [', datestr(now, datetimeFormat), ...
        '] Done!'])
end

%% Simulation Overview Plot
overviewGridOnMap;

%% Simulation: Sunrise and Sunset Times

disp(' ')
disp(['        [', datestr(now, datetimeFormat), ...
    '] Computing sun positions in the daytime ...'])
% We will go through each day to inspect, each datetime to inspect in that
% day, and each grid location to inspect.
totalNumOfDays = simState.numOfDays;
totalNumOfLocs = simState.numOfGridPts;
% For avoiding unnecessary communications to parfor workers.
localDatetimesToInspect = simConfigs.localDatetimesToInspect;
tz = simConfigs.timezone;
for idxDay = 1:totalNumOfDays
    disp(['            [', datestr(now, datetimeFormat), ...
        '] Day ', num2str(idxDay), '/', num2str(totalNumOfDays), ' ...'])
    % Find the indices for the datetimes to inspect in this day.
    indicesTimesToInspect = find(simState.dayLabels==idxDay);
    
    % Process locations one by one.
    numOfLocsProcessed = 0;
    clearvars curEle;
    for idxLoc = 1:totalNumOfLocs
        curXY = simConfigs.gridXYPts(idxLoc, :);
        curLatLon = simConfigs.gridLatLonPts(idxLoc, :);
        
        % If this day has not been processed for this location before, we
        % first get the sunrise and sunset times, and mark the times at
        % night accordingly as "in shadow" for this location.
        curIdxDatetime = indicesTimesToInspect(1);
        flagSimStateUpdated = false;
        if isnan(simState.sunAzis(idxLoc, curIdxDatetime))
            % Simulate the first datetime to inspect for this day to get
            % the information needed.
            curDatetime = simConfigs.localDatetimesToInspect( ...
                curIdxDatetime);
            
            % We will use the profile generation function to fetch the
            % LiDAR z value and use that as the elevation for the point of
            % interest. Essentially, it is a profile with only one location
            % in it. Note that this is different from the terrain elevation
            % simState.gridEles (the height of the ground) .
            curSampLoc = generateTerrainProfileSampLocs( ...
                curXY, curXY, ...
                simConfigs.MAX_ALLOWED_LIDAR_PROFILE_RESOLUTION_IN_M, ...
                1);
            % Temporarily disable the warning.
            warning('off', 'MATLAB:dispatcher:UnresolvedFunctionHandle');
            [~, curObserverEle, ~] ...
                = generateProfileSamps( ...
                curSampLoc, simConfigs.utm2deg_speZone, ...
                lidarFileXYCentroids, lidarFileXYCoveragePolyshapes, ...
                lidarMatFileAbsDirs, 'LiDAR');
            % Reenable warning.
            warning('on', 'MATLAB:dispatcher:UnresolvedFunctionHandle');
            
            curSpaIn = constructSpaStruct(simConfigs.timezone, ...
                curDatetime, [curLatLon curObserverEle]);
            % Calculate zenith, azimuth, and sun rise/transit/set values:
            % SPA_ZA_RTS = 2.
            curSpaIn.function = 2;
            [spaErrCode, curSpaOut] = getSolarPosition(curSpaIn);
            assert(spaErrCode==0, ...
                ['There was an error from SPA; error code: ', ...
                num2str(spaErrCode), '!'])
            
            curSunriseFracHour = curSpaOut.sunrise;
            curSunsetFracHour = curSpaOut.sunset;
            
            % Save the sunrise and sunset times. Note that in the time
            % conversion here, we do not need to consider the local time
            % zone (i.e., time zone zero is used).
            curDate = dateshift(curDatetime, 'Start', 'day');
            curSunriseDatetime = utmUnixTimeInS2LocalDatetime( ...
                localDatetime2UtmUnixTimeInS(curDate, 0) ...
                + curSunriseFracHour*60*60, 0);
            curSunsetDatetime = utmUnixTimeInS2LocalDatetime( ...
                localDatetime2UtmUnixTimeInS(curDate, 0) ...
                + curSunsetFracHour*60*60, 0);
            simState.sunriseDatetimes{idxLoc, idxDay} ...
                = curSunriseDatetime;
            simState.sunsetDatetimes{idxLoc, idxDay} ...
                = curSunsetDatetime;
            
            % Set the sun power to zero for all times that are not in the
            % daytime (bigger than the sunrise time and smaller than the
            % sunset time).
            curTimesToInspect = ...
                simConfigs.localDatetimesToInspect(indicesTimesToInspect);
            boolsInTheSun = (curTimesToInspect>curSunriseDatetime) ...
                & (curTimesToInspect<curSunsetDatetime);
            simState.uniformSunPower(idxLoc, ...
                indicesTimesToInspect(~boolsInTheSun)) = 0;
            
            % Save the sun position information.
            simState.sunAzis(idxLoc, curIdxDatetime) = curSpaOut.azimuth;
            simState.sunZens(idxLoc, curIdxDatetime) = curSpaOut.zenith;
            
            % Loop through the rest of the times to inspect. In order to
            % make parfor work, we will store the results directly in some
            % temporary variables first.
            curLocSunAzis = simState.sunAzis(idxLoc, :);
            curLocSunZens = simState.sunZens(idxLoc, :);
            curLocSuniformSunPower = simState.uniformSunPower(idxLoc, :);
            parfor curIdxDatetime = indicesTimesToInspect(2:end)
                % And find the solar position if nessary, that is (1) the
                % sun aimuth has not been evaluated for this location and
                % time, and (2) if this location is in the sun at this time
                % (where uniformSunPower is not set to be 0 and remains NaN
                % for now).
                if isnan(curLocSunAzis(curIdxDatetime)) ...
                        && isnan(curLocSuniformSunPower(curIdxDatetime))
                    curDatetime = localDatetimesToInspect( ...
                        curIdxDatetime);
                    curSpaIn = constructSpaStruct(tz, ...
                        curDatetime, [curLatLon curObserverEle]);
                    % Calculate only zenith and azimuth: SPA_ZA = 0;
                    curSpaIn.function = 0;
                    [spaErrCode, curSpaOut] = getSolarPosition(curSpaIn);
                    assert(spaErrCode==0, ...
                        ['There was an error from SPA; error code: ', ...
                        num2str(spaErrCode), '!'])
                    
                    % Save the sun position information.
                    curLocSunAzis(curIdxDatetime) ...
                        = curSpaOut.azimuth;
                    curLocSunZens(curIdxDatetime) ...
                        = curSpaOut.zenith;
                end
            end
            simState.sunAzis(idxLoc, :) = curLocSunAzis;
            simState.sunZens(idxLoc, :) = curLocSunZens;
            flagSimStateUpdated = true;
        end
        numOfLocsProcessed = numOfLocsProcessed+1;
        % Report the progress regularly. Note that we are interested in the
        % overall progress, so the number of dates needs to be considered,
        % too.
        if numOfLocsProcessed/totalNumOfLocs ...
                > simConfigs.MIN_PROGRESS_RATIO_TO_REPORT*totalNumOfDays
            % Also take the chance to update the history results if
            % necessary. Note that this attempt may miss the last save
            % required when all locations are processed.
            if flagSimStateUpdated
                save(dirToSaveSimState, 'simState', '-v7.3');
                flagSimStateUpdated = false;
            end
            
            disp(['                [', ...
                datestr(now, datetimeFormat), ...
                '] Location ', num2str(idxLoc), '/', ...
                num2str(totalNumOfLocs), ' (Overall progress: ', ...
                num2str( ...
                ((idxDay-1)*totalNumOfLocs+idxLoc) ...
                /(totalNumOfLocs*totalNumOfDays)*100, '%.2f'), '%) ...'])
            
            numOfLocsProcessed = 0;
        end
        if idxLoc == totalNumOfLocs
            % Also take the chance to update the history results if
            % necessary.
            if flagSimStateUpdated
                save(dirToSaveSimState, 'simState', '-v7.3');
                flagSimStateUpdated = false;
            end
            
            disp(['                [', ...
                datestr(now, datetimeFormat), ...
                '] Done! (Overall progress: ', ...
                num2str( ...
                ((idxDay-1)*totalNumOfLocs+idxLoc) ...
                /(totalNumOfLocs*totalNumOfDays)*100, '%.2f'), '%)'])
        end
    end
end
disp(['        [', datestr(now, datetimeFormat), ...
    '] Done!'])

%% Simulation: Locs in the Sun

disp(' ')
disp(['        [', datestr(now, datetimeFormat), ...
    '] Locating spots in the sun ', ...
    'and computing their uniform sun powers ...'])
totalNumOfLocTimePairs = ...
    simState.numOfGridPts*simState.numOfTimesToInspect;
curNumOfLocTimePairsProcessed = 0;
numOfLocTimePairsProcessed = 0;

% We only need to do the simulation if it was not completed before.
indicesLocToProcess = 1:simState.numOfGridPts;
if isfield(simState, 'flagShadowLocated')
    if simState.flagShadowLocated
        indicesLocToProcess = [];
    end
end

for idxLoc = indicesLocToProcess
    % Report progress regularly.
    if curNumOfLocTimePairsProcessed == 0
        disp(['            [', ...
            datestr(now, datetimeFormat), ...
            '] Location and time pair ', ...
            num2str(numOfLocTimePairsProcessed), '/', ...
            num2str(totalNumOfLocTimePairs), ' (', ...
            num2str( ...
            numOfLocTimePairsProcessed/totalNumOfLocTimePairs*100, ...
            '%.2f'), '%) ...'])
    end
    
    % We only need to go through time and loc pairs not yet processed.
    curLocUniformSunPowers = simState.uniformSunPower(idxLoc, :);
    indicesDatetimeToProcess = ...
        find(isnan(curLocUniformSunPowers));
    if ~isempty(indicesDatetimeToProcess)
        curGirdLatLon = simConfigs.gridLatLonPts(idxLoc, :);
        curGridXY = simConfigs.gridXYPts(idxLoc, :);
        
        % For parfor workers.
        curLocSunAzisSeg = simState.sunAzis(idxLoc, ...
            indicesDatetimeToProcess);
        curLocSunZensSeg = simState.sunZens(idxLoc, ...
            indicesDatetimeToProcess);
        
        radiusToInspectInM = simConfigs.RADIUS_TO_INSPECT_IN_M;
        maxAllowedLidarProfileResolutionInM = ...
            simConfigs.MAX_ALLOWED_LIDAR_PROFILE_RESOLUTION_IN_M;
        
        curLocUniformSunPowersSeg = ...
            curLocUniformSunPowers(indicesDatetimeToProcess);
        
        parfor idxIdxDatetime = 1:length(indicesDatetimeToProcess)
            idxDatetime = indicesDatetimeToProcess(idxIdxDatetime);
            % For debugging.
            try
                % Load our Python module for accessing USGS elevation data.
                py_addpath(fullfile(pwd, 'libs', 'python'));
                
                curSunAzi = curLocSunAzisSeg(idxIdxDatetime);
                curEndXY = ...
                    [curGridXY(1) ...
                    + sind(curSunAzi)*radiusToInspectInM, ...
                    curGridXY(2) ...
                    + cosd(curSunAzi)*radiusToInspectInM]; %#ok<PFBNS>
                
                % Construct the LiDAR z profile for this location and time.
                curSampLocs = generateTerrainProfileSampLocs( ...
                    curGridXY, curEndXY, ...
                    maxAllowedLidarProfileResolutionInM, 1);
                
                % Temporarily disable the warning.
                warning('off', ...
                    'MATLAB:dispatcher:UnresolvedFunctionHandle');
                [~, curLidarProfile, curElesForNanProfLocs] ...
                    = generateProfileSamps( ...
                    curSampLocs, utm2deg_speZone, ...
                    lidarFileXYCentroids, ...
                    lidarFileXYCoveragePolyshapes, ...
                    lidarMatFileAbsDirs, 'LiDAR');
                % Reenable warning.
                warning('on', ...
                    'MATLAB:dispatcher:UnresolvedFunctionHandle');
                
                if any(isnan(curLidarProfile))
                    warning(['[', datestr(now, datetimeFormat), ...
                        '] Part of the path (', ...
                        num2str(sum(isnan(curLidarProfile))), ...
                        ' samples) for loc #', num2str(idxLoc), ...
                        ' and time #', num2str(idxDatetime), ...
                        ' is not covered by the LiDAR data set!'])
                    warning(['USGS elevations will be used ', ...
                        'for invalid LiDAR z values!'])
                    curBoolsLidarSampsAreNan = isnan(curLidarProfile);
                    curLidarProfile(curBoolsLidarSampsAreNan) ...
                        = curElesForNanProfLocs(curBoolsLidarSampsAreNan);
                end
                
                curSunZen = curLocSunZensSeg(idxIdxDatetime);
                curAltsOnDirectPath = linspace( ...
                    curLidarProfile(1), ...
                    curLidarProfile(1) ...
                    + radiusToInspectInM/tand(curSunZen), ...
                    size(curSampLocs,1))';
                if any(curAltsOnDirectPath<curLidarProfile)
                    % Obstacle detected.
                    curLocUniformSunPowersSeg(idxIdxDatetime) = 0;
                else
                    % In the sun.
                    curLocUniformSunPowersSeg(idxIdxDatetime) = ...
                        computeUniformSunPowerFromZenith( ...
                        curLocSunZensSeg(idxIdxDatetime));
                end
            catch parErr
                warning(['[', datestr(now, datetimeFormat), ...
                    '] Error for loc #', num2str(idxLoc), ...
                    ' and time #', num2str(idxDatetime), '!'])
                disp(parErr.message);
                rethrow(parErr);
            end
        end
        
        simState.uniformSunPower(idxLoc, indicesDatetimeToProcess) ...
            = curLocUniformSunPowersSeg;
    end
    
    curNumOfLocTimePairsProcessed = ...
        curNumOfLocTimePairsProcessed+simState.numOfTimesToInspect;
    numOfLocTimePairsProcessed = ...
        numOfLocTimePairsProcessed+simState.numOfTimesToInspect;
    
    % For progress reporting. Note that we are interested in the overall
    % progress, so the number of dates needs to be considered, too.
    if curNumOfLocTimePairsProcessed/totalNumOfLocTimePairs ...
            > simConfigs.MIN_PROGRESS_RATIO_TO_REPORT*totalNumOfDays
        curNumOfLocTimePairsProcessed = 0;
        % Also take the chance to update the history results.
        save(dirToSaveSimState, 'simState', '-v7.3');
    end
    
    if numOfLocTimePairsProcessed == totalNumOfLocTimePairs
        % All done. Save the results.
        simState.flagShadowLocated = true;
        save(dirToSaveSimState, 'simState', '-v7.3');
        disp(['            [', ...
            datestr(now, datetimeFormat), '] Done!'])
    end
end

disp(['        [', datestr(now, datetimeFormat), ...
    '] Done!'])

%% Visualization: 3D LiDAR Plots for Debugging

disp(' ')
disp(['        [', datestr(now, datetimeFormat), ...
    '] Generating plots for LiDAR data in the area of interest ...'])

debugLidarDataForAreaOfInterest;

disp(['        [', datestr(now, datetimeFormat), ...
    '] Done!'])

%% Visualization: Video Clip for Shadow Location

disp(' ')
disp(['        [', datestr(now, datetimeFormat), ...
    '] Generating illustration video clip for shadow location ...'])

timeToPauseForFigUpdateInS = 0.001;
pathToSaveVideo = fullfile(folderToSaveResults, 'shadowLocOverTime.mp4');

% Video parameters.
simTimeLengthPerFrameInS = simConfigs.PLAYBACK_SPEED/simConfigs.FRAME_RATE;
assert(floor(simTimeLengthPerFrameInS)==simTimeLengthPerFrameInS, ...
    ['For simplicity, ', ...
    'please make sure PLAYBACK_SPEED/VIDEO_FRAME_RATE is an integer!']);

% Plot the background.
matRxLonLatWithPathLoss = [simConfigs.gridLatLonPts(:,[2,1]), ...
    simState.uniformSunPower(:,1)];
sunAziZens = [simState.sunAzis(:,1), simState.sunZens(:,1)];
[hFigShadowLoc, hsShadowMap] = ...
    plotSunShadowMap(matRxLonLatWithPathLoss, simConfigs, sunAziZens);
lastDatetime = simConfigs.localDatetimesToInspect(1);
title(datestr(lastDatetime, datetimeFormat));
drawnow; pause(timeToPauseForFigUpdateInS);

% Create a video writer for outputting the frames.
curVideoWriter = VideoWriter( ...
    pathToSaveVideo, 'MPEG-4');
curVideoWriter.FrameRate = simConfigs.FRAME_RATE;
open(curVideoWriter);

% Go through all remaining times.
for curIdxDatetime = 2:length(simConfigs.localDatetimesToInspect)
    curDatetime = simConfigs.localDatetimesToInspect(curIdxDatetime);
    
    % Output the video.
    lastSimTime = lastDatetime;
    for curSimTimeInS = lastDatetime:seconds(1):(curDatetime-seconds(1))
        elapsedSimTimeInS = seconds(curSimTimeInS-lastSimTime);
        if elapsedSimTimeInS>=simTimeLengthPerFrameInS
            writeVideo(curVideoWriter, getframe(hFigShadowLoc));
            lastSimTime = curSimTimeInS;
        end
    end
    
    % Update the figure.
    deleteHandles(hsShadowMap);
    
    matRxLonLatWithPathLoss = [simConfigs.gridLatLonPts(:,[2,1]), ...
        simState.uniformSunPower(:,curIdxDatetime)];
    sunAziZens = [simState.sunAzis(:,curIdxDatetime), ...
        simState.sunZens(:,curIdxDatetime)];
    [hFigShadowLoc, hsShadowMap] = ...
        plotSunShadowMap(matRxLonLatWithPathLoss, ...
        simConfigs, sunAziZens, hFigShadowLoc);
    title(datestr(curDatetime, datetimeFormat));
    drawnow; pause(timeToPauseForFigUpdateInS);
    
    lastDatetime = curDatetime;
end
% Output the last frame and close the video writer.
for curSimTimeInS ...
        = lastDatetime:seconds(1):(simConfigs.LOCAL_TIME_END-seconds(1))
    elapsedSimTimeInS = seconds(curSimTimeInS-lastSimTime);
    if elapsedSimTimeInS>=simTimeLengthPerFrameInS
        writeVideo(curVideoWriter, getframe(hFigShadowLoc));
        lastSimTime = curSimTimeInS;
    end
end
close(curVideoWriter);

disp(['        [', datestr(now, datetimeFormat), ...
    '] Done!'])

%% Statistics: Sun Engergy

disp(' ')
disp(['        [', datestr(now, datetimeFormat), ...
    '] Computing the sun energies ...'])
disp(['        [', datestr(now, datetimeFormat), ...
    '] Done!'])

disp(['    [', datestr(now, datetimeFormat), '] Done!'])

%% Cleanup

diary off;

% EOF