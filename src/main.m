% This file is the project entry point

clc;
clear;
close all;

%% iterate each image in the input folder
infiles = [
    dir('input/*.jpg'), ...
    dir('input/*.jpeg'), ...
    dir('input/*.png')
];
for k = 1 : length(infiles)

    baseFileName = infiles(k).name;
    fullFileName = fullfile(infiles(k).folder, baseFileName);
    process_file(fullFileName, false);
end