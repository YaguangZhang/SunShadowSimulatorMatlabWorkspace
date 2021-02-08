% TESTCONSTRUCTUTMROADSEGPOLYGON
%
% Yaguang Zhang, Purdue, 02/03/2021

clc; close all;
dbstop if error;

% Locate the Matlab workspace and save the current filename.
cd(fullfile(fileparts(mfilename('fullpath')), '..', '..', '..'));
addpath('libs');
curFileName = mfilename;

prepareSimulationEnv;

simConfigs.UTM_ZONE = '16 T';
% For GPS and UTM conversions.
[deg2utm_speZone, utm2deg_speZone] ...
    = genUtmConvertersForFixedZone(simConfigs.UTM_ZONE);

% Store these functions in simConfigs.
simConfigs.deg2utm_speZone = deg2utm_speZone;
simConfigs.utm2deg_speZone = utm2deg_speZone;

loadIndotRoads;
loadIndotMileMarkers;

roadName = 'U41';
latLonStartPts = {[39.791532, -87.236069], [39.792541, -87.235928]};
latLonEndPts = {[39.792553, -87.236054], [39.791528, -87.235930]};
[utmRoadSegPoly] = constructUtmRoadSegPolygon( ...
    roadName, ... roadNamesForCenterlinesAndMileMarkers
    latLonStartPts, latLonEndPts);

latLonStartPtsMat = vertcat(latLonStartPts{:});
latLonEndPtsMat = vertcat(latLonEndPts{:});

[latLonStartXs, latLonStartYs] = deg2utm_speZone( ...
    latLonStartPtsMat(:,1), latLonStartPtsMat(:,2));
[latLonEndXs, latLonEndYs] = deg2utm_speZone( ...
    latLonEndPtsMat(:,1), latLonEndPtsMat(:,2));
figure; hold on;
plot(polyshape(utmRoadSegPoly));
hS = plot(latLonStartXs, latLonStartYs, 'rx');
hE = plot(latLonEndXs, latLonEndYs, 'bo');
axis equal;
legend([hS, hE], 'Start Pts', 'End Pts');

[roadSegPolyLats, roadSegPolyLons] = utm2deg_speZone( ...
    utmRoadSegPoly(:,1), utmRoadSegPoly(:,2));
lonLatRoadSegPoly = polyshape(roadSegPolyLons, roadSegPolyLats);
figure; hold on;
plot(lonLatRoadSegPoly);
hS = plot(latLonStartPtsMat(:,2), latLonStartPtsMat(:,1), 'rx');
hE = plot(latLonEndPtsMat(:,2), latLonEndPtsMat(:,1), 'bo');
legend([hS, hE], 'Start Pts', 'End Pts', 'AutoUpdate', 'off')
axisToSet = axis;

% Show the centerline.
roadSegs = getRoadSegsByRoadName(roadName, indotRoads);
for idxSeg = 1:length(roadSegs)
    plot(roadSegs(idxSeg).Lon, roadSegs(idxSeg).Lat, ...
        'Linewidth', 3);
end
axis(axisToSet);

plot_google_map('MapType', 'hybrid');

% EOF