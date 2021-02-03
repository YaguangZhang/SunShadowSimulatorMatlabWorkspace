function [Xmin, XMas, Ymin, YMas] = constructSquareLimits( ...
    X, Y, nearbySquSideLength)
%CONSTRUCTSQUARELIMITS Computes the limits for a square according to it's
%center and side length.
%
% Inputs:
%
% - X, Y
%
%   Coordinates for the center.
%
% - nearbySquSideLength
%
%   Side length.
%
% Outputs:
%
% - Xmin, XMas, Ymin, YMas
%
%   The min and max values for the square boundaries.
%
% Yaguang Zhang, Purdue, 06/10/2015

lengthDiff = nearbySquSideLength/2;
Xmin = X - lengthDiff;
XMas = X + lengthDiff;
Ymin = Y - lengthDiff;
YMas = Y + lengthDiff;

end
% EOF