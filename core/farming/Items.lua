local _, addon = ...

function addon:GetFarmItems()
    local items = {}
    local totalValue = 0
    local hasFreeGeneralBagSlot

    for _, farmItem in pairs(self.farmItems) do
        if farmItem.remaining > 0 then
            local name, _, quality, _, _, _, _, _, _, _, sellPrice, classID =
                self:GetCachedItemInfo(farmItem.itemID, farmItem.link)
            if name then
                farmItem.name = name
                farmItem.quality = quality or farmItem.quality
                farmItem.sellPrice = type(sellPrice) == "number" and sellPrice or 0
                farmItem.isReagent = classID == self.constants.tradeGoodsItemClass
            end

            local unitPrice = farmItem.isReagent and not self.db.sellFarmReagents
                and 0 or (farmItem.sellPrice or 0)
            local sellableCount = 0
            local remainingCount = farmItem.remaining
            local currentItem = self.farmCurrentItems[farmItem.itemID]
            if unitPrice > 0
                and currentItem
                and not self:IsExcluded(currentItem) then
                for _, slot in ipairs(currentItem.slots) do
                    if slot.count <= remainingCount
                        and not slot.isLocked
                        and not slot.hasNoValue
                        and not slot.hasLoot then
                        sellableCount = sellableCount + slot.count
                        remainingCount = remainingCount - slot.count
                    end
                end
                if remainingCount > 0
                    and currentItem.isReagent
                    and self.db.sellFarmReagents then
                    if hasFreeGeneralBagSlot == nil then
                        hasFreeGeneralBagSlot = self:GetFreeGeneralBagSlot() ~= nil
                    end
                    if hasFreeGeneralBagSlot then
                        for _, slot in ipairs(currentItem.slots) do
                            if slot.count > remainingCount
                                and not slot.isLocked
                                and not slot.hasNoValue
                                and not slot.hasLoot then
                                sellableCount = sellableCount + remainingCount
                                break
                            end
                        end
                    end
                end
            end
            local value = unitPrice * sellableCount
            totalValue = totalValue + value
            items[#items + 1] = {
                itemID = farmItem.itemID,
                name = farmItem.name or ("Item " .. farmItem.itemID),
                link = farmItem.link,
                icon = farmItem.icon,
                quality = farmItem.quality or 1,
                looted = farmItem.looted,
                remaining = farmItem.remaining,
                sellableCount = sellableCount,
                unitPrice = unitPrice,
                value = value,
                isReagent = farmItem.isReagent,
            }
        end
    end

    table.sort(items, function(a, b)
        if a.value ~= b.value then
            return a.value > b.value
        end
        return a.name < b.name
    end)
    return items, totalValue
end

function addon:CloneFarmItemsToSell()
    for itemID in pairs(self.farmItems) do
        self.db.keptItemIDs[itemID] = nil
        self.db.saleRules[itemID] = true
    end
    self:RefreshUI()
    self:RefreshFarmUI()
    if self.merchantOpen then
        self:StartSelling()
    end
end

function addon:RefreshFarmUI()
    if self.UI and self.UI.RefreshFarm then
        self.UI:RefreshFarm()
    end
end
