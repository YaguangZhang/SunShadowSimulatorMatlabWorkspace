function spaStruct = constructSpaStruct(timeZone, dt, latLonEle)
%CONSTRUCTSPASTRUCT Construct the input struct for the solar position
%algorithm.
%
% Inputs:
%   - timeZone
%     The time zone (e.g., -7), such that:
%       local time (hour) = UTC time (hour) + timeZone
%   - dt
%     A datetime variable for the year, month, date, hour, minute, and
%     second to use.
%   - latLonEle
%     The GPS [lat, lon, elevation (m)] for the location of interest.
%
% Please refer to getSolarPostion.m for more details.
%
% Yaguang Zhang, Purdue, 12/19/2020

% Observer local time.
spaStruct.year          = year(dt);
spaStruct.month         = month(dt);
spaStruct.day           = day(dt);
spaStruct.hour          = hour(dt);
spaStruct.minute        = minute(dt);
spaStruct.second        = second(dt);
spaStruct.timezone      = timeZone;
% Observer location.
spaStruct.latitude      = latLonEle(1);
spaStruct.longitude     = latLonEle(2);
spaStruct.elevation     = latLonEle(3);

end
% EOF