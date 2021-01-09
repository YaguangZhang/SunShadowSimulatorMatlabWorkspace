function [hFigShadowLoc, hsShadowMap, ...
    hPolyClear, hPolyBlocked] ...
    = plotSunShadowMap(matLonLatSunPowers, simConfigs, sunAziZens, ...
    hFigShadowLoc, flagVisible, flagZoomIn, customFigSize)
%PLOTSUNSHADOWMAP Plot the sun shadow on a map.
%
% Generate a figure on Google map to show the blockage areas. We will use
% triangulation-based nearest neighbor interpolation for the (lon, lat)
% grid to get the blockage values.
%
% Inputs:
%   - matLonLatSunPowers
%     A matrix with each row being the (lon, lat, sun power) for one pixel
%     of the sun shadow map to be shown. The blocked areas should have a
%     sun power value of NaN or 0.
%   - simConfigs
%     The configuration struct for the simulation. We need fields:
%     UTM_X_Y_BOUNDARY_OF_INTEREST, utm2deg_speZone, and
%     numOfPixelsForLongerSide.
%   - sunAziZens
%     A two-column matrix [sunAzis, sunZens] for sun azimuth and zenith
%     angles in degree for each map grid point.
%   - flagVisible
%     An optional boolean to control whether to show the plot or not.
%   - flagZoomIn
%     An optional boolean to control whether to zoom in to fit the area of
%     the input path loss map or not.
%   - customFigSize
%     An optional boolean to specify the desired figure size. The resultant
%     figure will start with this size and be adjusted according to the
%     figure content.
%
% Outputs:
%   - hFigShadowLoc
%     The handle to the resultant figure.
%   - hsShadowMap
%     A cell array of handles {hShadowMapPoly, hSunDirLines, (TODO)
%     hLidarZ} to the black and white shadow illustration surf plot, a line
%     illustrating the direction of the sun for each grid point, and (TODO)
%     a color plot3k illustration for the LiDAR z values.
%   - hPolyClear, hPolyBlocked
%     The handles to empty polygons in the figure representing the styles
%     of the clear regions and the blocked regions, respectively. Note that
%     they are just for the legends.
%
% Yaguang Zhang, Purdue, 01/03/2021

% (TODO) Set this to be true to also show LiDAR z on the plot.
%FLAG_SHOW_LIDAR_Z = true;

legendBackgroundColor = ones(1,3).*0.9;

% We will use the first color for clearance and the last color for
% blockage. Note that we will reverse the gray color map in the plot so
% that black means shadow while white means in the sun.
COLORMAP_TO_USE = 'gray';
ALPHA = 0.5;

% The location of the legend.
LEGEND_LOC = 'NorthEast';

% By default, show the plot.
if ~exist('flagVisible', 'var')
    flagVisible = true;
end

% By default, do not zoom in to the path loss map, so that all TXs will be
% shown.
if ~exist('flagZoomIn', 'var')
    flagZoomIn = false;
end

colorRange = [0,1];

flagFigAvailable = false;
if exist('hFigShadowLoc', 'var')
    figure(hFigShadowLoc);
    flagFigAvailable = true;
else
    if exist('customFigSize', 'var')
        hFigShadowLoc = figure('Visible', flagVisible, ...
            'Position', [0,0,customFigSize], ...
            'MenuBar', 'none', 'ToolBar', 'none');
    else
        % By default, start with a full-screen figure.
        hFigShadowLoc = figure('Visible', flagVisible, ...
            'MenuBar', 'none', 'ToolBar', 'none', ...
            'Units', 'normalized', 'OuterPosition',[0 0 1 1]);
    end
    
    hFigShadowLoc.InvertHardcopy = 'off';
    hFigShadowLoc.Color = 'none';
end
hold on;

% Fetch the color map after a figure is available.
curColormap = colormap(COLORMAP_TO_USE);
switch COLORMAP_TO_USE
    case 'gray'
        curColormap = curColormap(end:-1:1, :);
end

% Area of interest.
[areaOfInterestLats, areaOfInterestLons] = simConfigs.utm2deg_speZone( ...
    simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,1), ...
    simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,2));
if ~flagFigAvailable
    plot(polyshape(areaOfInterestLons, areaOfInterestLats), ...
        'FaceColor', 'white', 'LineWidth', 1);
    
    % Plot simulation results.
    xLabelToSet = 'Longitude';
    yLabelToSet = 'Latitude';
    
    set(gca, 'fontWeight', 'bold');
end

if flagZoomIn
    extensionFactor = 0.05;
else
    extensionFactor = 0.2;
