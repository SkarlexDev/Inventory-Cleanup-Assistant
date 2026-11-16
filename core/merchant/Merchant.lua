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
    local function enqueue(item)
        local slotKey = item.bag .. ":" .. item.slot
        if self:GetItemStatus(item) == "sell"
            and not queuedSlots[slotKey]
            and item.sellPrice > 0
            and not self:IsExcluded(item)
            and not item.isLocked
            and not item.hasNoValue
            and not item.hasLoot then
            queuedSlots[slotKey] = true
            queue[#queue + 1] = item
        end
    end

    for _, item in ipairs(self.items) do
        enqueue(item)
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
        if current
            and current.itemID == item.itemID
            and not current.isLocked
            and not current.hasNoValue
            and not current.hasLoot
            and self:GetItemStatus(item) == "sell" then
            local purchaseInfo = C_Container.GetContainerItemPurchaseInfo(item.bag, item.slot, false)
            local isRefundable = purchaseInfo
                and purchaseInfo.refundSeconds
                and purchaseInfo.refundSeconds > 0
            if not isRefundable then
                C_Container.UseContainerItem(item.bag, item.slot)
            end
        end
    end)
end
