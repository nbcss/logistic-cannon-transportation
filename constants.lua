local constants = {}

-- base
constants.ammo_category = "lct-capsule"
constants.highlight_box = "lct-highlight-box"
constants.negative_font = "lct-negative-effect"
constants.item_subgroup = "lct-cannon-transport"
constants.rotate_input_event = "lct-rotate-entity-action"
constants.reverse_rotate_input_event = "lct-reverse-rotate-entity-action"
constants.capsule_launched_effect_id = "lct-capsule-launched"
constants.capsule_landed_effect_id = "lct-capsule-landed"
constants.capsule_projectile_format = "%s-projectile-%s"
-- settings
constants.setting_coloring_projectile_smoke = "lct-coloring-projectile-smoke"
constants.setting_capsule_consumption_mode = "lct-capsule-consumption-mode"
constants.setting_se_allow_in_space = "lct-se-allow-in-space"
constants.setting_entity_update_interval = "lct-entity-update-interval"
constants.setting_gui_update_interval = "lct-gui-update-interval"
constants.setting_default_launcher_auto_load = "lct-default-launcher-auto-load-setting"
constants.setting_default_launcher_side_load = "lct-default-launcher-side-load-setting"
constants.setting_range_visualization_mode = "lct-range-visualization-mode"
constants.setting_launcher_base_range = "lct-launcher-base-range"
constants.setting_launcher_base_consumption = "lct-launcher-base-consumption"
-- bonus effect
constants.range_upgrade_bonus = "lct-launcher-range-bonus"
constants.energy_capacity_modifier = "lct-launcher-energy-capacity-modifier"
constants.energy_consumption_modifier = "lct-launcher-energy-consumption-modifier"
-- data
constants.data_capsule_properties = "lct-capsule-properties"
constants.data_launcher_properties = "lct-launcher-properties"
constants.data_receiver_properties = "lct-receiver-properties"
-- capsule
constants.item_capsule_basic = "lct-capsule-basic"
constants.item_capsule_reinforced = "lct-capsule-reinforced"
constants.item_capsule_propelled = "lct-capsule-propelled"
constants.item_capsules = {
    constants.item_capsule_basic,
    constants.item_capsule_reinforced,
    constants.item_capsule_propelled,
}
-- launcher
constants.item_launcher = "lct-launcher"
constants.entity_launcher_inventory = constants.item_launcher
constants.entity_launcher_turret = "lct-launcher-turret"
constants.entity_launcher_base = "lct-launcher-base"
constants.entity_launcher_energy_interface = "lct-launcher-energy-interface"
constants.entity_launcher_ammo_proxy = "lct-launcher-ammo-proxy"
constants.entity_launcher_gui_proxy = "lct-launcher-gui-proxy"
-- receiver
constants.item_receiver = "lct-receiver"
constants.entity_receiver_inventory = constants.item_receiver
constants.entity_receiver_gui_proxy = "lct-receiver-gui-proxy"
-- small receiver
constants.item_receiver_small = "lct-receiver-small"
constants.entity_receiver_small_inventory = constants.item_receiver_small
constants.entity_receiver_small_gui_proxy = "lct-receiver-small-gui-proxy"
-- other entities
constants.entity_target = "lct-cannon-target"
constants.entity_proxy_connector = "lct-proxy-connector"
constants.entity_tracker = "lct-capsule-tracker"
constants.entity_capsule_inventory = "lct-capsule-inventory"
-- GUI
constants.gui_tag_event_handlers = "lct-event-handlers"
constants.gui_tag_tracked_hover_state = "lct-tracked-hover-state"
-- other
constants.capsule_landed_sound = "lct-capsule-landed-sound"
constants.capsule_no_consumption_energy_modifier = 2.5
constants.out_of_map_position = { x = 1025914, y = -895124 }

return constants