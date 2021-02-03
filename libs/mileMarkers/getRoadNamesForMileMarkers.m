function roadNames = getRoadNamesForMileMarkers(mileMarkers)
% GETROADNAMESFORMILEMARKERS Extract all the road name labels of the input
% mile markers (2016).
%
% Inputs:
%   - mileMarkers
%     Struct array. Struct defined in the INDOT mile marker database.
%
% Outputs:
%   - roadNames
%     Cell of strings. The road names found. The road names are in the form
%     like "S49". We use "S" as State, "I" as Interstate, "T" as Toll, and
%     "U" as US.
%
% Yaguang Zhang, Purdue, 02/02/2021

roadNames = cell(length(mileMarkers),1);

for idx = 1:length(mileMarkers)
    roadNames{idx} = getRoadNameFromMileMarker(mileMarkers(idx));
end

end
% EOF