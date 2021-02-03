RoadToShow = 'S53'; % S53, U41, I69, S161, S66

if ~exist('indotMileMarkers','var')
    loadIndotMileMarkers;
end

if ~exist('indotHighways','var')
    loadIndotRoads;
end

close all;
figure;
hold on;
axis equal;
grid on;

mileMarkersSelected = getMileMarkersByRoadName( ...
    RoadToShow, indotMileMarkers);
highWaySegmentsSelected = getRoadSegsByRoadName(RoadToShow, indotRoads);
for idx = 1:length(mileMarkersSelected)
    plot(mileMarkersSelected(idx).Lon, mileMarkersSelected(idx).Lat,'xr');
    text(mileMarkersSelected(idx).Lon, mileMarkersSelected(idx).Lat, ...
        mileMarkersSelected(idx).POST_NAME, 'Interpreter', 'none');
end
plot([highWaySegmentsSelected.Lon], [highWaySegmentsSelected.Lat], ...
    'b-', 'LineWidth', 3);


% For analyzing mile markers on S161.

% mileMarkersSelected = getMileMarkersByRoadName('S161',indotMileMarkers);
% highWaySegmentsSelected = getHighwaySegsByRoadName('S161',indotHighways);
% for idx = 1:length(mileMarkersSelected)
%     plot(mileMarkersSelected(idx).Lon, mileMarkersSelected(idx).Lat,'ob');
%     text(mileMarkersSelected(idx).Lon, mileMarkersSelected(idx).Lat, ...
%         mileMarkersSelected(idx).IIT_NOTE);
% end
% plot([highWaySegmentsSelected.Lon], [highWaySegmentsSelected.Lat]);
%
% mileMarkersRef = getMileMarkersByRoadName('S66',indotMileMarkers);
% highWaySegmentsRef = getHighwaySegsByRoadName('S66',indotHighways);
% for idx = 1:length(mileMarkersRef)
%     plot(mileMarkersRef(idx).Lon, mileMarkersRef(idx).Lat,'xr');
%     text(mileMarkersRef(idx).Lon, mileMarkersRef(idx).Lat, ...
%         mileMarkersRef(idx).IIT_NOTE);
% end
% plot([highWaySegmentsRef.Lon], [highWaySegmentsRef.Lat]);

hold off;

plot_google_map('MapType', 'roadmap');