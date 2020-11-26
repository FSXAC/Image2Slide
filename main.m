% This file is the project entry point

clc;
clear;
close all;

% Parameters
SHOW_DEBUG = false;
HOUGH_RHO_RES = 1;
HOUGH_THETA_RES = 0.2;


in_file = 'classroom.png';
out_file = 'classroom_scan.png';

img = imread(in_file);

% Convert to greyscale
img_bw = uint8(rgb2gray(img));
[img_bin, thres] = binaryImage2(img_bw);

if (SHOW_DEBUG)
    figure;
    montage({img_bw, img_bin},'Size',[1 2]);
end


%% Apply edge detection filter (note: sobel is not suitable because lines could be diagonal)
img_grad = edge_grad(img_bin, thres);

%% Hough transform
[H, T, R] = hough(img_grad,'RhoResolution', HOUGH_RHO_RES ,'Theta', -90:HOUGH_THETA_RES:89);

% Make bright spots more visible
H = H .^ 2;

%% Find points from H (binary search) (0.7 seconds vs 1.75s of old method)
peaks = hough_search(H, 4, 10);
lines = houghlines(img_bw, T, R, peaks);

line_verts = hough_lines2verts(lines);
points = intersection_points(line_verts, img);
draw_detection(img, line_verts, points);

%% rectify image
[img_rectified, transformation, ref] = rectify_image(img, points, 4/3);

%% crop the rectified image
img_cropped = crop2doc(img_rectified, transformation, ref, points);

%% Document segmentation (TODO: use the rice example from HW4)
img_doc = imadjust(rgb2gray(img_cropped));
img_doc = imbinarize(img_doc, 'adaptive', 'Sensitivity', 0.630000, 'ForegroundPolarity', 'bright');
figure;
imshow(img_doc);

%% Save the image
imwrite(img_doc, out_file);

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
            ratio_hi = ratio;
        elseif size(points, 1) < n
            ratio_lo = ratio;
        else
            break
        end
        
        epoch = epoch + 1;
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
