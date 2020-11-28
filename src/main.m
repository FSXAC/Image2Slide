% This file is the project entry point

clc;
clear;
close all;

% Clear output
rmdir('output/*', 's');

% Use alpha output for image pieces
EXPORT_ALPHA_MASK = true;

% Downsample factor
BOUND_DETECT_DS_FACTOR = 0.1;
DOC_ROI_DS_FACTOR = 0.15;


% iterate each image in the input folder
infiles = [
    dir('input/*.jpg'), ...
    dir('input/*.jpeg'), ...
    dir('input/*.png')
];
for k = 1 : length(infiles)

    baseFileName = infiles(k).name;
    fullFileName = fullfile(infiles(k).folder, baseFileName);
    process_file(fullFileName, BOUND_DETECT_DS_FACTOR, DOC_ROI_DS_FACTOR, EXPORT_ALPHA_MASK);
end