%GENERATEDEBUGFIGSFORLIDAR A snippet to help create and save debug figures
%for the processed LiDAR data set.
%
% Yaguang Zhang, Purdue, 01/09/2021

close all;

% Boundary on map.
figure;
plot(lonLatBoundryPolygon, ...
    'FaceColor','red','FaceAlpha',0.1);
plot_google_map('MapType', 'satellite');
title('Coverage on Map');

% (lidarLons, lidarLats, lidarZ).
figure; hold on;
plot(lonLatBoundryPolygon, ...
    'FaceColor','red','FaceAlpha',0.1);
plot3k([lidarLons, lidarLats, lidarXYZ(:,3)]);
view(2);
plot_google_map('MapType', 'satellite');
title('LiDAR z (m) on Map');

% lidarXYZ.
figure; hold on;
plot(xYBoundryPolygon, 'FaceColor','red','FaceAlpha',0.1);
plot3k(lidarXYZ);
axis equal; view(2);
title('LiDAR z (m) in UTM');

% A preview of all the elevation data fetched.
dispelev(rawElevData, 'mode', 'latlong');
plot_google_map('MapType', 'satellite');
title('Raw Terrain Elevation Data Tile');

% lidarZ - getLiDarZFromXYFct(lidarX, lidarY).
figure; hold on;
plot(xYBoundryPolygon, 'FaceColor','red','FaceAlpha',0.1);
plot3k([lidarXYZ(:,1), lidarXYZ(:,2), ...
    lidarXYZ(:,3) - getLiDarZFromXYFct(lidarXYZ(:,1), ...
    lidarXYZ(:,2))]);
axis equal; view(2);
title('lidarZ - getLiDarZFromXYFct(lidarX, lidarY)');

% lidarEles - getEleFromXYFct(lidarX, lidarY).
figure; hold on;
plot(xYBoundryPolygon, 'FaceColor','red','FaceAlpha',0.1);
plot3k([lidarXYZ(:,1), lidarXYZ(:,2), ...
    lidarEles - getEleFromXYFct(lidarXYZ(:,1), ...
    lidarXYZ(:,2))]);
axis equal; view(2);
title('lidarEles - getEleFromXYFct(lidarX, lidarY)');

% lidarZ - lidarEles.
figure; hold on;
plot(xYBoundryPolygon, 'FaceColor','red','FaceAlpha',0.1);
plot3k([lidarXYZ(:,1), lidarXYZ(:,2), ...
    lidarXYZ(:,3) - lidarEles]);
axis equal; view(2);
title('lidarZ - lidarEles');

% Save all the figures.
debugResultsDir = fullfile(ABS_PATH_TO_LOAD_LIDAR, ...
    'debugFigs');
if ~exist(debugResultsDir, 'dir')
    mkdir(debugResultsDir)
end
curFigList = findobj(allchild(0), 'flat', ...
    'Type', 'figure');
for idxFig = 1:length(curFigList)
    curFigHandle = curFigList(idxFig);
    curFigName   = ['LidarFile_', num2str(idxF), ...
        '_Fig_', num2str(get(curFigHandle, 'Number'))];
    set(0, 'CurrentFigure', curFigHandle);
    saveas(curFigHandle, fullfile(debugResultsDir, ...
        [curFigName '.fig']));
    saveas(curFigHandle, fullfile(debugResultsDir, ...
        [curFigName '.jpg']));
end