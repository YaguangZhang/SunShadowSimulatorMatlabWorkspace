function roadSegUtmPolyshapeNew = extractRoadSegUtmPolyshapeBetweenPts( ...
    roadSegUtmPolyshape, roadPtMs, ptXYMs, flagDebug)
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
%   - flagDebug
%     Optional. Set this to be true to generate debug figures.
%
% Outputs:
%   - roadSegUtmPolyshapeNew
%     The extracted new road segment as a polyshape.
%
% Yaguang Zhang, Purdue, 02/04/2021

if ~exist('flagDebug', 'var')
    flagDebug = false;
end

numVs = length(roadPtMs);

% Mimic the circular nature of the vertices.
roadPtMsDouble = [roadPtMs; roadPtMs(1)];
roadPtMsDoubleSelfDiff = roadPtMsDouble(2:end)-roadPtMsDouble(1:(end-1));

% Find the strictly increasing segment(s) of roadPtMs to locate one road
% side. Note that this could corresponds to multiple road segments because
% there could be more than one lane.
[indicesStarts, indicesEnds] = findConsecutiveSubSeq( ...
    roadPtMsDoubleSelfDiff>0, true);
numOfRoadSegsSideIncMs = length(indicesStarts);
indicesSideRoadSegIncMsCell = cell(numOfRoadSegsSideIncMs, 1);
for idxRoadSegIncMs = 1:numOfRoadSegsSideIncMs
    % To avoid redundent sequences, the start index has to be in roadPtMs.
    if indicesStarts(idxRoadSegIncMs)<=length(roadPtMs)
        indicesSideRoadSegIncMs = ...
            indicesStarts(idxRoadSegIncMs) ...
            :(indicesEnds(idxRoadSegIncMs)+1);
        boolsTooBig = indicesSideRoadSegIncMs>numVs;
        indicesSideRoadSegIncMs(boolsTooBig) ...
            = indicesSideRoadSegIncMs(boolsTooBig) - numVs;
        indicesSideRoadSegIncMsCell{idxRoadSegIncMs} ...
            = indicesSideRoadSegIncMs;
    end
end
indicesSideRoadSegIncMsCell( ...
    cellfun('isempty', indicesSideRoadSegIncMsCell)) = [];

% Similarly, the strictly decreasing segment of roadPtMs locats the other
% road side.
[indicesStarts, indicesEnds] = findConsecutiveSubSeq( ...
    roadPtMsDoubleSelfDiff<0, true);
numOfRoadSegsSideDecMs = length(indicesStarts);
indicesSideRoadSegDecMsCell = cell(numOfRoadSegsSideDecMs, 1);
for idxRoadSegDecMs = 1:numOfRoadSegsSideDecMs
    if indicesStarts(idxRoadSegDecMs)<=length(roadPtMs)
        indicesSideRoadSegDecMs = ...
            indicesStarts(idxRoadSegDecMs) ...
            :(indicesEnds(idxRoadSegDecMs)+1);
        boolsTooBig = indicesSideRoadSegDecMs>numVs;
        indicesSideRoadSegDecMs(boolsTooBig) ...
            = indicesSideRoadSegDecMs(boolsTooBig) - numVs;
        indicesSideRoadSegDecMsCell{idxRoadSegDecMs} ...
            = indicesSideRoadSegDecMs;
    end
end
indicesSideRoadSegDecMsCell( ...
    cellfun('isempty', indicesSideRoadSegDecMsCell)) = [];

% Locate the nearest line segment on each side road segment and add the new
% vertices there.
indicesSideRoadSegsCell = vertcat( ...
    indicesSideRoadSegIncMsCell, indicesSideRoadSegDecMsCell);
% Temporarily store the vertices in a 3D matrix.
numOfSideRoadSegs = length(indicesSideRoadSegsCell);
roadSegUtmPolyshapeNewVXs = roadSegUtmPolyshape.Vertices(:,1)';
roadSegUtmPolyshapeNewVYs = roadSegUtmPolyshape.Vertices(:,2)';
roadSegUtmPolyshapeNewVMs = roadPtMs';
% We expect at most two break points (one by each input point) to be added
% on one 2-vertex segment.
[roadSegUtmPolyshapeNewVXs(2:3,:), ...
    roadSegUtmPolyshapeNewVYs(2:3,:), ...
    roadSegUtmPolyshapeNewVMs(2:3,:)] ...
    = deal(inf(2, length(roadSegUtmPolyshapeNewVXs)));
