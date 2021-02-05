function [cleanedIndices] = cleanBoundaryFacetIndices(indices)
%CLEANBOUNDARYFACETINDICES Reorder the indice rows of the input boundary
%facet indices, so that connected segments are adjacent.
%
% Yaguang Zhang, Purdue, 03/19/2015

cleanedIndices = nan(size(indices));
indicesToProc = indices;

cleanedIndices(1,:) = indicesToProc(1,:);
indicesToProc(1,:) = nan;

curIdx = 2;
while curIdx<=size(indices,1)
    rowIdxToLoad = ...
        find(indicesToProc(:, 1)==cleanedIndices(curIdx-1, 2), 1, 'first');
    if isempty(rowIdxToLoad)
        rowIdxToLoad = find(~isnan(indicesToProc(:,1)), 1, 'first');
    end
    if ~isempty(rowIdxToLoad)
        cleanedIndices(curIdx,:) = indicesToProc(rowIdxToLoad,:);
        indicesToProc(rowIdxToLoad,:) = nan;
    end
    curIdx = curIdx+1;
end
end
% EOF