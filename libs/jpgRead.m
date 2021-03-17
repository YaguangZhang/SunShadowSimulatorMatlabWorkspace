function [jpgData, jpgInfo] = jpgRead(dirToJpg)
%JPGREAD Read in the raw data of a .jpg photo, similar to imread, but
%considering the rotation information if it is present.
%
% Ref:
%   https://www.mathworks.com/matlabcentral/answers/260607-how-to-load-a-jpg-properly
%
% Yaguang Zhang, Purdue, 03/16/2021

jpgData = imread(dirToJpg);
% We need to consider the rotation of the image.
jpgInfo = imfinfo(dirToJpg);
if isfield(jpgInfo,'Orientation')
    orient = jpgInfo(1).Orientation;
    switch orient
        case 1
            %normal, leave the data alone
        case 2
            jpgData = jpgData(:,end:-1:1,:);         %right to left
        case 3
            jpgData = jpgData(end:-1:1,end:-1:1,:);  %180 degree rotation
        case 4
            jpgData = jpgData(end:-1:1,:,:);         %bottom to top
        case 5
            jpgData = permute(jpgData, [2 1 3]);     %counterclockwise and upside down
        case 6
            jpgData = rot90(jpgData,3);              %undo 90 degree by rotating 270
        case 7
            jpgData = rot90(jpgData(end:-1:1,:,:));  %undo counterclockwise and left/right
        case 8
            jpgData = rot90(jpgData);                %undo 270 rotation by rotating 90
        otherwise
            warning(sprintf('unknown orientation %g ignored\n', orient));
    end
end

end
% EOF