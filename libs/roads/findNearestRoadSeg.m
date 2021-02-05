function [nearestSegs, nearestDist] ...
    = findNearestRoadSeg(X, Y, ...
    indotRoads, flagPlotResults)
% FINDNEARESTROADSEG Find the nearest road segment to the input
% point.
%
%   roadSeg = findNearestRoadSeg(X, Y, indotRoads)
%
% Inputs:
%   - X, Y
%     The coordinates in UMT for the locations that is being queried.
%   - indotRoads
%     Loaded INDOT road database. Fields required:
%       - Shape_Leng
%         The length (in meter) of the road segment.
%       - BoundingBox
%         The bounding box [xMin, ymin; xMax, yMax] for the road segment.
%   - flagPlotResults
%     Optional. If it is true, a figure will be generated to show (X, Y), the
%     vertices and bounding boxes for the nearby road segments.
%
% Outputs:
%   - nearestSegs
%     The road segments found.
%
% Yaguang Zhang, Purdue, 02/03/2020

% First construct a nearby bounding area for the point specified so that we
% can filter out the segments outside.

% The side lenght of the nearby square area we'll search. If the bounding
% box is in the square we are searching, we will treat the cooresponding
% segments as nearby. To make sure we won't miss the road segment that the
% point (X,Y) may be on, we will use twice the maximum segment length in
% the INDOT road database as the side length for the nearby square that
% we will search. The unit is in meters: 1 mile = 1609.344 meters.
nearbySquSideLength = max([indotRoads.Shape_Leng])*2;
[Xmin, XMax, Ymin, YMax] = constructSquareLimits( ...
    X, Y, nearbySquSideLength);

boundingBoxes = reshape([indotRoads.BoundingBox], 2, 2, []);
nearestSegs = indotRoads(...
    boundingBoxes(1,1,:) >= Xmin ...
    & boundingBoxes(2,1,:) <= XMax ...
    & boundingBoxes(1,2,:) >= Ymin ...
    & boundingBoxes(2,2,:) <= YMax);

% Calculate the distances from the qurrying location to these segments.
distRoadSegs = zeros(length(nearestSegs),1);
for idxRoadSeg = 1:length(nearestSegs)
    % Create the polygons to for the min-dist computation.
    P1.x = X;
    P1.y = Y;
    P2.x = nearestSegs(idxRoadSeg).X;
    P2.y = nearestSegs(idxRoadSeg).Y;
    distRoadSegs(idxRoadSeg) = ...
        min_dist_between_two_polygons(P1,P2,0);
end

% Use the nearest segment(s) as the output.
nearestSegs = nearestSegs(distRoadSegs == min(distRoadSegs));
if nargout == 2
    nearestDist = min(distRoadSegs);
end

% Plot the result if necessary.
if nargin == 4
    if flagPlotResults == true
        figure('name','Nearby road segments');
        hold on;
        axis equal;
        grid on;
        for idxSegment=1:length(nearestSegs)
            plot(nearestSegs(idxSegment).X, nearestSegs(idxSegment).Y,'ro');
            bbb = nearestSegs(idxSegment).BoundingBox;am = bbb(1,1);
            aM = bbb(2,1);bm = bbb(1,2);bM = bbb(2,2);
            plot([am, aM, aM, am, am], [bM, bM, bm, bm, bM],'b');
        end
        plot(X,Y,'k*');
        hold off;
    end
end

end

% % The maximum side length for the nearby square that we will search in %
% meters: 1 mile = 1609.344 meters. SIDE_LENGTH = (...
%     mean([indotRoads.LENGTH]) + 3 * var([indotRoads.LENGTH])... ) *
%     1609.344;
% % How many times to try finding the segments. NUM_TRIALS = 100;
%
% % First find nearby road segments. We will search the nearby area with
% a % square. We will start with a small square and enlarge it if no
% segments % are found. for indexTrial = 1:NUM_TRIALS
%     % The side lenght of the nearby square area we'll search.
%     nearbySquSideLength = indexTrial*SIDE_LENGTH/NUM_TRIALS; [Xmin, XMax,
%     Ymin, YMax] = constructSquareLimits(X, Y, nearbySquSideLength);
%
%     % If any vertex of the bounding box is in the square we are
%     searching, % we will treat that segments as nearby. boundingBoxes =
%     reshape([indotRoads.BoundingBox], 2, 2, []); roadSegs =
%     indotRoads(...
%         [boundingBoxes(1,1,:)] >= Xmin ... & [boundingBoxes(1,1,:)] <=
%         XMax ... & [indotRoads.Y] >= Ymin ... & [indotRoads.Y] <=
%         YMax);
%     if ~isempty(roadSegs)
%         break;
%     end
% end
%
% if isempty(roadSegs)
%         break;
% end
%
%
% end EOF