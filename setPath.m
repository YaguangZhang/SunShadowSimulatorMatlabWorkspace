% SETPATH Add libraries for the simulation.
%
% Yaguang Zhang, Purdue, 11/24/2020

cd(fileparts(mfilename('fullpath')));
addpath(fullfile(pwd));
addpath(genpath(fullfile(pwd, 'libs')));

% A workaround for making Matlab R2019b work. If
% preprocessIndianaLidarDataSet.m is in the path, it has trouble using
% loaded functions as they are, even though R2019a works anyway.
rmpath(fullfile(pwd, 'libs', 'lidar'));

% The absolute path to the shared/synched folder holding the data and code.
% Please make sure it is correct for the machine to run this script.
%  - On (quite powerful) Windows Artsy:
absHomePathWinArtsy = ['D:\One Drive - Purdue\OneDrive - purdue.edu', ...
    '\INDOT\20201124_ShadowOnRoad\'];
%  - Local copy on the computer cluster at Purdue:
absHomePathLinuxCoverage = ['/home/coverage', ...
    '/INDOT_ShadowOnRoad'];
%  - Local copy on the computer cluster at Purdue:
absHomePathLinuxCoverageOnFrankie = ['/home/coverage/nvme/', ...
    '/INDOT_ShadowOnRoad'];

% Path to LiDAR data.
absPathLidarWinArtsy = ['D:\One Drive - Purdue\OneDrive - purdue.edu', ...
    '\OATS\CellCoverageMapper'];
absPathLidarLinuxCoverage = ['/home/coverage', ...
    '/CellCoverageMapper'];
absPathLidarLinuxCoverageOnFrankie = ['/home/coverage/nvme/', ...
    '/CellCoverageMapper'];

% Path to Indiana road data sets.
absPathRoadsWinArtsy = ['D:\One Drive - Purdue\OneDrive - purdue.edu', ...
    '\INDOT\Roads'];
absPathRoadsLinuxCoverage = ['/home/coverage', ...
    '/Roads'];
absPathRoadsLinuxCoverageOnFrankie = ['/home/coverage/nvme/', ...
    '/Roads'];

% The absolute path to Python 3. Please make sure it is correct for the
% machine to run this script.
%  - On (quite powerful) Windows Artsy:
absPythonPathWinArtsy ...
    = ['C:\Users\Yaguang Zhang\AppData\Local\Programs', ...
    '\Python\Python37\python.exe'];
%  - Local copy on the computer cluster at Purdue:
absPythonPathLinuxCoverage = '/usr/bin/python3.7';
%  - Local copy on the computer cluster at Purdue:
absPythonPathLinuxCoverageOnFrankie = '/usr/bin/python3.7';

unknownComputerErrorMsg = ...
    ['Compute not recognized... \n', ...
    '    Please update setPath.m for your machine. '];
unknownComputerErrorId = 'setPath:computerNotKnown';

[~, curHostname] = system('hostname');
switch strtrim(curHostname)
    case 'Artsy'
        % ZYG's lab desktop.
        ABS_PATH_TO_SHARED_FOLDER = absHomePathWinArtsy;
        ABS_PATH_TO_LIDAR = absPathLidarWinArtsy;
        ABS_PATH_TO_ROADS = absPathRoadsWinArtsy;
        ABS_PATH_TO_PYTHON = absPythonPathWinArtsy;
    case 'coverage-compute-big'
        % The computer cluster at Purdue.
        ABS_PATH_TO_SHARED_FOLDER = absHomePathLinuxCoverage;
        ABS_PATH_TO_LIDAR = absPathLidarLinuxCoverage;
        ABS_PATH_TO_ROADS = absPathRoadsLinuxCoverage;
        ABS_PATH_TO_PYTHON = absPythonPathLinuxCoverage;
    case 'ygzhang'
        % The virtual machine coverage on Purdue GPU cluster Frankie.
        ABS_PATH_TO_SHARED_FOLDER = absHomePathLinuxCoverageOnFrankie;
        ABS_PATH_TO_LIDAR = absPathLidarLinuxCoverageOnFrankie;
        ABS_PATH_TO_ROADS = absPathRoadsLinuxCoverageOnFrankie;
        ABS_PATH_TO_PYTHON = absPythonPathLinuxCoverageOnFrankie;
    otherwise
        error(unknownComputerErrorId, unknownComputerErrorMsg);
end

% We need Python for concurrent HTTP requests to get elevation data from
% USGS faster. Make sure Python and its lib folder is added to path.

% Make sure Python is available.
curPythonVersion = pyversion;
if isempty(curPythonVersion) || (~strcmp(curPythonVersion(1:3), '3.7'))
    pyversion(ABS_PATH_TO_PYTHON);
end
% Check the version again.
curPythonVersion = pyversion;
if ~strcmp(curPythonVersion(1:3), '3.7')
    error(['Loaded Python is not version 3.7.', ...
        ' Please restart Matlab and try again!']);
end
% Make sure our Python module is available.
try
    py_addpath(fullfile(pwd, 'libs', 'python'));
catch err
    warning(['Error identifier: ', err.identifier]);
    warning(['Error message: ',err.message]);
    errorMsg = 'Unable to set Python path! ';
    if isunix
        errorMsg = [errorMsg, ...
            'Please make sure both python3.7 and ', ...
            'python3.7-dev are installed!'];
    end
    error(errorMsg);
end
% EOF