% This function takes the non-zero low end of a histogram and bump it to an
% upper level
function Iout = bump_hist_channel(I, bgI, upper)
    thres_lo = 10;
    thres_hi = 300;
    h = imhist(bgI);
    h = h(2:end);
    for k = 1:size(h, 1)
        if h(k) > thres_hi
            break
        end
    end
    f = (upper - k) / 255 + 1;
    Iout = I .* f;
end