% Test best binarization method
clc;
clear;
close all;

%%
se = offsetstrel('ball',5,5);
I = imread("ikea.jpg");
I_grey = uint8(rgb2gray(I));

% I2 = imdilate(I_grey, se);
I2 = imgaussfilt(I_grey, 2);

figure;
imshowpair(I_grey, I2,'montage')

I = binaryImage2(I2);
% I = segmentImage1(I_grey);

%%
I_sobel = edge(I, 'Sobel');
I_prewitt = edge(I, 'Prewitt');
I_roberts = edge(I, 'Roberts');
I_log = edge(I, 'log');
I_zc = edge(I, 'zerocross');
I_canny = edge(I, 'Canny');
I_approxcanny = edge(I, 'approxcanny');
I_grad = imgradient(I);

figure;
montage({I_sobel, I_prewitt, I_roberts, I_log, I_zc, I_canny, I_approxcanny, I_grad},'Size',[3 3]);
