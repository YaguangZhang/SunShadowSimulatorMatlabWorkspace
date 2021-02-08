function [mat] = swapNewBreakPoints(mat, idxColumn)
%SWAPNEWBREAKPOINTS A helper function to swap the 2nd and 3rd row of the
%input matrix at a given column.
%
% Yaguang Zhang, Purdue, 02/07/2021

temp = mat(2, idxColumn); 
mat(2, idxColumn) = mat(3, idxColumn); 
mat(3, idxColumn) = temp;

end
% EOF