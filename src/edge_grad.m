function img = edge_grad(I, thres)
    img = imgradient(I);
    img(img < thres) = 0;
end

