%TESTSHADOWRATIOOVERLOCANDTIME A few tests on the shadow ratio over a long
%time for polygons under different scenarios.
%
% Yaguang Zhang, Purdue, 02/15/2021
clear; clc; close all; dbstop if error;

% Locate the Matlab workspace and save the current filename.
cd(fileparts(mfilename('fullpath'))); cd(fullfile('..', '..'));
addpath('libs');
curFileName = mfilename;

prepareSimulationEnv;

%% Script Parameters

% The folder containing the simulation results.
folderForSimResults = fullfile(ABS_PATH_TO_SHARED_FOLDER, ...
    'SunShadowSimulatorResults');

% The absolute path to the folder for saving the results.
folderToSaveResults = fullfile(folderForSimResults, ...
    'Test_ShadowRatioOverLocAndTime');

% Folders to load and plot simulation results of the shadow ratio in a
% polygon.
foldersToPlotShadowRatio = {fullfile(folderForSimResults, ...
    'Simulation_US41_InShadowSeg_DecToMar_LiDAR_IN_DSM_2019'); ...
    fullfile(folderForSimResults, ...
    'Simulation_US41_InShadowSeg_North_DecToMar_LiDAR_IN_DSM_2019'); ...
    fullfile(folderForSimResults, ...
    'Simulation_US41_InShadowSeg_South_DecToMar_LiDAR_IN_DSM_2019'); ...
    fullfile(folderForSimResults, ...
    'Simulation_US41_InShadowSeg_Hori_DecToMar_LiDAR_IN_DSM_2019'); ...
    fullfile(folderForSimResults, ...
    'Simulation_US41_HalfShadowSeg_DecToMar_LiDAR_IN_DSM_2019'); ...
    fullfile(folderForSimResults, ...
    'Simulation_US41_UnderSunSeg_DecToMar_LiDAR_IN_DSM_2019')};

% Turn the diary logging function on.
dirToSaveDiary = fullfile(folderToSaveResults, 'diary.txt');
if ~exist(dirToSaveDiary, 'file')
    if ~exist(folderToSaveResults, 'dir')
        mkdir(folderToSaveResults)
    end
    fclose(fopen(dirToSaveDiary, 'w'));
end
diary(dirToSaveDiary);

%% Plot the Change of Shadow Ratio over Different Dates

numOfSims = length(foldersToPlotShadowRatio);
for idxSim = 1:numOfSims
    % Load simulation results.
    curFolderToPlotShadowRatio = foldersToPlotShadowRatio{idxSim};
    load(fullfile(curFolderToPlotShadowRatio, 'simState.mat'));
    
    curSimLabel = simConfigs.CURRENT_SIMULATION_TAG;
    curLocalDatetimesInspected = simConfigs.localDatetimesToInspect;
    curUnifSunPower = simState.uniformSunPower;
    numOfGridPts = size(curUnifSunPower, 1);
    
    % Organize the times inspected into different dates.
    datenumsInspected = datenum(curLocalDatetimesInspected);
    uniqeDates = unique(floor(datenumsInspected));
    
    numOfDates = length(uniqeDates);
    [datesToPlotCell, hoursToPlotCell, shadowRatiosToPlotCell] ...
        = deal(cell(numOfDates, 1));
    for idxDate = 1:numOfDates
        curDateDatenum = uniqeDates(idxDate);
        curDateDatetime = datetime(curDateDatenum, ...
            'ConvertFrom','datenum');
        
        boolsInThisDay = ...
            (curLocalDatetimesInspected >= curDateDatetime) ...
            & (curLocalDatetimesInspected < curDateDatetime+days(1));
        numOfTimesThisDay = sum(boolsInThisDay);
        datetimesThisDay = curLocalDatetimesInspected(boolsInThisDay);
        
        [hoursToPlot, shadowRatiosToPlot] ...
            = deal(nan(numOfTimesThisDay, 1));
        for idxTime = 1:numOfTimesThisDay
            curTime = datetimesThisDay(idxTime);
            
            hoursToPlot(idxTime) = datenum(curTime - curDateDatetime)*24;
            unifSunPowersThisTime = ...
                curUnifSunPower(:, curLocalDatetimesInspected==curTime);
            curNumOfGridPts = length(unifSunPowersThisTime(:));
            assert(curNumOfGridPts==numOfGridPts, ...
                ['Expecting ', num2str(numOfGridPts), ...
                ' grid points (instead of ', ...
                num2str(curNumOfGridPts), ' in unifSunPowersThisTime)!']);
            shadowRatiosToPlot(idxTime) = sum(unifSunPowersThisTime==0) ...
                /length(unifSunPowersThisTime);
        end
        
        datesToPlotCell{idxDate} = curDateDatetime;
        hoursToPlotCell{idxDate} = hoursToPlot;
        shadowRatiosToPlotCell{idxDate} = shadowRatiosToPlot;
    end
    
    % Plot
    datetimeDateFormat = 'dd-mmm-yyyy';
    datetimeHourFormat = 'HH:MM';
    
    hFigShawdow = figure; hold on; legend('Location', 'SouthEast');
    for idxDate = 1:numOfDates
        plot(hoursToPlotCell{idxDate}, shadowRatiosToPlotCell{idxDate}, ...
            'DisplayName', ...
            datestr(datesToPlotCell{idxDate}, datetimeDateFormat));
    end
    grid on; grid minor;
    title(strrep(curSimLabel, '_', ' '));
    xticklabels(arrayfun(@(h) datestr(datetime(h/24, ...
        'ConvertFrom','datenum'), datetimeHourFormat), xticks, ...
        'UniformOutput', false));
    xlabel('Local Time'); ylabel('Shadow Ratio');
    
    curDirToSaveFig = fullfile(folderToSaveResults, ...
        ['shadowRatio_', curSimLabel]);
    saveas(hFigShawdow, [curDirToSaveFig, '.fig']);
    saveas(hFigShawdow, [curDirToSaveFig, '.jpg']);
    
    % Save a copy with legend off.
    legend off;
    saveas(hFigShawdow, [curDirToSaveFig, '_legendOff.fig']);
    saveas(hFigShawdow, [curDirToSaveFig, '_legendOff.jpg']);
end

%% Cleanup

diary off;

% EOF
