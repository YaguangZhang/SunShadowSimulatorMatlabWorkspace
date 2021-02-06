% PLOTMILEMARKERSFORROAD
%
% Yaguang Zhang, Purdue, 02/03/2021

RoadToShow = 'U41'; % S53 (Broadway), U41, I69, S161, S66

if ~exist('indotMileMarkers','var')
    loadIndotMileMarkers;
end

if ~exist('indotRoads','var')
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
plot(vertcat(highWaySegmentsSelected.Lon), ...
    vertcat(highWaySegmentsSelected.Lat), ...
    'b-', 'LineWidth', 3);

hold off;
plot_google_map('MapType', 'roadmap');

% EOF