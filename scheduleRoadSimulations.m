%SCHEDULEROADSIMULATIONS A scheduler to carry out simualtions for a long
%road segment, chunk by chunk.
%
% Given the name for a road, and the start&end points for the segment of
% interest, we will create smaller segments and simulate the sun's shadow
% for these segements one by one.
%
% The simualtion scheduler/manager settings and outputs are saved in struct
% variables simManConfigs and simManState, respectively. Please refer to
% the comments in this file for more details.
%
% Yaguang Zhang, Purdue, 02/06/2021

% Avoid clearing big static variables.
clearvars -except indotRoads ROAD_PROJ ...
    indotMileMarkers MILE_MARKER_PROJ INDOT_MILE_MARKERS_ROADNAME_LABELS;
clc; close all; dbstop if error;

% Locate the Matlab workspace and save the current filename.
cd(fileparts(mfilename('fullpath'))); addpath('libs');
curFileName = mfilename;

prepareSimulationEnv;

flagInitiatedByRoadSimManager = true;
PRESET = 'U41_TerreHauteToRockville';

%% Script Parameters

% The absolute path to the folder for saving the results.
folderToSaveResults = fullfile(ABS_PATH_TO_SHARED_FOLDER, ...
    'SunShadowSimulatorResults', ['RoadSimSeries_', PRESET]);

% This is needed for creating the converters in
% constructUtmRoadSegPolygon.m.
simConfigs.UTM_ZONE = '16 T';

%% Simulation Manager Configurations

switch PRESET
    case 'U41_TerreHauteToRockville'
        % 	- A cell or a char vector for the name of the road. If it is a
        %   cell, we expect its first element being the road name to use in
        %   the Indiana road data set, and the second element being the
        %   road name to use in the Indiana milemarker data set. If it is a
        %   char vector, we will use it as the road name for both the road
        %   and the milemarker data sets.
        simManConfigs.ROAD_NAMES_FOR_CENTERLINES_AND_MILE_MARKERS = 'U41';
        %   - The (latitude, longitude) vectors for the start and end
        %   locations of the road segment of interest, respectively. If
        %   they are cells of (latitude, longitude), we will construct a
        %   polygon for each element pair and use the union of the results.
        simManConfigs.LAT_LON_START_PTS = { ...
            [39.466703, -87.414147], ... Left (west) side at Terre Haute
            [39.466703, -87.413768]}; % Right (east) side at Terre Haute
        simManConfigs.LAT_LON_END_PTS = { ...
            [39.762315, -87.236326], ... Left (west) side at Rockville
            [39.762322, -87.236162]}; % Right (east) side at Rockville
        
        %   - A positive float number to control (at most) how long of the
        %   road in meters will be covered in each simulation.
        simManConfigs.MAX_ROAD_SEG_LENGTH_PER_SIM_IN_M = 50;
        %   - We will use this spacial resolution to construct the
        %   inspection location grid for the area of interest.
        simManConfigs.GRID_RESOLUTION_IN_M = 3;
        
        %   - The time range of interest to inspect. The datetime for this
        %   is specified in terms of the local time without a time zone.
        %   The time zone will be derived from simConfigs.UTM_ZONE. The
        %   times to inspect are essentially constructed via something
        %   like:
        %     inspectTimeStartInS:inspectTimeIntervalInS:inspectTimeEndInS
        simManConfigs.LOCAL_TIME_START = datetime('11-Feb-2021 06:00:00');
        simManConfigs.LOCAL_TIME_END = datetime('11-Feb-2021 18:00:00');
        simManConfigs.TIME_INTERVAL_IN_M = 30; % In minutes.
        
        %   - The zone label to use in the UTM (x, y) system. Note: this
        %   will be used for preprocessing the LiDAR data, too; so if it
        %   changes, the history LiDAR data will become invalid.
        simManConfigs.UTM_ZONE = '16 T';
    otherwise
        error(['Unsupported preset "', PRESET, '"!'])
end

%% Derive Other Configurations Accordingly

% Turn the diary logging function on.
dirToSaveManDiary = fullfile(folderToSaveResults, 'diary.txt');
if ~exist(dirToSaveManDiary, 'file')
    if ~exist(folderToSaveResults, 'dir')
        mkdir(folderToSaveResults)
    end
    fclose(fopen(dirToSaveManDiary, 'w'));
