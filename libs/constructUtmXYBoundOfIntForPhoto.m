function boundOfIntUtmXYs = constructUtmXYBoundOfIntForPhoto( ...
    cameraLatLon, targetLatLon, deg2utmSpeZone, distInM)
%CONSTRUCTUTMXYBOUNDOFINTFORPHOTO Construct the boundary of interest to
%carry out simulation for a photo.
%
% Inputs:
%   - cameraLatLon, targetLatLon
%     The GPS (lat, lon) for the camera and the target location the camera
%     looks at, respectively.
%   - deg2utmSpeZone
%     The deg2utm function to use for converting GPS coordinates to UTM
%     ones, but with the UTM zone imbedded. Please refer to deg2utm and
%     genUtmConvertersForFixedZone for more information.
%   - distInM
%     The distance we will inspect from the camera towards the target
%     location.
%
% Output:
%   - boundOfIntUtmXYs
%     A closed square (5 points) covering an area in front of the camera.
%
% Yaguang Zhang, Purdue, 3/16/2021

[cameraUtmXY, targetUtmXY] = deal(nan(1, 2));
[cameraUtmXY(1), cameraUtmXY(2)] = deg2utmSpeZone( ...
    cameraLatLon(1), cameraLatLon(2));
[targetUtmXY(1), targetUtmXY(2)] = deg2utmSpeZone( ...
    targetLatLon(1), targetLatLon(2));

% Compute the unit vector from the camera to the target.
vCam2Tar = targetUtmXY - cameraUtmXY;
uCam2Tar = vCam2Tar./norm(vCam2Tar);

% Find the new target point which is distInM away from the camera.
newTargetUtmXY = cameraUtmXY + uCam2Tar.*distInM;

% Rotated (+/- 90 degree) versions of uCam2Tar.
uCam2TarClockwise = uCam2Tar*[0, -1; 1, 0];
uCam2TarCntClkwise = uCam2Tar*[0, 1; -1, 0];

% Construct the output.
boundOfIntUtmXYs = [cameraUtmXY + distInM/2.*uCam2TarCntClkwise; ...
    newTargetUtmXY + distInM/2.*uCam2TarCntClkwise; ...
    newTargetUtmXY + distInM/2.*uCam2TarClockwise; ...
    cameraUtmXY + distInM/2.*uCam2TarClockwise];
% Close the polygon.
boundOfIntUtmXYs(5,:) = boundOfIntUtmXYs(1,:);

end
% EOF