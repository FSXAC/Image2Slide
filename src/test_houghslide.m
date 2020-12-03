clc;
clear;
close all;

I = imread('img/ikea.jpg');
I = imgradient(imbinarize(rgb2gray(I)));
figure;
imshow(I, []);

HOUGH_RHO_RES = 1 + floor(max(size(I)) / 1000);
HOUGH_THETA_RES = 0.2;

[H, T, R] = hough(I, 'RhoResolution', HOUGH_RHO_RES ,'Theta', -90:HOUGH_THETA_RES:89);
figure;
imshow(H, []);