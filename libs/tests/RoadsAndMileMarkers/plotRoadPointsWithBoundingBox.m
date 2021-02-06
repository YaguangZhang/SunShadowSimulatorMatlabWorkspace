% PLOTROADPOINTSWITHBOUNDINGBOX
%
% Yaguang Zhang, Purdue, 02/03/2021

% Check the road segments.
close all;
figure;
hold on;
axis equal;
grid on;
for iii=1:length(indotRoads)
    plot(indotRoads(iii).X, indotRoads(iii).Y,'ro');
    bbb = indotRoads(iii).BoundingBox;
    am = bbb(1,1);aM = bbb(2,1);bm = bbb(1,2);bM = bbb(2,2);
    plot([am, aM, aM, am, am], [bM, bM, bm, bm, bM],'b');
    pause;
end
hold off;

% Check the zero-length anomalies.
close all;
figure;
hold on;
axis equal;
grid on;
for iii=find([indotRoads.Shape_Leng ]== 0)
    clf;
    plot(indotRoads(iii).X, indotRoads(iii).Y,'ro');
    bbb = indotRoads(iii).BoundingBox;
    am = bbb(1,1);aM = bbb(2,1);bm = bbb(1,2);bM = bbb(2,2);
    plot([am, aM, aM, am, am], [bM, bM, bm, bm, bM],'b');
    pause;
end
hold off;

% EOF