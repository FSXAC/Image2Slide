% https://www.mathworks.com/matlabcentral/answers/70287-to-find-intersection-point-of-two-lines
function [x, y] = intersection(x1, y1, x2, y2)
    p1 = polyfit(x1, y1, 1);
    p2 = polyfit(x2, y2, 1);
    x = fzero(@(x) polyval(p1 - p2, x), 3);
    y = polyval(p1, x);
end