for idxSideRoadSeg = 1:numOfSideRoadSegs
    curIndicesSideRoadSeg = indicesSideRoadSegsCell{idxSideRoadSeg};
    numOfLineSegs = length(curIndicesSideRoadSeg)-1;
    distsToLineSegs = nan(numOfLineSegs, 1);
    for idxBreakPt = 1:2
        % Locate the nearest 2-vertex segment.
        for idxL = 1:numOfLineSegs
            distsToLineSegs(idxL) = p_poly_dist( ...
                ptXYMs(idxBreakPt,1), ptXYMs(idxBreakPt,2), ...
                roadSegUtmPolyshape.Vertices( ...
                curIndicesSideRoadSeg(idxL:(idxL+1)), 1), ...
                roadSegUtmPolyshape.Vertices( ...
                curIndicesSideRoadSeg(idxL:(idxL+1)), 2), false);
        end
        [~, idxNearestL] = min(distsToLineSegs);
        
        % We now need to add the break point on the road side (between
        % vertices curIndicesSideRoadSeg(idxNearestL) and
        % curIndicesSideRoadSeg(idxNearestL+1)).
        [~, breakPtX, breakPtY, isVertex] = p_poly_dist( ...
            ptXYMs(idxBreakPt,1), ptXYMs(idxBreakPt,2), ...
            roadSegUtmPolyshape.Vertices( ...
            curIndicesSideRoadSeg(idxNearestL:(idxNearestL+1)), 1), ...
            roadSegUtmPolyshape.Vertices( ...
            curIndicesSideRoadSeg(idxNearestL:(idxNearestL+1)), 2), false);
        % Only add the point if it is a new vertex on the 2-vertex segment.
        onEdgeXBound = [min(roadSegUtmPolyshape.Vertices( ...
            curIndicesSideRoadSeg(idxNearestL:(idxNearestL+1)), 1)), ...
            max(roadSegUtmPolyshape.Vertices( ...
            curIndicesSideRoadSeg(idxNearestL:(idxNearestL+1)), 1))];
        if onEdgeXBound(1)~=onEdgeXBound(2)
            flagBreakPtOnEdge = breakPtX>onEdgeXBound(1) ...
                && breakPtX<onEdgeXBound(2);
        else
            onEdgeYBound = [min(roadSegUtmPolyshape.Vertices( ...
                curIndicesSideRoadSeg( ...
                idxNearestL:(idxNearestL+1)), 2)), ...
                ...
                max(roadSegUtmPolyshape.Vertices( ...
                curIndicesSideRoadSeg( ...
                idxNearestL:(idxNearestL+1)), 2))];
            flagBreakPtOnEdge = breakPtY>onEdgeYBound(1) ...
                && breakPtY<onEdgeYBound(2);
        end
        if ~isVertex && flagBreakPtOnEdge
            curRowToStoreResult = idxBreakPt+1;
            assert(all(isinf([ ...
                roadSegUtmPolyshapeNewVXs(curRowToStoreResult, ...
                curIndicesSideRoadSeg(idxNearestL)), ...
                roadSegUtmPolyshapeNewVYs(curRowToStoreResult, ...
                curIndicesSideRoadSeg(idxNearestL)), ...
                roadSegUtmPolyshapeNewVMs(curRowToStoreResult, ...
                curIndicesSideRoadSeg(idxNearestL))])), ...
                'This 2-vertex segment has been splitted already!')
            roadSegUtmPolyshapeNewVXs(curRowToStoreResult, ...
                curIndicesSideRoadSeg(idxNearestL)) = breakPtX;
            roadSegUtmPolyshapeNewVYs(curRowToStoreResult, ...
                curIndicesSideRoadSeg(idxNearestL)) = breakPtY;
            roadSegUtmPolyshapeNewVMs(curRowToStoreResult, ...
                curIndicesSideRoadSeg(idxNearestL)) = ptXYMs(idxBreakPt,3);
        end
    end
end

% If two break points are added for one 2-vertex segment, we need to make
% sure their order is correct for forming the new polyshape.
indicesTwoBreakPtsAdded = find(sum(isinf(roadSegUtmPolyshapeNewVXs))==0);
for curIdxRoadSegPt = indicesTwoBreakPtsAdded
    idxRowSecond = curIdxRoadSegPt+1;
    if idxRowSecond>size(roadSegUtmPolyshapeNewVMs,2)
        idxRowSecond = mod( ...
            idxRowSecond, size(roadSegUtmPolyshapeNewVMs,2));
    end
    curSegMs = roadSegUtmPolyshapeNewVMs(1, ...
        [curIdxRoadSegPt, idxRowSecond]);
    curBreakPtMs = roadSegUtmPolyshapeNewVMs(2:3, curIdxRoadSegPt);
    % If curSegMs is increasing, curBreakPtMs should be increasing, too
    % (and vice versa). We will need to swap the break points if this is
    % not the case.
    if diff(curSegMs)*diff(curBreakPtMs)<0
        roadSegUtmPolyshapeNewVXs = ...
            swapNewBreakPoints(roadSegUtmPolyshapeNewVXs, curIdxRoadSegPt);
        roadSegUtmPolyshapeNewVYs = ...
            swapNewBreakPoints(roadSegUtmPolyshapeNewVYs, curIdxRoadSegPt);
        roadSegUtmPolyshapeNewVMs = ...
            swapNewBreakPoints(roadSegUtmPolyshapeNewVMs, curIdxRoadSegPt);
    end