end
diary(dirToSaveManDiary);

disp(' ')
disp(['    [', datestr(now, datetimeFormat), ...
    '] Configuring the simulation series for PRESET ', PRESET, ' ...'])

% Save simManConfigs if it is not yet done.
dirToSaveSimManConfigs = fullfile(folderToSaveResults, ...
    'simManConfigs.mat');
if exist(dirToSaveSimManConfigs, 'file')
    disp(['        [', datestr(now, datetimeFormat), ...
        '] The specified PRESET "', ...
        PRESET, '" has been processed before.'])
    disp(['        [', datestr(now, datetimeFormat), ...
        '] Loading history simManConfigs ...'])
    histSimManConfigs = load(dirToSaveSimManConfigs);
    if ~isequaln(histSimManConfigs.simManConfigs, simManConfigs)
        error(['        [', datestr(now, datetimeFormat), ...
            '] The settings for this PRESET have changed!']);
    end
else
    % Note that the simManConfigs saved now only contains user-specified
    % parameters.
    save(dirToSaveSimManConfigs, 'simManConfigs', '-v7.3');
end

% The location for saving history results of simManState, just in case any
% interruption happens.
dirToSaveSimManState = fullfile(folderToSaveResults, 'simManState.mat');

% For GPS and UTM conversions.
[deg2utm_speZone, utm2deg_speZone] ...
    = genUtmConvertersForFixedZone(simConfigs.UTM_ZONE);
% Store these functions in simConfigs.
simConfigs.deg2utm_speZone = deg2utm_speZone;
simConfigs.utm2deg_speZone = utm2deg_speZone;

if exist(dirToSaveSimManState, 'file')
    load(dirToSaveSimManState, 'simManState');
else
    % Construct a polyshape for the road segment of interest.
    disp(['        [', datestr(now, datetimeFormat), ...
        '] Constructing a polyshape for the road segment of interest ...'])
    [utmRoadSegOfInterestPoly, ~, roadNameForMileMarkers] ...
        = constructUtmRoadSegPolygon( ...
        simManConfigs.ROAD_NAMES_FOR_CENTERLINES_AND_MILE_MARKERS, ...
        simManConfigs.LAT_LON_START_PTS, simManConfigs.LAT_LON_END_PTS);
    simManState.utmRoadSegOfInterestPolyshape ...
        = polyshape(utmRoadSegOfInterestPoly);
    
    % Compute the mileages for the vertices to estimate the total road
    % segment length.
    disp(['        [', datestr(now, datetimeFormat), ...
        '] Computing the mileages for the vertices ...'])
    simManState.utmRoadSegOfInterestPolyshapePtMileages ...
        = estimateVertexMileagesForUtmPolyshape( ...
        simManState.utmRoadSegOfInterestPolyshape, ...
        utm2deg_speZone, roadNameForMileMarkers);
    mileageStart = min( ...
        simManState.utmRoadSegOfInterestPolyshapePtMileages);
    mileageEnd = max( ...
        simManState.utmRoadSegOfInterestPolyshapePtMileages);
    totalRoadSegLengthInMiles = mileageEnd - mileageStart;
    totalRoadSegLengthInM = distdim(totalRoadSegLengthInMiles, ...
        'miles', 'meters');
    
    % Break the whole road segment into shorter ones.
    disp(['        [', datestr(now, datetimeFormat), ...
        '] Splitting the whole road segment into shorter ones ...'])
    numOfSimsNeeded = ceil(totalRoadSegLengthInM ...
        /simManConfigs.MAX_ROAD_SEG_LENGTH_PER_SIM_IN_M);
    simBreakPtsMileages = linspace(mileageStart, mileageEnd, ...
        numOfSimsNeeded+1)';
    [simBreakPtsXs, simBreakPtsYs] = mileage2XY(simBreakPtsMileages, ...
        simManState.utmRoadSegOfInterestPolyshape, ...
        simManState.utmRoadSegOfInterestPolyshapePtMileages);
    simManState.utmXYBoundariesOfInterest = cell(numOfSimsNeeded,1);
    % Also store the directories for saving the results of all simulations.
    simManState.foldersToSaveResults = cell(numOfSimsNeeded,1);
    for idxSim = 1:numOfSimsNeeded
        [utmBoundariesOfInterestXs, utmBoundariesOfInterestYs] ...
            = boundary(extractRoadSegUtmPolyshapeBetweenPts( ...
            simManState.utmRoadSegOfInterestPolyshape, ...
            simManState.utmRoadSegOfInterestPolyshapePtMileages, ...
            [simBreakPtsXs(idxSim), simBreakPtsYs(idxSim), ...
            simBreakPtsMileages(idxSim); ...
            simBreakPtsXs(idxSim+1), simBreakPtsYs(idxSim+1), ...
            simBreakPtsMileages(idxSim+1)]));
        simManState.utmXYBoundariesOfInterest{idxSim} ...
            = [utmBoundariesOfInterestXs, utmBoundariesOfInterestYs];
        simManState.foldersToSaveResults{idxSim} ...
            = fullfile(folderToSaveResults, ...
            ['simSeries_', num2str(idxSim)]);
    end
    
    % Flags to record which simulations are already done.
    simManState.flagsSimCompleted = false(numOfSimsNeeded, 1);
    
    save(dirToSaveSimManState, 'simManState', '-v7.3');
