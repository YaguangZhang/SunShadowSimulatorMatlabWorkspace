function [utmRoadSegPoly] = constructUtmRoadSegPolygon( ...
    roadNamesForCenterlinesAndMileMarkers, ...
    latLonStartPts, latLonEndPts, ...
    roadWidthInM, simConfigs, mileMarkers)
%CONSTRUCTUTMROADSEGPOLYGON Construct a closed polygon in UTM (x, y) for a
%road segment specified by the start and end GPS locations.
%
% Required inputs:
%   - roadNamesForCenterlinesAndMileMarkers
%     A cell or a char vector for the name of the road. If it is a cell, we
%     expect its first element being the road name to use in the Indiana
%     road data set, and the second element being the road name to use in
%     the Indiana milemarker data set. If it is a char vector, we will use
%     it as the road name for both the road and the milemarker data sets.
%   - latLonStartPts, latLonEndPts
%     The (latitude, longitude) vectors for the start and end locations of
%     the road of interest, respectively. If they are cells of (latitude,
%     longitude), we will construct a polygon for each element pair and out
%     put the union of the results.
%
% Optional inputs:
%   - roadWidthInM
%     The width of the road in meter. We will extend the centerline
%     accordingly (by half of this value outwards) to construct each
%     polygon (the width of the resultant polygon will be this value).
%   - simConfigs
%     A structure for the simulation configurations. We will need fields
%     deg2utm_speZone and utm2deg_speZone for more precise convertions
%     between GPS and UTM. Note: the UTM zone used by simConfigs can be
%     different from that for UTM_STRUCT.
%   - mileMarkers
%     The milemarkers generated by loadIndotMileMarkers.m.
%
% Implicit inputs (cached in the base workspace):
%   - UTM_STRUCT
%     Generated by loadIndotMileMarkers.m.
%   - INDOT_MILE_MARKERS_ROADNAME_LABELS, roadSegMileages
%     We will generate these and store them in the base workspace if
%     necessary.
%
% Output:
%   - utmRoadSegPoly
%     The boundary points of the road segment in the UTM zone controled by
%     deg2utm_speZone.
%
% Yaguang Zhang, Purdue, 02/02/2021

% Default value for road width.
if ~exist('roadWidthInM', 'var')
    roadWidthInM = 5;
end

%% Preprocessing

if iscell(roadNamesForCenterlinesAndMileMarkers)
    roadNameForCenterLines = roadNamesForCenterlinesAndMileMarkers{1};
    roadNameForMileMarkers = roadNamesForCenterlinesAndMileMarkers{2};
else
    [roadNameForCenterLines, roadNameForMileMarkers] ...
        = deal(roadNamesForCenterlinesAndMileMarkers);
end

if ~iscell(latLonStartPts)
    latLonStartPts = mat2cell(latLonStartPts,1);
    latLonEndPts = mat2cell(latLonEndPts,1);
end

if ~exist('mileMarkers', 'var')
    if ~evalin('base', "exist('indotMileMarkers', 'var')")
        evalin('base', "loadIndotMileMarkers");
    end
    mileMarkers = evalin('base', 'indotMileMarkers');
end
UTM_STRUCT = evalin('base', "UTM_STRUCT");

if ~exist('simConfigs', 'var')
    if evalin('base', "exist('simConfigs', 'var')")
        simConfigs = evalin('base', "simConfigs");
        try
            deg2utm_speZone = simConfigs.deg2utm_speZone;
            utm2deg_speZone = simConfigs.utm2deg_speZone;
        catch
            try
                deg2utm_speZone = evalin('base', "deg2utm_speZone");
                utm2deg_speZone = evalin('base', "utm2deg_speZone");
            catch
                [deg2utm_speZone, utm2deg_speZone] ...
                    = genUtmConvertersForFixedZone(simConfigs.UTM_ZONE);
            end
        end
    else
        % We will use the UTM zone of the first input GPS point to
        % construct these functions.
        deg2utm_speZone = @deg2utm;
        [~, ~, utmZone] = deg2utm_speZone( ...
            latLonStartPts{1}(1), latLonStartPts{1}(2));
        utm2deg_speZone = @(x, y) utm2deg(x, y, ...
            repmat(utmZone, length(x), 1));
    end
else
    deg2utm_speZone = simConfigs.deg2utm_speZone;
    utm2deg_speZone = simConfigs.utm2deg_speZone;
end

if evalin('base', "exist('INDOT_MILE_MARKERS_ROADNAME_LABELS', 'var')")
    INDOT_MILE_MARKERS_ROADNAME_LABELS ...
        = evalin('base', "INDOT_MILE_MARKERS_ROADNAME_LABELS");
end

%% Construct a Polyshape for Each Segment

