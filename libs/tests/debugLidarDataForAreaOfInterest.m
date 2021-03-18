%DEBUGLIDARDATAFORAREAOFINTEREST A script to show the LiDAR data for the
%area of interest.
%
% Yaguang Zhang, Purdue, 01/08/2021

disp(' ')
disp(['        [', datestr(now, datetimeFormat), ...
    '] Generating plots for LiDAR data in the area of interest ...'])

close all;

%% LiDAR and terrain elevation data.

figure; hold on;
plot3k([simConfigs.gridLatLonPts(:,2), simConfigs.gridLatLonPts(:,1), ...
    simState.gridEles]);
plot_google_map('MapType', 'satellite');
curZLim = zlim; newZLim = [min(curZLim(1), 0) max(curZLim(2), 0)];
zlim(newZLim); view(2);
title('Terrain Elevation on Map');

figure; hold on;
plot3k([simConfigs.gridLatLonPts(:,2), simConfigs.gridLatLonPts(:,1), ...
    simState.gridEles-min(simState.gridEles)]);
plot_google_map('MapType', 'satellite');
curZLim = zlim; newZLim = [min(curZLim(1), 0) max(curZLim(2), 0)];
zlim(newZLim); view(2);
title('Terrain Elevation (minus min(eles)) on Map');

figure; hold on;
plot3k([simConfigs.gridLatLonPts(:,2), simConfigs.gridLatLonPts(:,1), ...
    simState.gridLidarZs]);
plot_google_map('MapType', 'satellite');
curZLim = zlim; newZLim = [min(curZLim(1), 0) max(curZLim(2), 0)];
zlim(newZLim); view(2);
title('LiDAR z on Map');

boolsNotInfZ = ~isinf(simState.gridLidarZs);
figure; hold on;
plot3k([simConfigs.gridLatLonPts(boolsNotInfZ,2), ...
    simConfigs.gridLatLonPts(boolsNotInfZ,1), ...
    simState.gridLidarZs(boolsNotInfZ) ...
    - min(simState.gridLidarZs(boolsNotInfZ))]);
plot_google_map('MapType', 'satellite');
curZLim = zlim; newZLim = [min(curZLim(1), 0) max(curZLim(2), 0)];
zlim(newZLim); view(2);
title('LiDAR z (minus min(zs)) on Map');

figure; hold on;
plot3k([simConfigs.gridLatLonPts(boolsNotInfZ,2), ...
    simConfigs.gridLatLonPts(boolsNotInfZ,1), ...
    simState.gridLidarZs(boolsNotInfZ)-simState.gridEles(boolsNotInfZ)]);
plot_google_map('MapType', 'satellite');
curZLim = zlim; newZLim = [min(curZLim(1), 0) max(curZLim(2), 0)];
zlim(newZLim); view(2); axisToSetForLidarOverviewFig = axis;
title('LiDAR z minus Terrain Elevation on Map');

figure; hold on;
plot3k([simConfigs.gridLatLonPts(boolsNotInfZ,2), ...
    simConfigs.gridLatLonPts(boolsNotInfZ,1), ...
    simState.gridLidarZs(boolsNotInfZ)-simState.gridEles(boolsNotInfZ)]);
curZLim = zlim; newZLim = [min(curZLim(1), 0) max(curZLim(2), 0)];
zlim(newZLim); view(2); axis(axisToSetForLidarOverviewFig);
title('LiDAR z minus Terrain Elevation');

%% Save all the figures.

if ~exist(debugResultsDir, 'dir')
    mkdir(debugResultsDir)
end
curFigList = findobj(allchild(0), 'flat', 'Type', 'figure');
for idxFig = 1:length(curFigList)
    curFigHandle = curFigList(idxFig);
    curFigName   = num2str(get(curFigHandle, 'Number'));
    set(0, 'CurrentFigure', curFigHandle);
    saveas(curFigHandle, fullfile(debugResultsDir, [curFigName '.fig']));
    saveas(curFigHandle, fullfile(debugResultsDir, [curFigName '.jpg']));
end

disp(['        [', datestr(now, datetimeFormat), ...
    '] Done!'])

% EOF