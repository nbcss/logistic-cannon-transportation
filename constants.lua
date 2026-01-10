local constants = {}

-- base
constants.mod_name = "logistic-cannon-transportation"
constants.name_prefix = "logistic-cannon-"
constants.ammo_category = "logistic-cannon-capsule"
constants.item_subgroup = "cannon-transport"
constants.gui_tag_event_handlers = constants.name_prefix.."event-handlers"
constants.rotate_input_event = "lct-rotate-entity-action"
constants.reverse_rotate_input_event = "lct-reverse-rotate-entity-action"
constants.capsule_launched_effect_id = "lct-capsule-launched"
constants.capsule_landed_effect_id = "lct-capsule-landed"
-- settings
constants.update_interval_setting = constants.name_prefix.."update-interval"
-- bonus effect
constants.range_upgrade_bonus = "lct-launcher-range-bonus"
constants.energy_capacity_modifier = "lct-launcher-energy-capacity-modifier"
constants.energy_consumption_modifier = "lct-launcher-energy-consumption-modifier"
-- data
constants.data_capsule_properties = constants.name_prefix .. "capsule-properties"
constants.data_launcher_properties = constants.name_prefix .. "launcher-properties"
-- capsule
constants.item_capsule_basic = "logistic-cannon-capsule-basic"
constants.item_capsule_reinforced = "logistic-cannon-capsule-reinforced"
constants.item_capsule_propelled = "logistic-cannon-capsule-propelled"
-- launcher
constants.item_launcher = constants.name_prefix.."launcher"
constants.entity_launcher_inventory = constants.item_launcher
constants.entity_launcher_turret = constants.name_prefix.."launcher-turret"
constants.entity_launcher_energy_interface = constants.name_prefix.."launcher-energy-interface"
constants.entity_launcher_ammo_proxy = constants.name_prefix.."launcher-ammo-proxy"
constants.entity_launcher_gui_proxy = constants.name_prefix.."launcher-gui-proxy"
-- receiver
constants.item_receiver = constants.name_prefix.."receiver"
constants.entity_receiver_inventory = constants.item_receiver
constants.entity_receiver_gui_proxy = constants.name_prefix.."receiver-gui-proxy"
-- other entities
constants.entity_target = constants.name_prefix.."target"
constants.entity_tracker = "logistic-cannon-capsule-tracker"
constants.entity_capsule_container = "cannon-capsule-storage"

return constants