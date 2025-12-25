local math2d = require("math2d")
local constants = require("constants")
local BucketSet = require("scripts.bucket_set")

local CannonNetwork = {}

---Represents a cannon network in storage.
---@class CannonNetwork
---@field id string
---@field force LuaForce
---@field surface LuaSurface
---@field signal SignalID?
---@field launchers BucketSet<LauncherStation>
---@field receivers BucketSet<ReceiverStation>
---@field launcher_to_receivers table<uint64, table<uint64, ReceiverStation>>
---@field receiver_to_launchers table<uint64, table<uint64, LauncherStation>>
---@field launcher_to_items table<uint64, table<string, ItemWithQualityCount>> -- launcher id to encoded item name set
---@field item_to_launchers table<string, table<uint64, LauncherStation>> -- encoded item name to set of launchers
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

function CannonNetwork.resize_buckets()
    for network in CannonNetwork.all() do
        -- resize launchers
        local launchers = BucketSet.new(settings.global[constants.update_interval_setting].value)
        for launcher in network.launchers:all() do
            launchers:put(launcher:id(), launcher)
        end
        network.launchers = launchers
        -- resize receivers
        local receivers = BucketSet.new(settings.global[constants.update_interval_setting].value)
        for receiver in network.receivers:all() do
            receivers:put(receiver:id(), receiver)
        end
        network.receivers = receivers
    end
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
        launchers = BucketSet.new(settings.global[constants.update_interval_setting].value),
        receivers = BucketSet.new(settings.global[constants.update_interval_setting].value),
        launcher_to_receivers = {},
        receiver_to_launchers = {},
        launcher_to_items = {},
        item_to_launchers = {},
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

local function encode_item(name, quality)
    return name .. ":" .. quality
end

---@param receiver ReceiverStation
---@return table<string, ItemWithQualityCount>
local function get_receiver_demand(receiver)
    local request_demands = {}
    for _, request in ipairs(receiver.settings.delivery_requests) do
        local key = encode_item(request.name, request.quality)
        request_demands[key] = request.amount > 0 and
            { name = request.name, quality = request.quality, count = request.amount } or nil
    end
    for _, item in ipairs(receiver:get_inventory().get_contents()) do
        local key = encode_item(item.name, item.quality)
        local demand = request_demands[key]
        if demand then
            request_demands[key] = demand.count - item.count > 0 and
                { name = item.name, quality = item.quality, count = demand.count - item.count } or nil
        end
    end
    for _, delivery in pairs(receiver.scheduled_deliveries) do
        if delivery:valid() then
            local key = encode_item(delivery.item, delivery.quality)
            local demand = request_demands[key]
            if demand then
                request_demands[key] = demand.count - delivery.amount > 0 and
                    { name = delivery.item, quality = delivery.quality, count = demand.count - delivery.amount } or nil
            end
        end
    end
    return request_demands
end

function CannonNetwork.prototype:update_launcher_storage(launcher)
    if not launcher:valid() or not self.launchers:contains(launcher:id()) then return end
    -- delete previous item index
    for encoded_item, _ in pairs(self.launcher_to_items[launcher:id()]) do
        self.item_to_launchers[encoded_item][launcher:id()] = nil
    end
    self.launcher_to_items[launcher:id()] = {}
    -- indexing items
    local payload_stack = launcher:get_max_payload_size()
    if not payload_stack or payload_stack <= 0 then return end
    for _, item in ipairs(launcher:get_inventory().get_contents()) do
        local payload_count = payload_stack * prototypes.item[item.name].stack_size
        local encoded_item = encode_item(item.name, item.quality)
        if item.count >= payload_count then
            -- add to item index
            self.launcher_to_items[launcher:id()][encoded_item] = item
            if not self.item_to_launchers[encoded_item] then
                self.item_to_launchers[encoded_item] = {}
            end
            self.item_to_launchers[encoded_item][launcher:id()] = launcher
        end
    end
end

