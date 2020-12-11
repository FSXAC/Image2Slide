# EECE 570 (Computer Vision) Project

This project involves scanning of document/writeboards

## Requirement

- MATLAB (tested versio 2020b)
- Python 3.6+
  - pip3
  - pipenv
  - python-pptx

To setup the Python environment, follow:

- Inside the src folder, do `pipenv install` to install
- and then `pipenv shell` to go into environment shell

## Usage

There are two components to this project: one is converting input images to a set of region subimages and metadata and the second is taking that output and export a single .pptx file.

1. Launch MATLAB and set `src/` as working directory
2. Copy input images into `input/` (a set of images is already there that you may use)
3. Run `main.m`
4. Run `buildpptx.py` using Python 3.
5. If successful, the file will be outputed as `test.pptx` in the directory above the `src/` directory.

**Note**: not all `.m` files are used
