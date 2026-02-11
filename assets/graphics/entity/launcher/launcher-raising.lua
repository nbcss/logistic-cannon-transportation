local util = require("util")
return {
    filenames = {"-0.png", "-1.png", "-2.png", "-3.png"},
    width = 340,
    height = 288,
    line_length = 4,
    lines_per_file = 16,
    shift = util.by_pixel(0.0, -74.0),
}
