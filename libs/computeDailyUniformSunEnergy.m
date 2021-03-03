function [dailyUniformSunEnergy, dates] = computeDailyUniformSunEnergy( ...
    uniformSunPower, times)
%COMPUTEDAILYUNIFORMSUNENERGY Compute the daily uniform sun energy by
%trapezoidal numerical integration on the input sun power values.
%
% Inputs:
%   - uniformSunPower
%     A matrix for the uniform sun power values in [0,1]. Each row
%     cooresponds to a location of interest, while each column cooresponds
%     to an inspected time.
%   - times
%     A datetime array for the inspected times (cooresponding to the
%     columns of uniformSunPower). Note: the inspected times for each day
%     of interest should cover all the day time (the time after sunrise and
%     before sunset) to ensure an accurate output.
%
% Outputs:
%   - dailyUniformSunEnergy
%     A matrix for the uniform sun energy values in [0,1], where
%       - 0 means all relevant sun power values during the day of
%         interest are 0 or nan, and
%       - 1 means all relevant sun power values during the day of
%         interest are 1.
%     Each row cooresponds to a location of interest, while each column
%     cooresponds to an inspected day.
%   - dates
%     A datetime array for the inspected dates (cooresponding to the
%     columns of dailyUniformSunEnergy).
%
% Yaguang Zhang, Purdue, 03/03/2021

% Treat power value nan as 0.
uniformSunPower(isnan(uniformSunPower)) = 0;
numOfLocs = size(uniformSunPower, 1);

dates = unique(dateshift(times, 'start', 'day'));
numOfDs = length(dates);

dailyUniformSunEnergy = nan(numOfLocs, numOfDs);
for idxD = 1:numOfDs
    curDate = dates(idxD);
    curDateEndTime = dateshift(curDate, 'end', 'day');
    
    curBoolsTimeToday = times>=curDate & times<=curDateEndTime;
    curUnifDayTime = days(times(curBoolsTimeToday) - curDate);
    dailyUniformSunEnergy(:, idxD) = trapz( ...
        curUnifDayTime, uniformSunPower(:, curBoolsTimeToday), 2);
end

end
% EOF