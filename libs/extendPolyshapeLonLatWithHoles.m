function [outputPolyshapeLonLat] = extendPolyshapeLonLatWithHoles( ...
    inputPolyshapeLonLat, range)
%EXTENDPOLYSHAPELONLATWITHHOLES Extend a polyshape with (one-level) holes
%in (lon, lat) by a radius in meters.
%
% We will process the extention in the UTM system.
%
% Yaguang Zhang, Purdue, 11/02/2020

[xs, ys, curZone] = deg2utmForceOneZone( ...
    inputPolyshapeLonLat.Vertices(:,2),...
    inputPolyshapeLonLat.Vertices(:,1));

outputPolyshapeUtm = polybuffer(polyshape(xs, ys), range);
[lats, lons] = utm2deg(outputPolyshapeUtm.Vertices(:,1), ...
    outputPolyshapeUtm.Vertices(:,2), ...
    repmat(curZone, size(outputPolyshapeUtm.Vertices(:,1),1), 1));

outputPolyshapeLonLat = polyshape(lons, lats);
end
% EOF