numOfSegs = length(latLonStartPts);
% Create a polyshape array for holding the results.
destRoadSegUtmPolyshapes = polyshape();
destRoadSegUtmPolyshapes(numOfSegs) = polyshape();
for idxSeg = 1:numOfSegs
    curLatLonStart = latLonStartPts{idxSeg};
    curLatLonEnd = latLonEndPts{idxSeg};
    
    % Snap the start and end points to the destination road.
    [~, xYOnRoadStart, roadSegs] = snapLatLonToRoad( ...
        curLatLonStart, roadNameForCenterLines, ...
        deg2utm_speZone, utm2deg_speZone);
    [~, xYOnRoadEnd, ~] = snapLatLonToRoad( ...
        curLatLonEnd, roadNameForCenterLines, ...
        deg2utm_speZone, utm2deg_speZone);
    
    % Find the mileage of the start point on road.
    [ptOnRoadStartLat, ptOnRoadStartLon] ...
        = utm2deg_speZone(xYOnRoadStart(1), xYOnRoadStart(2));
    if exist('INDOT_MILE_MARKERS_ROADNAME_LABELS', 'var')
        ptOnRoadStartMileage = ...
            gpsCoorWithRoadName2MileMarker( ...
            ptOnRoadStartLat, ptOnRoadStartLon, ...
            roadNameForMileMarkers, ...
            mileMarkers, UTM_STRUCT, ...
            INDOT_MILE_MARKERS_ROADNAME_LABELS);
    else
        % This function will store in the base workspace a copy of
        % INDOT_MILE_MARKERS_ROADNAME_LABELS if it is not there.
        [ptOnRoadStartMileage, INDOT_MILE_MARKERS_ROADNAME_LABELS] = ...
            gpsCoorWithRoadName2MileMarker( ...
            ptOnRoadStartLat, ptOnRoadStartLon, ...
            roadNameForMileMarkers, ...
            mileMarkers, UTM_STRUCT);
    end
    % Also for the end point on road.
    [ptOnRoadEndLat, ptOnRoadEndLon] ...
        = utm2deg_speZone(xYOnRoadEnd(1), xYOnRoadEnd(2));
    ptOnRoadEndMileage = ...
        gpsCoorWithRoadName2MileMarker( ...
        ptOnRoadEndLat, ptOnRoadEndLon, ...
        roadNameForMileMarkers, ...
        mileMarkers, UTM_STRUCT, ...
        INDOT_MILE_MARKERS_ROADNAME_LABELS);
    
    % Find the mileages for all the points of the road segments.
    numOfRoadSegs = length(roadSegs);
    if ~exist('roadSegMileages', 'var')
        % Load the cached version in the base workspace if possible.
        roadSegMileagesVarName = ['roadSegMileages_', ...
            roadNameForCenterLines];
        if evalin('base', ...
                strcat("exist('", roadSegMileagesVarName, "', 'var')"))
            roadSegMileages = evalin('base', roadSegMileagesVarName);
        else
            roadSegMileages = cell(numOfRoadSegs, 1);
            for idxRoadSeg = 1:numOfRoadSegs
                curRoadSeg = roadSegs(idxRoadSeg);
                roadSegMileages{idxRoadSeg} = ...
                    arrayfun(@(idxPt) gpsCoorWithRoadName2MileMarker( ...
                    curRoadSeg.Lat(idxPt), curRoadSeg.Lon(idxPt), ...
                    roadNameForMileMarkers, ...
                    mileMarkers, UTM_STRUCT, ...
                    INDOT_MILE_MARKERS_ROADNAME_LABELS), ...
                    1:length(curRoadSeg.Lat))';
            end
            assignin('base', roadSegMileagesVarName, roadSegMileages);
        end
    end
    
    % Filter roadSegs by the mileages of the input start and end locations.
    curBoolsRoadSegToKeep = false(numOfRoadSegs, 1);
    mileageBounds = [min([ptOnRoadStartMileage, ptOnRoadEndMileage]), ...
        max([ptOnRoadStartMileage, ptOnRoadEndMileage])];
    for idxRoadSeg = 1:numOfRoadSegs
        if any( ...
                roadSegMileages{idxRoadSeg} >= mileageBounds(1) ...
                & roadSegMileages{idxRoadSeg} <= mileageBounds(2))
            curBoolsRoadSegToKeep(idxRoadSeg) = true;
        end
    end
    curRoadSegs = roadSegs(curBoolsRoadSegToKeep);
    
    % Construct one polyline for each destination road segment.
    roadSegsUtmPolylines = roadSegsToUtmPolylines( ...
        curRoadSegs, deg2utm_speZone);
    
    % Extend the lines to polyshapes and merge them.
    curDestRoadSegUtmPolyshape = union(cellfun( ...
        @(line) polybuffer(line, 'lines', roadWidthInM, ...
        'JointType','miter'), ...
        roadSegsUtmPolylines));
    
    % Add a few more vertices near the start and end points.
    curDestRoadSegPtXYs = curDestRoadSegUtmPolyshape.Vertices;
    [curDestRoadSegPtLats, curDestRoadSegPtLons] ...
        = utm2deg_speZone(curDestRoadSegPtXYs(:,1), ...
        curDestRoadSegPtXYs(:,2));
    curDestRoadPtMs = arrayfun( ...
        @(idxPt) gpsCoorWithRoadName2MileMarker( ...
        curDestRoadSegPtLats(idxPt), curDestRoadSegPtLons(idxPt), ...
        roadNameForMileMarkers, ...
        mileMarkers, UTM_STRUCT, ...
        INDOT_MILE_MARKERS_ROADNAME_LABELS), ...
        1:length(curDestRoadSegPtLats))';
    
    destRoadSegUtmPolyshapes(idxSeg) ...
        = extractRoadSegUtmPolyshapeBetweenPts( ...
        curDestRoadSegUtmPolyshape, curDestRoadPtMs, ...
        [xYOnRoadStart, ptOnRoadStartMileage; ...
        xYOnRoadEnd, ptOnRoadEndMileage]);
end

% Merget the road segments.
utmRoadSegPolyshape = union(destRoadSegUtmPolyshapes);
[utmRoadSegPolyXs, utmRoadSegPolyYs] = boundary(utmRoadSegPolyshape);
utmRoadSegPoly = [utmRoadSegPolyXs utmRoadSegPolyYs];

end
% EOF