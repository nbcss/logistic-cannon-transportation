local BucketSet = {}

---Data structure
---@class BucketSet<T>
---@field private buckets { [integer]: { [integer]: any } }
---@field public n uint Number of buckets to split elements into. Read-only.
BucketSet.prototype = {}
BucketSet.prototype.__index = BucketSet.prototype


---@generic T
---@return BucketSet<T>
function BucketSet.new(n)
    return setmetatable({
        buckets = {},
        n = n,
    }, BucketSet.prototype)
end

---@generic T
---@param id integer
---@param value T
function BucketSet.prototype:put(id, value)
    local bucket_id = id % self.n + 1
    if not self.buckets[bucket_id] then
        self.buckets[bucket_id] = {}
    end
    self.buckets[bucket_id][id] = value
end

---@param id integer
---@return boolean
function BucketSet.prototype:contains(id)
    local bucket_id = id % self.n + 1
    if not self.buckets[bucket_id] then
        return false
    end
    return self.buckets[bucket_id][id] ~= nil
end

---@param id integer
function BucketSet.prototype:remove(id)
    local bucket_id = id % self.n + 1
    if not self.buckets[bucket_id] then
        return
    end
    self.buckets[bucket_id][id] = nil

    if not next(self.buckets[bucket_id]) then
        self.buckets[bucket_id] = nil
    end
end

---@generic T
---@return fun():T?
function BucketSet.prototype:all()
    local bucket_id, bucket = next(self.buckets)
    local element_id = nil

    return function()
        while bucket do
            local element
            element_id, element = next(bucket, element_id)
            if element then
                return element
            end
            -- Move to next bucket
            bucket_id, bucket = next(self.buckets, bucket_id)
            element_id = nil
        end
        return nil
    end
end

---@generic T
---@param bucket_id integer
---@return fun():T?
function BucketSet.prototype:bucket(bucket_id)
    local bucket = self.buckets[bucket_id]
    if not bucket then
        return function() return nil end
    end

    local element_id
    return function()
        local element
        element_id, element = next(bucket, element_id)
        return element
    end
end

return BucketSet