function [pShp] = alphaShape2Polyshape(aShp)
%ALPHASHAPE2POLYSHAPE Convert a 2D alphaShape, aShp to polyshape pShp.
%
% Yaguang Zhang, Purdue, 10/31/2020

% Find breaks in the alphaShape boundary to deal with holes.
indicesFacets = boundaryFacets(aShp);
indicesFacets = cleanBoundaryFacetIndices(indicesFacets);
indicesBreak = find(...
    [0;~(indicesFacets(2:end,1)==indicesFacets(1:(end-1),2))]);

% Construct a polyshape and add the breaks backwards.
vertices = [aShp.Points(indicesFacets(:,1), :); ...
    aShp.Points(indicesFacets(end, 2), :)];
for idxLastRemaingBreak = indicesBreak(end:-1:1)'
    vertices = [vertices(1:(idxLastRemaingBreak-1),:); ...
        aShp.Points(indicesFacets(idxLastRemaingBreak-1,2), :); ...
        nan nan; ...
        vertices(idxLastRemaingBreak:end,:)];
end

pShp = polyshape(vertices);
end
% EOF