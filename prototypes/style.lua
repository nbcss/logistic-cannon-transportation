local styles = data.raw["gui-style"].default

styles["lct_config_frame"] = {
    type = "frame_style",
    minimal_width = 320,
    natural_width = 320,
    vertical_flow_style = {
        type = "vertical_flow_style",
        vertical_spacing = 8,
    }
}

styles["lct_request_shallow_scroll"] = {
    type = "scroll_pane_style",
    parent = "shallow_scroll_pane",
    horizontally_stretchable = "on",
    vertical_stretchable = "on",
    scrollbars_go_outside = false,
    always_draw_borders = false,
    dont_force_clipping_rect_for_contents = false,
    left_margin = -12,
    bottom_margin = -12,
    right_margin = -12,
    top_padding = 4,
    bottom_padding = 8,
    right_padding = 4,
    left_padding = 12,
    extra_right_padding_when_activated = -4,
    vertical_flow_style = {
        type = "vertical_flow_style",
        right_padding = 10,
    }
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
    bottom_margin = 5,
    horizontally_stretchable = "on",
    horizontally_squashable = "on",
}

styles["lct_configuration_deep_frame"] = {
    type = "frame_style",
    parent = "deep_frame_in_shallow_frame",
    vertical_flow_style = {
        type = "vertical_flow_style",
        vertical_spacing = 4,
    },
    left_margin = -12,
    right_margin = -12,
    top_margin = -2,
    bottom_margin = -2,
    left_padding = 12,
    right_padding = 12,
    top_padding = 2,
    bottom_padding = 6,
    horizontally_stretchable = "on",
}

styles["lct_configuration_select_button"] = {
    type = "button_style",
    parent = "mini_button_aligned_to_text_vertically_when_centered",
}

styles["lct_configuration_confirm_button"] = {
    type = "button_style",
    parent = "green_button",
    padding = 0,
    size = 16,
    top_margin = 1,
    invert_colors_of_picture_when_disabled = true,
    tooltip = "",
}

styles["lct_overlay_progressbar_flow"] = {
    type = "vertical_flow_style",
    vertical_spacing = 0,
}

styles["lct_overlay_progressbar_base"] = {
    type = "progressbar_style",
    horizontally_stretchable = "on",
    bar_width = 8,
}

styles["lct_overlay_progressbar_top"] = {
    type = "progressbar_style",
    horizontally_stretchable = "on",
    bar_width = 8,
    top_margin = -8,
    bar_background = {},
}

styles["lct_energy_bar"] = {
    type = "progressbar_style",
    height = 24,
    bar_width = 24,
    font_color = { 0.9, 0.9, 0.9 },
    filled_font_color = { 0, 0, 0 },
    horizontally_stretchable = "on",
    horizontally_squashable = "on",
    embed_text_in_bar = true,
}
