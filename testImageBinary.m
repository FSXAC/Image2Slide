% Test best binarization method
clc;
clear;
close all;

%%
I = imread("ikea.jpg");

%%
I_grey = uint8(rgb2gray(I));
I_grey2 = histeq(I_grey);

I_b1 = binaryImage1(I_grey);
I_b2 = binaryImage2(I_grey);

I_otsu = imbinarize(I_grey, graythresh(I_grey));

figure;
montage({I_grey, I_grey2, I_b1, I_b2, I_otsu},'Size',[2 3]);
title("Grayscale, Grayscale (Hist enhance), Binary 1, Binary 2, Ostu threshold");