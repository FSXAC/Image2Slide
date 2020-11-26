
% Rectifies the image -- returns the rectified image as well as reference information
function [img_rectified, transformation, ref] = rectify_image(img, control_points, aspect_ratio)
    h = size(img, 1);
    w = aspect_ratio * h;
    C = [0, 0;
        w, 0;
        w, h;
        0, h];

    transformation = fitgeotrans(control_points, C, 'projective');
    [img_rectified, ref] = imwarp(img, transformation);
end
