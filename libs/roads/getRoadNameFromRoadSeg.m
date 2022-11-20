function roadName = getRoadNameFromRoadSeg(roadSeg)
%GETROADNAMEFROMROADSEG Get the road name from a road segment from the
%INDOT road database (centerline 2019).
%
% Inputs:
%   - roadSeg
%     Struct. The road segment from the INDOT centerline database.
% Outputs:
%   - roadName
%     String. The road name in the form like "S49". We use "S" as State,
%     "I" as Interstate, "T" as Toll, and "U" as US.
%
% Note that in the INDOT centerline data set, we have in the FULL_STREE
% field various ways of naming roads, for example, "N/E/S/E SR/State
% Rd/State Road" as State, "INTERSTATE HIGHWAY/INTERSTATE/I(-)#" for
% Interstate, seemingly nothing for Toll, and "N/E/S/E US/USHY/United
% States Highway(-)#" as US.
%
% Yaguang Zhang, Purdue, 02/02/2021

% RegExp patterns (case-insensitive) to identify the road types.
roadTypes = {'S', 'I', 'U'};
regPats = {'(SR|State Rd|State Road)( |-|)(\d+)', ...
    '(INTERSTATE HIGHWAY|INTERSTATE|I)( |-|)(\d+)', ...
    '(US|USHY|US HWY|US HIGHWAY|United States Highway)( |-|)(\d+)'};

roadName = roadSeg.FULL_STREE;

for idxType = 1:length(roadTypes)
    ts = regexpi(roadName, regPats{idxType}, 'tokens');
    if ~isempty(ts)
        roadNumStr = ts{1}{3};
        roadName = [roadTypes{idxType}, roadNumStr];
        break;
    end
end

end
% EOF