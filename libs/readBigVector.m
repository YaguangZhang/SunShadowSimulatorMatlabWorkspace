function [flagSuccess] = readBigVector(absDirToRead)
%SAVEBIGVECTOR Read a big vector/struct array from the .mat files generated
%by saveBigVector.
%
% Yaguang Zhang, Purdue, 02/02/2021

flagSuccess = false;

load(absDirToRead);

if eval(['iscolumn(', bigVectName, '_1)'])
    fctCat = @vertcat;
elseif eval(['isrow(', bigVectName, '_1)'])
    fctCat = @cat;
else
    error('A vector is expected!')
end

cmdToConstructBigVect = 'bigVect = fctCat(';
for idxMatFile = 1:numOfVarsNeeded
    cmdToConstructBigVect = [cmdToConstructBigVect, ...
        bigVectName, '_', num2str(idxMatFile), ',']; %#ok<AGROW>
end
cmdToConstructBigVect = [cmdToConstructBigVect(1:(end-1)), ');'];
eval(cmdToConstructBigVect);

assignin('base', bigVectName, bigVect);

flagSuccess = true;
end
% EOF