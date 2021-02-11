%GENVIDEOFORUNIFSUNPOWER Generate a video for the uniform sun power over
%time on a map based on simConfigs and simState.
%
% Yaguang Zhang, Purdue, 02/11/2021

timeToPauseForFigUpdateInS = 0.000001;
pathToSaveVideo = fullfile(folderToSaveResults, 'unifSunPowerOverTime');

% Video parameters.
simTimeLengthPerFrameInS ...
    = simConfigs.PLAYBACK_SPEED/simConfigs.FRAME_RATE;
assert(floor(simTimeLengthPerFrameInS)==simTimeLengthPerFrameInS, ...
    ['For simplicity, ', ...
    'please make sure PLAYBACK_SPEED/VIDEO_FRAME_RATE ', ...
    'is an integer!']);

% Plot the background.
sz = 10;
hSunPower = figure;
hScatter = scatter(simConfigs.gridLatLonPts(:,2), ...
    simConfigs.gridLatLonPts(:,1), ...
    sz, [simState.uniformSunPower(:,1), ...
    zeros(size(simConfigs.gridLatLonPts, 1), 2)], 'filled');
plot_google_map('MapType', 'hybrid');
xticks([]); yticks([]); view(2);

lastDatetime = simConfigs.localDatetimesToInspect(1);
title(datestr(lastDatetime, datetimeFormat));
drawnow; pause(timeToPauseForFigUpdateInS);

% Create a video writer for outputting the frames.
curVideoWriter = VideoWriter( ...
    pathToSaveVideo, 'MPEG-4');
curVideoWriter.FrameRate = simConfigs.FRAME_RATE;
open(curVideoWriter);

try
    % Go through all remaining times.
    for curIdxDatetime = 2:length(simConfigs.localDatetimesToInspect)
        curDatetime ...
            = simConfigs.localDatetimesToInspect(curIdxDatetime);
        
        % Output the video.
        lastSimTime = lastDatetime;
        for curSimTimeInS ...
                = lastDatetime:seconds(1):(curDatetime-seconds(1))
            elapsedSimTimeInS = seconds(curSimTimeInS-lastSimTime);
            if elapsedSimTimeInS>=simTimeLengthPerFrameInS
                writeVideo(curVideoWriter, getframe(hSunPower));
                lastSimTime = curSimTimeInS;
            end
        end
        
        % Update the figure.
        deleteHandles(hScatter);
        
        hScatter = scatter(simConfigs.gridLatLonPts(:,2), ...
            simConfigs.gridLatLonPts(:,1), ...
            sz, [simState.uniformSunPower(:, curIdxDatetime), ...
            zeros(size(simConfigs.gridLatLonPts, 1), 2)], 'filled');
        title(datestr(curDatetime, datetimeFormat));
        drawnow; pause(timeToPauseForFigUpdateInS);
        
        lastDatetime = curDatetime;
    end
    % Output the last frame and close the video writer.
    for curSimTimeInS ...
            = lastDatetime:seconds(1) ...
            :(simConfigs.LOCAL_TIME_END-seconds(1))
        elapsedSimTimeInS = seconds(curSimTimeInS-lastSimTime);
        if elapsedSimTimeInS>=simTimeLengthPerFrameInS
            writeVideo(curVideoWriter, getframe(hSunPower));
            lastSimTime = curSimTimeInS;
        end
    end
catch err
    disp(getReport(exception))
    if strcmp(PRESET, 'RoadSimManager')
        warning([ ...
            'There was an error generating the video ', ...
            'for simulation #', num2str(idxSim), '!'])
    else
        error('There was an error generating the video!')
    end
end
close(curVideoWriter);

% EOF