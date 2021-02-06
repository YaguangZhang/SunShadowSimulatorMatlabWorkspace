function highwaySegs = getHighwaySegsByRoadName(roadName, ...
    indotRoads, INDOT_HIGHWAY_SEGS_ROADNAME_LABELS)
% GETHIGHWAYSEGSBYROADNAME Find all highway segments marked with the
% specified road name from the INDOT highway database.
%
% Inputs:
%   - roadName
%     String. The road name in the form like "S49". We use "S" as State,
%     "I" as Interstate, "T" as Toll and "U" as US (case insensitive).
%   - indotRoads
%     Loaded INDOT highway database. Also works with part of it.
%   - INDOT_HIGHWAY_SEGS_ROADNAME_LABELS
%     Cell. Optional (however, may improve the codes improvement depending
%     how the function is used). The road name labels extracted from
%     indotRoads.
%
% Outputs:
%   - highwaySegs
%     The highway segments found.
%
% Yaguang Zhang, Purdue, 02/06/2021

if nargin == 2
    if evalin('base', ...
            '~exist(''INDOT_HIGHWAY_SEGS_ROADNAME_LABELS'',''var'')')
        INDOT_HIGHWAY_SEGS_ROADNAME_LABELS = ...
            getRoadNamesForHighwaySegs(indotRoads);
        putvar(INDOT_HIGHWAY_SEGS_ROADNAME_LABELS);
    else
        INDOT_HIGHWAY_SEGS_ROADNAME_LABELS ...
            = evalin('base','INDOT_HIGHWAY_SEGS_ROADNAME_LABELS');
    end
end

highwaySegs = indotRoads(...
    strcmpi(INDOT_HIGHWAY_SEGS_ROADNAME_LABELS, roadName)...
    );

end
% EOF