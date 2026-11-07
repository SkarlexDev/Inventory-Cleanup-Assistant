local _, addon = ...

function addon:ScanBags()
    self:InitializeDatabase()
    wipe(self.items)
    if not self.bagItemIDs then
        self.bagItemIDs = {}
    else
        wipe(self.bagItemIDs)
    end
    self.pendingItemInfo = false
    local itemsToRequest = {}

    for bag = 0, self.constants.bagCount do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local bagItem = C_Container.GetContainerItemInfo(bag, slot)
            if bagItem and bagItem.itemID then
                self.bagItemIDs[bagItem.itemID] = true
                local name, _, quality, _, _, _, _, _, _, _, price, classID =
                    self:GetCachedItemInfo(bagItem.itemID, bagItem.hyperlink)

                if not name then
                    if not self.failedItemInfo[bagItem.itemID]
                        and (self.itemInfoAttempts[bagItem.itemID] or 0) < self.constants.maxItemInfoRequests then
                        self.pendingItemInfo = true
                        itemsToRequest[bagItem.itemID] = true
                    end
                end

                quality = bagItem.quality or quality
                if type(quality) == "number"
                    and quality >= 0
                    and quality <= self.constants.maxQuality
                    and classID ~= self.constants.questItemClass then
                    local linkName = bagItem.hyperlink
                        and bagItem.hyperlink:match("|h%[(.-)%]|h")
                    self.items[#self.items + 1] = {
                        bag = bag,
                        slot = slot,
                        itemID = bagItem.itemID,
                        name = name or linkName or ("Item " .. bagItem.itemID),
                        link = bagItem.hyperlink,
                        icon = bagItem.iconFileID,
                        count = bagItem.stackCount or 1,
                        sellPrice = type(price) == "number" and price or 0,
                        quality = quality,
                        classID = classID,
                        isReagent = classID == self.constants.tradeGoodsItemClass,
                        isLocked = bagItem.isLocked,
                        hasNoValue = bagItem.hasNoValue,
                        hasLoot = bagItem.hasLoot,
                    }
                end
            end
        end
    end

    for index = #self.items, 1, -1 do
        if self:IsExcluded(self.items[index]) then
            table.remove(self.items, index)
        end
    end

    table.sort(self.items, function(a, b)
        local aStackValue = a.sellPrice * a.count
        local bStackValue = b.sellPrice * b.count
        if aStackValue ~= bStackValue then
            return aStackValue < bStackValue
        end
        return a.name < b.name
    end)

    for itemID in pairs(itemsToRequest) do
        if not self.requestedItems[itemID]
            and (self.itemInfoAttempts[itemID] or 0) < self.constants.maxItemInfoRequests then
            self.requestedItems[itemID] = true
            self.itemInfoAttempts[itemID] = (self.itemInfoAttempts[itemID] or 0) + 1
            C_Timer.After(0, function()
                C_Item.RequestLoadItemDataByID(itemID)
            end)
        end
    end

    self:UpdateFarmTracking()
    self:RefreshUI()
end
