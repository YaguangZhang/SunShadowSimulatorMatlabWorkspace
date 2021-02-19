%LOADINDOTROADS Loads INDOT's road structure.
%
% Note that this structure doesn't contain the GPS coordinates we need for
% plotting it on a map (X and Y are easting and northing used in UTM
% system). So this script also compute and add the coordinates fields to
% this structure.
%
% References:
%
%   http://www.mathworks.com/help/map/working-with-the-utm-system.html
%
%   https://maps.indiana.edu/metadata/Infrastructure/Streets_Centerlines_IGIO.html
%
% The detailed info, for example the unit, for each field can be found at
% the IU link above.
%
% If the data are stored as shape type PolyLineZ (type code = 13) or shape
% type PointM (type code = 21), one will need to convert them to something
% Matlab supports (by disabling Z and M fields) or use the m_map library.
%
%   https://www.eoas.ubc.ca/~rich/map.html
%
%   https://gis.stackexchange.com/questions/40613/importing-shapefile-in-matlab
%
% Yaguang Zhang, Purdue, 02/02/2021

% We will save the results into multiple files to save The resultant
% variable could still be too big. If this is the case, please set this to
% be false so that the results are loaded and processed as needed, without
% the results being cached in .mat file.
flagSaveResultsToMat = true;

nameFoler = 'Streets_Centerlines_IGIO_2019';
nameFile = 'Export_Output';

disp('-------------------------------------------------------------')
disp(['Data set: ', nameFoler])

pathShapeFile = fullfile(ABS_PATH_TO_ROADS, nameFoler, ...
    strcat(nameFile, '.shp'));
pathShapeMatFile = fullfile(ABS_PATH_TO_ROADS, nameFoler, ...
    strcat(nameFile, '.mat'));

if ~exist('ROAD_PROJ', 'var')
    mileMarkerShpInfo = shapeinfo(pathShapeFile);
    ROAD_PROJ = mileMarkerShpInfo.CoordinateReferenceSystem;
end

if ~exist('indotRoads', 'var')
    
    if exist(pathShapeMatFile, 'file')
        disp('-------------------------------------------------------------')
        disp('Pre-processing: Loading the INDOT road structure from history mat file...')
        tic;
        flagSuccess = readBigVector(pathShapeMatFile);
        assert(flagSuccess, ...
            'Error in reading the road info as a big vector!');
        toc;
        disp('Pre-processing: Done!')
    else
        disp('-------------------------------------------------------------')
        
        disp('Pre-processing: Loading the INDOT road structure from the shape file...')
        tic;
        indotRoads = shaperead(pathShapeFile);
        toc;
        disp('Pre-processing: Done!')
        
        disp(' ')
        disp('Pre-processing: Computing geographical coordinates...')
        
        % Compute the Lat and Lon fields for the road structure.
        tic;
        [indotRoadsLats, indotRoadsLons] ...
            = projinv(ROAD_PROJ, ...
            [indotRoads.X]', ...
            [indotRoads.Y]' ...
            );
        indotRoadsPtCnt = 1;
        for idxRoad = 1:1:length(indotRoads)
            % By our convention, we will use column vectors for the
            % coordinates.
            indotRoads(idxRoad).X = indotRoads(idxRoad).X';
            indotRoads(idxRoad).Y = indotRoads(idxRoad).Y';
            
            curIndotRoadPtNum = length(indotRoads(idxRoad).X);
            indotRoads(idxRoad).Lat = indotRoadsLats( ...
                indotRoadsPtCnt:(indotRoadsPtCnt+curIndotRoadPtNum-1));
            indotRoads(idxRoad).Lon = indotRoadsLons( ...
                indotRoadsPtCnt:(indotRoadsPtCnt+curIndotRoadPtNum-1));
            indotRoadsPtCnt = indotRoadsPtCnt+curIndotRoadPtNum;
        end
        toc;
        
        disp('Pre-processing: Done!')
        
        if flagSaveResultsToMat
            disp(' ')
            disp('Pre-processing: Saving the INDOT road structure in to a mat file...')
            
            tic;
            flagSuccess = saveBigVector(pathShapeMatFile, indotRoads);
            assert(flagSuccess, ...
                'Error in saving the road info as a big vector!');
            toc;
            
            disp('Pre-processing: Done!')
        end
    end
    
else
    disp('-------------------------------------------------------------')
    disp('Pre-processing: Found indotRoads in the current workspace.')
    disp('Pre-processing: No need to load it again.')
end

%% Show these roads on a plot.
if false
    % The lat-lon version.
    figure; hold on; %#ok<UNRCH>
    for idxRoad = 1:length(indotRoads)
        plot(indotRoads(idxRoad).Lon,indotRoads(idxRoad).Lat);
        if mod(idxRoad,1000) == 0
            pause;
        end
    end
    hold off; grid on; axis equal;
    
    % The UTM version
    figure;hold on;
    for indexRoad = 1:length(indotRoads)
        plot(indotRoads(idxRoad).X,indotRoads(idxRoad).Y);
    end
    hold off; grid on; axis equal;
end
% EOF