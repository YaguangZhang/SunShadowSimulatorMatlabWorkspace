%TESTSUNPOSITIONOVERLOCANDTIME A couple of tests on the sun position with
%fixed location/fixed time, to investigate whether it is possible to avoid
%evaluating sun position for each loc/time pair.
%
% Yaguang Zhang, Purdue, 01/27/2021
clear; clc; close all; dbstop if error;

% Locate the Matlab workspace and save the current filename.
cd(fileparts(mfilename('fullpath'))); cd(fullfile('..', '..'));
addpath('libs');
curFileName = mfilename;

prepareSimulationEnv;

%% Script Parameters

% The absolute path to the folder for saving the results.
folderToSaveResults = fullfile(ABS_PATH_TO_SHARED_FOLDER, ...
    'SunShadowSimulatorResults', 'Test_SunPostionOverLocAndTime');

% The format to use for displaying datetime.
datetimeFormat = 'yyyy/mm/dd HH:MM:ss';

% UTM zone to use.
UTM_ZONE = '16 T';
[deg2utm_speZone, utm2deg_speZone] ...
    = genUtmConvertersForFixedZone(UTM_ZONE);

% The time zone to use for the observer is derived from the UTM zone.
[~, zoneCenterLon] = utm2deg_speZone(500000,0);
tz = -timezone(zoneCenterLon);

% Turn the diary logging function on.
dirToSaveDiary = fullfile(folderToSaveResults, 'diary.txt');
if ~exist(dirToSaveDiary, 'file')
    if ~exist(folderToSaveResults, 'dir')
        mkdir(folderToSaveResults)
    end
    fclose(fopen(dirToSaveDiary, 'w'));
end
diary(dirToSaveDiary);

% The interval to inspect within one day.
timeIntervalInM = 15;

%% Test 1: Fixed Time over Widely Spread Locations
% We will choose some points widely spread over Indiana and compute the sun
% positions for them over one day.
centerLatLon = [39.826246, -86.164845];
% References: Indiana width ~= 435 km; Indiana height ~= 285 km.
sideLengthInKm = 450;
% Number of points to inspect for each dimension. An odd value of this will
% ensure the center is included.
numOfPtsPerSide = 11;
% Local times to inspect.
localTimesToInspect = datetime('1-Feb-2021 00:00:00') ...
    :minutes(timeIntervalInM):datetime('8-Feb-2021 00:00:00');
numOfTimesToInspect = length(localTimesToInspect);

% Locate the points to inspect in the UTM system.
sideLengthInM = sideLengthInKm*1000;
[centerX, centerY] = deg2utm_speZone(centerLatLon(1), centerLatLon(2));
horiPtsXs = linspace(centerX-sideLengthInM/2, ...
    centerX+sideLengthInM/2, numOfPtsPerSide);
horiPtsYs = ones(size(horiPtsXs)).*centerY;

vertPtsYs = linspace(centerY-sideLengthInM/2, ...
    centerY+sideLengthInM/2, numOfPtsPerSide);
vertPtsXs = ones(size(vertPtsYs)).*centerX;

% Find the GPS coordinates for them.
[horiLats, horiLons] = utm2deg_speZone(horiPtsXs, horiPtsYs);
[vertLats, vertLons] = utm2deg_speZone(vertPtsXs, vertPtsYs);

% Plot the locations to inspect.
hLocsToInspect = figure; hold on;
hHoriPts = plot(horiLons, horiLats, 'oc');
hVertPts = plot(vertLons, vertLats, 'xy');
plot_google_map('MapType', 'hybrid');
title({['Locations to Inspect (Side Length = ', ...
    num2str(sideLengthInKm), ' km)'];
    'Indiana width ~= 285 km; Indiana height ~= 435 km'});
legend([hHoriPts, hVertPts], 'Horizontal Locs', 'Vertical Locs');
saveas(hLocsToInspect, ...
    fullfile(folderToSaveResults, 'locsToInspect.fig'));
saveas(hLocsToInspect, ...
    fullfile(folderToSaveResults, 'locsToInspect.jpg'));

% Fetch the elevations for these locations.
%  allEles = getElevations([horiLats; vertLats], [horiLons; vertLons]);
%   horiEles = allEles(1:numOfPtsPerSide); vertEles =
%   allEles((numOfPtsPerSide+1):end);