function CannonNetwork.prototype:update_deliveries(tick)
    local bucket_id = tick % settings.global[constants.update_interval_setting].value + 1
    for launcher in self.launchers:bucket(bucket_id) do
        launcher:update_state()
        self:update_launcher_storage(launcher)
    end
    for receiver in self.receivers:bucket(bucket_id) do
        if not receiver:valid() then goto next_receiver end
        local empty_slots = receiver:get_inventory().count_empty_stacks(false, false)
        if empty_slots <= 0 then goto next_receiver end
        local demands = get_receiver_demand(receiver)
        local neighbours = self.receiver_to_launchers[receiver:id()]
        local neighbour_size = table_size(neighbours)
        for encoded_item, demand in pairs(demands) do
            local item_providers = self.item_to_launchers[encoded_item]
            if item_providers then
                local item = { name = demand.name, quality = demand.quality }
                local launchers = {}
                if table_size(item_providers) <= neighbour_size then
                    -- iterate over item providers
                    for _, launcher in pairs(item_providers) do
                        if neighbours[launcher:id()] then
                            table.insert(launchers, launcher)
                        end
                    end
                else
                    -- iterate over neighbours
                    for _, launcher in pairs(neighbours) do
                        if self.launcher_to_items[launcher:id()][encoded_item] then
                            table.insert(launchers, launcher)
                        end
                    end
                end
                for _, launcher in ipairs(launchers) do
                    local delivery = launcher:schedule_delivery(receiver, item, demand.count)
                    if delivery then
                        receiver:add_delivery(delivery)
                        demand.count = demand.count - delivery.amount
                        empty_slots = empty_slots - launcher:get_max_payload_size()
                        if empty_slots <= 0 then goto next_receiver end
                        if demand.count <= 0 then break end
                    end
                end
            end
        end
        ::next_receiver::
    end
end

---@param launcher LauncherStation
function CannonNetwork.prototype:update_launcher_connections(launcher)
    if not launcher:valid() or not self.launchers:contains(launcher:id()) then return end
    local receivers_in_range = self.launcher_to_receivers[launcher:id()]
    for receiver_id, _ in pairs(receivers_in_range) do
        self.receiver_to_launchers[receiver_id][launcher:id()] = nil
    end
    self.launcher_to_receivers[launcher:id()] = {}
    local maximum_range = launcher:get_max_range()
    if maximum_range > 0 then
        for receiver in self.receivers:all() do
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
    if not receiver:valid() or not self.receivers:contains(receiver:id()) then return end
    local launchers_in_range = self.receiver_to_launchers[receiver:id()]
    for launcher_id, _ in pairs(launchers_in_range) do
        self.launcher_to_receivers[launcher_id][receiver:id()] = nil
    end
    self.receiver_to_launchers[receiver:id()] = {}
    for launcher in self.launchers:all() do
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
    if not launcher:valid() or self.launchers:contains(launcher:id()) then return end
    self.launchers:put(launcher:id(), launcher)
    self.launcher_to_receivers[launcher:id()] = {}
    self.launcher_to_items[launcher:id()] = {}
    self:update_launcher_connections(launcher)
end

---@param receiver ReceiverStation
function CannonNetwork.prototype:add_receiver(receiver)
    if not receiver:valid() or self.receivers:contains(receiver:id()) then return end
    self.receivers:put(receiver:id(), receiver)
    self.receiver_to_launchers[receiver:id()] = {}
    self:update_receiver_connections(receiver)
end

function CannonNetwork.prototype:destroy_if_empty()
    if not next(self.receiver_to_launchers) and not next(self.launcher_to_receivers) then
        storage.cannon_networks[self.id] = nil
    end
end

---@param launcher_id uint64
function CannonNetwork.prototype:remove_launcher(launcher_id)
    if not self.launchers:contains(launcher_id) then return end
    -- delete connections
    local receivers_in_range = self.launcher_to_receivers[launcher_id]
    for receiver_id, _ in pairs(receivers_in_range) do
        self.receiver_to_launchers[receiver_id][launcher_id] = nil
    end
    -- delete item index
    local items = self.launcher_to_items[launcher_id]
    for encoded_item, _ in pairs(items) do
        self.item_to_launchers[encoded_item][launcher_id] = nil
    end
    self.launcher_to_receivers[launcher_id] = nil
    self.launcher_to_items[launcher_id] = nil
    self.launchers:remove(launcher_id)
    self:destroy_if_empty()
end

---@param receiver_id uint64
function CannonNetwork.prototype:remove_receiver(receiver_id)
    if not self.receivers:contains(receiver_id) then return end
    -- delete connections
    local launchers_in_range = self.receiver_to_launchers[receiver_id]
    for launcher_id, _ in pairs(launchers_in_range) do
        self.launcher_to_receivers[launcher_id][receiver_id] = nil
    end
    self.receiver_to_launchers[receiver_id] = nil
    self.receivers:remove(receiver_id)
    self:destroy_if_empty()
end

return CannonNetwork
