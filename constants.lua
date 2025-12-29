local constants = {}

constants.mod_name = "logistic-cannon-transportation"
constants.name_prefix = "logistic-cannon-"
constants.gui_tag_event_handlers = constants.name_prefix.."event-handlers"
-- settings
constants.update_interval_setting = constants.name_prefix.."update-interval"
-- bonus effect
constants.range_upgrade_bonus = "logistic-cannon-launcher-range-bonus"

constants.entity_target = constants.name_prefix.."target"
-- item/entity
constants.entity_launcher = constants.name_prefix.."launcher"
constants.entity_launcher_placement = constants.name_prefix.."launcher-placement"
constants.entity_launcher_inventory = constants.name_prefix.."launcher-inventory"
constants.entity_launcher_turret = constants.name_prefix.."launcher-turret"
constants.entity_launcher_gui_proxy = constants.name_prefix.."launcher-proxy"
constants.entity_launcher_energy_interface = constants.name_prefix.."launcher-energy-interface"
constants.entity_launcher_entity = constants.name_prefix.."launcher-entity"
constants.entity_receiver = constants.name_prefix.."receiver"
constants.entity_receiver_entity = constants.name_prefix.."receiver-entity"

return constants