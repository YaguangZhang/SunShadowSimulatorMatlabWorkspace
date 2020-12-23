function [localDatetime] ...
    = utmUnixTimeInS2LocalDatetime(utmUnixTimeInS, timeZone)
%UTMUNIXTIMEINS2LOCALDATETIME Convert the Unix time in UTM to a local time
%represented by a Matlab datetime variable.
%
% Inputs:
%   - utmUnixTimeInS
%     The UTM Unix time in seconds.
%   - timeZone
%     The time zone in hours (e.g., -7): local time = UTM time + time zone.
%
% Output:
%   - localDatetime
%     A Matlab datetime representing the local time of interest.
%
% Example:
%   localDatetime = utmUnixTimeInS2LocalDatetime(3600, 1);
% This should yield a datetime variable representing 01-Jan-1970 00:00:00.
%
% Yaguang Zhang, Purdue, 12/17/2020

localDatetime = datetime(utmUnixTimeInS-60*60*timeZone, ...
    'ConvertFrom', 'epochtime', 'TicksPerSecond', 1, ...
    'Format','dd-MMM-yyyy HH:mm:ss');

end
% EOF