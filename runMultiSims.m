%RUNMULTISIMS A helper to run multiple simulations via simulateSunShadow.w
%with different PRESETs.
%
% This script can also be used to update the figures for completed
% simulations on PCs.
%
% Yaguang Zhang, Purdue, 12/06/2022

clear; clc; close all; dbstop if error;

% Locate the Matlab workspace and save the current filename.
cd(fileparts(mfilename('fullpath'))); addpath('libs');
curFileName = mfilename;

prepareSimulationEnv;

pathToPostProcessingResultsFolder ...
    = fullfile(ABS_PATH_TO_SHARED_FOLDER, ...
    'PostProcessingResults');
if ~exist(pathToPostProcessingResultsFolder, 'dir')
    mkdir(pathToPostProcessingResultsFolder);
end

flagInitiatedByRoadSimManager = 3;

% Shortcuts for predefined simulation groups.
%   - 'IN_MotorSpeedway_Oval_6PcSet'
%     All 6 road segments of the Oval Course (biggest lap) of the
%     Indianapolis Motor Speedway
SIM_GROUP_PRESET = 'IN_MotorSpeedway_Oval_6PcSet';

pathToSaveSimManDiary = fullfile( ...
    pathToPostProcessingResultsFolder, ...
    ['multiSimDiary_', SIM_GROUP_PRESET, '.txt']);
diary(pathToSaveSimManDiary);

switch SIM_GROUP_PRESET
    case 'IN_MotorSpeedway_Oval_6PcSet'
        % Presets of interest.
        PRESETS = {'IN_MotorSpeedway_Oval_6PcSet_NE', ...
            'IN_MotorSpeedway_Oval_6PcSet_E', ...
            'IN_MotorSpeedway_Oval_6PcSet_SE', ...
            'IN_MotorSpeedway_Oval_6PcSet_SW', ...
            'IN_MotorSpeedway_Oval_6PcSet_W', ...
            'IN_MotorSpeedway_Oval_6PcSet_NW'};
    otherwise
        error(['Unknown simulation group: ', SIM_GROUP_PRESET, '!']);
end

for idxPreset = 1:length(PRESETS)
    curPreset = PRESETS{idxPreset};

    disp(' ')
    disp(['[', datestr(now, datetimeFormat), ...
        '] Running sim for ', curPreset, '...'])

    try
        diary off;

        simulateSunShadow;

        diary(pathToSaveSimManDiary);
    catch err
        diary(pathToSaveSimManDiary);
        disp(getReport(err))
        rethrow(err);
    end
    disp(['[', datestr(now, datetimeFormat), ...
        '] Done!'])
end

diary off;

% EOF