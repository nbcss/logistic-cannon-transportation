local constants = {}

-- base
constants.mod_name = "logistic-cannon-transportation"
constants.ammo_category = "lct-capsule"
constants.item_subgroup = "cannon-transport"
constants.rotate_input_event = "lct-rotate-entity-action"
constants.reverse_rotate_input_event = "lct-reverse-rotate-entity-action"
constants.capsule_launched_effect_id = "lct-capsule-launched"
constants.capsule_landed_effect_id = "lct-capsule-landed"
constants.capsule_projectile_format = "%s-projectile-%s"
-- settings
constants.coloring_projectile_smoke = "lct-coloring-projectile-smoke"
constants.entity_update_interval_setting = "lct-entity-update-interval"
constants.gui_update_interval_setting = "lct-gui-update-interval"
constants.range_visualization_mode = "lct-range-visualization-mode"
-- bonus effect
constants.range_upgrade_bonus = "lct-launcher-range-bonus"
constants.energy_capacity_modifier = "lct-launcher-energy-capacity-modifier"
constants.energy_consumption_modifier = "lct-launcher-energy-consumption-modifier"
-- data
constants.data_capsule_properties = "lct-capsule-properties"
constants.data_launcher_properties = "lct-launcher-properties"
-- capsule
constants.item_capsule_basic = "lct-capsule-basic"
constants.item_capsule_reinforced = "lct-capsule-reinforced"
constants.item_capsule_propelled = "lct-capsule-propelled"
-- launcher
constants.item_launcher = "lct-launcher"
constants.entity_launcher_inventory = constants.item_launcher
constants.entity_launcher_turret = "lct-launcher-turret"
constants.entity_launcher_energy_interface = "lct-launcher-energy-interface"
constants.entity_launcher_ammo_proxy = "lct-launcher-ammo-proxy"
constants.entity_launcher_gui_proxy = "lct-launcher-gui-proxy"
-- receiver
constants.item_receiver = "lct-receiver"
constants.entity_receiver_inventory = constants.item_receiver
constants.entity_receiver_gui_proxy = "lct-receiver-gui-proxy"
-- other entities
constants.entity_target = "lct-cannon-target"
constants.entity_proxy_connector = "lct-proxy-connector"
constants.entity_tracker = "lct-capsule-tracker"
constants.entity_capsule_inventory = "lct-capsule-inventory"
-- GUI
constants.gui_launcher = "lct-launcher-gui"
constants.gui_receiver = "lct-receiver-gui"
constants.gui_tag_event_handlers = "lct-event-handlers"

return constants