end
[axisLonLatToSet, weightForWidth] ...
    = extendLonLatAxisByFactor( ...
    [min(areaOfInterestLons), max(areaOfInterestLons), ...
    min(areaOfInterestLats), max(areaOfInterestLats)], ...
    extensionFactor, simConfigs);

% Create meshgrid for surf. We will increase the grid density by a factor
% of 10 to better show the blockage areas.
upSampFactor = 10;
sufNumPtsPerSide = simConfigs.numOfPixelsForLongerSide.*upSampFactor;
lons = matLonLatSunPowers(:, 1);
lats = matLonLatSunPowers(:, 2);
zs = matLonLatSunPowers(:, 3);

% Set blockage area to 1 and other areas to 0.
boolsBlocked = (isnan(zs)) | (zs==0);
zs(boolsBlocked) = 1;
zs(~boolsBlocked) = 0;

% Find the ranges for the boundary of interet (BoI) to build a new grid for
% showing the results.
[latsBoI, lonsBoI] = simConfigs.utm2deg_speZone( ...
    simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,1), ...
    simConfigs.UTM_X_Y_BOUNDARY_OF_INTEREST(:,2));
lonMinBoI = min(lonsBoI);
lonMaxBoI = max(lonsBoI);
latMinBoI = min(latsBoI);
latMaxBoI = max(latsBoI);

[lonsNew, latsNew] = meshgrid( ...
    linspace(lonMinBoI, lonMaxBoI, sufNumPtsPerSide), ...
    linspace(latMinBoI, latMaxBoI, sufNumPtsPerSide));
zsNew = griddata(lons,lats,zs,lonsNew,latsNew,'Nearest');

% Ignore points out of the area of interest by seting the z values for them
% to NaN.
[in,on] = inpolygon(lonsNew(:), latsNew(:), lonsBoI, latsBoI);
boolsPtsToIgnore = ~(in|on);
if any(boolsPtsToIgnore)
    zsNew(boolsPtsToIgnore) = nan;
end

% Plot the blockage areas.
hShadowMapPoly = surf(lonsNew, latsNew, zsNew, ...
    'FaceAlpha', ALPHA, 'EdgeColor', 'none');
colormap(curColormap);

if ~flagFigAvailable
    hPolyClear = plot(polyshape(nan(3,2)), ...
        'FaceColor', curColormap(1, :));
    hPolyBlocked = plot(polyshape(nan(3,2)), ...
        'FaceColor', curColormap(end, :));
    hGridPts = plot(simConfigs.gridLatLonPts(:,2), ...
        simConfigs.gridLatLonPts(:,1), '.k', 'MarkerSize', 3);
    hSunDirLines = plot(nan, nan, '-', 'Color', [1,0,0,ALPHA]);
    
    caxis(colorRange);
    xticks([]); yticks([]);
    xlabel(xLabelToSet); ylabel(yLabelToSet);
    
    hLeg = legend([hGridPts, hSunDirLines, hPolyClear, hPolyBlocked], ...
        'Grid Points', 'Sun Directions', 'Clear', 'Blocked', ...
        'Location', LEGEND_LOC, 'AutoUpdate','off');
    view(2);
    set(hLeg, 'color', legendBackgroundColor);
    set(hFigShadowLoc, 'Color', 'w');
    
    adjustFigSizeByContent(hFigShadowLoc, ...
        axisLonLatToSet, 'height', weightForWidth*0.9);
    
    plot_google_map('MapType', 'satellite');
end

% Plot the sun directions.
axis manual; % Lock the axis limits.
% Use the grid points as the start points.
sunDirLineStartLons = simConfigs.gridLatLonPts(:,2)';
sunDirLineStartLats = simConfigs.gridLatLonPts(:,1)';
sunDirLineStartXs = simConfigs.gridXYPts(:,1)';
sunDirLineStartYs = simConfigs.gridXYPts(:,2)';
% Use the grid resolution length as the length of the line markers.
sunDirLineLenInM = simConfigs.GRID_RESOLUTION_IN_M;
% Compute the end points.
[xs, ys] = aer2enu(sunAziZens(:,1), 90-sunAziZens(:,2), ...
    ones(size(sunAziZens,1),1).*sunDirLineLenInM, 'degrees');
sunDirLineEndXs = sunDirLineStartXs + xs';
sunDirLineEndYs = sunDirLineStartYs + ys';
[sunDirLineEndLats, sunDirLineEndLons] ...
    = simConfigs.utm2deg_speZone(sunDirLineEndXs, sunDirLineEndYs);
hSunDirLines = plot([sunDirLineStartLons; sunDirLineEndLons], ...
    [sunDirLineStartLats; sunDirLineEndLats], '-', 'Color', [1,0,0,ALPHA]);

hsShadowMap = {hShadowMapPoly, hSunDirLines};
end
% EOF