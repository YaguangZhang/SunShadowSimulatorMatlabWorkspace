function roadNames = getRoadNamesForRoadSegs(roadSegs)
% GETROADNAMESFORROADSEGS Extract all the road name labels of the input
% road segments (centerline 2019).
%
% Inputs:
%   - roadSegs
%     Struct array. Struct defined in the INDOT road database.
%
% Outputs:
%   - roadNames
%     Cell of strings. The road names found. The road names are in the form
%     like "S49". We use "S" as State, "I" as Interstate, "T" as Toll, and
%     "U" as US.
%
% Yaguang Zhang, Purdue, 02/02/2021

roadNames = cell(length(roadSegs),1);

for idx = 1:length(roadSegs)
    roadNames{idx} = getRoadNameFromRoadSeg(roadSegs(idx));
end

end
% EOF