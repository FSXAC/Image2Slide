function points = hough_search(H, n, max_epoch, dilate_factor)
    ratio_hi = 1.0;
    ratio_lo = 0.0;
    epoch = 0;

    while epoch < max_epoch
        ratio = (ratio_hi - ratio_lo) / 2 + ratio_lo;

        mask = H > ratio * max(H(:));
        mask = bwmorph(mask, 'dilate', dilate_factor);
        mask = bwmorph(mask, 'shrink', Inf);
        mask = double(mask);

        [r_idx, t_idx] = find(mask);
        points = [r_idx, t_idx];

        if size(points, 1) > n
            ratio_lo = ratio;
        elseif size(points, 1) < n
            ratio_hi = ratio;
        else
            break
        end
        
        epoch = epoch + 1;
    end
    
    if epoch >= max_epoch
        error('Max epoch too low');
    end
end

