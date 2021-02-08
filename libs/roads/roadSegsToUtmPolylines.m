function [roadSegUtmPolylines, mileages] ...
    = roadSegsToUtmPolylines(roadSegs, deg2utm_speZone, ...
    maxDistInMBetweenAdjPts, roadSegMileages)
%ROADSEGSTOPOLYLINES Convert road segments to polylines.
%
% Inputs:
%   - roadSegs
%     A struct array for the road segments (from the 2019 Indiana
%     Centerline data set).
%   - deg2utm_speZone
%     The conversion function to use from GPS to UTM.
%   - maxDistInMBetweenAdjPts
%     Optional. A positive number. If provided, we will interpolate the
%     output polylines so that the distance in meters between adjacent
%     points is at most this value.
%   - roadSegMileages
%     Optional. A cell with each element containing the mileage values, as
%     a column vector, for the points in the corresponding roadSeg. If
%     provideded with maxDistInMBetweenAdjPts, we will interpolate the
%     mileage values, too.
%
% Outputs:
%   - roadSegUtmPolylines
%     A cell of polylines. Each polyline is a N x 2 matrix, where N is the
%     number of vertices. Multiple line segments in the save polyline can
%     be separated by a [nan nan] row.
%   - mileages
%     When both maxDistInMBetweenAdjPts and roadSegMileages are specified,
%     this will be a cell of column vectors, containing the mileage values
%     for points in roadSegUtmPolylines.
%
% Yaguang Zhang, Purdue, 02/03/2021

numOfRoadSegs = length(roadSegs);

% Preallocate memory.
[roadSegUtmPolylines, mileages] = deal(cell(numOfRoadSegs, 1));

for idxRoadSeg = 1:numOfRoadSegs
    curRoadSeg = roadSegs(idxRoadSeg);
    if ~isempty(curRoadSeg.Lat)
        [curXs, curYs] = deg2utm_speZone(curRoadSeg.Lat, curRoadSeg.Lon);
        if isrow(curXs)
            curXs = curXs';
            curYs = curYs';
        end
        if exist('maxDistInMBetweenAdjPts', 'var')
            indicesForNanPts = find(isnan(curXs)|isnan(curYs));
            assert(length(indicesForNanPts)==1 ...
                && indicesForNanPts(1) == length(curXs), ...
                ['One and only one trailing [nan, nan] row ', ...
                'is expected for each road segement!'])
            % Interpolate the polylines.
            N = ceil(curRoadSeg.Shape_Leng/maxDistInMBetweenAdjPts);
            if exist('roadSegMileages', 'var')
                curXYMs = interppolygon( ...
                    [curXs(1:(end-1)), curYs(1:(end-1)), ...
                    roadSegMileages{idxRoadSeg}(1:(end-1))], ...
                    N, 'linear');
                curXs = curXYMs(:,1);
                curYs = curXYMs(:,2);
                mileages{idxRoadSeg} = curXYMs(:,3);
            else
                curXYs = interppolygon( ...
                    [curXs(1:(end-1)), curYs(1:(end-1))], N, 'linear');
                curXs = curXYs(:,1);
                curYs = curXYs(:,2);
            end
        end
        roadSegUtmPolylines{idxRoadSeg} = [curXs, curYs];
    end
end

end
% EOF