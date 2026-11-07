local _, addon = ...
local UI = addon.UI

function UI:GetModeItems(mode, ignoreSearch)
    mode = mode or self.mode
    local result = {}
    local listedIDs = {}
    for _, item in ipairs(addon.items) do
        local status = addon:GetItemStatus(item)
        local hiddenZeroValue = not addon.db.showZeroValue and item.sellPrice == 0
        local matchesSearch = ignoreSearch or self.search == ""
            or item.name:lower():find(self.search, 1, true) ~= nil
        listedIDs[item.itemID] = true
        if status == mode and matchesSearch and not hiddenZeroValue then
            result[#result + 1] = item
        end
    end

    local function addSavedRule(itemID)
        if listedIDs[itemID] or addon.bagItemIDs[itemID] then
            return
        end

        local name, link, quality, _, _, _, _, _, _, icon, sellPrice =
            addon:GetCachedItemInfo(itemID)
        if not name then
            addon:RequestItemInfo(itemID)
        end
        if not icon and C_Item and C_Item.GetItemIconByID then
            icon = C_Item.GetItemIconByID(itemID)
        end
        local item = {
            itemID = itemID,
            name = name or ("Item " .. itemID),
            link = link,
            icon = icon,
            quality = quality or 1,
            count = 0,
            sellPrice = type(sellPrice) == "number" and sellPrice or 0,
        }
        if addon:IsExcluded(item) then
            return
        end
        local matchesSearch = ignoreSearch or self.search == ""
            or item.name:lower():find(self.search, 1, true) ~= nil
        local hiddenZeroValue = not addon.db.showZeroValue and item.sellPrice == 0
        if matchesSearch and not hiddenZeroValue then
            result[#result + 1] = item
        end
    end

    local savedRuleIDs = {}
    if mode == "sell" then
        for itemID, isForSale in pairs(addon.db.saleRules) do
            if isForSale and not addon.db.keptItemIDs[itemID] then
                savedRuleIDs[#savedRuleIDs + 1] = itemID
            end
        end
    elseif mode == "kept" then
        for itemID, isKept in pairs(addon.db.keptItemIDs) do
            if isKept then
                savedRuleIDs[#savedRuleIDs + 1] = itemID
            end
        end
    end
    table.sort(savedRuleIDs)
    for _, itemID in ipairs(savedRuleIDs) do
        addSavedRule(itemID)
    end

    return result
end

function UI:UpdateScrollBar()
    if not self.scrollFrame then return end
    local viewportHeight = math.max(self.scrollFrame:GetHeight(), 1)
    local contentHeight = math.max(self.content:GetHeight(), viewportHeight)
    local range = math.max(contentHeight - viewportHeight, 0)
    local trackHeight = math.max(self.scrollTrack:GetHeight(), 1)
    local thumbHeight = math.min(trackHeight, math.max(28, trackHeight * viewportHeight / contentHeight))
    local offset = math.max(0, math.min(self.scrollFrame:GetVerticalScroll(), range))

    self.syncingScrollBar = true
    self.scrollBar:SetMinMaxValues(0, range)
    self.scrollBar:SetValue(offset)
    self.syncingScrollBar = false
    self.scrollBar:SetShown(range > 0)
    self.scrollTrack:SetShown(range > 0)
    self.scrollThumb:SetHeight(thumbHeight)
    if offset ~= self.scrollFrame:GetVerticalScroll() then
        self.scrollFrame:SetVerticalScroll(offset)
    end
end

function UI:RenderRows()
    if not self.scrollFrame then return end
    local items = self:GetModeItems()
    local range = math.max(#items * self.ROW_HEIGHT - self.scrollFrame:GetHeight(), 0)
    local offset = math.max(0, math.min(self.scrollFrame:GetVerticalScroll(), range))
    if self.scrollFrame:GetVerticalScroll() ~= offset then
        self.scrollFrame:SetVerticalScroll(offset)
    end

    self.syncingScrollBar = true
    self.scrollBar:SetMinMaxValues(0, range)
    self.scrollBar:SetValue(offset)
    self.syncingScrollBar = false
    self.scrollBar:SetShown(range > 0)
    self.scrollTrack:SetShown(range > 0)

    local firstIndex = math.floor(offset / self.ROW_HEIGHT) + 1
    for slot, row in ipairs(self.rows) do
        local itemIndex = firstIndex + slot - 1
        local item = items[itemIndex]
        row.item = item
        if item then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -(itemIndex - 1) * self.ROW_HEIGHT)
            row:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -(itemIndex - 1) * self.ROW_HEIGHT)
            row.icon:SetTexture(item.icon)
            row.name:SetText(item.name .. (item.count > 1 and (" x" .. item.count) or ""))
            row.name:SetTextColor(unpack(self.QUALITY_COLORS[item.quality] or self.QUALITY_COLORS[1]))
            local itemValue = self:FormatMoney(item.sellPrice)
            local stackValue = item.sellPrice * item.count
            if item.count > 1 and stackValue > 0 then
                itemValue = ("Each: %s  |  Stack: %s"):format(
                    itemValue,
                    self:FormatMoney(stackValue))
            end
            row.value:SetText(item.bag and itemValue or "")

            if self.mode == "review" then
                row.action.label:SetText("Sell")
                row.action.actionStatus = "sell"
                row.ignoreAction.label:SetText("Ignore")
                row.ignoreAction.actionStatus = "kept"
            elseif self.mode == "sell" then
                row.action.label:SetText("Review")
                row.action.actionStatus = "review"
                row.ignoreAction.label:SetText("Ignore")
                row.ignoreAction.actionStatus = "kept"
            else
                row.action.label:SetText("Review")
                row.action.actionStatus = "review"
                row.ignoreAction.label:SetText("Sell")
                row.ignoreAction.actionStatus = "sell"
            end
            row:Show()
        else
            row.item = nil
            row:Hide()
        end
    end
end

function UI:Refresh()
    if not self.window then return end

    self.zeroValueFilter.label:SetText(addon.db.showZeroValue
        and "SHOW 0-VALUE  |cff42a882ON|r"
        or "SHOW 0-VALUE  |cffe05a61OFF|r")
    self:RefreshSettings()
    if self.page == "settings" then
        return
    end

    local counts = { review = 0, sell = 0, kept = 0 }
    local sellValue = 0
    for _, mode in ipairs(self.MODES) do
        counts[mode.id] = #self:GetModeItems(mode.id, true)
    end
    for _, item in ipairs(addon.items) do
        local status = addon:GetItemStatus(item)
        local hiddenZeroValue = not addon.db.showZeroValue and item.sellPrice == 0
        if status == "sell" and not hiddenZeroValue then
            sellValue = sellValue + item.sellPrice * item.count
        end
    end
    self.summary:SetText(("%d review    %d to sell    %d ignored"):format(
        counts.review, counts.sell, counts.kept))
    self.value:SetText(self:FormatMoney(sellValue))
    self.status:SetText(addon.statusText)
    self.searchFrame:SetBackdropBorderColor(unpack(
        self.searchBox:HasFocus() and self.COLORS.accent or self.COLORS.border))
    self.searchPlaceholder:SetShown(self.searchBox:GetText() == "")

    local items = self:GetModeItems()
    self.content:SetWidth(math.max(self.scrollFrame:GetWidth(), 1))
    self.content:SetHeight(math.max(#items * self.ROW_HEIGHT, 1))
    self.scrollFrame:UpdateScrollChildRect()
    self:UpdateScrollBar()
    local visibleRows = math.ceil(math.max(self.scrollFrame:GetHeight(), 1) / self.ROW_HEIGHT) + 2
    local rowCapacity = math.min(#items, visibleRows)
    while #self.rows < rowCapacity do
        self.rows[#self.rows + 1] = self:CreateRow(#self.rows + 1)
    end

    self:RenderRows()
    if #items == 0 and addon.pendingItemInfo then
        self.emptyState:SetText("Loading item details...")
        self.emptyState:Show()
    elseif #items == 0 then
        local message = #addon.items == 0
            and counts.sell == 0
            and counts.kept == 0
            and "No eligible items in your bags."
            or "No items in this list."
        self.emptyState:SetText(message)
        self.emptyState:Show()
    else
        self.emptyState:Hide()
    end

    for mode, button in pairs(self.modeButtons) do
        local selected = self.mode == mode
        button:SetBackdropColor(unpack(selected and self.COLORS.panel or self.COLORS.background))
        button:SetBackdropBorderColor(unpack(selected and self.COLORS.accent or self.COLORS.border))
        button.label:SetTextColor(unpack(selected and self.COLORS.accent or self.COLORS.muted))
        button.label:SetText(("%s  (%d)"):format(button.modeLabel, counts[mode]))
    end
end
