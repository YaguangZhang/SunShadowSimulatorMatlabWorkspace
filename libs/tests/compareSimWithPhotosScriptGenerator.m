%COMPARESIMWITHPHOTOSSCRIPTGENERATOR This script copies
%compareSimWithPhotos for a few times, with the presets to run configured
%for different Matlab instances.
%
% To run the generated script, one could use the bash command:
%   matlab -r "parpool(2); dirToTests/compareSimWithPhotos#.m"
%
% Yaguang Zhang, Purdue, 03/19/2020

cd(fileparts(mfilename('fullpath')));

numOfPresets = 37;
presetsPerWorker = 3;

line_to_change = 167;

indicesStart = 1:presetsPerWorker:numOfPresets;
indicesEnd = (presetsPerWorker):presetsPerWorker:numOfPresets;
numOfFiles = length(indicesStart);
if length(indicesEnd)<numOfFiles
    indicesEnd(end+1) = numOfPresets;
end
for idxF = 1:numOfFiles
    new_output = ['for idxPreset = ', num2str(indicesStart(idxF)), ...
        ':', num2str(indicesEnd(idxF))];
    fid_in = fopen('compareSimWithPhotos.m', 'r');
    fid_out = fopen(['compareSimWithPhotos', num2str(idxF), '.m'], 'w');
    for K = 1 : line_to_change - 1
        %copy lines unchanged
        this_line = fgets(fid_in);
        fwrite(fid_out, this_line);
    end
    this_line = fgets(fid_in);  %read line that will be changed
    fprintf(fid_out, '%s\n', new_output);  %write changed version
    while true
        %copy lines unchanged
        this_line = fgets(fid_in);  %try getting a line
        if ~ischar(this_line); break; end   %end of file?
        fwrite(fid_out, this_line);  %no, copy it
    end
    fclose(fid_in);
    fclose(fid_out);
end

% EOF