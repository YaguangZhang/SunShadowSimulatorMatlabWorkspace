% TESTGPSCOORWITHROADNAME2MILEMARKER
%
% Yaguang Zhang, Purdue, 02/03/2021

close all; clc;

% Changed folder to the root Matlab script foler first.
cd(fullfile(fileparts(which(mfilename)), '..', '..', '..'));
% Set path.
setPath;

% We will test the point (38.0032011,-87.4670625,'I164') => 9.839 (and some
% more points).
lati = [38.0032011, 38.0061252, 38.0101697, ...
    41.2657366, 41.2686889, 41.272901, -1];
long = [-87.4670625, -87.4676415, -87.4687818, ...
    -85.8524668, -85.8525377, -85.8528402, -1];
% The last test location should have no valid output.
roadName = {'I69', 'I69', 'I69', 'S15', 'S15', 'S15', 'S7272'};
correctMile = [9.839, 10.039, 10.32, ...
    59.003, 59.203, 59.491, -1];

% Load the mile marker and highway databases of INDOT.
if ~exist('indotMileMarkers', 'var')
    loadIndotMileMarkers;
end

% Generate the mile markers for the potholes automatically.

% Test speed using the first sample.
disp('Time for computing one sample without INDOT_MILE_MARKERS_ROADNAME_LABELS:');
tic;
[mile1, INDOT_MILE_MARKERS_ROADNAME_LABELS] = ...
    gpsCoorWithRoadName2MileMarker(...
    lati(1), long(1), roadName{1},...
    indotMileMarkers, UTM_STRUCT);
toc;

disp(' ');
disp('Time for computing one sample with INDOT_MILE_MARKERS_ROADNAME_LABELS:');
disp('    (The speed should be much faster.)')
tic;
mile2 = gpsCoorWithRoadName2MileMarker(...
    lati(1), long(1), roadName{1}, ...
    indotMileMarkers, UTM_STRUCT, ...
    INDOT_MILE_MARKERS_ROADNAME_LABELS);
toc;

disp(' ');
disp('Time for computing (and plotting for) all samples with INDOT_MILE_MARKERS_ROADNAME_LABELS:');
tic;
% Compute mile markers for all samples with debug function on.
numSampels = length(lati);
mileSamples = nan(numSampels,1);
for idx = 1:numSampels
    mileSamples(idx) = gpsCoorWithRoadName2MileMarker(...
        lati(idx), long(idx), roadName{idx}, ...
        indotMileMarkers, UTM_STRUCT, ...
        INDOT_MILE_MARKERS_ROADNAME_LABELS, true, correctMile(idx));
end
toc

% EOF