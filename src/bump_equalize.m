function Iout = bump_equalize(I, bgI, upper)
    % For each RGB channels
    Iout = I;
    Iout(:, :, 1) = bump_hist_channel(I(:, :, 1), bgI(:, :, 1), upper);
    Iout(:, :, 2) = bump_hist_channel(I(:, :, 2), bgI(:, :, 2), upper);
    Iout(:, :, 3) = bump_hist_channel(I(:, :, 3), bgI(:, :, 3), upper);
end