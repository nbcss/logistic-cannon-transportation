local constants = {}

constants.mod_name = "logistic-cannon-transportation"
constants.name_prefix = "logistic-cannon-"
constants.gui_tag_event_handlers = constants.name_prefix.."event-handlers"
-- settings
constants.update_interval_setting = constants.name_prefix.."update-interval"
-- bonus effect
constants.range_upgrade_bonus = "logistic-cannon-launcher-range-bonus"

-- item/entity
constants.entity_launcher = constants.name_prefix.."launcher"
constants.entity_launcher_entity = constants.name_prefix.."launcher-entity"
constants.entity_receiver = constants.name_prefix.."receiver"
constants.entity_receiver_entity = constants.name_prefix.."receiver-entity"

return constants