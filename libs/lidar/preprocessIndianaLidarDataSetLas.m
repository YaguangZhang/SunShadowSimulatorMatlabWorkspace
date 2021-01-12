function [lidarFileRelDirs, xYBoundryPolygons, lonLatBoundryPolygons] ...
    = preprocessIndianaLidarDataSetLas(ABS_PATH_TO_LOAD_LIDAR, ...
    DEG2UTM_FCT, UTM2DEG_FCT)
%PREPROCESSINDIANALIDARDATASETLAS Preprocess the .las LiDAR data set
%located at ABS_PATH_TO_LOAD_LIDAR.
%
% We will load the LiDAR data, obtain the sample locations, obtain the
% elevation data for them, and save the results in .mat files.
%
% Inputs:
%   - ABS_PATH_TO_LOAD_LIDAR
%     The absolute path to the .las LiDAR data (unit: ftUS) obtained from
%       https://portal.opentopography.org/lidarDataset?opentopoID=OTLAS.062012.4326.1
%     Note that the LiDAR data files should be organized under two
%     subdirectories under ABS_PATH_TO_LOAD_LIDAR
%       - IN_2011_2013_W
%           Data for west Indiana, cooresponding to the output coordinate
%           system: NAD83 Indiana West (ftUS) [EPSG: 2966].
%       - IN_2011_2013_E
%           Data for east Indiana, cooresponding to the output coordinate
%           system: NAD83 Indiana East (ftUS) [EPSG: 2965].
%     This is required to correctly convert the unit survey foot in the
%     LiDAR data to the metric system.
%   - DEG2UTM_FCT, UTM2DEG_FCT
%     The functions to use to convert (lat, lon) to UTM (x, y) and back,
%     respectively, i.e.: (x, y) = DEG2UTM_FCT(lat, lon); (lat, lon) =
%     UTM2DEG_FCT(x, y).
%
% Outputs:
%   - lidarFileRelDirs
%     A column cell with the relative paths (relative to
%     ABS_PATH_TO_LOAD_LIDAR) for .img LiDAR data files processed. For
%     example,
%       fullfile(ABS_PATH_TO_LOAD_LIDAR, lidarFileRelDirs{1})
%     will output the absolute path to the first LiDAR data file processed.
%   - xYBoundryPolygons, lonLatBoundryPolygons
%     The polygon boundries (Matlab built-in polyshape) for the files
%     processed indicating the area they cover, in terms of UTM (x,y) and
%     GPS (lon, lat), respectively.
%
% Yaguang Zhang, Purdue, 01/09/2021

ABS_DIR_TO_SAVE_RESULTS = fullfile(ABS_PATH_TO_LOAD_LIDAR, 'metaInfo.mat');
flagDatasetProcessed = exist(ABS_DIR_TO_SAVE_RESULTS, 'file');

% Set this to be false to reuse history processing results.
FLAG_FORCE_REPROCESSING_DATA = false;
% Set this to be true to generate figures for debugging. Because reusing
% history processing results will skip loading all the data needed for
% plotting, we will not generate figures if the data set of interest is
% already processed and FLAG_FORCE_REPROCESSING_DATA is false.
FLAG_GEN_DEBUG_FIGS = (~flagDatasetProcessed) ...
    || FLAG_FORCE_REPROCESSING_DATA;

% Any LiDAR z value too big or too small will be discarded (set to NaN).
maxAllowedAbsLidarZ = 10^38;

% We will temporarily ignore the warning from polyshape.
warning('off','MATLAB:polyshape:repairedBySimplify');

[~, datasetName] = fileparts(ABS_PATH_TO_LOAD_LIDAR);

disp(' ')
disp(['    Preprocessing Indiana LiDAR dataset ', datasetName, ' ...'])

if flagDatasetProcessed ...
        && (~FLAG_FORCE_REPROCESSING_DATA)
    disp('        The specified dataset has been processed before.')
    disp('        Loading history results ...')
    load(ABS_DIR_TO_SAVE_RESULTS, ...
        'lidarFileRelDirs', 'xYBoundryPolygons', 'lonLatBoundryPolygons');
