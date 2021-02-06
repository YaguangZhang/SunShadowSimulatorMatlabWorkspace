% TESTGPSCOOR2MILEMARKER
%
% Yaguang Zhang, Purdue, 02/03/2021

loadIndotRoads;
loadIndotMileMarkers;

%% Test the time to run the code below.
tic
[roadName, mile1] = ...
    gpsCoor2MileMarker(39.776301, -87.236079);
toc

%% Compare it with the other version
tic
mile2 = ...
    gpsCoorWithRoadName2MileMarker(39.776301, -87.236079, roadName);
toc

disp(['mile1 = ', num2str(mile1)])
disp(['mile2 = ', num2str(mile2)])
disp(['Difference = ', num2str(mile1-mile2)])

% EOF