function PolyshapeLonLat = alphaShapeUtm2PolyshapeLonLat( ...
    alphaShapeUtm, zone)
%ALPHASHAPEUTM2POLYSHAPELONLAT Convert an alpha shape in UTM to
%
% Yaguang Zhang, Purdue, 11/01/2020

curPolyshapeUtm = alphaShape2Polyshape(alphaShapeUtm);

try
    [lats, lons] = utm2deg(...
        curPolyshapeUtm.Vertices(:,1), ...
        curPolyshapeUtm.Vertices(:,2), ...
        repmat(zone, size(curPolyshapeUtm.Vertices, 1), 1));
catch ConversionError
    error(ConversionError);
end

PolyshapeLonLat = polyshape([lons, lats]);
end
% EOF