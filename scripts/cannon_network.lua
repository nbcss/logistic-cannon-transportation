local math2d = require("math2d")

local CannonNetwork = {}

---Represents a cannon network in storage.
---@class CannonNetwork
---@field id string
---@field force LuaForce
---@field surface LuaSurface
---@field signal SignalID?
---@field launchers LauncherStation[]
---@field receivers ReceiverStation[]
---@field launcher_index table<uint64, uint>
---@field receiver_index table<uint64, uint>
---@field launcher_to_receivers table<uint64, table<uint64, ReceiverStation>>
---@field receiver_to_launchers table<uint64, table<uint64, LauncherStation>>
CannonNetwork.prototype = {}
CannonNetwork.prototype.__index = CannonNetwork.prototype

---@param force LuaForce
---@param surface LuaSurface
---@param signal SignalID?
---@return string
local function get_network_id(force, surface, signal)
    local signal_name = ""
    if signal then
        signal_name = "," .. signal.type .. "/" .. signal.name .. ":" .. signal.quality
    end
    return tostring(surface.index) .. "," .. tostring(force.index) .. signal_name
end

function CannonNetwork.on_init()
    ---@type table<string, CannonNetwork?>
    storage.cannon_networks = storage.cannon_networks or {}
end

---@param force LuaForce
---@param surface LuaSurface
---@param signal SignalID?
---@return CannonNetwork
function CannonNetwork.get_or_create(force, surface, signal)
    local network_id = get_network_id(force, surface, signal)
    if storage.cannon_networks[network_id] then
        return storage.cannon_networks[network_id]
    end
    local instance = setmetatable({
        id = network_id,
        force = force,
        surface = surface,
        signal = signal,
        launchers = {},
        receivers = {},
        launcher_index = {},
        receiver_index = {},
        launcher_to_receivers = {},
        receiver_to_launchers = {},
    } --[[@as CannonNetwork]], CannonNetwork.prototype)

    storage.cannon_networks[network_id] = instance
    return instance
end

---Get an iterator over all CannonNetwork's.
---@return fun():CannonNetwork?
function CannonNetwork.all()
    local key = nil
    return function()
        local value
        key, value = next(storage.cannon_networks, key)
        return value
    end
end

---@param receiver ReceiverStation
---@return table<string, ItemWithQualityCount>
local function get_receiver_demand(receiver)
    local request_demands = {}
    for _, request in ipairs(receiver.settings.delivery_requests) do
        local key = request.name .. ":" .. request.quality
        request_demands[key] = { name = request.name, quality = request.quality, count = request.amount }
    end
    for _, item in ipairs(receiver:get_inventory().get_contents()) do
        local key = item.name .. ":" .. item.quality
        local demand = request_demands[key]
        if demand then
            request_demands[key] = demand.count - item.count > 0 and
                { name = item.name, quality = item.quality, count = demand.count - item.count } or nil
        end
    end
    for _, delivery in pairs(receiver.scheduled_deliveries) do
        if delivery:valid() then
            local key = delivery.item .. ":" .. delivery.quality
            local demand = request_demands[key]
            if demand then
                request_demands[key] = demand.count - delivery.amount > 0 and
                    { name = delivery.item, quality = delivery.quality, count = demand.count - delivery.amount } or nil
            end
        end
    end
    return request_demands
end

function CannonNetwork.prototype:update_deliveries(tick)
    if tick % 5 ~= 0 then return end
    -- TODO optimize
    for _, launcher in ipairs(self.launchers) do
        if launcher:update_state() then
            self:update_launcher_connections(launcher)
        end
    end
    for _, receiver in ipairs(self.receivers) do
        if not receiver:valid() then goto next_receiver end

        local empty_slots = receiver:get_inventory().count_empty_stacks(false, false)
        if empty_slots <= 0 then goto next_receiver end

        local demands = get_receiver_demand(receiver)
        for _, demand in pairs(demands) do
            local item = { name = demand.name, quality = demand.quality }
            for _, launcher in pairs(self.receiver_to_launchers[receiver:id()]) do
                if launcher:valid() and launcher:is_ready(receiver:position()) then
                    local payload_size = launcher:get_max_payload_size()
                    if payload_size <= empty_slots then
                        local delivery = launcher:schedule_delivery(receiver, item, demand.count)
                        if delivery then
                            receiver:add_delivery(delivery)
                            demand.count = demand.count - delivery.amount
                            empty_slots = empty_slots - payload_size
                            if empty_slots <= 0 then goto next_receiver end
                            if demand.count <= 0 then goto next_demand_item end
                        end
                    end
                end
            end
            ::next_demand_item::
        end
        ::next_receiver::
    end
