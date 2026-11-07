local _, addon = ...

function addon:StopSelling()
    if self.sellTicker then
        self.sellTicker:Cancel()
        self.sellTicker = nil
    end
    self.isSelling = false
end

function addon:StartSelling()
    self:StopSelling()
    if not self.merchantOpen then
        return
    end
    if self.pendingItemInfo then
        self.statusText = "Waiting for item information..."
        self:RefreshUI()
        return
    end

    local queue = {}
    local queuedSlots = {}
    local farmQueuedCounts = {}
    local function enqueue(item, isFarmItem)
        local mainSale = self:GetItemStatus(item) == "sell"
        local farmRecord = self.farmItems[item.itemID]
        local farmSale = isFarmItem
            and self.db.enableFarmLoot
            and self.farmAutoSell
            and farmRecord
            and self:GetItemStatus(item) ~= "kept"
            and farmRecord.remaining - (farmQueuedCounts[item.itemID] or 0) >= item.count
            and (self.db.sellFarmReagents or not item.isReagent)
        local slotKey = item.bag .. ":" .. item.slot
        if (mainSale or farmSale)
            and not queuedSlots[slotKey]
            and item.sellPrice > 0
            and not self:IsExcluded(item)
            and not item.isLocked
            and not item.hasNoValue
            and not item.hasLoot then
            item.farmSale = not mainSale and farmSale or nil
            if item.farmSale then
                farmQueuedCounts[item.itemID] =
                    (farmQueuedCounts[item.itemID] or 0) + item.count
            end
            queuedSlots[slotKey] = true
            queue[#queue + 1] = item
        end
    end

    for _, item in ipairs(self.items) do
        enqueue(item, true)
    end

    if self.db.enableFarmLoot and self.farmAutoSell then
        local _, farmBagItems = self:GetFarmBagSnapshot()
        for itemID, farmItem in pairs(self.farmItems) do
            local canSellFarmItem = farmItem.remaining > 0
                and (self.db.sellFarmReagents or not farmItem.isReagent)
            local currentItem = farmBagItems[itemID]
            if canSellFarmItem and currentItem then
                for _, slot in ipairs(currentItem.slots) do
                    enqueue({
                        bag = slot.bag,
                        slot = slot.slot,
                        itemID = itemID,
                        count = slot.count,
                        name = currentItem.name,
                        link = currentItem.link,
                        sellPrice = currentItem.sellPrice,
                        isReagent = currentItem.isReagent,
                        isLocked = slot.isLocked,
                        hasNoValue = slot.hasNoValue,
                        hasLoot = slot.hasLoot,
                    }, true)
                end
            end
        end
    end

    if #queue == 0 then
        self.statusText = "No items selected for sale."
        self:RefreshUI()
        return
    end

    self.isSelling = true
    self.statusText = ("Selling all %d eligible selected items..."):format(#queue)
    self:RefreshUI()

    local index = 0
    self.sellTicker = C_Timer.NewTicker(0.25, function()
        if not self.merchantOpen then
            self:StopSelling()
            return
        end

        index = index + 1
        local item = queue[index]
        if not item then
            self:StopSelling()
            self:ScanBags()
            self.statusText = "All eligible selected items have been processed."
            self:RefreshUI()
            return
        end

        local current = C_Container.GetContainerItemInfo(item.bag, item.slot)
        local farmRecord = self.farmItems[item.itemID]
        local isStillFarmSale = item.farmSale
            and self.db.enableFarmLoot
            and self.farmAutoSell
            and farmRecord
            and self:GetItemStatus(item) ~= "kept"
            and farmRecord.remaining >= item.count
            and (self.db.sellFarmReagents or not item.isReagent)
        if current
            and current.itemID == item.itemID
            and not current.isLocked
            and not current.hasNoValue
            and not current.hasLoot
            and (self:GetItemStatus(item) == "sell" or isStillFarmSale) then
            local purchaseInfo = C_Container.GetContainerItemPurchaseInfo(item.bag, item.slot, false)
            local isRefundable = purchaseInfo
                and purchaseInfo.refundSeconds
                and purchaseInfo.refundSeconds > 0
            if not isRefundable then
                C_Container.UseContainerItem(item.bag, item.slot)
                if farmRecord then
                    farmRecord.remaining = math.max(0, farmRecord.remaining - item.count)
                    self.farmBagCounts[item.itemID] = math.max(
                        0,
                        (self.farmBagCounts[item.itemID] or 0) - item.count)
                    self:RefreshFarmUI()
                    C_Timer.After(0.1, function()
                        self.farmBagCounts, self.farmCurrentItems = self:GetFarmBagSnapshot()
                        self:RefreshFarmUI()
                    end)
                end
            end
        end
    end)
end