else
    lasFileHandles = rdir(fullfile( ...
        ABS_PATH_TO_LOAD_LIDAR, '**', '*.las'), ...
        '', ABS_PATH_TO_LOAD_LIDAR);
    lidarFileRelDirs = {lasFileHandles(:).name}';
    
    numLidarFiles = length(lidarFileRelDirs);
    
    [xYBoundryPolygons, lonLatBoundryPolygons] ...
        = deal(cell(numLidarFiles,1));
    
    % TODO: if the number of files to process is large, use parfor here.
    for idxF = 1:numLidarFiles
        try
            tic;
            
            disp(['        File # ', ...
                num2str(idxF), '/', num2str(numLidarFiles), ' ...']);
            
            [curLidarFileParentRelDir, curLidarFileName] ...
                = fileparts(lidarFileRelDirs{idxF});
            
            % For saving and reusing the results.
            curFullPathToSaveLidarResults = fullfile( ...
                ABS_PATH_TO_LOAD_LIDAR, ...
                curLidarFileParentRelDir, [curLidarFileName, '.mat']);
            
            % Try reusing the history results.
            flagSuccessInLoadingData = false;
            if exist(curFullPathToSaveLidarResults, 'file') ...
                    && (~FLAG_FORCE_REPROCESSING_DATA)
                disp('            Loading history results ...');
                
                % Clear last warning message.
                lastwarn('');
                try
                    historyResult = load(curFullPathToSaveLidarResults, ...
                        'xYBoundryPolygon', 'lonLatBoundryPolygon');
                    xYBoundryPolygon = historyResult.xYBoundryPolygon;
                    lonLatBoundryPolygon ...
                        = historyResult.lonLatBoundryPolygon;
                catch err
                    disp('            There was an error!')
                    dispErr(err);
                    warning('The history result .mat file is invalid!');
                end
                
                % Check whether there is any warning in loading the desired
                % data.
                [warnMsg, ~] = lastwarn;
                if isempty(warnMsg)
                    flagSuccessInLoadingData = true;
                end
                
                if ~flagSuccessInLoadingData
                    warning('Failed in loading history data!');
                    disp('            Aborted.');
                end
            end
            
            if ~flagSuccessInLoadingData
                disp('            Processing raw LiDAR data ...');
                
                % Load LiDAR data.
                curLidarFileAbsDir = fullfile(ABS_PATH_TO_LOAD_LIDAR, ...
                    curLidarFileParentRelDir, [curLidarFileName, '.las']);
                lidarData = lasdata(curLidarFileAbsDir);
                
                lidarDataXs = lidarData.x;
                lidarDataYs = lidarData.y;
                lidarDataZs = lidarData.z;
                lidarDataZs(abs(lidarDataZs(:))>maxAllowedAbsLidarZ) ...
                    = nan;
                
                % Convert survery feet to meter.
                lidarDataZs = distdim(lidarDataZs, 'ft', 'm');
                % Convert raster (row, col) to (lat, lon).
                pathparts = strsplit(curLidarFileParentRelDir, filesep);                
                assert( ...
                    strcmpi(pathparts{2}(1:(end-1)), 'IN_2011_2013_'), ...
                    'Data are not from Indiana 2011~2013 LiDAR datasets!');
                
                switch lower(pathparts{2}(end))
                    case 'e'
                        % The State plane code for the Tippecanoe data.
                        STATE_PLANE_CODE_TIPP = 'indiana east';
                    case 'w'
                        STATE_PLANE_CODE_TIPP = 'indiana west';
                    otherwise
                        error( ...
                            ['Unknown Indiana dataset for ', ...
                            'STATE_PLANE_CODE_TIPP!']);
                end
                [lidarLons, lidarLats] ...
                    = sp_proj(STATE_PLANE_CODE_TIPP, 'inverse', ...
                    lidarDataXs(:), lidarDataYs(:), 'sf');
                
                % Store the new (x,y,z) data.
                lidarLats = lidarLats(:);
                lidarLons = lidarLons(:);
                [lidarXs, lidarYs] ...
                    = DEG2UTM_FCT(lidarLats, lidarLons);
                lidarXYZ = [lidarXs, lidarYs, lidarDataZs(:)];
                
                % Find the polygon boundaries.
                xYBoundryPolygonIndices = boundary(lidarXs, lidarYs);
                xYBoundryPolygon ...
                    = polyshape([lidarXs(xYBoundryPolygonIndices), ...
                    lidarYs(xYBoundryPolygonIndices)]);
                lonLatBoundryPolygonIndices ...
                    = boundary(lidarLons, lidarLats);
                lonLatBoundryPolygon ...
                    = polyshape(...
                    [lidarLons(lonLatBoundryPolygonIndices), ...
                    lidarLats(lonLatBoundryPolygonIndices)]);
                
                assert( (xYBoundryPolygon.NumRegions == 1) ...
                    && (lonLatBoundryPolygon.NumRegions == 1), ...
                    'Generated boundaries should have only one region!');
                
                % Create a function to get LiDAR z from UTM coordinates.
                fctLonLatToLidarStatePlaneXY ...
                    = @(lon, lat) sp_proj(STATE_PLANE_CODE_TIPP, ...
                    'forward', lon, lat, 'sf');
                
                getLiDarZFromStatePlaneXYFct = ...
                    scatteredInterpolant(lidarDataXs, lidarDataYs, ...
                    lidarDataZs);
                getLiDarZFromXYFct ...
                    = @(xs, ys) genRasterLidarZGetter( ...
                    getLiDarZFromStatePlaneXYFct, ...
                    fctLonLatToLidarStatePlaneXY, ...
                    xs, ys, UTM2DEG_FCT);
                
                disp('            Generating elevation information ...');
                
                latRange = [min(lidarLats) max(lidarLats)];
                lonRange = [min(lidarLons) max(lidarLons)];
                
                % For avoid reading in incomplete raw terrain files that
                % are being downloaded by other worker, we will try loading
                % the data a few times.
                numTrials = 0;
                maxNumTrialsAllowed = 30;
                timeToWaitBeforeTryAgainInS = 30;
                % Default directory to save USDA data.
                usdaDataDir = 'usgsdata';
                % Backup directory to store USDA data when the data in the
                % default directory do not work (possibly because of the
                % collision of workers trying to store the same data file
                % at the same dir).
                %	usdaDataBackupDir = 'usgsdata_backup';
                fctFetchRegion = @(latR, longR) ...
                    fetchregion(latR, longR, ...
                    'display', true, 'dataDir', usdaDataDir);
                while ~isinf(numTrials)
                    try
                        % Use USGS 1/3 arc-second (~10m) resolution data
                        % for US terrain elevation.
                        region = fctFetchRegion(latRange, lonRange);
                        rawElevData = region.readelevation(...
                            latRange, lonRange, ...
                            'sampleFactor', 1, ...
                            'display', true);
                        numTrials = inf;
                    catch err
                        disp('            There was an error!')
                        dispErr(err);
                        
                        % A nasty workaround for a bug in the terrain
                        % elevation libary.
                        if strcmpi(err.identifier, ...
                                'MATLAB:subsassigndimmismatch')
                            fctFetchRegion = @(latR, longR) ...
                                fetchAnomalyRegion(latR, longR, ...
                                'display', true, 'dataDir', usdaDataDir);
                        end
                        
                        % usdaDataDir = usdaDataBackupDir;
                        numTrials = numTrials+1;
                        warning(['Error fetching elevation info for ', ...
                            'file # ', num2str(idxF), '/', ...
                            num2str(numLidarFiles), ...
                            ' (trial # ', num2str(numTrials), ')!']);
                        if numTrials == maxNumTrialsAllowed
                            error( ...
                                ['Error fetching elevation info for ', ...
                                'file # ', num2str(idxF), '/', ...
                                num2str(numLidarFiles), ...
                                ' (trial # ', num2str(numTrials), ')!']);
                        end
                        pause(timeToWaitBeforeTryAgainInS);
                    end
                end
                
                disp(['        Fitting elevation data ', ...
                    'in the (lon, lat) system ...']);
                % Order the raw elevation data so that both lat and lon are
                % monotonically increasing.
                [rawElevDataLonsSorted, rawElevDataLatsSorted, ...
                    rawElevDataElesSorted] ...
                    = sortGridMatrixByXY(...
                    rawElevData.longs, rawElevData.lats, ...
                    rawElevData.elev);
                
                % Create a grid for the elevation data.
                [tippElevDataLons, tippElevDataLats] = meshgrid( ...
                    rawElevDataLonsSorted, rawElevDataLatsSorted);
                
                % For very tiny LiDAR data tiles, we may not have enough
                % elevation data to carry out interp2. If that happens, we
                % will use the LiDAR data grid for the elevation, too.
                try
                    % Interperlate the data with lat and lon.
                    lidarEles = interp2( ...
                        tippElevDataLons, tippElevDataLats, ...
                        rawElevDataElesSorted, lidarLons, lidarLats);
                    
                    % Create a function to get elevation from UTM
                    % coordinates in the same way.
                    getEleFromXYFct = @(xs, ys) ...
                        genUtmEleGetter( ...
                        tippElevDataLats, tippElevDataLons, ...
                        rawElevDataElesSorted, xs, ys, UTM2DEG_FCT);
                catch err
                    disp(['        There was an error ', ...
                        'interperlating the elevation data!']);
                    dispErr(err);
                    
                    % Fetch the key stored by plot_google_maps. If this
                    % does not work, please run plot_google_maps
                    % with your Google Maps API once and try again.
                    googleApiKeyFile = load(fullfile( ...
                        fileparts(which('plot_google_map')), ...
                        'api_key.mat'));
                    lidarEles = getElevations(lidarLats, lidarLons, ...
                        'key', googleApiKeyFile.apiKey);
                    lidarRasterEles ...
                        = reshape(lidarEles, size(lidarDataXs));
                    
                    getLiDarZFromStatePlaneXYFct = @(spXs, spYs) ...
                        interp2(lidarDataXs, lidarDataYs, ...
                        lidarRasterEles, spXs, spYs);
                    getEleFromXYFct ...
                        = @(xs, ys) genRasterLidarZGetter( ...
                        getLiDarZFromStatePlaneXYFct, ...
                        fctLonLatToLidarStatePlaneXY, ...
                        xs, ys, UTM2DEG_FCT);                
                end
                
                parsave(curFullPathToSaveLidarResults, ...
                    lidarXYZ, xYBoundryPolygon, getLiDarZFromXYFct, ...
                    lidarLats, lidarLons, lidarEles, getEleFromXYFct, ...
                    lonLatBoundryPolygon,  ...
                    STATE_PLANE_CODE_TIPP, DEG2UTM_FCT, UTM2DEG_FCT);
                
                if FLAG_GEN_DEBUG_FIGS
                    generateDebugFigsForLidar;
                end
            end
            
            xYBoundryPolygons{idxF} = xYBoundryPolygon;
            lonLatBoundryPolygons{idxF} = lonLatBoundryPolygon;
            
            toc;
            disp('        Done!');
        catch err
            disp('        There was an error!')
            dispErr(err);
            error(...
                ['Error processing LiDAR data for ', ...
                'file # ', num2str(idxF), '/', ...
                num2str(numLidarFiles), '!']')
        end
    end
    
    save(ABS_DIR_TO_SAVE_RESULTS, ...
        'lidarFileRelDirs', 'xYBoundryPolygons', 'lonLatBoundryPolygons');
end

warning('on','MATLAB:polyshape:repairedBySimplify');

disp('    Done!')

end
% EOF