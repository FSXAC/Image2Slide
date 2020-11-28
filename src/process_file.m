% process a single input input image

function process_file(input_file, ds1, ds2, alpha)
    [~, infile, ~] = fileparts(input_file);


    img = imread(input_file);
    low_img_h = round(size(img, 1) * ds1);
    low_img_h2 = round(size(img, 1) * ds2);
    img_xs = imresize(img, [low_img_h, NaN]);

    % to greyscale for boundary detection
    img_bw = uint8(rgb2gray(img_xs));
    npoints = get_corners(img_bw);
    points = zeros(size(npoints));
    points(:, 1) = npoints(:, 1) .* size(img, 2);
    points(:, 2) = npoints(:, 2) .* size(img, 1);

    % rectify image
    [img_rectified, transformation, ref] = rectify_image(img, points, 4/3);

    % crop
    img_cropped = crop2doc(img_rectified, transformation, ref, points);

    % document segmentation
    img_cropped_grey = rgb2gray(img_cropped);
    img_doc = imbinarize(img_cropped_grey);
%     img_doc = imadjust(img_cropped_grey);
%     img_doc = imbinarize(img_doc, 'adaptive', 'Sensitivity', 0.67, 'ForegroundPolarity', 'bright');
%     img_doc = imclose(img_doc, strel('disk', 6, 0));

    img_doc_xs = imresize(img_doc, [low_img_h2 NaN]);
    img_cropped_xs = imresize(img_cropped, [low_img_h2 NaN]);

    % equalize histogram
    img_bg_seg = repmat(uint8(img_doc_xs), 1, 1, 3) .* img_cropped_xs;
    img_cropped_c = bump_equalize(double(img_cropped), img_bg_seg, 240);

    % boost contrast
    img_cropped_c = img_cropped_c .* 2.0 - 255;
    img_boosted = img_cropped_c + (img_doc - 0.01) * 255;

    % ROI
    doc_roi = imdilate(imclearborder(imcomplement(img_doc_xs)), strel('rectangle', [4 15]));
%     doc_roi = imclearborder(imcomplement(imerode(img_doc_xs, strel('rectangle', [4 15]))));
    doc_rp = regionprops(doc_roi);
    bboxes = [doc_rp.BoundingBox];
    doc_bbox_xs = reshape(bboxes, 4, size(bboxes, 2) / 4);
    doc_bbox_xs = doc_bbox_xs';
    doc_bbox_n = doc_bbox_xs ./ size(img_doc_xs, 1);
    doc_bbox = doc_bbox_n .* size(img_boosted, 1);

    % Save ROI and metadata
    for k = 1:size(doc_bbox, 1)
        subimg = imcrop(img_boosted, doc_bbox(k, :));
        submask = 255 .* uint8(imcrop(1 - img_doc, doc_bbox(k, :)));
        foldername = append('output/', infile, '/');
        fname = append(foldername, string(k), '.png');
        if ~exist(foldername)
            mkdir(foldername)
        end
        if (alpha)
            imwrite(subimg, fname, 'png', 'Alpha', submask);
        else
            imwrite(subimg, fname);
        end
    end
    writematrix(doc_bbox_n, append('output/', infile, '/', 'meta.csv'));

    % Save processed file as bg
    imwrite(img_boosted, append('output/', infile, '/bg.jpg'));
end