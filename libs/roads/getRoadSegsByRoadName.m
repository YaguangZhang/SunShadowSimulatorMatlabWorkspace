function roadSegs = getRoadSegsByRoadName( ...
    roadName, indotRoads)
% GETROADSEGSBYROADNAME Find all road segments marked with the specified
% road name from the INDOT road database (centerline 2019).
%
% Inputs:
%   - roadName
%     String. The road name in the form like "S49". We use "S" as State,
%     "I" as Interstate, "T" as Toll, and "U" as US (case insensitive).
%   - indotRoads
%     Loaded INDOT road database. Also works with part of it.
%
% Outputs:
%   - roadSegs
%     The road segments found.
%
% Implicit cache variable in the base workspace:
%   - INDOT_ROAD_SEGS_ROADNAME_LABELS
%     Cell. The road name labels extracted from indotRoads.
%
% Yaguang Zhang, Purdue, 02/02/2021

if evalin('base', '~exist(''INDOT_ROAD_SEGS_ROADNAME_LABELS'',''var'')')
    INDOT_ROAD_SEGS_ROADNAME_LABELS = ...
        getRoadNamesForRoadSegs(indotRoads);
    putvar(INDOT_ROAD_SEGS_ROADNAME_LABELS);
else
    INDOT_ROAD_SEGS_ROADNAME_LABELS ...
        = evalin('base', 'INDOT_ROAD_SEGS_ROADNAME_LABELS');
end


roadSegs = indotRoads(...
    strcmpi(INDOT_ROAD_SEGS_ROADNAME_LABELS, roadName)...
    );

end
% EOF