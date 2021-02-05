%LOADINDOTMILEMARKERS Loads INDOT's mile marker structure.
%
% An example of the mile marker structure:
%
%     >> indotMileMarkers(1)
%
%     ans =
%
%          Geometry: 'Point'
%                 X: 6.5200e+05 Y: 4.6121e+06
%         IIT_NE_ID: 5449608
%          IIT_DESCR: 'S 327 Post 24'
%         IIT_NOTE: '24'
%          OBJECTID: 1836
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
%   https://maps.indiana.edu/previewMaps/Infrastructure/Interstates_Mile_Markers_System1_INDOT.html
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

nameFoler = 'Interstates_Mile_Markers_System1_INDOT_2016';
nameFile = 'Export_Output';

disp('-------------------------------------------------------------')
disp(['Data set: ', nameFoler])

pathShapeFile = fullfile(ABS_PATH_TO_ROADS, nameFoler, [nameFile, '.shp']);
pathShapeMatFile = fullfile(ABS_PATH_TO_ROADS, ...
    nameFoler, [nameFile, '.mat']);

% Note: we are assuming the UTM struct is the same for both roads and
% milemarkers.
if ~exist('UTM_STRUCT', 'var')
    % Create a UTM structure with UTM_Zone_Number to be 16 (northern
    % hemisphere). UTM_Zone_Number (and the projection parameters) can be
    % got from the INDOT mile marker document.
    UTM_STRUCT = defaultm('utm');
    UTM_STRUCT.zone = '16N';
    % Create a map projection structure.
    UTM_STRUCT = defaultm(UTM_STRUCT);
end

if ~exist('indotMileMarkers', 'var')
    
    if exist(pathShapeMatFile, 'file')
        disp('-------------------------------------------------------------')
        disp('Pre-processing: Loading the INDOT mile marker structure from history mat file...')
        tic;
        load(pathShapeMatFile);
        toc;
        disp('Pre-processing: Done!')
    else
        disp('-------------------------------------------------------------')
        
        disp('Pre-processing: Loading the INDOT mile marker structure from the shape file...')
        tic;
        indotMileMarkers = shaperead(pathShapeFile);
        toc;
        disp('Pre-processing: Done!')
        
        disp(' ')
        disp('Pre-processing: Computing geographical coordinates...')
        tic;
        
        if ~exist('UTM_STRUCT', 'var')
            % Create a UTM structure with UTM_Zone_Number to be 16
            % (northern hemisphere). UTM_Zone_Number can be got from the
            % INDOT highway document.
            UTM_STRUCT = defaultm('utm');
            UTM_STRUCT.zone = '16N';
            % Create a map projection structure.
            UTM_STRUCT = defaultm(UTM_STRUCT);
        end
        
        % Compute the Lat and Lon fields for the mile marker structure.
        for idxMileMarker = 1:1:length(indotMileMarkers)
            [indotMileMarkers(idxMileMarker).Lat, ...
                indotMileMarkers(idxMileMarker).Lon] = ...
                minvtran(UTM_STRUCT, ...
                indotMileMarkers(idxMileMarker).X, ...
                indotMileMarkers(idxMileMarker).Y ...
                );
        end
        toc;
        disp('Pre-processing: Done!')
        
        disp(' ')
        disp('Pre-processing: Saving the INDOT mile marker structure in to a mat file...')
        tic;
        save(pathShapeMatFile,'indotMileMarkers');
        toc;
        disp('Pre-processing: Done!')
    end
    
else
    disp('-------------------------------------------------------------')
    disp('Pre-processing: Found indotMileMarkers in the current workspace.')
    disp('Pre-processing: No need to load it again.')
end

% EOF