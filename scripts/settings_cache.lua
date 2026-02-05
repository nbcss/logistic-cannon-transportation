local settings_cache = {}

---@type table<string, boolean|string|number|Color>
settings_cache.global = setmetatable({}, {
    __index = function(t, k)
        local value = settings.global[k].value
        t[k] = value
        return value
    end
})

---@type table<string, boolean|string|number|Color>
settings_cache.startup = setmetatable({}, {
    __index = function(t, k)
        local value = settings.startup[k].value
        t[k] = value
        return value
    end
})

---@param event EventData.on_runtime_mod_setting_changed
function settings_cache.on_runtime_mod_setting_changed(event)
    if event.setting_type == "runtime-global" then
        settings_cache.global[event.setting] = nil
    end
end

return settings_cache