% get RGB histogram
function [r, g, b] = rgbhist(img)
    r = imhist(img(:, :, 1));
    g = imhist(img(:, :, 2));
    b = imhist(img(:, :, 3));
    figure;
    plot(r, 'r');
    hold on
    plot(g, 'g');
    plot(b, 'b');
    hold off
end