local _, addon = ...
local UI = addon.UI

function UI:CreateFarmButton(window)
    self.farmButton = self:CreateActionButton(window, 112)
    self.farmButton:SetSize(112, 26)
    self.farmButton:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -14, 10)
    self.farmButton.label:SetText("FARM LOOT")
    self.farmButton:SetScript("OnClick", function()
        self:ShowFarm()
    end)
end

function UI:CreateFarmWindow()
    local window = self:CreateBackdropFrame({
        name = "InventoryCleanupAssistantFarmWindow",
        parent = UIParent,
        width = 350,
        height = 400,
        point = { "CENTER", UIParent, "CENTER", 500, 0 },
        backgroundColor = self.COLORS.background,
        borderColor = self.COLORS.border,
        backdrop = { insets = { left = 1, right = 1, top = 1, bottom = 1 } },
    })
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:SetToplevel(true)
    window:SetClipsChildren(true)
    addon:RestoreWindowPosition("farm", window)
    window:Hide()
    self.farmWindow = window
    table.insert(UISpecialFrames, "InventoryCleanupAssistantFarmWindow")

    local header = self:CreateBackdropFrame({
        parent = window,
        height = 46,
        points = {
            { "TOPLEFT", window, "TOPLEFT", 12, -12 },
            { "TOPRIGHT", window, "TOPRIGHT", -12, -12 },
        },
        backgroundColor = self.COLORS.panel,
        borderColor = self.COLORS.border,
        backdrop = { insets = false },
    })
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() window:StartMoving() end)
    header:SetScript("OnDragStop", function()
        window:StopMovingOrSizing()
        addon:SaveWindowPosition("farm", window)
    end)

    local title = self:CreateFont(header, "FARM LOOT", "GameFontNormalLarge",
        "TOPLEFT", header, "TOPLEFT", 14, -8)
    title:SetTextColor(unpack(self.COLORS.accent))
    local subtitle = self:CreateFont(header, "Session loot is temporary and clears on reload.",
        "GameFontHighlightSmall", "BOTTOMLEFT", header, "BOTTOMLEFT", 14, 8)
    subtitle:SetTextColor(unpack(self.COLORS.muted))

    local closeButton = CreateFrame("Button", nil, header, "BackdropTemplate")
    closeButton:SetSize(28, 28)
    closeButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", -4, -2)
    closeButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    closeButton:SetBackdropColor(unpack(self.COLORS.panel))
    closeButton:SetBackdropBorderColor(unpack(self.COLORS.border))
    local closeLabel = self:CreateFont(closeButton, "×", "GameFontNormalLarge",
        "CENTER", closeButton, "CENTER", 0, 0)
    closeLabel:SetTextColor(unpack(self.COLORS.muted))
    closeButton:SetScript("OnEnter", function(button)
        button:SetBackdropColor(unpack(self.COLORS.panelHover))
        button:SetBackdropBorderColor(unpack(self.COLORS.accent))
        closeLabel:SetTextColor(unpack(self.COLORS.accent))
    end)
    closeButton:SetScript("OnLeave", function(button)
        button:SetBackdropColor(unpack(self.COLORS.panel))
        button:SetBackdropBorderColor(unpack(self.COLORS.border))
        closeLabel:SetTextColor(unpack(self.COLORS.muted))
    end)
    self.farmSummary = self:CreateFont(window, "", "GameFontHighlightSmall",
        "TOPLEFT", header, "BOTTOMLEFT", 8, -10)
    self.farmSummary:SetTextColor(unpack(self.COLORS.text))
    self.farmValue = self:CreateFont(window, "", "GameFontNormal",
        "TOPRIGHT", header, "BOTTOMRIGHT", -8, -10)
    self.farmValue:SetTextColor(unpack(self.COLORS.gold))

    local scroll = CreateFrame("ScrollFrame", nil, window)
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -34)
    scroll:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -14, 52)
    scroll:EnableMouseWheel(true)
    self.farmScrollFrame = scroll
    self.farmContent = CreateFrame("Frame", nil, scroll)
    self.farmContent:SetSize(490, 1)
    scroll:SetScrollChild(self.farmContent)
    self.farmEmptyState = self:CreateFont(self.farmContent,
        "No instance loot tracked yet.", "GameFontNormal",
        "CENTER", self.farmContent, "CENTER", 0, 0)
    self.farmEmptyState:SetWidth(300)
    self.farmEmptyState:SetJustifyH("CENTER")
    self.farmEmptyState:SetTextColor(unpack(self.COLORS.muted))
    scroll:SetScript("OnMouseWheel", function(frame, delta)
        local range = math.max(UI.farmContent:GetHeight() - frame:GetHeight(), 0)
        local offset = math.max(0, math.min(
            frame:GetVerticalScroll() - delta * UI.FARM_ROW_HEIGHT * 2, range))
        frame:SetVerticalScroll(offset)
        UI:RenderFarmRows()
    end)

    self.farmAutoSellButton = self:CreateActionButton(window, 78)
    self.farmAutoSellButton:SetSize(78, 26)
    self.farmAutoSellButton:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 10, 12)
    self.farmAutoSellButton:SetScript("OnClick", function()
        addon.farmAutoSell = not addon.farmAutoSell
        if addon.merchantOpen then
            addon:StartSelling()
        end
        self:RefreshFarm()
    end)

    self.farmReagentsButton = self:CreateActionButton(window, 74)
    self.farmReagentsButton:SetSize(74, 26)
    self.farmReagentsButton:SetPoint("LEFT", self.farmAutoSellButton, "RIGHT", 3, 0)
    self.farmReagentsButton:SetScript("OnClick", function()
        addon.db.sellFarmReagents = not addon.db.sellFarmReagents
        if addon.merchantOpen then
            addon:StartSelling()
        end
        self:RefreshFarm()
    end)

    self.farmSplitButton = self:CreateActionButton(window, 60)
    self.farmSplitButton:SetSize(60, 26)
    self.farmSplitButton:SetPoint("LEFT", self.farmReagentsButton, "RIGHT", 3, 0)
    self.farmSplitButton:SetScript("OnClick", function()
        addon:SplitNextFarmStack()
    end)
    self.farmSplitButton:SetScript("OnEnter", function(button)
        button:SetBackdropColor(unpack(UI.COLORS.panelHover))
        button:SetBackdropBorderColor(unpack(UI.COLORS.accent))
        button.label:SetTextColor(unpack(UI.COLORS.text))
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:SetText("Split farmed reagents")
        GameTooltip:AddLine(
            "At a merchant, separates the tracked quantity into a free general bag slot, then resumes auto-sell.",
            1, 1, 1, true)
        GameTooltip:Show()
    end)
    self.farmSplitButton:SetScript("OnLeave", function(button)
        button:SetBackdropColor(unpack(UI.COLORS.panel))
        button:SetBackdropBorderColor(unpack(UI.COLORS.border))
        button.label:SetTextColor(unpack(UI.COLORS.muted))
        GameTooltip:Hide()
    end)

    self.cloneFarmButton = self:CreateActionButton(window, 57)
    self.cloneFarmButton:SetSize(57, 26)
    self.cloneFarmButton:SetPoint("LEFT", self.farmSplitButton, "RIGHT", 3, 0)
    self.cloneFarmButton:SetScript("OnClick", function()
        addon:CloneFarmItemsToSell()
    end)

    self.clearFarmButton = self:CreateActionButton(window, 49)
    self.clearFarmButton:SetSize(49, 26)
    self.clearFarmButton:SetPoint("LEFT", self.cloneFarmButton, "RIGHT", 3, 0)
    self.clearFarmButton:SetScript("OnClick", function()
        addon:ClearFarmItems()
    end)

    closeButton:SetScript("OnClick", function()
        addon.farmWindowShouldBeOpen = false
        window:Hide()
    end)

    self.farmRows = {}
    window:SetScript("OnShow", function()
        self:RefreshFarm()
    end)
    self:RefreshFarm()
end

function UI:ShowFarm()
    if not addon.db then return end
    if not self.farmWindow then
        self:CreateFarmWindow()
    end
    addon.farmWindowShouldBeOpen = true
    self.farmWindow:Show()
    self:RefreshFarm()
end
