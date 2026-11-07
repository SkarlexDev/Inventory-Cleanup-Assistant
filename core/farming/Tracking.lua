local _, addon = ...

function addon:GetFarmBagSnapshot()
    local counts = {}
    local items = {}

    for bag = 0, self.constants.bagCount do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local bagItem = C_Container.GetContainerItemInfo(bag, slot)
            if bagItem and bagItem.itemID then
                local itemID = bagItem.itemID
                local count = bagItem.stackCount or 1
                counts[itemID] = (counts[itemID] or 0) + count

                local name, _, quality, _, _, _, _, _, _, _, sellPrice, classID =
                    self:GetCachedItemInfo(itemID, bagItem.hyperlink)
                if not name and (self.farmTracking or self.farmItems[itemID]) then
                    self:RequestItemInfo(itemID)
                end

                local item = items[itemID]
                if not item then
                    local linkName = bagItem.hyperlink
                        and bagItem.hyperlink:match("|h%[(.-)%]|h")
                    item = {
                        itemID = itemID,
                        name = name or linkName or ("Item " .. itemID),
                        link = bagItem.hyperlink,
                        icon = bagItem.iconFileID,
                        quality = bagItem.quality or quality or 1,
                        sellPrice = type(sellPrice) == "number" and sellPrice or 0,
                        classID = classID,
                        isReagent = classID == self.constants.tradeGoodsItemClass,
                        slots = {},
                    }
                    items[itemID] = item
                end
                item.slots[#item.slots + 1] = {
                    bag = bag,
                    slot = slot,
                    count = count,
                    isLocked = bagItem.isLocked,
                    hasNoValue = bagItem.hasNoValue,
                    hasLoot = bagItem.hasLoot,
                }
            end
        end
    end

    for _, item in pairs(items) do
        table.sort(item.slots, function(a, b)
            if a.count ~= b.count then
                return a.count < b.count
            end
            if a.bag ~= b.bag then
                return a.bag < b.bag
            end
            return a.slot < b.slot
        end)
    end

    return counts, items
end

function addon:UpdateFarmTracking()
    if not self.db or not self.db.enableFarmLoot then
        return
    end

    if self.farmBaselinePending then
        self:ScheduleFarmBaseline(self.farmInstanceID)
        return
    end

    local currentCounts, currentItems = self:GetFarmBagSnapshot()
    local changed = false

    if self.farmTracking then
        for itemID, count in pairs(currentCounts) do
            local difference = count - (self.farmBagCounts[itemID] or 0)
            if difference > 0 then
                local farmItem = self.farmItems[itemID]
                if not farmItem then
                    farmItem = {
                        itemID = itemID,
                        looted = 0,
                        remaining = 0,
                    }
                    self.farmItems[itemID] = farmItem
                end
                farmItem.looted = farmItem.looted + difference
                farmItem.remaining = farmItem.remaining + difference
                changed = true
            elseif difference < 0 and self.farmItems[itemID] then
                local farmItem = self.farmItems[itemID]
                farmItem.remaining = math.max(0, farmItem.remaining + difference)
                changed = true
            end
        end

        for itemID, count in pairs(self.farmBagCounts) do
            if count > 0 and not currentCounts[itemID] and self.farmItems[itemID] then
                self.farmItems[itemID].remaining = 0
                changed = true
            end
        end
    end

    for itemID, farmItem in pairs(self.farmItems) do
        local currentItem = currentItems[itemID]
        if currentItem then
            farmItem.name = currentItem.name
            farmItem.link = currentItem.link or farmItem.link
            farmItem.icon = currentItem.icon
            farmItem.quality = currentItem.quality
            farmItem.sellPrice = currentItem.sellPrice
            farmItem.isReagent = currentItem.isReagent
        end
    end

    self.farmBagCounts = currentCounts
    self.farmCurrentItems = currentItems
    if changed or next(self.farmItems) then
        self:RefreshFarmUI()
    end
