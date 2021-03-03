%GENVIDEOFORUNIFSUNPOWER Generate a video for the uniform sun power over
%time on a map based on simConfigs and simState.
%
% Yaguang Zhang, Purdue, 02/11/2021

timeToPauseForFigUpdateInS = 0.000001;
if ~exist('pathToSaveVideo', 'var')
    pathToSaveVideo = fullfile(folderToSaveResults, ...
        'unifSunPowerOverTime');
end
if ~exist('FLAG_GEN_VIDEO_FOR_ONE_DAY', 'var')
    FLAG_GEN_VIDEO_FOR_ONE_DAY = false;
end

% Video parameters.
simTimeLengthPerFrameInS ...
    = simConfigs.PLAYBACK_SPEED/simConfigs.FRAME_RATE;
assert(floor(simTimeLengthPerFrameInS)==simTimeLengthPerFrameInS, ...
    ['For simplicity, ', ...
    'please make sure PLAYBACK_SPEED/VIDEO_FRAME_RATE ', ...
    'is an integer!']);

% Plot the background.
hSunPower = figure;
% Inverse hot color map: colormap(flipud(hot));
colormap parula;
curCAxis = [0,1];

numOfPtsPerSide = 32;
surfOpts = {'EdgeColor', 'interp', 'FaceAlpha', 0.9};
matRxLonLatWithSunPower = [simConfigs.gridLatLonPts(:,[2,1]), ...
    simState.uniformSunPower(:,1)];
hSunPowerSurf = gridDataSurf( ...
    matRxLonLatWithSunPower, numOfPtsPerSide, ...
    surfOpts{:});
caxis(curCAxis);

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
        
        if FLAG_GEN_VIDEO_FOR_ONE_DAY
            if curDatetime-simConfigs.localDatetimesToInspect(1) ...
                    > days(1)
                break
            end
        end
        
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
        deleteHandles(hSunPowerSurf);
        
        matRxLonLatWithSunPower = [simConfigs.gridLatLonPts(:,[2,1]), ...
            simState.uniformSunPower(:,curIdxDatetime)];
        hSunPowerSurf = gridDataSurf( ...
            matRxLonLatWithSunPower, numOfPtsPerSide, ...
            surfOpts{:});
        caxis(curCAxis);
        
        title(datestr(curDatetime, datetimeFormat));
        drawnow; pause(timeToPauseForFigUpdateInS);
        
        lastDatetime = curDatetime;
    end
    
    % Output the last frame and close the video writer.
    for curSimTimeInS ...
            = lastDatetime:seconds(1):(min( ...
            lastDatetime+minutes(simConfigs.TIME_INTERVAL_IN_M), ...
            simConfigs.localDatetimesToInspect(end)) ...
            - seconds(1))
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