function [xs, ys] = mileage2XY(mileages, ...
    roadSegPolyshape, roadSegPtMileages, ...
    flagDebug)
%MILEAGE2XY Estimate the (x, y) coordinates for the input mileage values
%based on a road segment polyshape and the mileages for its vertices.
%
% Inputs:
%   - mileages
%     A column vector for the input mileage values.
%   - roadSegPolyshape
%     A polyshape representing the reference road segment.
%   - roadSegPtMileages
%     A column vector for the mileage values of the vertices of the input
%     road segment polyshape.
%   - flagDebug
%     Optional. Set this to be true for debugging.
%
% Outputs:
%   - xs, ys
%     Column vectors. The estimated [xs, ys] coordinates for the input
%     mileage values.
%
% Yaguang Zhang, Purdue, 02/06/2021

if ~exist('flagDebug', 'var')
    flagDebug = false;
end

numVs = length(roadSegPtMileages);

% Mimic the circular nature of the vertices.
roadPtMsDouble = [roadSegPtMileages; roadSegPtMileages];
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

% Use this side as the reference side for interpolation.
roadSegPtMileagesRef = roadSegPtMileages(indicesRoadSegSideIncMs);
roadSegPtXsRef = roadSegPolyshape.Vertices(indicesRoadSegSideIncMs,1);
roadSegPtYsRef = roadSegPolyshape.Vertices(indicesRoadSegSideIncMs,2);

% We will use linear interpolation.
[roadSegPtMileagesSorted, idxOrderSorted] = sort(roadSegPtMileagesRef);
roadSegPtXsSorted = roadSegPtXsRef(idxOrderSorted);
roadSegPtYsSorted = roadSegPtYsRef(idxOrderSorted);
xs = interp1q(roadSegPtMileagesSorted, roadSegPtXsSorted, mileages);
ys = interp1q(roadSegPtMileagesSorted, roadSegPtYsSorted, mileages);

if flagDebug
    figure; hold on;
    plot3(roadSegPolyshape.Vertices(:,1), ...
        roadSegPolyshape.Vertices(:,2), roadSegPtMileages, 'b-');
    plot3(xs, ys, mileages, 'rx');
    
    figure; hold on;
    plot(roadSegPtMileagesSorted, roadSegPtXsSorted, 'b-');
    plot(mileages, xs, 'rx');
    xlabel('Mileage'); ylabel('x');
    grid on; grid minor;
    
    figure; hold on;
    plot(roadSegPtMileagesSorted, roadSegPtYsSorted, 'b-');
    plot(mileages, ys, 'rx');
    xlabel('Mileage'); ylabel('y');
    grid on; grid minor;
end

end
% EOF