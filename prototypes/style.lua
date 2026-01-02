local styles = data.raw["gui-style"].default

styles["lct_config_frame"] = {
    type = "frame_style",
    minimal_width = 300,
    natural_width = 300,
}

styles["lct_player_input"] = {
    type = "horizontal_flow_style",
    minimal_height = 20,
    horizontal_spacing = 4,
    vertical_align = "center",
}

styles["lct_subheader_frame"] = {
    type = "frame_style",
    parent = "subheader_frame",
    top_margin = -12,
    left_margin = -12,
    right_margin = -12,
    bottom_margin = 8,
    horizontally_stretchable = "on",
    horizontally_squashable = "on",
}

styles["lct_energy_bar"] = {
    type = "progressbar_style",
    height = 24,
    bar_width = 24,
    font_color = {0.8, 0.8, 0.8},
    filled_font_color = {0, 0, 0},
    horizontally_stretchable = "on",
    horizontally_squashable = "on",
    vertical_align = "center",
}