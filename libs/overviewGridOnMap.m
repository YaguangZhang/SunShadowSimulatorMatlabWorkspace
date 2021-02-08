%OVERVIEWGRIDONMAP A snippet to plot and save a figure for the grid points
%to inspect.
%
% Yaguang Zhang, Purdue, 01/29/2021

disp(' ')
disp(['        [', datestr(now, datetimeFormat), ...
    '] Generating an overview for the area of interest ...'])

close all;

hGridOnMapOverview = figure;
plot(simConfigs.gridLatLonPts(:,2), simConfigs.gridLatLonPts(:,1), 'r.');
plot_google_map('MapType', 'hybrid');

saveas(hGridOnMapOverview, [pathToSaveGridOnMapOverview, '.fig']);
saveas(hGridOnMapOverview, [pathToSaveGridOnMapOverview, '.jpg']);

close all;

disp(['        [', datestr(now, datetimeFormat), ...
    '] Done!'])

% EOF