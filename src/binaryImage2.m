function [img, thres] = binaryImage2(I)
    [c, p] = imhist(I, 16);
    c(1:8) = 0;
    cs = sort(c, 'descend');
    m = max(cs);
    i = c == m;
    t = p(i);
    thres = 0.8 * t / 256;
    img = uint8(imbinarize(I, thres) * 255);
end