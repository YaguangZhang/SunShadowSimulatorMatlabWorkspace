function [localDatetime] ...
    = utcUnixTimeInS2LocalDatetime(utcUnixTimeInS, timeZone)
%UTCUNIXTIMEINS2LOCALDATETIME Convert the Unix time in UTC to a local time
%represented by a Matlab datetime variable.
%
% Inputs:
%   - utcUnixTimeInS
%     The UTC Unix time in seconds.
%   - timeZone
%     The time zone in hours (e.g., -7): local time = UTC time + time zone.
%
% Output:
%   - localDatetime
%     A Matlab datetime representing the local time of interest.
%
% Example:
%   localDatetime = utcUnixTimeInS2LocalDatetime(3600, 1);
% This should yield a datetime variable representing 01-Jan-1970 00:00:00.
%
% Yaguang Zhang, Purdue, 12/17/2020

localDatetime = datetime(utcUnixTimeInS+60*60*timeZone, ...
    'ConvertFrom', 'epochtime', 'TicksPerSecond', 1, ...
    'Format','dd-MMM-yyyy HH:mm:ss');

end
% EOF