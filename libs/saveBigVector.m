function [flagSuccess] = saveBigVector(absDirToSave, bigVect)
%SAVEBIGVECTOR Save a big vector/struct array to multiple .mat files.
%
% Yaguang Zhang, Purdue, 02/02/2021

flagSuccess = false;

% At most 2^32 bytes of data can be saved in each variable.
maxVarSizePerMatFileInByte = 2*10^9;
bigVectName = inputname(2);
bigVectLength = length(bigVect);

whosIndotRoads = whos('bigVect');
numOfVarsNeeded = ceil(whosIndotRoads.bytes ...
    /maxVarSizePerMatFileInByte);

numOfElesPerFile = ceil(bigVectLength/numOfVarsNeeded);
indiceRanges = 1:numOfElesPerFile:bigVectLength;
indiceRanges = [indiceRanges', (indiceRanges+numOfElesPerFile-1)'];
indiceRanges(end,2) = bigVectLength;

save(absDirToSave, 'bigVectName', 'numOfVarsNeeded', 'indiceRanges');

for idxMatFile = 1:numOfVarsNeeded
    curVarName = [bigVectName, '_', num2str(idxMatFile)];
    eval([curVarName, ' = bigVect(indiceRanges(idxMatFile, 1)', ...
        ':indiceRanges(idxMatFile, 2));']); 
    save(absDirToSave, curVarName, '-append');    
end

flagSuccess = true;
end
% EOF