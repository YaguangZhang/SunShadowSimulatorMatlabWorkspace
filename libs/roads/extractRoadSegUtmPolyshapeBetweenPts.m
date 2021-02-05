function [roadSegUtmPolyshapeNew, roadPtMsNew] ...
    = extractRoadSegUtmPolyshapeBetweenPts( ...
    roadSegUtmPolyshape, roadPtMs, ptXYMs)
%EXTRACTROADSEGUTMPOLYSHAPEBETWEENPTS This function will break the input
%road segment polyshape along both road sides at the input points on the
%road, and return the road segment between these break points.
%
% Inputs:
%   - roadSegUtmPolyshape
%     The input road segment polyshape.
%   - roadPtMs
%     A column vector for the mileage values of the polyshape vertices.
%     This input is needed to find the road sides.
%   - ptXYMs
%     A 2 x 3 matrix with the [x, y, mileage] coordinates of the two points
%     where the road segment needs to be split.
%
% Outputs:
%   - roadSegUtmPolyshapeNew
%     The extracted new road segment as a polyshape.
%   - roadPtMsNew
%     The updated mileage values for the polyshape vertices of the road
%     segment. We will use the mileages values for break points as those
%     for the newly added vertices.
%
% Yaguang Zhang, Purdue, 02/04/2021

numVs = length(roadPtMs);

% Mimic the circular nature of the vertices.
roadPtMsDouble = [roadPtMs; roadPtMs];
roadPtMsDoubleSelfDiff = roadPtMsDouble(2:end)-roadPtMsDouble(1:(end-1));

% Find the longest monotonically increasing segment of roadPtMs to locate
% one road side.
[indicesStarts, indicesEnds] = findConsecutiveSubSeq( ...
    roadPtMsDoubleSelfDiff>=0, true);
[~, idxLongestInc] = max(indicesEnds-indicesStarts);
indicesRoadSegSideIncMs = ...
    indicesStarts(idxLongestInc):(indicesEnds(idxLongestInc)+1);
boolsTooBig = indicesRoadSegSideIncMs>numVs;
indicesRoadSegSideIncMs(boolsTooBig) ...
    = indicesRoadSegSideIncMs(boolsTooBig) - numVs;

% Similarly, the longest monotonically decreasing segment of roadPtMs
% locats the other road side.
[indicesStarts, indicesEnds] = findConsecutiveSubSeq( ...
    roadPtMsDoubleSelfDiff<=0, true);
[~, idxLongestDec] = max(indicesEnds-indicesStarts);
indicesRoadSegSideDecMs = ...
    indicesStarts(idxLongestDec) ...
    :(indicesEnds(idxLongestDec)+1);
boolsTooBig = indicesRoadSegSideDecMs>numVs;
indicesRoadSegSideDecMs(boolsTooBig) ...
    = indicesRoadSegSideDecMs(boolsTooBig) - numVs;

% Locate the nearest line segment on each road side and add the new
% vertices there.
indicesRoadSegSide = {indicesRoadSegSideIncMs; indicesRoadSegSideDecMs};
% Temporarily store the vertices in a 3D matrix.
roadSegUtmPolyshapeNewVXs = roadSegUtmPolyshape.Vertices(:,1)';
roadSegUtmPolyshapeNewVYs = roadSegUtmPolyshape.Vertices(:,2)';
roadSegUtmPolyshapeNewVMs = roadPtMs';
[roadSegUtmPolyshapeNewVXs(2,:), ...
    roadSegUtmPolyshapeNewVYs(2,:), ...
    roadSegUtmPolyshapeNewVMs(2,:)] ...
    = deal(inf(size(roadSegUtmPolyshapeNewVXs)));
for idxSide = 1:2
    curIndicesRoadSegSide = indicesRoadSegSide{idxSide};
    numOfLineSegs = length(curIndicesRoadSegSide)-1;
    distsToLineSegs = nan(numOfLineSegs, 1);
    for idxBreakPt = 1:2
        for idxL = 1:numOfLineSegs
            distsToLineSegs(idxL) = p_poly_dist( ...
                ptXYMs(idxBreakPt,1), ptXYMs(idxBreakPt,2), ...
                roadSegUtmPolyshape.Vertices( ...
                curIndicesRoadSegSide(idxL:(idxL+1)), 1), ...
                roadSegUtmPolyshape.Vertices( ...
                curIndicesRoadSegSide(idxL:(idxL+1)), 2), false);
        end
        [~, idxNearestL] = min(distsToLineSegs);
        
        % We now need to add the break point on the road side (between
        % vertices curIndicesRoadSegSide(idxNearestL) and
        % curIndicesRoadSegSide(idxNearestL+1)).
        [~, breakPtX, breakPtY, isVertex] = p_poly_dist( ...
            ptXYMs(idxBreakPt,1), ptXYMs(idxBreakPt,2), ...
            roadSegUtmPolyshape.Vertices( ...
            curIndicesRoadSegSide(idxNearestL:(idxNearestL+1)), 1), ...
            roadSegUtmPolyshape.Vertices( ...
            curIndicesRoadSegSide(idxNearestL:(idxNearestL+1)), 2), false);
        % Only add the new point if it is a new vertex.
        if ~isVertex
            roadSegUtmPolyshapeNewVXs(2, ...
                curIndicesRoadSegSide(idxNearestL)) = breakPtX;
            roadSegUtmPolyshapeNewVYs(2, ...
                curIndicesRoadSegSide(idxNearestL)) = breakPtY;
            roadSegUtmPolyshapeNewVMs(2, ...
                curIndicesRoadSegSide(idxNearestL)) = ptXYMs(idxBreakPt,3);
        end
    end
end

roadSegUtmPolyshapeNewVXs = roadSegUtmPolyshapeNewVXs(:);
roadSegUtmPolyshapeNewVYs = roadSegUtmPolyshapeNewVYs(:);
roadSegUtmPolyshapeNewVMs = roadSegUtmPolyshapeNewVMs(:);

% Remove points out of the mileage range of interest.
mileageBounds = [min(ptXYMs(:,3)), max(ptXYMs(:,3))];
boolsPtsToKeep = roadSegUtmPolyshapeNewVMs >= mileageBounds(1) ...
    & roadSegUtmPolyshapeNewVMs <= mileageBounds(2);

roadSegUtmPolyshapeNew = polyshape( ...
    roadSegUtmPolyshapeNewVXs(boolsPtsToKeep), ...
    roadSegUtmPolyshapeNewVYs(boolsPtsToKeep));
roadPtMsNew = roadSegUtmPolyshapeNewVMs(boolsPtsToKeep);

end
% EOF