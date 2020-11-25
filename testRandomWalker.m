% Test best binarization method
clc;
clear;
close all;

%%
I = imread("ikea.jpg");
I_grey = uint8(rgb2gray(I));

seed = [sub2ind(size(I), 360, 500)]
RandomWalker(I, seed, 1)