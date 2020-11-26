% This file is the project entry point

clc;
clear;
close all;

% Parameters
SHOW_DEBUG = false;
HOUGH_RHO_RES = 1;
HOUGH_THETA_RES = 0.2;


in_file = 'classroom.jpg';
out_file = 'classroom_scan.png';

img = imread(in_file);

% Convert to greyscale
img_bw = uint8(rgb2gray(img));
[img_bin, thres] = binaryImage2(img_bw);

%% Apply edge detection filter (note: sobel is not suitable because lines could be diagonal)
img_grad = edge_grad(img_bin, thres);

%% Hough transform
[H, T, R] = hough(img_grad,'RhoResolution', HOUGH_RHO_RES ,'Theta', -90:HOUGH_THETA_RES:89);

% Make bright spots more visible
H = H .^ 2;

%% Find points from H (binary search) (0.7 seconds vs 1.75s of old method)
peaks = hough_search(H, 4, 50);
lines = houghlines(img_bw, T, R, peaks);

line_verts = hough_lines2verts(lines);
points = intersection_points(line_verts, img);
draw_detection(img, line_verts, points);

%% rectify image
[img_rectified, transformation, ref] = rectify_image(img, points, 4/3);

%% crop the rectified image
img_cropped = crop2doc(img_rectified, transformation, ref, points);

%% Document segmentation (TODO: use the rice example from HW4)
img_cropped_grey = rgb2gray(img_cropped);
img_doc = imadjust(img_cropped_grey);
img_doc = imbinarize(img_doc, 'adaptive', 'Sensitivity', 0.630000, 'ForegroundPolarity', 'bright');
figure;
imshow(img_doc);

%% Save the image
% imwrite(img_doc, out_file);

%% Perform colour correction
% Masking the background of the document
bg_mask = imadjust(img_cropped_grey) > 220;
img_bg_seg = repmat(uint8(bg_mask), 1, 1, 3) .* img_cropped;

% 3 Channels of histogram don't line up (so let's apply transformations
% independently to each channel so they look white
figure;
imshow(img_bg_seg);
% [R, G, B] = rgbhist(img_bg_seg);
img_cropped_c = bumpEqualize(double(img_cropped), img_bg_seg, 240);
% rgbhist(img_cropped_c);
figure;
imshow(uint8(img_cropped_c));

% Apply contrast
img_cropped_c = img_cropped_c .* 2.0 - 255;
figure;
imshow(uint8(img_cropped_c));

% Apply segment boost
img_boosted = img_cropped_c + (img_doc - 0.2) * 60;
figure;
imshow(uint8(img_boosted));

% x = 0:255;
% x1 = 0.5 * 255 * (sin(x * pi / 255 - pi / 2) + 1);
% x2 = min(x .^ 2 / (255 * 0.5), 255);
% x3_shift = 50;
% x3 = 255 * (sin((x - x3_shift) * pi / 255 - pi / 4).^2);
% x3(1:64+x3_shift) = 0;
% x3(191+x3_shift:end) = 255;
% % plot(x3);
% % 
% i1 = intlut(uint8(img_cropped_c), uint8(x1));
% i2 = intlut(img_cropped, uint8(x2));
% i3 = intlut(img_cropped, uint8(x3));
% figure;
% imshow(i3);

%% Functions
function img = edge_grad(I, thres)
    img = imgradient(I);
    img(img < thres) = 0;
end

function points = hough_search(H, n, max_epoch)
    ratio_hi = 1.0;
    ratio_lo = 0.0;
    epoch = 0;

    while epoch < max_epoch
        ratio = (ratio_hi - ratio_lo) / 2 + ratio_lo;

        mask = H > ratio * max(H(:));
        mask = bwmorph(mask, 'dilate', 15);
        mask = bwmorph(mask, 'shrink', Inf);
        mask = double(mask);

        [r_idx, t_idx] = find(mask);
        points = [r_idx, t_idx];

        if size(points, 1) > n
            ratio_lo = ratio;
        elseif size(points, 1) < n
            ratio_hi = ratio;
        else
            break
        end
        
        epoch = epoch + 1;
    end
    
    if epoch >= max_epoch
        error('Max epoch too low');
    end
