%DEBUGCURLOCUNIFORMSUNPOWERSSEG A script to show how
%curLocUniformSunPowersSeg was generated.
%
% Yaguang Zhang, Purdue, 11/24/2020

close all;

%% LiDAR profile for determining blockage.
figure; hold on;
hSunPath = plot(curAltsOnDirectPath, 'b');
hLidarProfile = plot(curLidarProfile, 'rx');
legend([hSunPath, hLidarProfile], 'Sun Path', 'LiDAR Profile');

simConfigs.localDatetimesToInspect(idxDatetime)
figure;
plot(curAltsOnDirectPath-curLidarProfile);
title('Sun Path Height minus LiDAR Profile');

curMarkerSize = 12;
curLineWidth = 3;
figure; hold on;
[curEndLat, curEndLon] = ...
    simConfigs.utm2deg_speZone(curEndXY(1), curEndXY(2));
[curSampLocsLat, curSampLocsLon] = ...
    simConfigs.utm2deg_speZone(curSampLocs(:, 1), curSampLocs(:, 2));
plot3k([curSampLocsLon curSampLocsLat ...
    curLidarProfile-min(curLidarProfile)]); view(2);
plot(curGirdLatLon(2), curGirdLatLon(1), ...
    'bo', 'MarkerSize', curMarkerSize, 'LineWidth', curLineWidth);
plot(curEndLon, curEndLat, ...
    'rx', 'MarkerSize', curMarkerSize, 'LineWidth', curLineWidth);
plot_google_map('MapType', 'satellite');

%% Display loc and time.
display(datestr(simConfigs.localDatetimesToInspect(idxDatetime), ...
    'yyyy/mm/dd HH:MM:ss'));
display(curSunAzi);
display(curSunZen);

%% Save all the figures.
debugResultsDir = fullfile(folderToSaveResults, ...
    'debugCurLocUniformSunPowersSeg');
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
% EOF