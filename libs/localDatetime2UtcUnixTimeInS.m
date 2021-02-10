function [utcUnixTimeInS] ...
    = localDatetime2UtcUnixTimeInS(localDatetime, timeZone)
%LOCALDATETIME2UTCUNIXTIMEINS Convert a Matlab datetime variable for a
%local time to Unix time in seconds in UTC.
%
% Inputs:
%   - localDatetime
%     A Matlab datetime representing the local time of interest.
%   - timeZone
%     The time zone in hours (e.g., -7): local time = UTC time + time zone.
%
% Output:
%   - utcUnixTimeInS
%     The UTC Unix time in seconds.
%
% Example:
%   utcUnixTimeInS = localDatetime2UtcUnixTimeInS( ...
%       datetime('1-Jan-1970 00:00:00'), 1);
% This should yield -3600.
%
% Yaguang Zhang, Purdue, 12/17/2020

localUnixTimeInS = posixtime(localDatetime);
utcUnixTimeInS = localUnixTimeInS-60*60*timeZone;

end
% EOF