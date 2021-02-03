function [roadName, mileage] = getRoadNameFromMileMarker(mileMarker)
%GETROADNAMEFROMMILEMARKER Get the highway name from a mile marker in the
%INDOT mile marker database (2016).
%
% Inputs:
%   - mileMarker
%     Struct. The mile marker from the INDOT mile marker database.
%
% Outputs:
%   - roadName
%     String. The road name in the form like "S49". We use "S" as State,
%     "I" as Interstate, "T" as Toll, and "U" as US.
%   - mileage
%     An integer number for the mileage of the marker.
%
% Yaguang Zhang, Purdue, 02/02/2021

postName = mileMarker.POST_NAME;
[idxStart, idxEnd] = regexpi(postName, '[USIT]_\d+_\d+');
if ~isempty(idxStart) && idxStart == 1 && idxEnd == length(postName)
    indicesUnderscore = strfind(postName, '_');
    assert(length(indicesUnderscore)==2, ...
        ['Two and only two underscores are expected! ', ...
        '(Mile marker: ', postName, ')'])
    assert(indicesUnderscore(1)==2, ...
        ['Only one character is expected for the road type! ', ...
        '(Mile marker: ', postName, ')'])
    roadName = [postName(1), ...
        postName((indicesUnderscore(1)+1):(indicesUnderscore(2)-1))];
    mileage = str2double(postName((indicesUnderscore(2)+1):end));
else
    roadName = '';
    mileage = nan;
end

end
% EOF