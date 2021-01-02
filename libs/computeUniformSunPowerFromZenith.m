function [sunPowers] = computeUniformSunPowerFromZenith(sunZens)
%COMPUTEUNIFORMSUNPOWERFROMZENITH Compute the uniform sun power from the
%sun zenith.
%
% Input:
%   - sunZens
%     The zenith angle(s) for the sun in degree.
%
% Output:
%   - sunPowers
%     The uniform sun power(s). It is a ratio in [0,1], corresponding to
%     zenith angles from 90 degrees to 0 degree. Values in between are
%     computed based on the area of a square sun beam on the ground.
%
% Yaguang Zhang, Purdue, 12/24/2020

sunPowers = cosd(sunZens);
sunPowers(sunPowers<0) = 0;

end
% EOF