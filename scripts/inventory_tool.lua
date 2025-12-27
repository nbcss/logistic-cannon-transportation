local inventory_tool = {}

---@param src LuaInventory
---@param dst LuaInventory
---@param item PrototypeWithQuality
---@param amount uint
---@return uint transferred
function inventory_tool.transfer_items(src, dst, item, amount)
    if not item.quality then item.quality = "normal" end
    local src_i = 1
    local dst_i = 1
    local transferred = 0

    while transferred < amount and src_i <= #src and dst_i <= #dst do
        -- Find matching source stack
        local src_stack = src[src_i] ---@type LuaItemStack
        if
            not src_stack.valid_for_read or
            src_stack.name ~= item.name or src_stack.quality.name ~= item.quality
        then
            src_i = src_i + 1
            goto continue
        end

        local dst_stack = dst[dst_i] ---@type LuaItemStack
        -- Try transferring to destination stack
        local src_count_before = src_stack.count
        dst_stack.transfer_stack(src_stack, amount - transferred)
        transferred = transferred + (src_count_before - src_stack.count)
        if src_stack.count == 0 then
            src_i = src_i + 1
            if dst_stack.count >= dst_stack.prototype.stack_size then
                dst_i = dst_i + 1
            end
        else
            dst_i = dst_i + 1
        end
        ::continue::
    end
    return transferred
end

---@param src LuaInventory
---@param dst LuaInventory
function inventory_tool.dump_items(src, dst)
    for i = 1, #src do
        local src_stack = src[i]
        if src_stack.valid_for_read then
            src_stack.count = src_stack.count - dst.insert(src_stack)
        end
    end
end

---@param src LuaInventory
---@param dst_slot LuaItemStack
function inventory_tool.transfer_to_slot(src, dst_slot)
    for i = 1, #src do
        local src_stack = src[i]
        if src_stack.valid_for_read then
            dst_slot.transfer_stack(src_stack)
        end
    end
end

return inventory_tool
