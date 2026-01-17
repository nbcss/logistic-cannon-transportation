local util = require("util")
return {
    filenames = {"-0.png", "-1.png", "-2.png", "-3.png"},
    width = 408,
    height = 242,
    line_length = 4,
    lines_per_file = 16,
    shift = util.by_pixel(147.0, 30.0),
}
