if ~exist('indotMileMarkers','var')
    loadIndotMileMarkers;
end

if ~exist('indotRoads','var')
    loadIndotRoads;
    [~, ~, INDOT_MILE_MARKERS_ROADNAME_LABELS] = ...
        gpsCoor2MileMarker(0, 0, ...
        indotMileMarkers, indotRoads, UTM_STRUCT);
    putvar(indotMileMarkers, UTM_STRUCT, INDOT_MILE_MARKERS_ROADNAME_LABELS);
end

close all;
hFig = figure;
axis equal;
grid on;

% Because the 2019 centerline data set is very big, we will only show a
% small part of it.
roadNames = getRoadNamesForRoadSegs(indotRoads(1:1000));
uniqueRoadNames = unique(roadNames);
uniqueRoadNames = uniqueRoadNames(~cellfun('isempty',uniqueRoadNames));

for idxRoad = 1:length(uniqueRoadNames)
    curRoadName = uniqueRoadNames{idxRoad};
    
    hold on;
    roadSegs = getRoadSegsByRoadName(curRoadName, ...
        indotRoads);
    for idxSeg = 1:length(roadSegs)
        plot(roadSegs(idxSeg).Lon, roadSegs(idxSeg).Lat, ...
            'Linewidth', 3);
    end
    plot_google_map;
    hold off;
    title(uniqueRoadNames(idxRoad));
    figure(hFig);
    pause;
    clf;
end