% 1. Downsample the image
% 2. Do regular edge detection
% 3. resovle the corners to be in normalized coordinates
% 4. return the normalized coordinates in form (0-0, 0-w, h-0, h-w) form
function norm_points = get_corners(I_bw)
    I_edge = edge(I_bw);

    HOUGH_RHO_RES = 1 + floor(max(size(I_bw)) / 1000);
    HOUGH_THETA_RES = 0.2;
    
    [H, T, R] = hough(I_edge, 'RhoResolution', HOUGH_RHO_RES ,'Theta', -90:HOUGH_THETA_RES:89);
%     H = H .^ 2;

    peaks = hough_search(H, 4, 10, 5);
    lines = houghlines(I_bw, T, R, peaks);

    line_verts = hough_lines2verts(lines);
    points = intersection_points(line_verts, I_bw);

    % debug only
    % draw_detection(I_bw, line_verts, points);

    npoints = zeros(size(points));
    npoints(:, 1) = points(:, 1) ./ size(I_bw, 2); % divide by width
    npoints(:, 2) = points(:, 2) ./ size(I_bw, 1); % divide by height

    % Sort the coordinates from top left to bottom right
    tp = npoints - 0.5;
    
    t = zeros([4, 2]);
    for j = 1:size(tp, 1)
        x = tp(j, 1);
        y = tp(j, 2);
        t(j, :) = [atan2(y, x), j];
    end
    idxs = sortrows(t);
    norm_points = npoints;
    for j = 1:size(npoints,1)
        norm_points(j,:) = npoints(idxs(j, 2), :);
    end
end