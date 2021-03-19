function [latLon, datetimeLocal, zone] ...
    = readLatLonTimeFromJpg(dirToJpg, zone)
%READLATLONTIMEFROMJPG Read the (lat, lon) information from a JPG image.
%
% Inputs:
%   - dirToJpg
%     The full path to the JPG photo.
%   - zone
%     Optional. The geo time zone based on the longitude of the location
%     where the photo was taken. Essentially, it is:
%           zone = -timezone(lon);
%     If GPS info is available for the photo, this input will be ignored.
%     Otherwise, the zone will default to -6 for Indiana.
%
% Outputs:
%   - latLon
%     The GPS (lat, lon) embedded in the photo.
%   - datetimeLocal
%     A datetime object for the time when the photo was taken.
%   - zone
%     The time zone in hours (e.g., -7): local time = UTC time + time zone.
%
% Yaguang Zhang, Purdue, 03/15/2021

datetimeFormat = 'yyyy:MM:dd HH:mm:ss';
datetimeFileModFormat = 'dd-MMM-yyyy HH:mm:ss';
info = imfinfo(dirToJpg);
if isfield(info, 'GPSInfo')
    gpsInfo = info.GPSInfo;
    
    lat = dms2degrees(gpsInfo.GPSLatitude);
    lon = dms2degrees(gpsInfo.GPSLongitude);
    
    if strcmpi(gpsInfo.GPSLatitudeRef(1), 's')
        lat = -lat;
    end
    
    if strcmpi(gpsInfo.GPSLongitudeRef(1), 'w')
        lon = -lon;
    end
    
    latLon = [lat, lon];
    zone = -timezone(lon);
    
    switch lower(info.Make)
        case 'apple'
            % Images from the iPhone do not have GPS time stamps. We will
            % use the image date and time, which should already be the
            % local time.
            datetimeLocal = datetime(info.DateTime, ...
                'InputFormat', datetimeFormat);
            % The iPhone uses time zone 'America/Indianapolis'. We need to
            % fix the time offset issue (compared with the geographical
            % time zone derived from the longitude).
            %   TODO: Determine time zone and daylight saving by
            %   coordinates.
            datetimeLocalIn = datetime(info.DateTime, ...
                'InputFormat', datetimeFormat, ...
                'TimeZone', 'America/Indianapolis');
            dateTimeLocalUtc = datetime(info.DateTime, ...
                'InputFormat', datetimeFormat, ...
                'TimeZone', 'UTC');
            % Note: it will take timezoneUsed hours for UTC time to "catch"
            % the local time.
            timezoneUsed = hours(dateTimeLocalUtc-datetimeLocalIn);
            % Convert the UTC time to local time.
            datetimeLocal = utcUnixTimeInS2LocalDatetime( ...
                localDatetime2UtcUnixTimeInS(...
                datetimeLocal, timezoneUsed), ...
                zone);
        case 'gopro'
            % We have GPS time available for GoPro.
            datetimeLocal = datetime(...
                join([info.GPSInfo.GPSDateStamp, ' ', ...
                join(arrayfun(@(n) num2str(n), ...
                info.GPSInfo.GPSTimeStamp, ...
                'UniformOutput', false), ':') ...
                ], ''), 'InputFormat', datetimeFormat);
            % Convert the UTC time to local time.
            datetimeLocal = utcUnixTimeInS2LocalDatetime( ...
                localDatetime2UtcUnixTimeInS(datetimeLocal,0), zone);
        otherwise
            error(['Unsupported info.Maker "', info.Make, '"!'])
    end
else
    % If no GPS info is available, we will use the modified date and time
    % for this photo.
    latLon = [nan, nan];
    datetimeLocal = datetime(info.FileModDate, ...
        'InputFormat', datetimeFileModFormat);
    datetimeLocalIn = datetime(info.FileModDate, ...
        'InputFormat', datetimeFileModFormat, ...
        'TimeZone', 'America/Indianapolis');
    dateTimeLocalUtc = datetime(info.FileModDate, ...
        'InputFormat', datetimeFileModFormat, ...
        'TimeZone', 'UTC');
    timezoneUsed = hours(dateTimeLocalUtc-datetimeLocalIn);
    % Note: we require the input zone in this case.
    if ~exist('zone', 'var')
        zone = -6;
    end
    datetimeLocal = utcUnixTimeInS2LocalDatetime( ...
        localDatetime2UtcUnixTimeInS(...
        datetimeLocal, timezoneUsed), ...
        zone);
end

end
% EOF