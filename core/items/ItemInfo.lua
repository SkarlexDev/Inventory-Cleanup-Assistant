local _, addon = ...

local itemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo

local function pack(...)
    return { n = select("#", ...), ... }
end

function addon:GetCachedItemInfo(itemID, link)
    if self.itemInfoCache[itemID] then
        local cached = self.itemInfoCache[itemID]
        return unpack(cached, 1, cached.n)
    end

    local data = pack(itemInfo(link or itemID))
    if data[1] then
        self.itemInfoCache[itemID] = data
        return unpack(data, 1, data.n)
    end
end

function addon:RequestItemInfo(itemID)
    if self.requestedItems[itemID]
        or self.failedItemInfo[itemID]
        or (self.itemInfoAttempts[itemID] or 0) >= self.constants.maxItemInfoRequests then
        return
    end

    self.requestedItems[itemID] = true
    self.itemInfoAttempts[itemID] = (self.itemInfoAttempts[itemID] or 0) + 1
    C_Timer.After(0, function()
        C_Item.RequestLoadItemDataByID(itemID)
    end)
end
