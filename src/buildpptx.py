from pptx import Presentation
from pptx.util import Inches

p = Presentation()

TITLE_LAYOUT = p.slide_layouts[0]
CONTENT_LAYOUT = p.slide_layouts[8]

slide = p.slides.add_slide(TITLE_LAYOUT)
title = slide.shapes.title
subtitle = slide.placeholders[1]

title.text = 'Hello world'
subtitle.text = 'EECE 570 Project Report'

# ==

# slide = p.slides.add_slide(CONTENT_LAYOUT)
# title = slide.shapes.title
# title.text = 'Image'
# pic = slide.shapes.add_picture('./src/img/ipad.jpg', Inches(0), Inches(0), width=Inches(10), height=Inches(7.5))

# ==

# Takes all the images in output folder and sticks them together



p.save('test.pptx')