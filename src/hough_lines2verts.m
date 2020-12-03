% This function finds the lines in spatial/px coordinates from hough lines
function line_verts = hough_lines2verts(lines)
    line_verts = zeros(4, 2, 2);

    for k = 1:numel(lines)
        x1 = lines(k).point1(1);
        y1 = lines(k).point1(2);
        x2 = lines(k).point2(1);
        y2 = lines(k).point2(2);

        if x1 == x2
            x1 = x1 + 0.1;
        end
        
        line_verts(k,1,:) = [x1 x2];
        line_verts(k,2,:) = [y1 y2];
    end
end

