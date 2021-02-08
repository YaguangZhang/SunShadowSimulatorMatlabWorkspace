function [roadSegUtmPolyshapeNewVCoorsSplitted] ...
    = addBreakPointsWithNan(roadSegUtmPolyshapeNewVCoors)
%ADDBREAKPOINTSWITHNAN A helper function to add break points and NaN values
%to the input roadSegUtmPolyshapeNewVCoors matrix.
%
% Yaguang Zhang, Purdue, 02/07/2021

roadSegUtmPolyshapeNewVCoorsSplitted ...
    = inf(7, size(roadSegUtmPolyshapeNewVCoors, 2)); 
roadSegUtmPolyshapeNewVCoorsSplitted(1, :) ...
    = roadSegUtmPolyshapeNewVCoors(1, :); 
roadSegUtmPolyshapeNewVCoorsSplitted([2,4], :) ...
    = repmat(roadSegUtmPolyshapeNewVCoors(2, :), 2, 1); 
roadSegUtmPolyshapeNewVCoorsSplitted([5,7], :) ...
    = repmat(roadSegUtmPolyshapeNewVCoors(3, :), 2, 1);

end
% EOF