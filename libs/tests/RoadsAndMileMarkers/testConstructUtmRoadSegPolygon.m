clc; close all;
dbstop if error;

% Locate the Matlab workspace and save the current filename.
cd(fullfile(fileparts(mfilename('fullpath')), '..', '..', '..')); 
addpath('libs');
curFileName = mfilename;

prepareSimulationEnv;

simConfigs.UTM_ZONE = '16 T';
% Convert GPS degrees to UTM coordinates for the specified zone.
utmstruct_speZone = defaultm('utm');
% Remove white space in the zone label.
utmstruct_speZone.zone ...
    = simConfigs.UTM_ZONE(~isspace(simConfigs.UTM_ZONE));
utmstruct_speZone.geoid = wgs84Ellipsoid;
utmstruct_speZone = defaultm(utmstruct_speZone);

deg2utm_speZone = @(lat, lon) mfwdtran(utmstruct_speZone, lat,lon);
utm2deg_speZone = @(x, y) minvtran(utmstruct_speZone, x, y);

% Store these functions in simConfigs.
simConfigs.deg2utm_speZone = deg2utm_speZone;
simConfigs.utm2deg_speZone = utm2deg_speZone;

loadIndotRoads;
loadIndotMileMarkers;

latLonStartPts = {[39.791532, -87.236069], [39.792541, -87.235928]};
latLonEndPts = {[39.792553, -87.236054], [39.791528, -87.235930]};
[utmRoadSegPoly] = constructUtmRoadSegPolygon( ...
    'U41', ... roadNamesForCenterlinesAndMileMarkers
    latLonStartPts, latLonEndPts);

latLonStartPtsMat = vertcat(latLonStartPts{:});
latLonEndPtsMat = vertcat(latLonEndPts{:});

[latLonStartXs, latLonStartYs] = deg2utm_speZone( ...
    latLonStartPtsMat(:,1), latLonStartPtsMat(:,2));
[latLonEndXs, latLonEndYs] = deg2utm_speZone( ...
    latLonEndPtsMat(:,1), latLonEndPtsMat(:,2));
figure; hold on;
plot(utmRoadSegPoly);
hS = plot(latLonStartXs, latLonStartYs, 'rx');
hE = plot(latLonEndXs, latLonEndYs, 'bo');
legend([hS, hE], 'Start Pts', 'End Pts');

[roadSegPolyLats, roadSegPolyLons] = utm2deg_speZone( ...
    utmRoadSegPoly.Vertices(:,1), utmRoadSegPoly.Vertices(:,2));
lonLatRoadSegPoly = polyshape(roadSegPolyLons, roadSegPolyLats);
figure; hold on;
plot(lonLatRoadSegPoly);
hS = plot(latLonStartPtsMat(:,2), latLonStartPtsMat(:,1), 'rx');
hE = plot(latLonEndPtsMat(:,2), latLonEndPtsMat(:,1), 'bo');
legend([hS, hE], 'Start Pts', 'End Pts');
plot_google_map('MapType', 'hybrid');