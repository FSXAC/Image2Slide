## Identifying a Document/Rectangle from a Scene

[Microsoft Research](https://www.microsoft.com/en-us/research/publication/whiteboard-scanning-image-enhancement/) shows a way to use Hough transfer to perform inverse transformation on the image to rectify the rectangle. They use a **Sobel filter** to extract edge information. Depending on the image, using **gradient** of the image shows more lines, but also creates more unecessary data in the Hough transform domain. I found more success if I make the image into a binary image first.

My initial process is:

1. Pre-process the image (manipulation of the histogram or binarize the image)
2. Edge extraction
3. Hough transform
4. Extract line segments

## Image Preprocessing

To perform line hough transform, we need to ensure that the document edges make up the dominant line geometry in the image. In the *ikea.jpg* this is a challenging picture because there is stripes on my shirt, and the brightness of my shirt matches with the paper which makes it difficult to segment.

