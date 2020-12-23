function [utmUnixTimeInS] ...
    = localDatetime2UtmUnixTimeInS(localDatetime, timeZone)
%LOCALDATETIME2UTMUNIXTIMEINS Convert a Matlab datetime variable for a
%local time to Unix time in seconds in UTM.
%
% Inputs:
%   - localDatetime
%     A Matlab datetime representing the local time of interest.
%   - timeZone
%     The time zone in hours (e.g., -7): local time = UTM time + time zone.
%
% Output:
%   - utmUnixTimeInS
%     The UTM Unix time in seconds.
%
% Example:
%   utmUnixTimeInS = localDatetime2UtmUnixTimeInS( ...
%       datetime('1-Jan-1970 00:00:00'), 1);
% This should yield 3600.
%
% Yaguang Zhang, Purdue, 12/17/2020

utmUnixTimeInS = posixtime(localDatetime);
utmUnixTimeInS = utmUnixTimeInS+60*60*timeZone;

end
% EOF