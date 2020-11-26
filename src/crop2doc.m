
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