%OVERVIEWGRIDONMAP A snippet to plot and save a figure for the grid points
%to inspect.
%
% Yaguang Zhang, Purdue, 01/29/2021

close all;

pathToSaveGridOnMapOverview = fullfile(folderToSaveResults, ...
    'gridOnMapOverview');
hGridOnMapOverview = figure;
plot(simConfigs.gridLatLonPts(:,2), simConfigs.gridLatLonPts(:,1), 'r.');
plot_google_map('MapType', 'hybrid');

saveas(hGridOnMapOverview, [pathToSaveGridOnMapOverview, '.fig']);
saveas(hGridOnMapOverview, [pathToSaveGridOnMapOverview, '.jpg']);

close all;
% EOF