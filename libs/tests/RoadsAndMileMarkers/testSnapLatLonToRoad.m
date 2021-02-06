% TESTSNAPLATLONTOROAD
%
% Yaguang Zhang, Purdue, 02/06/2021

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


loadIndotRoads;
loadIndotMileMarkers;

latLon = [39.791532, -87.236069];

snapLatLonToRoad(latLon, 'U41', ...
    deg2utm_speZone, utm2deg_speZone, true);

% EOF