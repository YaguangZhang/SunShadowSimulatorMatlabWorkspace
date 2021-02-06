%LOADINDOTMILEMARKERS Loads INDOT's mile marker structure.
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
%   https://maps.indiana.edu/previewMaps/Infrastructure/Interstates_Mile_Markers_System1_INDOT.html
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

nameFoler = 'Interstates_Mile_Markers_System1_INDOT_2016';
nameFile = 'Export_Output';

disp('-------------------------------------------------------------')
disp(['Data set: ', nameFoler])

pathShapeFile = fullfile(ABS_PATH_TO_ROADS, nameFoler, [nameFile, '.shp']);
pathShapeMatFile = fullfile(ABS_PATH_TO_ROADS, ...
    nameFoler, [nameFile, '.mat']);

if ~exist('MILE_MARKER_PROJ', 'var')
    mileMarkerShpInfo = shapeinfo(pathShapeFile);
    MILE_MARKER_PROJ = mileMarkerShpInfo.CoordinateReferenceSystem;
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
        
        % Compute the Lat and Lon fields for the mile marker structure.
        tic;
        [indotMileMarkersLats, indotMileMarkersLons] ...
            = projinv(MILE_MARKER_PROJ, ...
            vertcat(indotMileMarkers.X), ...
            vertcat(indotMileMarkers.Y) ...
            );
        for idxMileMarker = 1:1:length(indotMileMarkers)
            indotMileMarkers(idxMileMarker).Lat ...
                = indotMileMarkersLats(idxMileMarker);
            indotMileMarkers(idxMileMarker).Lon ...
                = indotMileMarkersLons(idxMileMarker);
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

% Show the mile markers on a map for debugging.
if false
    figure; hold on; %#ok<UNRCH>
    plot(vertcat(indotMileMarkers.Lon), ...
        vertcat(indotMileMarkers.Lat), 'r.');
    plot_google_map('MapType', 'hybrid');
end
% EOF