end

% This function finds the lines in spatial/px coordinates from hough lines
function line_verts = hough_lines2verts(lines)
    line_verts = zeros(4, 2, 2);

    for k = 1:numel(lines)
        x1 = lines(k).point1(1);
        y1 = lines(k).point1(2);
        x2 = lines(k).point2(1);
        y2 = lines(k).point2(2);
        
        line_verts(k,1,:) = [x1 x2];
        line_verts(k,2,:) = [y1 y2];
    end
end

function points = intersection_points(line_verts, img)
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
    end
end

% https://www.mathworks.com/matlabcentral/answers/70287-to-find-intersection-point-of-two-lines
function [x, y] = intersection(x1, y1, x2, y2)
    p1 = polyfit(x1, y1, 1);
    p2 = polyfit(x2, y2, 1);
    x = fzero(@(x) polyval(p1 - p2, x), 3);
    y = polyval(p1, x);
end

% Draw picture with detected lines and intersection points
function draw_detection(img, line_verts, points)
    figure;
    imshow(img);

    hold on
    for k = 1:size(line_verts, 1)
        x1 = line_verts(k, 1, 1);
        x2 = line_verts(k, 1, 2);
        y1 = line_verts(k, 2, 1);
        y2 = line_verts(k, 2, 2);
        plot([x1 x2],[y1 y2],'Color','g','LineWidth', 2);
    end

    for k = 1:size(points, 1)
        plot(points(k, 1), points(k, 2), 'r*');
    end
    hold off
end

% Rectifies the image -- returns the rectified image as well as reference information
function [img_rectified, transformation, ref] = rectify_image(img, control_points, aspect_ratio)
    h = size(img, 1);
    w = aspect_ratio * h;
    C = [0, 0;
        w, 0;
        0, h;
        w, h];

    transformation = fitgeotrans(control_points, C, 'projective');
    [img_rectified, ref] = imwarp(img, transformation);
end

% Crop the input image to the document only
function img_cropped = crop2doc(img, transformation, ref, points)
    wx = ref.XWorldLimits(1);
    wy = ref.YWorldLimits(1);

    % Control points on the new graph
    new_points = points;
    for k = 1:size(points, 1)
        x_i = points(k, 1);
        y_i = points(k, 2);
        
        [x_o, y_o] = transformation.transformPointsForward(x_i, y_i);
        
        xx = round(x_o - wx);
        yy = round(y_o - wy);
        
        new_points(k, :) = [xx, yy];
    end

    minnp = min(new_points);
    maxnp = max(new_points);

    img_cropped = imcrop(img, [minnp, maxnp - minnp]);
end

% get RGB histogram
function [r, g, b] = rgbhist(img)
    r = imhist(img(:, :, 1));
    g = imhist(img(:, :, 2));
    b = imhist(img(:, :, 3));
    figure;
    plot(r, 'r');
    hold on
    plot(g, 'g');
    plot(b, 'b');
    hold off
end

function x_out = map(x, in_min, in_max, out_min, out_max)
    x_out = (x - in_min) .* (out_max - out_min) ./ (in_max - in_min) + out_min;
end

% This function takes the non-zero low end of a histogram and bump it to an
% upper level
function Iout = bump_hist_channel(I, bgI, upper)
    thres_lo = 10;
    thres_hi = 300;
    h = imhist(bgI);
    h = h(2:end);
    for k = 1:size(h, 1)
        if h(k) > thres_hi
            break
        end
    end
    f = (upper - k) / 255 + 1;
    Iout = I .* f;
end

function Iout = bumpEqualize(I, bgI, upper)
    % For each RGB channels
    Iout = I;
    Iout(:, :, 1) = bump_hist_channel(I(:, :, 1), bgI(:, :, 1), upper);
    Iout(:, :, 2) = bump_hist_channel(I(:, :, 2), bgI(:, :, 2), upper);
    Iout(:, :, 3) = bump_hist_channel(I(:, :, 3), bgI(:, :, 3), upper);
end