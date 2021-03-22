%COMPARESIMWITHPHOTOS Carry out simulations for selected photos and
%evaluate the results.
%
% Based on simulateSunShadow.m.
%
% Yaguang Zhang, Purdue, 03/14/2020

%% Set Up Presets

% Locate the Matlab workspace and save the current filename.
cd(fileparts(mfilename('fullpath')));
cd(fullfile('..', '..')); addpath('libs');
curFileName = mfilename;

prepareSimulationEnv;

dirToPhotoFolder = fullfile(ABS_PATH_TO_SHARED_FOLDER, ...
    'SelectedPhotosForShadow');

% Load information for all scenarios.
scenarioFolders = dir(dirToPhotoFolder);
scenarioFolders = scenarioFolders([scenarioFolders.isdir]);
scenarioFolders(ismember({scenarioFolders.name}, {'.', '..'})) = [];

numOfScenarios = length(scenarioFolders);
% Required information from the simulation and visualization.
[dirToJpgsSceCell, datetimesLocalSceCell, ...
    cameraLatLonHsSceCell, targetLatLonsSceCell, ...
    boundOfIntUtmXYsSceCell, simLabelsSceCell] ...
    = deal(cell(numOfScenarios, 1));
[deg2utmSpeZone, utm2degSpeZone] ...
    = genUtmConvertersForFixedZone('16 T');
sideLenForAreaOfIntInM = 200;
for idxScenario = 1:numOfScenarios
    curScenarioFolderName = scenarioFolders(idxScenario).name;
    curScenarioLabel = curScenarioFolderName( ...
        find(isletter(curScenarioFolderName),1):end);
    curScenarioFolder = fullfile(scenarioFolders(idxScenario).folder, ...
        curScenarioFolderName);
    
    % Try loading camera height (required) and location (optional).
    cameraLatLon = [];
    dirToCamH = fullfile(curScenarioFolder, 'CameraHeight.csv');
    dirToCamLatLonH = fullfile(curScenarioFolder, ...
        'CameraLatLonHeight.csv');
    if exist(dirToCamH, 'file')
        cameraHInM = readmatrix(dirToCamH);
        assert(length(cameraHInM)==1, ...
            'Only one height value is expected!')
    elseif exist(dirToCamLatLonH, 'file')
        cameraLatLonHInM = readmatrix(dirToCamLatLonH);
        assert(length(cameraLatLonHInM)==3, 'Three values are expected!')
        
        cameraLatLon = cameraLatLonHInM(1:2);
        cameraHInM = cameraLatLonHInM(3);
    else
        error('Was not able to find the camera height!')
    end
    
    % Try loading the target location the camera looks at (optional).
    targetLatLon = [];
    dirToTargetLatLon = fullfile(curScenarioFolder, ...
        'CameraLookingAtLatLon.csv');
    if exist(dirToCamLatLonH, 'file')
        targetLatLon = readmatrix(dirToTargetLatLon);
        assert(length(targetLatLon)==2, 'Two values are expected!')
    end
    
    curDirsToJpgs = dir(fullfile(curScenarioFolder, '*.jpg'));
    % Get rid of preview figures.
    curDirsToJpgs(endsWith({curDirsToJpgs.name}, '_PreviewMap.jpg')) = [];
    % Get rid of comparison figures.
    curDirsToJpgs(endsWith({curDirsToJpgs.name}, '_Comp.jpg')) = [];
    % Get rid of result figures.
    curDirsToJpgs(endsWith({curDirsToJpgs.name}, ...
        '_SimResultsOnMap.jpg')) = [];
    curDirsToJpgs(endsWith({curDirsToJpgs.name}, ...
        '_SimResults3D.jpg')) = [];
    curNumOfPresets = length(curDirsToJpgs);
    
    [dirToJpgsSceCell{idxScenario}, datetimesLocalSceCell{idxScenario}, ...
        simLabelsSceCell{idxScenario}, ...
        boundOfIntUtmXYsSceCell{idxScenario}] ...
        = deal(cell(curNumOfPresets, 1));
    cameraLatLonHsSceCell{idxScenario} = nan(curNumOfPresets, 3);
    targetLatLonsSceCell{idxScenario} = nan(curNumOfPresets, 2);
    for curIdxPreset = 1:curNumOfPresets
        curPreset = [curScenarioLabel, '_', num2str(curIdxPreset)];
        
        curDirToJpg = fullfile(curDirsToJpgs(curIdxPreset).folder, ...
            curDirsToJpgs(curIdxPreset).name);
        
        dirToJpgsSceCell{idxScenario}{curIdxPreset} = curDirToJpg;
        
        [curCameraLatLon, curPhotoDatetime] ...
            = readLatLonTimeFromJpg(curDirToJpg);
        datetimesLocalSceCell{idxScenario}{curIdxPreset} ...
            = curPhotoDatetime;
        
        % The GPS information from manually created .csv file is
        % prioritized.
        if ~isempty(cameraLatLon)
            curCameraLatLon = cameraLatLon;
        end
        cameraLatLonHsSceCell{idxScenario}(curIdxPreset, :) ...
            = [curCameraLatLon, cameraHInM];
        
        [curDirToTargetLocCsvPath, curDirToTargetLocCsvName, ~] ...
            = fileparts(curDirToJpg);
        if isempty(targetLatLon)
            curDirToTargetLocCsv = fullfile(curDirToTargetLocCsvPath, ...
                [curDirToTargetLocCsvName, '.csv']);
            curTargetLatLon = readmatrix(curDirToTargetLocCsv);
        else
            curTargetLatLon = targetLatLon;
        end
        targetLatLonsSceCell{idxScenario}(curIdxPreset, :) ...
            = curTargetLatLon;
        
        simLabelsSceCell{idxScenario}{curIdxPreset} ...
            = [curScenarioLabel, '_', num2str(curIdxPreset)];
        
        boundOfIntUtmXYsSceCell{idxScenario}{curIdxPreset} ...
            = constructUtmXYBoundOfIntForPhoto( ...
            curCameraLatLon, curTargetLatLon, deg2utmSpeZone, ...
            sideLenForAreaOfIntInM);
        
        [boundOfIntLats, boundOfIntLons] = utm2degSpeZone( ...
            boundOfIntUtmXYsSceCell{idxScenario}{curIdxPreset}(:, 1), ...
            boundOfIntUtmXYsSceCell{idxScenario}{curIdxPreset}(:, 2));
        
        % Plot the camera and target locations, together with the
        % simulation boundary of interest, on a map.
        curDirToSavePreviewFig = fullfile(curDirToTargetLocCsvPath, ...
            [curDirToTargetLocCsvName, '_PreviewMap.jpg']);
        
        if ispc && ~exist(curDirToSavePreviewFig, 'file')
            hFigPreview = figure; hold on;
            hBound = plot(polyshape(boundOfIntLons, boundOfIntLats), ...
                'FaceColor', 'y', 'FaceAlpha', 0.1);
            plot([curCameraLatLon(2), curTargetLatLon(2)], ...
                [curCameraLatLon(1), curTargetLatLon(1)], '--w');
            hCam = plot(curCameraLatLon(2), curCameraLatLon(1), 'sg');
            hTar = plot(curTargetLatLon(2), curTargetLatLon(1), '*r');
            plot_google_map('MapType', 'hybrid');
            xticks([]); yticks([]);
            title(['Sim ', ...
                simLabelsSceCell{idxScenario}{curIdxPreset}, ': ', ...
                datestr(datetimesLocalSceCell{idxScenario}{curIdxPreset})], ...
                'Interpreter', 'none');
            legend([hCam, hTar, hBound], 'Camera', 'Target', ...
                'Simulation Area');
            saveas(hFigPreview, curDirToSavePreviewFig);
        end
    end
