from PIL import Image
import argparse


def parse_args():
    parser = argparse.ArgumentParser(description="Tile cropped PNGs into a grid.")
    parser.add_argument('images', nargs='+', help='Input PNG files')
    parser.add_argument('--columns', type=int, required=True, help='Number of columns in the output grid')
    parser.add_argument('--output', type=str, required=True, help='Output file (without extension)')
    parser.add_argument('--rows-per-output', type=int, default=None, help='Produce multiple output images with a number of rows each')
    return parser.parse_args()


def alpha_threshold(img: Image, thresh: int):
    alpha = img.getchannel('A').point(lambda x: x if x >= thresh else 0)
    img.putalpha(alpha)


def union_bbox(bboxes):
    x0 = min(b[0] for b in bboxes)
    y0 = min(b[1] for b in bboxes)
    x1 = max(b[2] for b in bboxes)
    y1 = max(b[3] for b in bboxes)
    return (x0, y0, x1, y1)


def main():
    args = parse_args()
    images = [Image.open(f) for f in args.images]
    size = images[0].size
    for img in images:
        assert img.size == size, "All images must be the same size."
        alpha_threshold(img, 16)

    bboxes = [img.getbbox() for img in images]
    union = union_bbox(bboxes)
    crop_size = (union[2] - union[0], union[3] - union[1])

    n = len(images)
    cols = args.columns
    rows_total = (n + cols - 1) // cols
    rows_per_output = args.rows_per_output or rows_total
    n_outputs = (rows_total + rows_per_output - 1) // rows_per_output

    out_file_suffixes = [f"-{i:0{len(str(n_outputs-1))}d}" for i in range(n_outputs)] if args.rows_per_output else None
    
    for out_idx in range(n_outputs):
        out_img = Image.new('RGBA', (cols * crop_size[0], rows_per_output * crop_size[1]), (0, 0, 0, 0))
        for idx, img in enumerate(images):
            row = idx // cols
            col = idx % cols
            out_img.paste(img.crop(union), (col * crop_size[0], row * crop_size[1]))

        out_file_name = f"{args.output}{out_file_suffixes[out_idx] if out_file_suffixes else ""}.png"
        out_img.save(out_file_name)
        print(f"Saved {out_file_name}")

    with open(f"{args.output}.lua", "w") as out_lua:
        # Generate Lua file to be used by util.
        sprite_data = {
            "filenames": '{' + ', '.join([f"\"{a}.png\"" for a in out_file_suffixes]) + '}' if out_file_suffixes else None,
            "width": crop_size[0],
            "height": crop_size[1],
            "line_length": cols if rows_total > 1 else None,
            "lines_per_file": rows_total if out_file_suffixes else None,
            "shift": f"util.by_pixel({-(union[0] + union[2] - size[0]) / 2}, {-(union[1] + union[3] - size[1]) / 2})",
        }
        out_lua.write("local util = require(\"util\")\nreturn {\n")
        for k, v in sprite_data.items():
            if v != None:
                out_lua.write(f"    {k} = {v},\n")
        out_lua.write("}\n")

if __name__ == '__main__':
    main()
