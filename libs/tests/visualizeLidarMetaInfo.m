%VISUALIZELIDARMETAINFO Generate overview figs for the metaInfo.mat file of
%a LiDAR data set.
%
% Yaguang Zhang, Purdue, 02/22/2021

% Please first set the path to the mtaInfo.mat file for this script to work
% properly. For example:
%    pathToMetaInfo = 'D:\One Drive - Purdue\OneDrive - purdue.edu\OATS\CellCoverageMapper\Lidar_2019\IN\DSM\metaInfo.mat'
assert(exist('pathToMetaInfo', 'var'), 'Please set pathToMetaInfo!')

dirToSaveResults = fileparts(pathToMetaInfo);
curDateStr = datestr(datetime('now'), 'yyyymmdd');

load(pathToMetaInfo);
allVertexXYs = cellfun(@(p) p.Vertices, xYBoundryPolygons, ...
    'UniformOutput', false);
allVertexXYs = vertcat(allVertexXYs{:});

hFigLidarCoverage = figure('units','normalized','outerposition',[0 0 1 1]);
plot(allVertexXYs(:,1), allVertexXYs(:,2), 'b.');
axis equal;

curPathToSaveFig = fullfile(dirToSaveResults, ...
    ['currentLidarCoverage_', curDateStr]);
saveas(hFigLidarCoverage, [curPathToSaveFig, '.fig']);
saveas(hFigLidarCoverage, [curPathToSaveFig, '.jpg']);

close all;
% EOF