local _, addon = ...

function addon:GetFarmStackToSplit()
    if not self.farmAutoSell then
        return nil
    end

    local _, bagItems = self:GetFarmBagSnapshot()
    for itemID, farmItem in pairs(self.farmItems) do
        local currentItem = bagItems[itemID]
        if farmItem.remaining > 0
            and currentItem
            and currentItem.isReagent
            and self.db.sellFarmReagents
            and currentItem.sellPrice > 0
            and not self:IsExcluded(currentItem)
            and self:GetItemStatus(currentItem) ~= "sell"
            and self:GetItemStatus(currentItem) ~= "kept" then
            local unassignedFarmCount = farmItem.remaining
            for _, slot in ipairs(currentItem.slots) do
                if not slot.isLocked and not slot.hasNoValue and not slot.hasLoot then
                    if slot.count <= unassignedFarmCount then
                        unassignedFarmCount = unassignedFarmCount - slot.count
                    elseif unassignedFarmCount > 0 then
                        return {
                            bag = slot.bag,
                            slot = slot.slot,
                            amount = unassignedFarmCount,
                        }
                    end
                end
            end
        end
    end
end

function addon:SplitNextFarmStack()
    if not self.merchantOpen or not self.farmAutoSell then
        return false
    end
    if InCombatLockdown() then
        self.statusText = "Leave combat before splitting farm stacks."
        self:RefreshUI()
        return false
    end
    if CursorHasItem() then
        self.statusText = "Place the item on your cursor before splitting farm stacks."
        self:RefreshUI()
        return false
    end

    local split = self:GetFarmStackToSplit()
    if not split then
        self.statusText = "No mixed farm stacks need splitting."
        self:RefreshUI()
        return false
    end

    local emptyBag, emptySlot = self:GetFreeGeneralBagSlot()
    if not emptyBag then
        self.statusText = "Free a bag slot before splitting farm stacks."
        self:RefreshUI()
        return false
    end

    self:StopSelling()
    C_Container.SplitContainerItem(split.bag, split.slot, split.amount)
    C_Container.PickupContainerItem(emptyBag, emptySlot)
    C_Timer.After(0.1, function()
        self:ScanBags()
        if self.merchantOpen then
            self:StartSelling()
        end
    end)
    return true
end

function addon:GetFreeGeneralBagSlot()
    for bag = 0, self.constants.bagCount do
        local _, bagFamily = C_Container.GetContainerNumFreeSlots(bag)
        if bag == 0 or bagFamily == 0 then
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                if not C_Container.GetContainerItemInfo(bag, slot) then
                    return bag, slot
                end
            end
        end
    end
end
