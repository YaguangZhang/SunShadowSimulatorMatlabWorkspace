%LOADINDOTROADS Loads INDOT's road structure.
%
% Note that this structure doesn't contain the geographical coordinates we
% need for plotting it on a map (X and Y are easting and northing used in
% UTM system). So this script also compute and add the coordinates fields
% to this structure.
%
% References:
%
%   http://www.mathworks.com/help/map/working-with-the-utm-system.html
%
%   https://maps.indiana.edu/metadata/Infrastructure/Streets_Roads_INDOT_2015.html
%
% The detailed info, for example the unit, for each field can be found at
% the IU link above. Note that LENGTH is in miles, and RTE_NAME means
% "route name".
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

if ~exist('UTM_STRUCT', 'var')
    % Create a UTM structure with UTM_Zone_Number to be 16 (northern
    % hemisphere). UTM_Zone_Number (and the projection parameters) can be
    % got from the INDOT road document.
    UTM_STRUCT = defaultm('utm');
    UTM_STRUCT.zone = '16N';
    % Create a map projection structure.
    UTM_STRUCT = defaultm(UTM_STRUCT);
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
        tic;
        
        % Compute the Lat and Lon fields for the road structure.
        for idxRoad = 1:1:length(indotRoads)
            [indotRoads(idxRoad).Lat, ...
                indotRoads(idxRoad).Lon] = ...
                minvtran(UTM_STRUCT, ...
                indotRoads(idxRoad).X, ...
                indotRoads(idxRoad).Y ...
                );
        end
        toc;
        disp('Pre-processing: Done!')
        
        if flagSaveResultsToMat
            disp(' ') %#ok<UNRCH>
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