local _, addon = ...
local UI = addon.UI

UI.FARM_ROW_HEIGHT = 34

function UI:CreateFarmRow()
    return self:CreateItemRow(self.farmContent, {
        height = self.FARM_ROW_HEIGHT,
        iconSize = 26,
        iconInset = 6,
        nameTemplate = "GameFontNormalSmall",
        nameGap = 8,
        nameTop = -6,
        nameWidth = 195,
        valueTemplate = "GameFontHighlightSmall",
        valueJustify = "RIGHT",
        valueRightInset = 8,
        tooltipAnchor = "ANCHOR_LEFT",
    })
end

function UI:RenderFarmRows(items)
    if items then
        self.farmDisplayItems = items
    end
    items = self.farmDisplayItems or {}

    local rowHeight = self.FARM_ROW_HEIGHT
    local viewportHeight = math.max(self.farmScrollFrame:GetHeight(), 1)
    local contentHeight = math.max(#items * rowHeight, viewportHeight)
    self.farmContent:SetWidth(math.max(self.farmScrollFrame:GetWidth(), 1))
    self.farmContent:SetHeight(contentHeight)
    self.farmScrollFrame:UpdateScrollChildRect()

    local scrollRange = math.max(contentHeight - viewportHeight, 0)
    local scrollOffset = math.max(
        0,
        math.min(self.farmScrollFrame:GetVerticalScroll(), scrollRange))
    if scrollOffset ~= self.farmScrollFrame:GetVerticalScroll() then
        self.farmScrollFrame:SetVerticalScroll(scrollOffset)
    end

    local visibleRows = math.ceil(viewportHeight / rowHeight) + 2
    local rowCapacity = math.min(#items, visibleRows)
    while #self.farmRows < rowCapacity do
        self.farmRows[#self.farmRows + 1] = self:CreateFarmRow()
    end

    local firstIndex = math.floor(scrollOffset / rowHeight) + 1
    for slot, row in ipairs(self.farmRows) do
        local itemIndex = firstIndex + slot - 1
        local item = items[itemIndex]
        if item and slot <= rowCapacity then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.farmContent, "TOPLEFT",
                0, -(itemIndex - 1) * rowHeight)
            row:SetPoint("TOPRIGHT", self.farmContent, "TOPRIGHT",
                0, -(itemIndex - 1) * rowHeight)
            row.icon:SetTexture(item.icon)
            row.item = item
            row.name:SetText(("%s  x%d"):format(item.name, item.remaining))
            row.name:SetTextColor(unpack(
                self.QUALITY_COLORS[item.quality] or self.QUALITY_COLORS[1]))
            row.value:SetText(self:FormatMoney(item.value))
            row:Show()
        else
            row.item = nil
            row:Hide()
        end
    end

    self.farmEmptyState:SetShown(#items == 0)
end

function UI:RefreshFarm()
    if not self.farmWindow or not addon.db then return end

    local items, totalValue = addon:GetFarmItems()
    self.farmSummary:SetText(("%d unique items tracked"):format(#items))
    self.farmValue:SetText(("Potential: %s"):format(self:FormatMoney(totalValue)))
    self.farmAutoSellButton.label:SetText(addon.farmAutoSell
        and "AUTO  |cff42a882ON|r"
        or "AUTO  |cffe05a61OFF|r")
    self.farmAutoSellButton:SetEnabled(addon.db.enableFarmLoot)
    self.farmReagentsButton.label:SetText(addon.db.sellFarmReagents
        and "REG  |cff42a882ON|r"
        or "REG  |cffe05a61OFF|r")
    self.farmSplitButton.label:SetText("SPLIT")
    local splitAvailable
    if addon.merchantOpen and addon.farmAutoSell and addon.db.enableFarmLoot then
        splitAvailable = addon:GetFarmStackToSplit()
    end
    local freeBag = splitAvailable and addon:GetFreeGeneralBagSlot()
    self.farmSplitButton:SetEnabled(splitAvailable ~= nil and freeBag ~= nil)
    self.farmReagentsButton:SetEnabled(addon.db.enableFarmLoot)
    self.cloneFarmButton.label:SetText("CLONE")
    self.clearFarmButton.label:SetText("CLEAR")

    self:RenderFarmRows(items)
end