end
disp(['    [', datestr(now, datetimeFormat), '] Done!'])

%% Generate Overview Plots

disp(' ')
disp(['    [', datestr(now, datetimeFormat), ...
    '] Generating plots ...'])

% The whole road segment of interest on map.
dirToSaveFigRoadSegOfInterest ...
    = fullfile(folderToSaveResults, 'roadOfInterest');
hFigRoadSegOfInterest = figure;
[roadSegOfInterestLats, roadSegOfInterestLons] = utm2deg_speZone( ...
    simManState.utmRoadSegOfInterestPolyshape.Vertices(:,1), ...
    simManState.utmRoadSegOfInterestPolyshape.Vertices(:,2));
plot(roadSegOfInterestLons, roadSegOfInterestLats, 'LineWidth', 3);
plot_google_map('MapType', 'hybrid');
saveas(hFigRoadSegOfInterest, [dirToSaveFigRoadSegOfInterest, '.fig']);
saveas(hFigRoadSegOfInterest, [dirToSaveFigRoadSegOfInterest, '.jpg']);

% All the simulation segments on map.
dirToSaveFigSimRoadSegs ...
    = fullfile(folderToSaveResults, 'roadSegsForSim');
hFigSimRoadSegs = figure; hold on;
for idxSimRoadSeg = 1:length(simManState.utmXYBoundariesOfInterest)
    curUtmXYBoundariesOfInterest ...
        = simManState.utmXYBoundariesOfInterest{idxSimRoadSeg};
    [roadSegOfInterestLats, roadSegOfInterestLons] = utm2deg_speZone( ...
        curUtmXYBoundariesOfInterest(:,1), ...
        curUtmXYBoundariesOfInterest(:,2));
    plot(roadSegOfInterestLons, roadSegOfInterestLats, 'LineWidth', 3);
end
plot_google_map('MapType', 'hybrid');
saveas(hFigSimRoadSegs, [dirToSaveFigSimRoadSegs, '.fig']);
saveas(hFigSimRoadSegs, [dirToSaveFigSimRoadSegs, '.jpg']);

disp(['    [', datestr(now, datetimeFormat), '] Done!'])

%% Run the Simulations

disp(' ')
disp(['    [', datestr(now, datetimeFormat), ...
    '] Running simulations ...'])

numOfSimSeries = length(simManState.flagsSimCompleted);
for idxSim = 1:numOfSimSeries
    if ~simManState.flagsSimCompleted(idxSim)
        disp(' ')
        disp(fileNameHintRuler)
        disp(['        [', datestr(now, datetimeFormat), ...
            '] Conducting simulation series #', num2str(idxSim), '...'])
        disp(fileNameHintRuler)
        disp(' ')
        diary off;
        simulateSunShadow;
        diary(dirToSaveManDiary);
        % Update and save the flags.
        simManState.flagsSimCompleted(idxSim) = true;
        save(dirToSaveSimManState, 'simManState', '-append');
    end
end

disp(['    [', datestr(now, datetimeFormat), '] Done!'])

%% Cleanup

disp(' ')
disp(['    [', datestr(now, datetimeFormat), ...
    '] Finishing simulation ...'])
clearvars flagCalledByRoadSimManager;
disp(['    [', datestr(now, datetimeFormat), ...
    '] Done!'])

diary off;

% EOF