end

% We just want to add new vertices to the polyshape. We do not want to
% actually split it.
if false
    % Add the break points with nan to actually break the resultant
    % polygon.
    [roadSegUtmPolyshapeNewVXs] ...
        = addBreakPointsWithNan(roadSegUtmPolyshapeNewVXs); %#ok<UNRCH>
    [roadSegUtmPolyshapeNewVYs] ...
        = addBreakPointsWithNan(roadSegUtmPolyshapeNewVYs);
    [roadSegUtmPolyshapeNewVMs] ...
        = addBreakPointsWithNan(roadSegUtmPolyshapeNewVMs);
end

% Convert the vertex matrices to column vectors.
roadSegUtmPolyshapeNewVXs = roadSegUtmPolyshapeNewVXs(:);
roadSegUtmPolyshapeNewVYs = roadSegUtmPolyshapeNewVYs(:);
roadSegUtmPolyshapeNewVMs = roadSegUtmPolyshapeNewVMs(:);

% Remove inf points.
boolsInfPts = isinf(roadSegUtmPolyshapeNewVXs) ...
    | isinf(roadSegUtmPolyshapeNewVYs) ...
    | isinf(roadSegUtmPolyshapeNewVMs);
roadSegUtmPolyshapeNewVXs = roadSegUtmPolyshapeNewVXs(~boolsInfPts);
roadSegUtmPolyshapeNewVYs = roadSegUtmPolyshapeNewVYs(~boolsInfPts);
roadSegUtmPolyshapeNewVMs = roadSegUtmPolyshapeNewVMs(~boolsInfPts);

% Remove points out of the mileage range of interest.
mileageBounds = [min(ptXYMs(:,3)), max(ptXYMs(:,3))];
boolsPtsToKeep = roadSegUtmPolyshapeNewVMs >= mileageBounds(1) ...
    & roadSegUtmPolyshapeNewVMs <= mileageBounds(2);

% Temporarily depress warnings.
warning('off', 'MATLAB:polyshape:repairedBySimplify');
roadSegUtmPolyshapeNew = polyshape( ...
    roadSegUtmPolyshapeNewVXs(boolsPtsToKeep), ...
    roadSegUtmPolyshapeNewVYs(boolsPtsToKeep));
warning('on', 'MATLAB:polyshape:repairedBySimplify');

% Intersect the new polygon with that for the whole road segment of
% interest to make sure the result is part of the input road.
roadSegUtmPolyshapeNew = intersect(roadSegUtmPolyshapeNew, ...
    roadSegUtmPolyshape);

if flagDebug
    if evalin('base', "exist('simConfigs', 'var')")
        simConfigs = evalin('base', "simConfigs");
        try
            utm2deg_speZone = simConfigs.utm2deg_speZone;
        catch
            try
                utm2deg_speZone = evalin('base', "utm2deg_speZone");
            catch
                [~, utm2deg_speZone] ...
                    = genUtmConvertersForFixedZone(simConfigs.UTM_ZONE);
            end
        end
        
        figure; hold on;
        [roadSegLats, roadSegLons] = utm2deg_speZone( ...
            roadSegUtmPolyshapeNew.Vertices(:,1), ...
            roadSegUtmPolyshapeNew.Vertices(:,2));
        roadSegLonLatPolyshapeNew = polyshape(roadSegLons, roadSegLats);
        plot(roadSegLonLatPolyshapeNew); axisToSet = axis;
        [roadSegNewLats, roadSegNewLons] = utm2deg_speZone( ...
            roadSegUtmPolyshapeNewVXs, roadSegUtmPolyshapeNewVYs);
        plot3k([roadSegNewLons, roadSegNewLats, roadSegUtmPolyshapeNewVMs])
        axis(axisToSet); view(2);
        plot_google_map('MapType', 'hybrid');
    else
        figure; hold on;
        plot(roadSegUtmPolyshapeNew); axisToSet = axis;
        plot3k([roadSegUtmPolyshapeNewVXs, roadSegUtmPolyshapeNewVYs, ...
            roadSegUtmPolyshapeNewVMs])
        axis(axisToSet); pbaspect([1,1,1]); view(2);
    end
end

end
% EOF