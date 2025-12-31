local constants = {}

-- base
constants.mod_name = "logistic-cannon-transportation"
constants.name_prefix = "logistic-cannon-"
constants.ammo_category = "logistic-cannon-capsule"
constants.item_subgroup = "cannon-transport"
constants.gui_tag_event_handlers = constants.name_prefix.."event-handlers"
-- settings
constants.update_interval_setting = constants.name_prefix.."update-interval"
-- bonus effect
constants.range_upgrade_bonus = "logistic-cannon-launcher-range-bonus"
-- data
constants.data_capsule_properties = constants.name_prefix .. "capsule-properties"
constants.data_projectile_properties = constants.name_prefix .. "projectile-properties"
constants.data_launcher_properties = constants.name_prefix .. "launcher-properties"
-- target
constants.entity_target = constants.name_prefix.."target"
-- capsule
constants.item_capsule_basic = "logistic-cannon-capsule-basic"
-- launcher
constants.item_launcher = constants.name_prefix.."launcher"
constants.entity_launcher_inventory = constants.item_launcher
constants.entity_launcher_placement = constants.name_prefix.."launcher-placement"
constants.entity_launcher_turret = constants.name_prefix.."launcher-turret"
constants.entity_launcher_energy_interface = constants.name_prefix.."launcher-energy-interface"
constants.entity_launcher_gui_proxy = constants.name_prefix.."launcher-proxy"
-- receiver
constants.item_receiver = constants.name_prefix.."receiver"
constants.entity_receiver_inventory = constants.item_receiver
constants.entity_receiver_gui_proxy = constants.name_prefix.."receiver-proxy"

return constants