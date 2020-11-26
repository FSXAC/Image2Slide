% Draw picture with detected lines and intersection points
function draw_detection(img, line_verts, points)
    figure;
    imshow(img);

    hold on
    for k = 1:size(line_verts, 1)
        x1 = line_verts(k, 1, 1);
        x2 = line_verts(k, 1, 2);
        y1 = line_verts(k, 2, 1);
        y2 = line_verts(k, 2, 2);
        plot([x1 x2],[y1 y2],'Color','g','LineWidth', 2);
    end

    for k = 1:size(points, 1)
        plot(points(k, 1), points(k, 2), 'r*');
    end
    hold off
end