end

---@param launcher LauncherStation
function CannonNetwork.prototype:update_launcher_connections(launcher)
    if not self.launcher_index[launcher:id()] or not launcher:valid() then return end
    local receivers_in_range = self.launcher_to_receivers[launcher:id()]
    for receiver_id, _ in pairs(receivers_in_range) do
        self.receiver_to_launchers[receiver_id][launcher:id()] = nil
    end
    self.launcher_to_receivers[launcher:id()] = {}
    local maximum_range = launcher:get_max_range()
    if maximum_range > 0 then
        for _, receiver in ipairs(self.receivers) do
            if receiver:valid() then
                local d = math2d.position.distance(receiver:position(), launcher:position())
                if d <= maximum_range then
                    self.launcher_to_receivers[launcher:id()][receiver:id()] = receiver
                    self.receiver_to_launchers[receiver:id()][launcher:id()] = launcher
                end
            else
                game.print("Invalid receiver: " .. receiver:id()) -- debug
            end
        end
    end
end

---@param receiver ReceiverStation
function CannonNetwork.prototype:update_receiver_connections(receiver)
    if not self.receiver_index[receiver:id()] or not receiver:valid() then return end
    local launchers_in_range = self.receiver_to_launchers[receiver:id()]
    for launcher_id, _ in pairs(launchers_in_range) do
        self.launcher_to_receivers[launcher_id][receiver:id()] = nil
    end
    self.receiver_to_launchers[receiver:id()] = {}
    for _, launcher in ipairs(self.launchers) do
        if launcher:valid() then
            local maximum_range = launcher:get_max_range()
            if maximum_range > 0 then
                local d = math2d.position.distance(receiver:position(), launcher:position())
                if d <= maximum_range then
                    self.launcher_to_receivers[launcher:id()][receiver:id()] = receiver
                    self.receiver_to_launchers[receiver:id()][launcher:id()] = launcher
                end
            end
        else
            game.print("Invalid launcher: " .. launcher:id()) -- debug
        end
    end
end

---@param launcher LauncherStation
function CannonNetwork.prototype:add_launcher(launcher)
    if not launcher:valid() or self.launcher_index[launcher:id()] then return end
    table.insert(self.launchers, launcher)
    self.launcher_index[launcher:id()] = #self.launchers
    self.launcher_to_receivers[launcher:id()] = {}
    self:update_launcher_connections(launcher)
end

---@param receiver ReceiverStation
function CannonNetwork.prototype:add_receiver(receiver)
    if not receiver:valid() or self.receiver_index[receiver:id()] then return end
    table.insert(self.receivers, receiver)
    self.receiver_index[receiver:id()] = #self.receivers
    self.receiver_to_launchers[receiver:id()] = {}
    self:update_receiver_connections(receiver)
end

function CannonNetwork.prototype:destroy_if_empty()
    if #self.receivers == 0 and #self.launchers == 0 then
        storage.cannon_networks[self.id] = nil
    end
end

---@param launcher_id uint64
function CannonNetwork.prototype:remove_launcher(launcher_id)
    if not self.launcher_index[launcher_id] then return end
    -- delete connections
    local receivers_in_range = self.launcher_to_receivers[launcher_id]
    for receiver_id, _ in pairs(receivers_in_range) do
        self.receiver_to_launchers[receiver_id][launcher_id] = nil
    end
    self.launcher_to_receivers[launcher_id] = nil
    -- swap with last & remove from storage
    local index = self.launcher_index[launcher_id]
    if index < #self.launchers then
        self.launchers[index] = self.launchers[#self.launchers]
        self.launcher_index[self.launchers[index]:id()] = index
    end
    table.remove(self.launchers)
    self.launcher_index[launcher_id] = nil
    self:destroy_if_empty()
end

---@param receiver_id uint64
function CannonNetwork.prototype:remove_receiver(receiver_id)
    if not self.receiver_index[receiver_id] then return end
    -- delete connections
    local launchers_in_range = self.receiver_to_launchers[receiver_id]
    for launcher_id, _ in pairs(launchers_in_range) do
        self.launcher_to_receivers[launcher_id][receiver_id] = nil
    end
    self.receiver_to_launchers[receiver_id] = nil
    -- swap with last & remove from storage
    local index = self.receiver_index[receiver_id]
    if index < #self.receivers then
        self.receivers[index] = self.receivers[#self.receivers]
        self.receiver_index[self.receivers[index]:id()] = index
    end
    table.remove(self.receivers)
    self.receiver_index[receiver_id] = nil
    self:destroy_if_empty()
end

return CannonNetwork
