function [datetimesToInspect] = constructDatetimesToInspect( ...
    datetimeStart, datetimeEnd, timeIntervalInM, timeIntervalInD)
%CONSTRUCTDATETIMESTOINSPECT Construct a datetime array based on the input
%specifications for the datetimes to inspect.
%
% Inputs:
%   - datetimeStart, datetimeEnd, timeIntervalInM
%     The start time (datetime), end time (datetime), and time intervel
%     (positive number) in minutes between the times of interest. If these
%     are cells, we will find the covered time by each set of elements in
%     them.
%   - timeIntervalInD
%     Optional. Time intervel in days between the dates of interest. If
%     this is present, then all the other inputs should not be cells. We
%     will first find the dates of interest by
%       date(datetimeStart):days(timeIntervalInD):date(datetimeEnd)
%     and then find in each day of interest the times of interest by
%       timeInDay(datetimeStart):minutes(timeIntervalInM): ...
%           timeInDay(datetimeEnd)
%
% Output:
%   - datetimesToInspect
%     A datetime array with all times covered by the input.
%
% Yaguang Zhang, Purdue, 02/11/2021

if exist('timeIntervalInD', 'var')
    dateFormat = 'dd-mmm-yyyy';
    startDate = datetime(datestr(datetimeStart, dateFormat));
    endDate = datetime(datestr(datetimeEnd, dateFormat));
    
    startTimeInDay = datetimeStart - startDate;
    endTimeInDay = datetimeEnd - endDate;
    
    datesOfInterest =  startDate:days(timeIntervalInD):endDate;
    numOfDays = length(datesOfInterest);
    
    [datetimeStartCell, datetimeEndCell, timeIntervalInMCell] ...
        = deal(cell(numOfDays, 1));
    for idxDay = 1:numOfDays
        datetimeStartCell{idxDay} = datesOfInterest(idxDay)+startTimeInDay;
        datetimeEndCell{idxDay} = datesOfInterest(idxDay)+endTimeInDay;
        timeIntervalInMCell{idxDay} = timeIntervalInM;
    end
    datetimesToInspect = constructDatetimesToInspect( ...
        datetimeStartCell, datetimeEndCell, timeIntervalInMCell);
else
    if iscell(datetimeStart)
        numOfRanges = length(datetimeStart);
        datetimesToInspectCell = cell(numOfRanges, 1);
        for idxRange = 1:numOfRanges
            datetimesToInspectCell{idxRange} = datetimeStart{idxRange} ...
                :minutes(timeIntervalInM{idxRange}) ...
                :datetimeEnd{idxRange};
        end
        datetimesToInspect = horzcat(datetimesToInspectCell{:});
    else
        datetimesToInspect = datetimeStart ...
            :minutes(timeIntervalInM) ...
            :datetimeEnd;
    end
end

end
% EOF