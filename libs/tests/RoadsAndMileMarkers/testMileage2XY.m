% TESTMILEAGE2XY
%
% Yaguang Zhang, Purdue, 02/06/2021

mileageDelat = 20;
mileages = distdim(2.5:3.1:10 + mileageDelat, 'm', 'mi')';
roadSegPtXs = [0:10, 10:-1:0]';
roadSegPtYs = [linspace(0,0.1,11), linspace(0.1,0,11)+1]';
noiseY = rand(11,1);

roadSegPolyshape = polyshape(roadSegPtXs, ...
    roadSegPtYs+[noiseY;noiseY(end:-1:1)]);
roadSegPtMileages = distdim(roadSegPtXs + mileageDelat, 'm', 'mi');
mileage2XY(mileages, roadSegPolyshape, roadSegPtMileages, true)

% EOF