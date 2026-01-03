local styles = data.raw["gui-style"].default

styles["lct_config_frame"] = {
    type = "frame_style",
    minimal_width = 300,
    natural_width = 300,
    vertical_flow_style = {
        type = "vertical_flow_style",
        vertical_spacing = 8,
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

styles["lct_configuration_select_button"] = {
    type = "button_style",
    parent = "mini_button_aligned_to_text_vertically_when_centered",
    tooltip = nil,
}

styles["lct_configuration_confirm_button"] = {
    type = "button_style",
    parent = "button",
    default_graphical_set = {
        base = { position = { 68, 17 }, corner_size = 8 },
        shadow = styles.default_dirt--[[@as data.ElementImageSetLayer]]
    },
    hovered_graphical_set = {
        base = { position = { 102, 17 }, corner_size = 8 },
        shadow = styles.default_dirt--[[@as data.ElementImageSetLayer]],
        glow = {
            position = { 200, 128 },
            corner_size = 8,
            tint = { 135, 216, 139, 128 },
            scale = 0.5,
            draw_type = "outer"
        }
    },
    clicked_graphical_set = {
        base = { position = { 119, 17 }, corner_size = 8 },
        shadow = styles.default_dirt--[[@as data.ElementImageSetLayer]]
    },
    disabled_graphical_set = {
        base = { position = { 85, 17 }, corner_size = 8 },
        shadow = styles.default_dirt--[[@as data.ElementImageSetLayer]]
    },
    left_click_sound = "__core__/sound/gui-green-confirm.ogg",
    padding = 0,
    size = 16,
    top_margin = 1,
    invert_colors_of_picture_when_disabled = true,
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