end

% Cache the info for simulation.
presetsInfo.dirToJpgs = vertcat(dirToJpgsSceCell{:});
presetsInfo.datetimesLocal = vertcat(datetimesLocalSceCell{:});
presetsInfo.cameraLatLonHs = vertcat(cameraLatLonHsSceCell{:});
presetsInfo.targetLatLons = vertcat(targetLatLonsSceCell{:});
presetsInfo.sideLenForAreaOfIntInM = sideLenForAreaOfIntInM;
presetsInfo.boundOfIntUtmXYs = vertcat(boundOfIntUtmXYsSceCell{:});
presetsInfo.simLabels = vertcat(simLabelsSceCell{:});

for idxPreset = 1:length(presetsInfo.simLabels)
    %% Initialization for Each Preset
    PRESET = presetsInfo.simLabels{idxPreset};
    
    % Avoid clearing (1) required variables by the simulation manager, and
    % (2) big static variables.
    clearvars -except presetsInfo PRESET ...
        flagInitiatedByRoadSimManager dirToSaveManDiary idxSim ...
        indotRoads ROAD_PROJ ...
        indotMileMarkers MILE_MARKER_PROJ ...
        INDOT_MILE_MARKERS_ROADNAME_LABELS;
    clc; close all; dbstop if error;
    
    % Locate the Matlab workspace and save the current filename.
    cd(fileparts(mfilename('fullpath')));
    cd(fullfile('..', '..')); addpath('libs');
    curFileName = mfilename;
    
    prepareSimulationEnv;
    
    % This script will be run directly, so flagInitiatedByRoadSimManager
    % will not be set and we will run the simulation for a scenario defined
    % below in this script. Please refer to the Simulation Configurations
    % section for the supported presets.
    flagInitiatedByRoadSimManager = false;
    
    %% Script Parameters
    
    % The LiDAR data set to use. Currently we only suppor the 2019 Indiana
    % state-wide digital surface model (DSM) data from:
    %       https://lidar.jinha.org/
    % Set this to "IN_DSM_2019"/"IN_DSM_2019_DEMO" for the complete/a demo
    % data set.
    LIDAR_DATA_SET_TO_USE = 'IN_DSM_2019';
    
    % The absolute path to the folder for saving the results.
    rootFolderToSaveResults = fullfile(ABS_PATH_TO_SHARED_FOLDER, ...
        'SunShadowSimulatorResults', 'ComparisonsWithPhotos');
    folderToSaveResults = fullfile(rootFolderToSaveResults, ...
        ['Simulation_', PRESET, ...
        '_LiDAR_', LIDAR_DATA_SET_TO_USE]);
    
    %% Simulation Configurations
    
    % We will organize all the necessary configurations into a structure
    % called simConfigs. User assigned configuration values are in
    % SCREAMING_SNAKE_CASE, while parameters derived accordingly are in
    % camelCase.
    %   - A string label to identify this simulation.
    simConfigs.CURRENT_SIMULATION_TAG = PRESET;
    
    %   - The UTM (x, y) polygon boundary vertices representing the area of
    %   interest for generating the coverage maps; note that it is possible
    %   to use the region covered by the available LiDAR data set as the
    %   corresponding area of interest.
    idxPreset = find(strcmp(presetsInfo.simLabels, PRESET));
    if ~isempty(idxPreset) && length(idxPreset)==1
        %   - Load the area of interest.
        simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST ...
            = presetsInfo.boundOfIntUtmXYs{idxPreset};
        %   - The time range of interest to inspect. The datetime for this
        %   is specified in terms of the local time without a time zone.
        %   The time zone will be derived from simConfigs.UTM_ZONE. The
        %   times to inspect are essentially constructed via something
        %   like:
        %       inspectTimeStartInS:inspectTimeIntervalInS:inspectTimeEndInS
        [simConfigs.LOCAL_TIME_START, simConfigs.LOCAL_TIME_END] ...
            = deal(presetsInfo.datetimesLocal{idxPreset});
    else
        error(['Unsupported preset "', PRESET, '"!'])
    end
    
    %   - We will use this spacial resolution to construct the inspection
    %   location grid for the area of interest.
    simConfigs.GRID_RESOLUTION_IN_M = 1.5;
    %   - We will use this time resolution. For photos only one time will
    %   be inspected, so this value does not matter much.
    simConfigs.TIME_INTERVAL_IN_M = 30; % In minutes.
    
    %   - The zone label to use in the UTM (x, y) system. Note: this will
    %   be used for preprocessing the LiDAR data, too; so if it changes,
    %   the history LiDAR data will become invalid.
    simConfigs.UTM_ZONE = '16 T';
    
    %   - The guaranteed spatial resolution for LiDAR profiles; a larger
    %   value will decrease the simulation time and the simulation accuracy
    %   (e.g., small obstacles may get ignored).
    simConfigs.MAX_ALLOWED_LIDAR_PROFILE_RESOLUTION_IN_M = 1.5;
    
    %   - For each location of interest, only a limited distance of the
    %   LiDAR data will be inspected. Increase this parameter will increase
    %   the computation needed for the simulation, but if this parameter is
    %   too low, the accuracy of the simulation may decrease, too,
    %   especially for the case when the sun is at a low angle (then a low
    %   obstacle far away may still block the location of interest).
    %     The length of the LiDAR profile needs to be chosen wisely because
    %     obstacles could cause extremely long shadows at sunset/sunrise.
    %     Say the sunshine duration is 12 hours/day and the sun location is
    %     uniformly distributed in [0, 180] degrees, where 0 degree
    %     corresponds to sunrise and 180 degrees corresponds to sunset.
    %     Then, if we would like to allow inaccurate results for 15 min of
    %     sunshine right after the sunrise and before the sunset, with a
    %     typical three-story building (~10 m high), we would need a radius
    %     to inspect of r meters such that:
    %         arctand(10/r)*2/180 *12*60 = 15*2
    %     We can get r here is around 152 meters:
    %         r = 10/tand(15*2/60/12*180/2) = 152.5705
    simConfigs.RADIUS_TO_INSPECT_IN_M = 150;
    
    %   - For adjusting the feedback frequency.
    simConfigs.MIN_PROGRESS_RATIO_TO_REPORT = 0.05;
    
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
    simConfigs.PLAYBACK_SPEED = 900; % Relative to real time.
    
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
            error(['        [', datestr(now, datetimeFormat), ...
                '] The settings for this PRESET have changed!']);
        end
    else
        % Note that the simConfigs saved now only contains user-specified
        % parameters.
        save(dirToSaveSimConfigs, 'simConfigs', '-v7.3');
    end
    
    % The location for saving history results of simState and the extended
    % version of simConfigs, just in case any interruption happens.
    dirToSaveSimState = fullfile(folderToSaveResults, 'simState.mat');
    
    % For GPS and UTM conversions.
    [deg2utm_speZone, utm2deg_speZone] ...
        = genUtmConvertersForFixedZone(simConfigs.UTM_ZONE);
    
    if exist(dirToSaveSimState, 'file')
        load(dirToSaveSimState, 'simConfigs');
    else
        % Pre-assign LIDAR_DATA_SET_TO_USE based on the user's settings. We
        % will verify this value later.
        simConfigs.LIDAR_DATA_SET_TO_USE = LIDAR_DATA_SET_TO_USE;
        
        % Store these functions in simConfigs.
        simConfigs.deg2utm_speZone = deg2utm_speZone;
        simConfigs.utm2deg_speZone = utm2deg_speZone;
        
        % The time zone to use for the observer is derived from the UTM
        % zone.
        [~, zoneCenterLon] = simConfigs.utm2deg_speZone(500000,0);
        simConfigs.timezone = -timezone(zoneCenterLon);
        
        % The local datetimes to inspect.
        if isfield(simConfigs, 'DATE_INTERVAL_IN_D')
            simConfigs.localDatetimesToInspect ...
                = constructDatetimesToInspect( ...
                simConfigs.LOCAL_TIME_START, simConfigs.LOCAL_TIME_END, ...
                simConfigs.TIME_INTERVAL_IN_M, simConfigs.DATE_INTERVAL_IN_D);
        else
            simConfigs.localDatetimesToInspect ...
                = constructDatetimesToInspect( ...
                simConfigs.LOCAL_TIME_START, simConfigs.LOCAL_TIME_END, ...
                simConfigs.TIME_INTERVAL_IN_M);
        end
        
        % The locations of interest to inspect.
        if isfield(simConfigs, 'LAT_LON_BOUNDARY_OF_INTEREST')
            if isfield(simConfigs, 'UTM_X_Y_BOUNDARY_OF_INTEREST')
                error(['Boundry of interest was set ', ...
                    'both in GPS (lat, lon) and UTM (x, y)!'])
            else
                disp(['        [', datestr(now, datetimeFormat), ...
                    '] Converting LAT_LON_BOUNDARY_OF_INTEREST to ', ...
                    'UTM_X_Y_BOUNDARY_OF_INTEREST ...'])
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
        % Only one way of specifying the locations to inspect is expected
        % to be used.
        if sum([flagGpsPtsOfInterestSpecified; flagAreaOfInterestSpecified])~=1
            error('Not able to consctruct the locations of interest!');
        end
        
        if flagGpsPtsOfInterestSpecified
            % If the GPS locations to inspect are set, we will use them
            % directly.
            simConfigs.gridLatLonPts = simConfigs.LAT_LON_PTS_OF_INTEREST;
            
            [gridXs,gridYs] = simConfigs.deg2utm_speZone( ...
                simConfigs.gridLatLonPts(:,1), simConfigs.gridLatLonPts(:, 2));
            simConfigs.gridXYPts = [gridXs,gridYs];
        elseif flagAreaOfInterestSpecified
            if isstring(simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST)
                disp(['        [', datestr(now, datetimeFormat), ...
                    '] Constructing UTM road segment of interest ...'])
                disp(' ')
                eval(strcat("simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST = ", ...
                    simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST));
                disp(' ')
            end
            
            % After the area of interest is properly set, we will generate
            % a grid to inspect accordingly.
            gridMinX = min(simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,1));
            gridMaxX = max(simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,1));
            gridMinY = min(simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,2));
            gridMaxY = max(simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,2));
            
            gridResolutionInM = simConfigs.GRID_RESOLUTION_IN_M;
            
            gridXLabels = constructAxisGrid( ...
                mean([gridMaxX, gridMinX]), ...
                floor((gridMaxX-gridMinX)./gridResolutionInM), ...
                gridResolutionInM);
            gridYLabels = constructAxisGrid( ...
                mean([gridMaxY, gridMinY]), ...
                floor((gridMaxY-gridMinY)./gridResolutionInM), ...
                gridResolutionInM);
            [gridXs,gridYs] = meshgrid(gridXLabels,gridYLabels);
            
            % For reconstructing the grid in 2D if necessary.
            simConfigs.numOfPixelsForLongerSide = ...
                max(length(gridXLabels), length(gridYLabels));
            
            % Make sure there are no grid points out of the area of
            % interest.
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
        
        save(dirToSaveSimState, 'simConfigs', '-v7.3');
    end
    
    % Append extra fields for easier data importation in other languages,
    % e.g., Python.
    dirToSaveSimConfigsExtra = fullfile(folderToSaveResults, ...
        'simConfigsExtra.mat');
    if ~exist(dirToSaveSimConfigsExtra, 'file')
        simConfigs.utcUnixTimesInSToInspect = nan( ...
            size(simConfigs.localDatetimesToInspect));
        numOfTimes = length(simConfigs.localDatetimesToInspect(:));
        for idxTime = 1:numOfTimes
            simConfigs.utcUnixTimesInSToInspect(idxTime) ...
                = localDatetime2UtcUnixTimeInS( ...
                simConfigs.localDatetimesToInspect(idxTime), ...
                simConfigs.timezone);
        end
        save(dirToSaveSimConfigsExtra, 'simConfigs', '-v7.3');
    end
    
    disp(['    [', datestr(now, datetimeFormat), '] Done!'])
    
    %% Preprocessing LiDAR Data
    % Note: the first time of this may take a long time, depending on the
    % size of the LiDAR data set, but (1) it supports recovery from
    % interruptions, and (2) once we have gone through all the data once,
    % loading the information would be very fast.
    
    % Set the dir to find the LiDAR data set.
    switch simConfigs.LIDAR_DATA_SET_TO_USE
        case 'IN_DSM_2019_DEMO'
            dirToLidarFiles = fullfile(ABS_PATH_TO_LIDAR, ...
                'Lidar_2019', 'IN', 'DSM_Demo');
        case 'IN_DSM_2019'
            dirToLidarFiles = fullfile(ABS_PATH_TO_LIDAR, ...
                'Lidar_2019', 'IN', 'DSM');
        otherwise
            error(['Unkown LiDAR data set ', ...
                simConfigs.LIDAR_DATA_SET_TO_USE, '!'])
    end
    
    % Preprocess .img/.tif LiDAR data. To make Matlab R2019b work, we need
    % to remove preprocessIndianaLidarDataSet from path after things are
    % done.
    addpath(fullfile(pwd, 'libs', 'lidar'));
    [lidarFileRelDirs, lidarFileXYCoveragePolyshapes, ~] ...
        = preprocessIndianaLidarDataSetDsm(dirToLidarFiles, ...
        simConfigs.deg2utm_speZone, simConfigs.utm2deg_speZone);
    rmpath(fullfile(pwd, 'libs', 'lidar'));
    lidarFileAbsDirs = cellfun(@(d) ...
        [dirToLidarFiles, strrep(d, '\', filesep)], ...
        lidarFileRelDirs, 'UniformOutput', false);
    
    % Extra information on the LiDAR data set.
    %   - Overall boundry for the area covered by the LiDAR data set in
    %   UTM.
    lidarFilesXYCoveragePolyshape ...
        = mergePolygonsForAreaOfInterest(lidarFileXYCoveragePolyshapes, 1);
    %   - Centroids for the LiDAR files in UTM.
    lidarFileXYCentroids ...
        = extractCentroidsFrom2DPolyCell(lidarFileXYCoveragePolyshapes);
    %   - The .mat copies for the LiDAR data. For the 2019 dataset, they
    %   are stored in a cache folder.
    lidarMatFileAbsDirs = lidarFileAbsDirs;
    for idxMatF = 1:length(lidarMatFileAbsDirs)
        [lidarMatFPath, lidarMatFName, ~] ...
            = fileparts(lidarMatFileAbsDirs{idxMatF});
        lidarMatFileAbsDirs{idxMatF} = fullfile(lidarMatFPath, '..', ...
            'MatlabCache', [lidarMatFName, '.mat']);
    end
    
    %% Simulation: Initialization
    
    disp(' ')
    disp(['    [', datestr(now, datetimeFormat), ...
        '] Conducting simulation ...'])
    
    % Because simState.mat not only stores simState, but also the extended
    % version of simConfigs, we can check first whether simState is already
    % in the file without loading the file's content.
    listOfSimStateVs = who('-file', dirToSaveSimState);
    if exist(dirToSaveSimState, 'file') ...
            && ismember('simState', listOfSimStateVs)
        disp(['        [', datestr(now, datetimeFormat), ...
            '] The specified PRESET "', ...
            PRESET, '" has been processed before.'])
        disp(['        [', datestr(now, datetimeFormat), ...
            '] Loading history simState ...'])
        load(dirToSaveSimState, 'simState');
    else
        disp(['        [', datestr(now, datetimeFormat), ...
            '] Initializing simState ...'])
        % Load history results if they are available. This is for recovery
        % from interruptions. We will save all simulation output in a
        % struct variable simState.
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
        %     need to find the times to inspect that are in the same days.
        %     Note that we do not need time zone compensation here.
        simState.dayLabels = findgroups( ...
            localDatetime2UtcUnixTimeInS( ...
            dateshift(simConfigs.localDatetimesToInspect, 'Start', 'day'), 0));
        %   - The integer labels for local days to inspect.
        simState.numOfDays = max(simState.dayLabels);
        
        % Preassign storage for the simulation outputs. The sunrise and
        % sunset time for all grid locations will be stored as columns of
        % cell matrices, with each column being the results for one day.
        % Note: for convenience, we will convert them from fractional hours
        % (which is the output format of the SPA function) to datatime and
        % store the results in simState.
        [simState.sunriseDatetimes, simState.sunsetDatetimes] ...
            = deal(cell([simState.numOfGridPts, simState.numOfDays]));
        
        % The sun position information and the resultant uniform sun power
        % values are stored as columns of a huge matrix, corresponding to
        % the grid locations, with each column being the results for one
        % local datetime to inspect.
        %   - Topocentric azimuth angle (eastward from north) [0 to 360
        %   degrees].
        %     The angle formed by the projection of the direction of the
        %     sun on the horizontal plane.
        %   - Topocentric zenith angle [degrees].
        %     Note: Zenith  = 90 degrees - elevation angle
        %   - Uniform sun powers
        %     Ratios in [0,1], where 0 means in the shadow and 1 means
        %     direct sunshine (at a zenith of 90 degrees).
        [simState.sunAzis, simState.sunZens, simState.uniformSunPower] ...
            = deal(nan([simState.numOfGridPts, simState.numOfTimesToInspect]));
        
        % Generate a history file. Note that the simConfigs saved now
        % contains information derived from the parameters set by the
        % users.
        save(dirToSaveSimState, 'simConfigs', 'simState', '-v7.3');
    end
    
    disp(['    [', datestr(now, datetimeFormat), ...
        '] Done!'])
    
    %% Simulation Overview Plot
    
    % Always generate the figures when the PRESET is not RoadSimManager.
    % Otherwise, only generate the figures once.
    pathToSaveGridOnMapOverview = fullfile(folderToSaveResults, ...
        'gridOnMapOverview');
    if strcmp(PRESET, 'RoadSimManager')
        if ~exist(pathToSaveGridOnMapOverview, 'file')
            overviewGridOnMap;
        end
    else
        overviewGridOnMap;
    end
    
    %% Simulation: Sunrise and Sunset Times
    
    disp(' ')
    disp(['    [', datestr(now, datetimeFormat), ...
        '] Computing sun positions in the daytime ...'])
    % We will go through each day to inspect, each datetime to inspect in
    % that day, and each grid location to inspect.
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
        numOfLocDatePairsProcessed = 0;
        clearvars curEle;
        for idxLoc = 1:totalNumOfLocs
            curXY = simConfigs.gridXYPts(idxLoc, :);
            curLatLon = simConfigs.gridLatLonPts(idxLoc, :);
            
            % If this day has not been processed for this location before,
            % we first get the sunrise and sunset times, and mark the times
            % at night accordingly as "in shadow" for this location.
            curIdxDatetime = indicesTimesToInspect(1);
            flagSimStateUpdated = false;
            if isnan(simState.sunAzis(idxLoc, curIdxDatetime))
                % Simulate the first datetime to inspect for this day to
                % get the information needed.
                curDatetime = simConfigs.localDatetimesToInspect( ...
                    curIdxDatetime);
                
                % We will use the profile generation function to fetch the
                % LiDAR z value and use that as the elevation for the point
                % of interest. Essentially, it is a profile with only one
                % location in it. Note that this is different from the
                % terrain elevation simState.gridEles (the height of the
                % ground) .
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
                
                % If the elevation for the point of interest is not valid,
                % we will switch to Google ground elevation data for the
                % observer's height.
                if isnan(curObserverEle) || isinf(curObserverEle)
                    if ~exist('apiKey', 'var')
                        % The library plot_google_map should have generated
                        % a cache .mat file with a valid Google Maps API
                        % key if it runs successfully. If not so, please
                        % run plot_google_map with a key first.
                        load('api_key.mat', 'apiKey');
                    end
                    curObserverEle = getElevations( ...
                        curLatLon(1), curLatLon(2), ...
                        'key', apiKey);
                end
                
                curSpaIn = constructSpaStruct(simConfigs.timezone, ...
                    curDatetime, [curLatLon curObserverEle]);
                % Calculate zenith, azimuth, and sun rise/transit/set
                % values: SPA_ZA_RTS = 2.
                curSpaIn.function = 2;
                [spaErrCode, curSpaOut] = getSolarPosition(curSpaIn);
                if spaErrCode~=0
                    warning(['There was an error from SPA; error code: ', ...
                        num2str(spaErrCode), '!'])
                end
                
                curSunriseFracHour = curSpaOut.sunrise;
                curSunsetFracHour = curSpaOut.sunset;
                
                % Save the sunrise and sunset times. Note that in the time
                % conversion here, we do not need to consider the local
                % time zone (i.e., time zone zero is used).
                curDate = dateshift(curDatetime, 'Start', 'day');
                curSunriseDatetime = utcUnixTimeInS2LocalDatetime( ...
                    localDatetime2UtcUnixTimeInS(curDate, 0) ...
                    + curSunriseFracHour*60*60, 0);
                curSunsetDatetime = utcUnixTimeInS2LocalDatetime( ...
                    localDatetime2UtcUnixTimeInS(curDate, 0) ...
                    + curSunsetFracHour*60*60, 0);
                simState.sunriseDatetimes{idxLoc, idxDay} ...
                    = curSunriseDatetime;
                simState.sunsetDatetimes{idxLoc, idxDay} ...
                    = curSunsetDatetime;
                
                % Set the sun power to zero for all times that are not in
                % the daytime (bigger than the sunrise time and smaller
                % than the sunset time).
                curTimesToInspect = ...
                    simConfigs.localDatetimesToInspect(indicesTimesToInspect);
                boolsInTheSun = (curTimesToInspect>curSunriseDatetime) ...
                    & (curTimesToInspect<curSunsetDatetime);
                simState.uniformSunPower(idxLoc, ...
                    indicesTimesToInspect(~boolsInTheSun)) = 0;
                
                % Save the sun position information.
                simState.sunAzis(idxLoc, curIdxDatetime) = curSpaOut.azimuth;
                simState.sunZens(idxLoc, curIdxDatetime) = curSpaOut.zenith;
                
                % Loop through the rest of the times to inspect. In order
                % to make parfor work, we will store the results directly
                % in some temporary variables first.
                curLocSunAzis = simState.sunAzis(idxLoc, :);
                curLocSunZens = simState.sunZens(idxLoc, :);
                curLocSuniformSunPower = simState.uniformSunPower(idxLoc, :);
                parfor curIdxDatetime = indicesTimesToInspect(2:end)
                    % And find the solar position if nessary, that is (1)
                    % the sun aimuth has not been evaluated for this
                    % location and time, and (2) if this location is in the
                    % sun at this time (where uniformSunPower is not set to
                    % be 0 and remains NaN for now).
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
            numOfLocDatePairsProcessed = numOfLocDatePairsProcessed+1;
            % Report the progress regularly. Note that we are interested in
            % the overall progress, so the number of dates needs to be
            % considered, too.
            if numOfLocDatePairsProcessed/totalNumOfLocs ...
                    > simConfigs.MIN_PROGRESS_RATIO_TO_REPORT*totalNumOfDays
                % Also take the chance to update the history results if
                % necessary. Note that this attempt may miss the last save
                % required when all locations are processed.
                if flagSimStateUpdated
                    save(dirToSaveSimState, 'simConfigs', 'simState', '-v7.3');
                    flagSimStateUpdated = false;
                end
                
                disp(['                [', ...
                    datestr(now, datetimeFormat), ...
                    '] Location ', num2str(idxLoc), '/', ...
                    num2str(totalNumOfLocs), ' (Overall progress: ', ...
                    num2str( ...
                    ((idxDay-1)*totalNumOfLocs+idxLoc) ...
                    /(totalNumOfLocs*totalNumOfDays)*100, '%.2f'), '%) ...'])
                
                numOfLocDatePairsProcessed = 0;
            end
            if idxLoc == totalNumOfLocs
                % Also take the chance to update the history results if
                % necessary.
                if flagSimStateUpdated
                    save(dirToSaveSimState, 'simConfigs', 'simState', '-v7.3');
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
    disp(['    [', datestr(now, datetimeFormat), '] Done!'])
    
    %% Simulation: Locs in the Sun
    
    disp(' ')
    disp(['    [', datestr(now, datetimeFormat), ...
        '] Locating spots in the sun ', ...
        'and computing their uniform sun powers ...'])
    
    % We only need to do the simulation if it was not completed before.
    indicesLocToProcess = 1:simState.numOfGridPts;
    if isfield(simState, 'flagShadowLocated')
        if simState.flagShadowLocated
            indicesLocToProcess = [];
        end
    end
    
    totalNumOfLocs = length(indicesLocToProcess);
    curNumOfLocProcessed = 0;
    numOfLocsProcessed = 0;
    for idxLoc = indicesLocToProcess
        % Report progress regularly.
        if curNumOfLocProcessed == 0
            disp(['            [', ...
                datestr(now, datetimeFormat), ...
                '] Location ', ...
                num2str(numOfLocsProcessed), '/', ...
                num2str(totalNumOfLocs), ' (', ...
                num2str( ...
                numOfLocsProcessed/totalNumOfLocs*100, ...
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
                    % Load our Python module for accessing USGS elevation
                    % data.
                    py_addpath(fullfile(pwd, 'libs', 'python'));
                    
                    curSunAzi = curLocSunAzisSeg(idxIdxDatetime);
                    curEndXY = ...
                        [curGridXY(1) ...
                        + sind(curSunAzi)*radiusToInspectInM, ...
                        curGridXY(2) ...
                        + cosd(curSunAzi)*radiusToInspectInM]; %#ok<PFBNS>
                    
                    % Construct the LiDAR z profile for this location and
                    % time.
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
        
        curNumOfLocProcessed = curNumOfLocProcessed + 1;
        numOfLocsProcessed = numOfLocsProcessed + 1;
        
        % For progress reporting. Note that we are interested in the
        % overall progress, so the number of dates needs to be considered,
        % too.
        if curNumOfLocProcessed/totalNumOfLocs ...
                > simConfigs.MIN_PROGRESS_RATIO_TO_REPORT
            curNumOfLocProcessed = 0;
            % Also take the chance to update the history results.
            save(dirToSaveSimState, 'simConfigs', 'simState', '-v7.3');
        end
        
        if numOfLocsProcessed == totalNumOfLocs
            % All done. Save the results.
            simState.flagShadowLocated = true;
            save(dirToSaveSimState, 'simConfigs', 'simState', '-v7.3');
            disp(['            [', ...
                datestr(now, datetimeFormat), '] Done!'])
        end
    end
    
    disp(['    [', datestr(now, datetimeFormat), ...
        '] Done!'])
    
    %% Visualization: 3D LiDAR Plots for Debugging
    
    % Always generate the figures when the PRESET is not RoadSimManager.
    % Otherwise, only generate the figures once.
    debugResultsDir = fullfile(folderToSaveResults, ...
        'debugLidarDataForAreaOfInterest');
    if strcmp(PRESET, 'RoadSimManager')
        if ~exist(debugResultsDir, 'dir')
            debugLidarDataForAreaOfInterest;
        end
    else
        debugLidarDataForAreaOfInterest;
    end
    
    %% Visualization: Video Clip for Shadow Location
    
    timeToPauseForFigUpdateInS = 0.000001;
    pathToSaveVideo = fullfile(folderToSaveResults, 'shadowLocOverTime');
    if ~exist('FLAG_GEN_VIDEO_FOR_ONE_DAY', 'var')
        FLAG_GEN_VIDEO_FOR_ONE_DAY = false;
    end
    
    % Only generate the video if it does not exist and if the host is a
    % windows computer.
    if ispc && ~exist(pathToSaveVideo, 'file')
        disp(' ')
        disp(['    [', datestr(now, datetimeFormat), ...
            '] Generating illustration video clip for shadow location ...'])
        
        % Video parameters.
        simTimeLengthPerFrameInS ...
            = simConfigs.PLAYBACK_SPEED/simConfigs.FRAME_RATE;
        assert(floor(simTimeLengthPerFrameInS)==simTimeLengthPerFrameInS, ...
            ['For simplicity, ', ...
            'please make sure PLAYBACK_SPEED/VIDEO_FRAME_RATE ', ...
            'is an integer!']);
        
        % Plot the background.
        matRxLonLatWithSunPower = [simConfigs.gridLatLonPts(:,[2,1]), ...
            simState.uniformSunPower(:,1)];
        sunAziZens = [simState.sunAzis(:,1), simState.sunZens(:,1)];
        [hFigShadowLoc, hsShadowMap] = ...
            plotSunShadowMap(matRxLonLatWithSunPower, simConfigs, sunAziZens);
        lastDatetime = simConfigs.localDatetimesToInspect(1);
        title(datestr(lastDatetime, datetimeFormat));
        drawnow; pause(timeToPauseForFigUpdateInS);
        
        % Create a video writer for outputting the frames.
        curVideoWriter = VideoWriter( ...
            pathToSaveVideo, 'MPEG-4'); %#ok<TNMLP>
        curVideoWriter.FrameRate = simConfigs.FRAME_RATE;
        open(curVideoWriter);
        
        try
            % Go through all remaining times.
            for curIdxDatetime = 2:length(simConfigs.localDatetimesToInspect)
                curDatetime ...
                    = simConfigs.localDatetimesToInspect(curIdxDatetime);
                
                if FLAG_GEN_VIDEO_FOR_ONE_DAY
                    if curDatetime-simConfigs.localDatetimesToInspect(1) ...
                            > days(1) %#ok<UNRCH>
                        break
                    end
                end
                
                % Output the video.
                lastSimTime = lastDatetime;
                for curSimTimeInS ...
                        = lastDatetime:seconds(1):(curDatetime-seconds(1))
                    elapsedSimTimeInS = seconds(curSimTimeInS-lastSimTime);
                    if elapsedSimTimeInS>=simTimeLengthPerFrameInS
                        writeVideo(curVideoWriter, getframe(hFigShadowLoc));
                        lastSimTime = curSimTimeInS;
                    end
                end
                
                % Update the figure.
                deleteHandles(hsShadowMap);
                
                matRxLonLatWithSunPower ...
                    = [simConfigs.gridLatLonPts(:,[2,1]), ...
                    simState.uniformSunPower(:,curIdxDatetime)];
                sunAziZens = [simState.sunAzis(:,curIdxDatetime), ...
                    simState.sunZens(:,curIdxDatetime)];
                [hFigShadowLoc, hsShadowMap] = ...
                    plotSunShadowMap(matRxLonLatWithSunPower, ...
                    simConfigs, sunAziZens, hFigShadowLoc);
                title(datestr(curDatetime, datetimeFormat));
                drawnow; pause(timeToPauseForFigUpdateInS);
                
                lastDatetime = curDatetime;
            end
            
            % Output the last frame and close the video writer.
            for curSimTimeInS ...
                    = lastDatetime:seconds(1):(min( ...
                    lastDatetime+minutes(simConfigs.TIME_INTERVAL_IN_M), ...
                    simConfigs.localDatetimesToInspect(end)) ...
                    - seconds(1))
                elapsedSimTimeInS = seconds(curSimTimeInS-lastSimTime);
                if elapsedSimTimeInS>=simTimeLengthPerFrameInS
                    writeVideo(curVideoWriter, getframe(hFigShadowLoc));
                    lastSimTime = curSimTimeInS;
                end
            end
        catch err
            disp(getReport(exception))
            if strcmp(PRESET, 'RoadSimManager')
                warning([ ...
                    'There was an error generating the video ', ...
                    'for simulation #', num2str(idxSim), '!'])
            else
                error('There was an error generating the video!')
            end
        end
        close(curVideoWriter);
        
        disp(['    [', datestr(now, datetimeFormat), '] Done!'])
    end
    
    %% Statistics: Sun Engergy
    % Note that we only consider the direct sun radiation.
    
    if ~isfield(simState, 'dailyUniformSunEnergy')
        disp(' ')
        disp(['    [', datestr(now, datetimeFormat), ...
            '] Computing the sun energies ...'])
        
        [simState.dailyUniformSunEnergy, ...
            simState.dailyUniformSunEnergyDates] ...
            = computeDailyUniformSunEnergy(simState.uniformSunPower, ...
            simConfigs.localDatetimesToInspect);
        % Update both the simulation results in the history .mat file, just
        % in case.
        disp(['        [', datestr(now, datetimeFormat), ...
            '] Saving results ...'])
        save(dirToSaveSimState, 'simConfigs', 'simState', '-v7.3');
        
        disp(['    [', datestr(now, datetimeFormat), '] Done!'])
    end
    
    pathToSaveVideo = fullfile(folderToSaveResults, ...
        'unifSunPowerOverTime');
    if ispc && ~exist(pathToSaveVideo, 'file')
        disp(' ')
        disp(['    [', datestr(now, datetimeFormat), ...
            '] Generating video clip for the sun power ...'])
        % Generate a video for debugging.
        genVideoForUnifSunPower;
        disp(['    [', datestr(now, datetimeFormat), '] Done!'])
    end
    
    %% Cleanup
    
    disp(' ')
    disp(['        [', datestr(now, datetimeFormat), ...
        '] Finishing simulation ...'])
    close all;
    disp(['        [', datestr(now, datetimeFormat), ...
        '] Done!'])
    
    diary off;
    
    %% Create a Comparison Figure with the Original Photo
    if ispc
        curDirToJpg = presetsInfo.dirToJpgs{idxPreset};
        [curDirToCompFigFolderPath, curCompFigName, ~] ...
            = fileparts(curDirToJpg);
        curPathToSaveCompFig = fullfile(curDirToCompFigFolderPath, ...
            [curCompFigName, '_Comp']);
        
        curBoundOfIntUtmXYs = presetsInfo.boundOfIntUtmXYs{idxPreset};
        [curBoundOfIntLats, curBoundOfIntLons] ...
            = simConfigs.utm2deg_speZone( ...
            curBoundOfIntUtmXYs(:, 1), curBoundOfIntUtmXYs(:, 2));
        curCameraLatLon = presetsInfo.cameraLatLonHs(idxPreset, 1:2);
        curTargetLatLon = presetsInfo.targetLatLons(idxPreset, :);
        curSimLabel = presetsInfo.simLabels{idxPreset};
        curDatetimeLocal = presetsInfo.datetimesLocal{idxPreset};
        
        [curCameraX, curCameraY] = simConfigs.deg2utm_speZone( ...
            curCameraLatLon(1), curCameraLatLon(2));
        [curTargetX, curTargetY] = simConfigs.deg2utm_speZone( ...
            curTargetLatLon(1), curTargetLatLon(2));
        
        estiLidarZFct = scatteredInterpolant(simConfigs.gridXYPts(:,1), ...
            simConfigs.gridXYPts(:,2), simState.gridLidarZs);
        curCameraZ = estiLidarZFct(curCameraX, curCameraY);
        curTargetZ = estiLidarZFct(curTargetX, curTargetY);
        
        curCameraHInM = presetsInfo.cameraLatLonHs(idxPreset, 3);
        curCamCenteredLidarXYZs = ...
            [simConfigs.gridXYPts(:,1) - curCameraX, ...
            simConfigs.gridXYPts(:,2) - curCameraY, ...
            simState.gridLidarZs - curCameraZ - curCameraHInM];
        
        % Note that this vector should originate from the center of the
        % plot box and point toward the camera.
        curCamViewVectXYZ = -[curTargetX-curCameraX, ...
            curTargetY-curCameraY, ...
            curTargetZ-curCameraZ-curCameraHInM];
        curCamViewEle = 10;
        curCamViewAng = 5;
        
        % Use a bigger canvas.
        hFigComp = figure('units','pixel','outerposition',[0 0 1920 1080]);
        % Raw image.
        subplot(2, 2, 1);
        [rawJpgData, ~] = jpgRead(curDirToJpg);
        imshow(rawJpgData);
        % 3D view of the LiDAR data colored by sun power values.
        subplot(2, 2, 2); hold on;
        [~, hCurAxes, hCurCb] = plot3k(curCamCenteredLidarXYZs, ...
            'ColorData', simState.uniformSunPower, ...
            'Labels', {['Estimated Camera Location (Green Square) ', ...
            'is Centered at (0,0,0)'], ...
            'x (m)', 'y (m)', 'z (m)', 'Normalized Sun Power'});
        [caz,cel] = view(curCamViewVectXYZ);
        view(caz, curCamViewEle);
        axis equal;
        plot3(0, 0, 0, 'gs');
        set(hCurAxes, 'Projection', 'perspective');
        set(hCurCb, 'Location', 'southoutside');
        camva(curCamViewAng);
        % A map for the location of interest.
        subplot(2, 2, [3,4]);
        hold on;
        hBound = plot(polyshape(curBoundOfIntLons, curBoundOfIntLats), ...
            'FaceColor', 'y', 'FaceAlpha', 0.1);
        %     hSunPower = plot3k([simConfigs.gridLatLonPts(:,2), ...
        %         simConfigs.gridLatLonPts(:,1), ...
        %           simState.gridLidarZs], ...
        %         'ColorData', simState.uniformSunPower);
        plot([curCameraLatLon(2), curTargetLatLon(2)], ...
            [curCameraLatLon(1), curTargetLatLon(1)], '--w');
        hCam = plot(curCameraLatLon(2), curCameraLatLon(1), 'sg');
        hTar = plot(curTargetLatLon(2), curTargetLatLon(1), '*r');
        plot_google_map('MapType', 'hybrid');
        xlabel('Longitude'); ylabel('Latitude');
        xticks([]); yticks([]); view(2);
        legend([hCam, hTar, hBound], 'Camera', 'Target', ...
            'Simulation Area');
        title(['Sim ', curSimLabel, ': ', datestr(curDatetimeLocal)], ...
            'Interpreter', 'none');
        
        saveas(hFigComp, [curPathToSaveCompFig, '.jpg']);
        saveas(hFigComp, [curPathToSaveCompFig, '.fig']);
        
        % Mimic the camera perspective.
        curPathToSave3DFig = fullfile(curDirToCompFigFolderPath, ...
            [curCompFigName, '_SimResults3D']);
        
        % For projecting 3D plot to a 2D camera view.
        %
        %   Reference:
        %       https://stackoverflow.com/questions/41371083/perspective-control-in-matlab-3d-figures
        curCamDistOffsetInM = 0.5*presetsInfo.sideLenForAreaOfIntInM;
        curCamEleInDegree = 15;
        
        curCamVertOffsetInM = tand(curCamEleInDegree)*curCamDistOffsetInM;
        curVCamToTar = [curTargetX-curCameraX, curTargetY-curCameraY];
        curUCamToTar = curVCamToTar./norm(curVCamToTar);
        curCamPosXYZ = [-curUCamToTar.*curCamDistOffsetInM, ...
            curCamVertOffsetInM];
        curCamTarXYZ = -curCamPosXYZ;
        curCamViewAng = 50;
        
        hFig3D = figure('units','pixel','outerposition',[0 0 1920 1080]);
        hold on;
        [~, hCurAxes, hCurCb] = plot3k(curCamCenteredLidarXYZs, ...
            'ColorData', simState.uniformSunPower, ...
            'Labels', {['Estimated Camera Location (Green Square) ', ...
            'is Centered at (0,0,0)'], ...
            'x (m)', 'y (m)', 'z (m)', 'Normalized Sun Power'});
        set(hCurCb, 'Location', 'southoutside');
        plot3(0, 0, 0, 'gs');
        plot3([curCamCenteredLidarXYZs(:,1)';...
            curCamCenteredLidarXYZs(:,1)'], ...
            [curCamCenteredLidarXYZs(:,2)';...
            curCamCenteredLidarXYZs(:,2)'], ...
            [curCamCenteredLidarXYZs(:,3)'.*0;...
            curCamCenteredLidarXYZs(:,3)'], ...
            '-', 'LineWidth', 0.5, 'Color', [0,0,0,0.5]);
        axis equal;
        set(hCurAxes, 'Projection', 'perspective');
        camva(curCamViewAng);
        campos(curCamPosXYZ);
        camtarget(curCamTarXYZ);
        title(['Sim ', curSimLabel, ': ', datestr(curDatetimeLocal)], ...
            'Interpreter', 'none');
        
        saveas(hFig3D, [curPathToSave3DFig, '.jpg']);
        saveas(hFig3D, [curPathToSave3DFig, '.fig']);
        
        % Simulation results on map.
        curPathToSaveMapFig = fullfile(curDirToCompFigFolderPath, ...
            [curCompFigName, '_SimResultsOnMap']);
        
        hFigMap = figure('units','pixel','outerposition',[0 0 1920 1080]);
        hold on;
        hBound = plot(polyshape(curBoundOfIntLons, curBoundOfIntLats), ...
            'FaceColor', 'y', 'FaceAlpha', 0.1);
        hSunPower = plot3k([simConfigs.gridLatLonPts(:,2), ...
            simConfigs.gridLatLonPts(:,1), ...
            simState.gridLidarZs], ...
            'ColorData', simState.uniformSunPower, ...
            'Marker', {'.', 5.5}, 'ColorBar', false);
        plot_google_map('MapType', 'hybrid'); axis('manual');
        plot([curCameraLatLon(2), curTargetLatLon(2)], ...
            [curCameraLatLon(1), curTargetLatLon(1)], '--w');
        hCam = plot(curCameraLatLon(2), curCameraLatLon(1), 'sg');
        hTar = plot(curTargetLatLon(2), curTargetLatLon(1), '*r');
        
        xlabel('Longitude'); ylabel('Latitude');
        xticks([]); yticks([]); view(2);
        legend([hCam, hTar, hBound], 'Camera', 'Target', ...
            'Simulation Area');
        title(['Sim ', curSimLabel, ': ', datestr(curDatetimeLocal)], ...
            'Interpreter', 'none');
        
        saveas(hFigComp, [curPathToSaveCompFig, '.jpg']);
        saveas(hFigComp, [curPathToSaveCompFig, '.fig']);
    end
end

% EOF