function [mile, INDOT_MILE_MARKERS_ROADNAME_LABELS] = ...
    gpsCoorWithRoadName2MileMarker(lat, lon, roadName, ...
    indotMileMarkers, UTM_STRUCT, ...
    INDOT_MILE_MARKERS_ROADNAME_LABELS, DEBUG, TRUE_MILE)
% GPSCOORWITHROADNAME2MILEMARKER Convert GPS coordinates with road name on
% INDOT roads to mile marker.
%
% Please remember to load INDOT mile marker database first by calling
% scripts loadIndotMileMarkers.
%
% Inputs:
%   - lat, lon
%     The GPS coordinates for the point for which we want to get the mile
%     marker.
%   - roadName
%     The road road name for the input point. It should be in the format
%     like "S49" (no space or underscore between the letter label and the
%     road number). Four letter labels are supported. They are "S" as
%     State, "I" as Interstate, "T" as Toll and "U" as US.
%   - indotMileMarkers
%     Structures storing INDOT mile markers. Can be generated by running
%     scripts loadIndotMileMarkers.m.
%   - UTM_STRUCT
%     Specifies the parameters for converting GPS coordinates to UTM and
%     vice versa. It will be automatically generated if
%     loadIndotMileMarkers is run.
%   - INDOT_MILE_MARKERS_ROADNAME_LABELS
%     The road names for indotMileMarkers. This is optional but will
%     improve the speed of this function dramatically. It can be generated
%     by this function itself if it's not provided. So it's recommeded to
%     get and store this variable during the first conversion and then use
%     that as an input for all the other conversions.
%   - DEBUG, TRUEMILE
%     Optional. If DEBUG is true, the nearest two milemarker together with
%     the input GPS point (marked with the true mile marker value) will be
%     plotted.
%
% Outputs:
%
%   - mile
%     A float value. The mile marker for the input point.
%   - INDOT_MILE_MARKERS_ROADNAME_LABELS
%     The road names for indotMileMarkers. This is optional but storing
%     this somewhere and using it as the input for the future use of this
%     function will improve the speed of this function dramatically.
%
% Example: please try running tests/testGpsCoorWithRoadName2MileMarker.m in
% the same folder as this file.
%
% Yaguang Zhang, Purdue, 02/03/2021

% If there's an error, we will just return -1 for the mile marker.
try
    LOC_INDOT_MILE_MARKERS_ROADNAME_LABELS = 6;
    
    % Project the coordinates into UMT system.
    [X, Y] = mfwdtran(UTM_STRUCT, lat, lon);
    
    % Next we need to compute the mile marker according to the road name
    % we've gotten.
    
    % Get all mile markers on that road.
    if nargin == LOC_INDOT_MILE_MARKERS_ROADNAME_LABELS-1
        INDOT_MILE_MARKERS_ROADNAME_LABELS = ...
            getRoadNamesForMileMarkers(indotMileMarkers);
    end
    mileMarkersOnThisRoad = getMileMarkersByRoadName( ...
        roadName, indotMileMarkers);
    
    % Get the nearest 2 mile markers. Here we only use them to estimate the
    % mile post for the input point.
    locationsMileMarkersOnThisRoad ...
        = zeros(length(mileMarkersOnThisRoad),2);
    for idx = 1:length(mileMarkersOnThisRoad)
        locationsMileMarkersOnThisRoad(idx,1) ...
            = mileMarkersOnThisRoad(idx).X;
        locationsMileMarkersOnThisRoad(idx,2) ...
            = mileMarkersOnThisRoad(idx).Y;
    end
    distMileMarkers = pdist2([X,Y],locationsMileMarkersOnThisRoad);
    sortedDistMileMarkersWithIndices = sortrows([distMileMarkers', ...
        (1:length(distMileMarkers))'], 1);
    if isempty(sortedDistMileMarkersWithIndices)
        error(['No mile markers found for road: ', roadName, '!'])
    end    
    nearest2Markers = mileMarkersOnThisRoad(...
        sortedDistMileMarkersWithIndices(1:2,2)...
        );
    
    % Get the vector of the 2 markers from the marker with smaller
    % postnumber.
    unitMileVector = [nearest2Markers(2).X - nearest2Markers(1).X, ...
        nearest2Markers(2).Y - nearest2Markers(1).Y];
    postNumNearest2Markers = nan(2,1);
    for idxNearestMM = 1:2
        [~, postNumNearest2Markers(idxNearestMM)] ...
            = getRoadNameFromMileMarker(nearest2Markers(idxNearestMM));
    end
    if postNumNearest2Markers(1) > postNumNearest2Markers(2)
        unitMileVector = -unitMileVector;
        % Also compute the vector from the marker with smaller postnumber
        % to the input point.
        inputMileVector = [X-nearest2Markers(2).X, Y-nearest2Markers(2).Y];
    else
        inputMileVector = [X-nearest2Markers(1).X, Y-nearest2Markers(1).Y];
    end
    
    % Compute the postnumber for the input point.
    mile = min(postNumNearest2Markers) + ...
        dot(inputMileVector, unitMileVector) / ...
        dot(unitMileVector, unitMileVector);
    
    if nargin >= LOC_INDOT_MILE_MARKERS_ROADNAME_LABELS+1
        if DEBUG
            if ~exist('TRUE_MILE', 'var')
                TRUE_MILE = 'Unkown';
            else
                TRUE_MILE = num2str(TRUE_MILE);
            end
            figure;hold on;
            plot([nearest2Markers(1).Lon],...
                [nearest2Markers(1).Lat],'bo');
            plot([nearest2Markers(2).Lon],...
                [nearest2Markers(2).Lat],'g*');
            plot(lon,lat,'rx');
            plot_google_map;
            hold off;
            legend(nearest2Markers(1).POST_NAME,  ...
                nearest2Markers(2).POST_NAME, ...
                strcat('GpsPoint: ', num2str(mile)), ...
                'Interpreter', 'none');
            title(['TrueMil: ', TRUE_MILE])
        end
    end
catch Error
    warning('An error orcurs when we tried to compute the mile marker.')
    disp(strcat('    Input info:',...
        32,num2str(lat),32, num2str(lon),32,roadName));
    mile = -1;
    disp(getReport(Error));
end

end
% EOF