end

function addon:ScheduleFarmBaseline(instanceID)
    self.farmBaselinePending = true
    self.farmBaselineGeneration = self.farmBaselineGeneration + 1
    local generation = self.farmBaselineGeneration

    C_Timer.After(1, function()
        if generation ~= self.farmBaselineGeneration or not self.farmBaselinePending then
            return
        end
        if not self.db or not self.db.enableFarmLoot then
            return
        end

        if not IsInInstance() then
            self:UpdateInstanceTracking()
            return
        end

        local _, _, _, _, _, _, _, currentInstanceID = GetInstanceInfo()
        if currentInstanceID ~= instanceID then
            self:UpdateInstanceTracking()
            return
        end

        self.farmBagCounts, self.farmCurrentItems = self:GetFarmBagSnapshot()
        self.farmInstanceID = instanceID
        self.farmBaselinePending = false
        self.farmTracking = true
        self:RefreshFarmUI()
    end)
end

function addon:UpdateInstanceTracking()
    if not self.farmInitialized then
        return
    end
    if not self.db or not self.db.enableFarmLoot then
        return
    end

    local inInstance = IsInInstance()
    local wasTracking = self.farmTracking
    local shouldTrack = inInstance == true
    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
    local samePendingInstance = self.farmBaselinePending
        and shouldTrack
        and instanceID == self.farmInstanceID
    local enteredInstance = shouldTrack
        and not samePendingInstance
        and (not wasTracking or instanceID ~= self.farmInstanceID)
    local leftInstance = not shouldTrack
        and (wasTracking or self.farmBaselinePending)

    if enteredInstance or leftInstance then
        if wasTracking and shouldTrack then
            self:UpdateFarmTracking()
        end
        self.farmBaselineGeneration = self.farmBaselineGeneration + 1
        self.farmBaselinePending = false
        self.farmTracking = false
        self.farmInstanceID = shouldTrack and instanceID or nil
        if shouldTrack then
            self:ScheduleFarmBaseline(instanceID)
        else
            local generation = self.farmBaselineGeneration
            C_Timer.After(1, function()
                if generation ~= self.farmBaselineGeneration
                    or self.farmTracking
                    or IsInInstance() then
                    return
                end

                self.farmBagCounts, self.farmCurrentItems = self:GetFarmBagSnapshot()
                self:RefreshFarmUI()
            end)
        end
    elseif wasTracking and shouldTrack and instanceID ~= self.farmInstanceID then
        self:UpdateFarmTracking()
        self.farmInstanceID = instanceID
        self.farmBagCounts, self.farmCurrentItems = self:GetFarmBagSnapshot()
    else
        self:UpdateFarmTracking()
    end

    if (enteredInstance or samePendingInstance) and self.UI and self.UI.ShowFarm then
        self.UI:ShowFarm()
    elseif leftInstance and self.UI then
        self.UI:RefreshFarm()
    end
end

function addon:SetFarmLootEnabled(enabled)
    if not self.db then
        return
    end

    self.db.enableFarmLoot = enabled == true
    if self.db.enableFarmLoot then
        self:UpdateInstanceTracking()
    else
        self.farmBaselineGeneration = self.farmBaselineGeneration + 1
        self.farmBaselinePending = false
        self.farmTracking = false
        self.farmInstanceID = nil
        self.farmAutoSell = false
        self.farmWindowShouldBeOpen = false
        if self.UI and self.UI.farmWindow then
            self.UI.farmWindow:Hide()
        end
    end

    self:RefreshUI()
    self:RefreshFarmUI()
end

function addon:ClearFarmItems()
    self.farmItems = {}
    if self.farmBaselinePending then
        self:ScheduleFarmBaseline(self.farmInstanceID)
    else
        self.farmBagCounts, self.farmCurrentItems = self:GetFarmBagSnapshot()
    end
    self:RefreshFarmUI()
    if self.merchantOpen then
        self:StartSelling()
    end
end