% Simulate sun for horizontal points. Each row is for one location, while
% each column is for one time.
[horiAzis, horiZens] = deal(nan(numOfPtsPerSide,1));
for idxPt = 1:numOfPtsPerSide
    curLatLon = [horiLats(idxPt), horiLons(idxPt)];
    % Assume the observer is at see level.
    curObserverEle = 0;
    
    for idxTime = 1:numOfTimesToInspect
        curDatetime = localTimesToInspect(idxTime);
        
        curSpaIn = constructSpaStruct(tz, ...
            curDatetime, [curLatLon curObserverEle]);
        % Calculate only zenith and azimuth: SPA_ZA = 0;
        curSpaIn.function = 0;
        [spaErrCode, curSpaOut] = getSolarPosition(curSpaIn);
        assert(spaErrCode==0, ...
            ['There was an error from SPA; error code: ', ...
            num2str(spaErrCode), '!'])
        
        % Save the sun position information.
        horiAzis(idxPt, idxTime) ...
            = curSpaOut.azimuth;
        horiZens(idxPt, idxTime) ...
            = curSpaOut.zenith;
    end
end

% Simulate sun for vertical points. Each row is for one location, while
% each column is for one time.
[vertAzis, vertZens] = deal(nan(numOfPtsPerSide,1));
for idxPt = 1:numOfPtsPerSide
    curLatLon = [vertLats(idxPt), vertLons(idxPt)];
    % Assume the observer is at see level.
    curObserverEle = 0;
    
    for idxTime = 1:numOfTimesToInspect
        curDatetime = localTimesToInspect(idxTime);
        
        curSpaIn = constructSpaStruct(tz, ...
            curDatetime, [curLatLon curObserverEle]);
        % Calculate only zenith and azimuth: SPA_ZA = 0;
        curSpaIn.function = 0;
        [spaErrCode, curSpaOut] = getSolarPosition(curSpaIn);
        assert(spaErrCode==0, ...
            ['There was an error from SPA; error code: ', ...
            num2str(spaErrCode), '!'])
        
        % Save the sun position information.
        vertAzis(idxPt, idxTime) ...
            = curSpaOut.azimuth;
        vertZens(idxPt, idxTime) ...
            = curSpaOut.zenith;
    end
end

% Plot the sun position angles over time. Horizontal.
hSunPosHoriAzis = figure; hold on;
for idxPt = 1:numOfPtsPerSide
    plot(localTimesToInspect, horiAzis(idxPt,:), '.');
end
grid on; grid minor;
ylabel('Azimuth (degree)');
title('Horizontal Points (Along Longitude)')
saveas(hSunPosHoriAzis, ...
    fullfile(folderToSaveResults, 'sunPosHoriAzis.fig'));
saveas(hSunPosHoriAzis, ...
    fullfile(folderToSaveResults, 'sunPosHoriAzis.jpg'));

hSunPosHoriZens = figure; hold on;
for idxPt = 1:numOfPtsPerSide
    plot(localTimesToInspect, horiZens(idxPt,:), '.');
end
grid on; grid minor;
ylabel('Zenith (degree)');
title('Horizontal Points (Along Longitude)')
saveas(hSunPosHoriZens, ...
    fullfile(folderToSaveResults, 'sunPosHoriZens.fig'));
saveas(hSunPosHoriZens, ...
    fullfile(folderToSaveResults, 'sunPosHoriZens.jpg'));

% Vertical.
hSunPosVertAzis = figure; hold on;
for idxPt = 1:numOfPtsPerSide
    plot(localTimesToInspect, vertAzis(idxPt,:), '.');
end
grid on; grid minor;
ylabel('Azimuth (degree)');
title('Vertical Points (Along Latitude)')
saveas(hSunPosVertAzis, ...
    fullfile(folderToSaveResults, 'sunPosVertAzis.fig'));
saveas(hSunPosVertAzis, ...
    fullfile(folderToSaveResults, 'sunPosVertAzis.jpg'));

hSunPosVertZens = figure; hold on;
for idxPt = 1:numOfPtsPerSide
    plot(localTimesToInspect, vertZens(idxPt,:), '.');
