function points = intersection_points(line_verts, img)
    points = [];
    index_opts = nchoosek(1:4, 2);
    for i = 1:size(index_opts, 1)
        l1_idx = index_opts(i, 1);
        l2_idx = index_opts(i, 2);
        
        x1 = line_verts(l1_idx,1,:);
        y1 = line_verts(l1_idx,2,:);
        x2 = line_verts(l2_idx,1,:);
        y2 = line_verts(l2_idx,2,:);
        
        [x_i, y_i] = intersection(x1, y1, x2, y2);
        
        % discard points outside of image
        if x_i < 0 || x_i > size(img, 2) || y_i < 0 || y_i > size(img, 1)
            continue
        end

        points = [points; x_i y_i];
    end
end


