function [img, thres] = binaryImage1(I)
    [c, p] = imhist(I, 16);
    cs = sort(c, 'descend');
    m1 = cs(1);
    m2 = cs(2);
    i1 = c == m1;
    i2 = c == m2;
    t1 = p(i1);
    t2 = p(i2);
    thres = (t1 + t2) / 2 / 256;
    img = uint8(imbinarize(I, thres) * 255);
end