end
grid on; grid minor;
ylabel('Zenith (degree)');
title('Vertical Points (Along Latitude)')
saveas(hSunPosVertZens, ...
    fullfile(folderToSaveResults, 'sunPosVertZens.fig'));
saveas(hSunPosVertZens, ...
    fullfile(folderToSaveResults, 'sunPosVertZens.jpg'));

%% Test 2: Fixed Location at Different Days
firstDate = datetime('22-Dec-2020');
lastDate = datetime('22-Mar-2021');
dateInterval = 7; % A week.

datesToInspect = firstDate:days(dateInterval):lastDate;
hoursToInspect = hours(0):minutes(timeIntervalInM):hours(24);
% Remove the first time of the next day.
hoursToInspect = hoursToInspect(1:(end-1));

numOfDays = length(datesToInspect);
numOfHoursPerDay = length(hoursToInspect);

% Simulate sun for the center location over multiple days. Each row is for
% one day, while each column is for one time of that day.
[centerAzis, centerZens] = deal(nan(numOfDays, numOfHoursPerDay));
for idxDate = 1:numOfDays
    for idxHour = 1:numOfHoursPerDay
        curDatetime = datesToInspect(idxDate)+hoursToInspect(idxHour);
        
        curSpaIn = constructSpaStruct(tz, ...
            curDatetime, [centerLatLon curObserverEle]);
        % Calculate only zenith and azimuth: SPA_ZA = 0;
        curSpaIn.function = 0;
        [spaErrCode, curSpaOut] = getSolarPosition(curSpaIn);
        assert(spaErrCode==0, ...
            ['There was an error from SPA; error code: ', ...
            num2str(spaErrCode), '!'])
        
        % Save the sun position information.
        centerAzis(idxDate, idxHour) ...
            = curSpaOut.azimuth;
        centerZens(idxDate, idxHour) ...
            = curSpaOut.zenith;
    end
end

% Plot the sun position angles.
hSunPosCenterAzis = figure; hold on;
for idxDate = 1:numOfDays
    if idxDate ==1
        hFirstDate = plot(hoursToInspect, centerAzis(idxDate,:), '.');
    elseif idxDate == numOfDays
        hLastDate = plot(hoursToInspect, centerAzis(idxDate,:), '.');
    else
        plot(hoursToInspect, centerAzis(idxDate,:), '.');
    end
end
grid on; grid minor;
legend([hFirstDate, hLastDate], datestr(firstDate), datestr(lastDate), ...
    'Location', 'northwest');
xlabel('Time (hour)'); ylabel('Azimuth (degree)');
title({'Center Point over a Long Time'; ...
    ['From ', datestr(firstDate), ' to ', datestr(lastDate), ...
    ' with ', num2str(dateInterval), '-day interval']})
saveas(hSunPosCenterAzis, ...
    fullfile(folderToSaveResults, 'sunPosCentAzis.fig'));
saveas(hSunPosCenterAzis, ...
    fullfile(folderToSaveResults, 'sunPosCentAzis.jpg'));

hSunPosCenterZens = figure; hold on;
for idxDate = 1:numOfDays
    if idxDate ==1
        hFirstDate = plot(hoursToInspect, centerZens(idxDate,:), '.');
    elseif idxDate == numOfDays
        hLastDate = plot(hoursToInspect, centerZens(idxDate,:), '.');
    else
        plot(hoursToInspect, centerZens(idxDate,:), '.');
    end
end
grid on; grid minor;
legend([hFirstDate, hLastDate], datestr(firstDate), datestr(lastDate), ...
    'Location', 'southeast');
xlabel('Time (hour)'); ylabel('Zenith (degree)');
title({'Center Point over a Long Time'; ...
    ['From ', datestr(firstDate), ' to ', datestr(lastDate), ...
    ' with ', num2str(dateInterval), '-day interval']})
saveas(hSunPosCenterZens, ...
    fullfile(folderToSaveResults, 'sunPosCentZens.fig'));
saveas(hSunPosCenterZens, ...
    fullfile(folderToSaveResults, 'sunPosCentZens.jpg'));

%% Cleanup

diary off;

% EOF