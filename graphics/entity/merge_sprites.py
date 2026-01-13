from PIL import Image
import sys
import math

# Parse args
if len(sys.argv) != 5:
    raise
x_count = int(sys.argv[1])
y_count = int(sys.argv[2])
input_filename = sys.argv[3]
output_filename = sys.argv[4]


result = None
frame_size = None

for xi in range(x_count):
    for yi in range(y_count):
        path = input_filename.replace('#', str(yi * x_count + xi).rjust(3, '0'))
        image = Image.open(path)

        # Create output canvas, assume all images have the same height
        if not result:
            result = Image.new("RGBA", (image.width * x_count, image.height * y_count))
            frame_size = (image.width, image.height)

        # Paste image
        result.paste(image, (frame_size[0] * xi, frame_size[1] * yi))

result.save(output_filename)