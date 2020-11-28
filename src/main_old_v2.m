% This file is the project entry point

clc;
clear;
close all;

% Parameters
in_file = 'input/3.jpeg';

img = imread(in_file);
img_xs = imresize(img, [200 NaN]);

SHOW_DEBUG = false;

% Convert to greyscale
img_bw = uint8(rgb2gray(img_xs));
[img_bin, thres] = binaryImage2(img_bw);

npoints = get_corners(img_bw);

points = zeros(size(npoints));
points(:, 1) = npoints(:, 1) .* size(img, 2);
points(:, 2) = npoints(:, 2) .* size(img, 1);

%% rectify image
[img_rectified, transformation, ref] = rectify_image(img, points, 4/3);

%% crop the rectified image
img_cropped = crop2doc(img_rectified, transformation, ref, points);

%% Document segmentation (TODO: use the rice example from HW4)
img_cropped_grey = rgb2gray(img_cropped);
% img_doc = imadjust(img_cropped_grey);
% img_doc = imbinarize(img_doc, 'adaptive', 'Sensitivity', 0.67, 'ForegroundPolarity', 'bright');
% img_doc = imclose(img_doc, strel('disk', 6, 0));
img_doc = imbinarize(img_cropped_grey);

img_doc_xs = imresize(img_doc, [200 NaN]);
img_cropped_xs = imresize(img_cropped, [200 NaN]);

% figure;
% imshow(img_doc);

%% Save the image
% imwrite(img_doc, out_file);

%% Perform colour correction
% Masking the background of the document
img_bg_seg = repmat(uint8(img_doc_xs), 1, 1, 3) .* img_cropped_xs;

% 3 Channels of histogram don't line up (so let's apply transformations
% independently to each channel so they look white
% figure;
% imshow(img_bg_seg);
img_cropped_c = bump_equalize(double(img_cropped), img_bg_seg, 240);
% figure;
% imshow(uint8(img_cropped_c));

% Apply contrast
img_cropped_c = img_cropped_c .* 2.0 - 255;
% figure;
% imshow(uint8(img_cropped_c));

% Apply segment boost
img_boosted = img_cropped_c + (img_doc - 0.01) * 255;
% figure;
% imshow(uint8(img_boosted));

%% Region of interest analysis
% Generate map
doc_roi = imclearborder(imcomplement(imerode(img_doc_xs, strel('rectangle', [4 15]))));
doc_rp = regionprops(doc_roi);
bboxes = [doc_rp.BoundingBox];
doc_bbox_xs = reshape(bboxes, 4, size(bboxes, 2) / 4);
doc_bbox_xs = doc_bbox_xs';

% Normalize bbox coordinates to unit-coords
doc_bbox_n = doc_bbox_xs ./ size(img_doc_xs, 1);

% Draw bonuding boxes
doc_bbox = doc_bbox_n .* size(img_boosted, 1);
figure;
imshow(img_boosted);
hold on
for k = 1:size(doc_bbox, 1)
    rectangle('Position', doc_bbox(k, :), 'EdgeColor', 'g', 'LineWidth', 2);
end
hold off

%% Subimages
% figure;
for k = 1:size(doc_bbox, 1)
%     subplot(size(doc_bbox, 1), 1, k);
    subimg = imcrop(img_boosted, doc_bbox(k, :));
    submask = 255 .* uint8(imcrop(1 - img_doc, doc_bbox(k, :)));
%     imshow(submask);
%     title(ocr(subimg,'TextLayout','Block').Text)
    fname = append('output/sub-', string(k), '.png');
    imwrite(subimg, fname, 'png', 'Alpha', submask);
end

