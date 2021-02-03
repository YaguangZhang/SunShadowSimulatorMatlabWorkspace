loadIndotRoads;
loadIndotMileMarkers;

%% First run this to get INDOT_MILE_MARKERS_ROADNAME_LABELS.
if ~exist('INDOT_MILE_MARKERS_ROADNAME_LABELS', 'var')
    [~, ~, INDOT_MILE_MARKERS_ROADNAME_LABELS] = ...
        gpsCoor2MileMarker(nan, nan, ...
        indotMileMarkers, indotRoads, UTM_STRUCT);
end

%% Test the time to run the code below.
[roadName, mile, INDOT_MILE_MARKERS_ROADNAME_LABELS] = ...
    gpsCoor2MileMarker(39.776301, -87.236079, ...
    indotMileMarkers, indotRoads, UTM_STRUCT, ...
    INDOT_MILE_MARKERS_ROADNAME_LABELS);