% This file is the project entry point

clc;
clear;
close all;

% Parameters
in_file = 'ieee_xs.jpg';
out_file = 'classroom_scan.png';

img = imread(in_file);

SHOW_DEBUG = false;
HOUGH_RHO_RES = 1 + floor(max(size(img)) / 1000);
HOUGH_THETA_RES = 0.2;

% Convert to greyscale
img_bw = uint8(rgb2gray(img));
[img_bin, thres] = binaryImage2(img_bw);

% Apply edge detection filter (note: sobel is not suitable because lines could be diagonal)
img_grad = edge_grad(img_bin, thres);
img_edge = edge(img_bw);

% Hough transform
[H, T, R] = hough(img_edge, 'RhoResolution', HOUGH_RHO_RES ,'Theta', -90:HOUGH_THETA_RES:89);

% Make bright spots more visible
H = H .^ 2;

% imshow(imgradient(H), []);
% return;

% Find points from H (binary search) (0.7 seconds vs 1.75s of old method)
peaks = hough_search(H, 4, 50, 5);
lines = houghlines(img_bw, T, R, peaks);

line_verts = hough_lines2verts(lines);
points = intersection_points(line_verts, img);
draw_detection(img, line_verts, points);

%% rectify image
[img_rectified, transformation, ref] = rectify_image(img, points, 16/9);

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
img_cropped_c = bump_equalize(double(img_cropped), img_bg_seg, 240);
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

function x_out = map(x, in_min, in_max, out_min, out_max)
    x_out = (x - in_min) .* (out_max - out_min) ./ (in_max - in_min) + out_min;
end

