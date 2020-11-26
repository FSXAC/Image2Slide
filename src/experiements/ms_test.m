clc;
clear;
close all;

showdebug = false;

in_file = 'classroom.png';
out_file = 'classroom_scan.png';

% cam = webcam('FaceTime');
% img = snapshot(cam);
% img = imread('ikea.jpg');
img = imread(in_file);

% Convert to greyscale
img_bw = uint8(rgb2gray(img));
[img_bin, thres] = binaryImage2(img_bw);
img_bin2 = uint8(morphCloseImage(img_bin)) .* 255;
img_eq = histeq(img_bw);

if (showdebug)
    figure;
    montage({img_bw, img_eq, img_bin, img_bin2},'Size',[1 4]);
    title("Grayscale, Histeq, Binary");
end


%% Apply sobel edge detection filter

img_g = edge_sobel(img_bin, thres);
img_grad = edge_grad(img_bin, thres);
img_g2 = edge_sobel(img_bin2, thres);
img_grad2 = edge_grad(img_bin2, thres);

if (showdebug)
    figure;
    imshowpair(img_g, img_grad, 'montage');
    figure;
    montage({img_g, img_grad, img_g2, img_grad2},'Size',[2 2]);
end

%% Hough transform
[H, T, R] = hough(img_grad,'RhoResolution',3 ,'Theta', -90:0.2:89);
% figure;

% Make bright spots more visible
% H = H .^ 2;

% imshow(imresize(H, [1200 1200], 'nearest'), []);
% H = imgaussfilt(H, 2);
if (showdebug)
    imshow(H, []);
end
% imshow(imadjust(rescale(H)),'XData',T,'YData',R);

%% Find points from H
ratio = 0.7;
if (showdebug)
    figure;
end
while ratio > 0.1
    ratio = ratio - 0.01;
    
    mask = H > ratio*max(H(:));
    mask = bwmorph(mask, 'dilate', 15);

    if (showdebug)
        imshow(mask, []);
    end
    mask = bwmorph(mask, 'shrink', Inf);
    mask = double(mask);
    % imshow(mask, []);

    [r_idx, t_idx] = find(mask);
    peaks = [r_idx, t_idx];
    
    if size(peaks, 1) >= 4
        break
    end
end
% peaks = houghpeaks(H, 5);

%% Find peak points furtherest apart
opts = nchoosek(1:size(peaks, 1), 4);
max_area = 0;
max_peaks = peaks;
for i = 1:size(opts, 1)
    P = zeros(4, 2);
    for j = 1:4
        P(j, :) = peaks(opts(i, j), :);
    end
    [hull, area] = convhull(P);
    
    if area > max_area
        max_peaks = P;
    end
end
peaks = max_peaks;

%% Draw line on image
figure;
hold on;
imshow(img_bw, []);
lines = houghlines(img_bw,T,R, peaks);
% for i = 1:size(r_idx, 1)
%     r = R(r_idx(i));
%     t = T(t_idx(i));
%     [x, y] = pol2cart(t, r);
%     line([0, x], [0, y]);
% end

line_verts = zeros(4, 2, 2);

hold on
for k = 1:numel(lines)
    x1 = lines(k).point1(1);
    y1 = lines(k).point1(2);
    x2 = lines(k).point2(1);
    y2 = lines(k).point2(2);
    plot([x1 x2],[y1 y2],'Color','g','LineWidth', 2)
    
    line_verts(k,1,:) = [x1 x2];
    line_verts(k,2,:) = [y1 y2];
end

% Find intersection
points = [];
index_opts = nchoosek(1:4, 2);
for i = 1:size(index_opts, 1)
    l1_idx = index_opts(i, 1);
    l2_idx = index_opts(i, 2);
    
    x1 = line_verts(l1_idx,1,:);
    y1 = line_verts(l1_idx,2,:);
    x2 = line_verts(l2_idx,1,:);
    y2 = line_verts(l2_idx,2,:);
    
    [x_i, y_i] = intersection(x1, y1, x2, y2);
    
    % discard points outside of image
    if x_i < 0 || x_i > size(img, 2) || y_i < 0 || y_i > size(img, 1)
        continue
    end
    points = [points; x_i y_i];
    plot(x_i, y_i, 'r*')
end
hold off


%% 

% Control (original image)
h = size(img, 1);
w = 4/3 * h;
% w = 16/9 * h;
C = [0, 0;
     w, 0;
     0, h;
     w, h];

tf = fitgeotrans(points, C, 'projective');
[img_rectified, ref] = imwarp(img, tf);

% tf2 = affine2d([1 0 0; 0 1 0; 20 30 1]);

wx = ref.XWorldLimits(1);
wy = ref.YWorldLimits(1);

% img_rectified = imwarp(img, 
if (showdebug)
    figure;
    imshow(img_rectified);
    hold on
end

% Control points on the new graph
new_points = [];
for i = 1:size(points, 1)
    x_i = points(i, 1);
    y_i = points(i, 2);
    
    [x_o, y_o] = tf.transformPointsForward(x_i, y_i);
    
    xx = round(x_o - wx);
    yy = round(y_o - wy);
    
    new_points = [new_points; xx, yy];

    if (showdebug)
        plot(xx, yy, 'g*', 'MarkerSize', 10)
    end
end

if (showdebug)
    hold off
end

%% don't care about anything else lol

minnp = min(new_points);
maxnp = max(new_points);

% img_bl(1:minnp(2),:,:) = 0;
% img_bl(maxnp(2):ref.ImageSize(1),:,:) = 0;

img_cropped = imcrop(img_rectified, [minnp, maxnp - minnp]);
    img_cropped_grey = rgb2gray(img_cropped);

if (showdebug)
    figure;
    imshowpair(img_cropped, img_cropped_grey, 'montage');
end

%% Document segmentation (TODO: use the rice example from HW4)
img_doc = imadjust(img_cropped_grey);
img_doc = imbinarize(img_doc, 'adaptive', 'Sensitivity', 0.630000, 'ForegroundPolarity', 'bright');
figure;
imshow(img_doc);

%% Save the image
imwrite(img_doc, outfile);

%% Functions

function img = edge_sobel(I, thres)
    gx = [-1 -2 -1; 0 0 0; 1 2 1];
    gy = [-1 0 1; -2 0 2; -1 0 1];
    img_gx = conv2(I, gx);
    img_gy = conv2(I, gy);
    img = abs(img_gx) + abs(img_gy);
    img(img < thres) = 0;
end

function img = edge_grad(I, thres)
    img = imgradient(I);
    img(img < thres) = 0;
end

% https://www.mathworks.com/matlabcentral/answers/70287-to-find-intersection-point-of-two-lines
function [x, y] = intersection(x1, y1, x2, y2)
p1 = polyfit(x1, y1, 1);
p2 = polyfit(x2, y2, 1);
x = fzero(@(x) polyval(p1 - p2, x), 3);
y = polyval(p1, x);
end