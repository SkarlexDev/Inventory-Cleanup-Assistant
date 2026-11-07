local _, addon = ...
local UI = addon.UI

function UI:CreateWindowFrame()
    local window = self:CreateBackdropFrame({
        name = "InventoryCleanupAssistantWindow",
        parent = UIParent,
        width = 500,
        height = 510,
        point = { "CENTER" },
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
    addon:RestoreWindowPosition("inventory", window)
    window:Hide()
    self.window = window
    table.insert(UISpecialFrames, "InventoryCleanupAssistantWindow")

    return window
end

function UI:CreateHeader(window)
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
        addon:SaveWindowPosition("inventory", window)
    end)
    local headerAccent = header:CreateTexture(nil, "ARTWORK")
    headerAccent:SetWidth(3)
    headerAccent:SetPoint("TOPLEFT", header, "TOPLEFT", 1, -8)
    headerAccent:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 1, 8)
    headerAccent:SetColorTexture(unpack(self.COLORS.accent))
    local title = self:CreateFont(header, "INVENTORY CLEANUP", "GameFontNormalLarge",
        "TOPLEFT", header, "TOPLEFT", 14, -8)
    title:SetTextColor(unpack(self.COLORS.accent))
    self.title = title
    local subtitle = self:CreateFont(header, "Review bag items before selling", "GameFontHighlightSmall",
        "BOTTOMLEFT", header, "BOTTOMLEFT", 14, 8)
    subtitle:SetTextColor(unpack(self.COLORS.muted))
    self.subtitle = subtitle

    local settingsButton = CreateFrame("Button", nil, header, "BackdropTemplate")
    settingsButton:SetSize(28, 28)
    settingsButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    settingsButton:SetBackdropColor(unpack(self.COLORS.panel))
    settingsButton:SetBackdropBorderColor(unpack(self.COLORS.border))
    local settingsIcon = settingsButton:CreateTexture(nil, "ARTWORK")
    settingsIcon:SetSize(18, 18)
    settingsIcon:SetPoint("CENTER")
    settingsIcon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    settingsIcon:SetVertexColor(unpack(self.COLORS.muted))
    self.settingsIcon = settingsIcon
    settingsButton:SetScript("OnEnter", function(button)
        button:SetBackdropColor(unpack(self.COLORS.panelHover))
        button:SetBackdropBorderColor(unpack(self.COLORS.accent))
        settingsIcon:SetVertexColor(unpack(self.COLORS.accent))
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        GameTooltip:SetText(self.page == "settings" and "Back to items" or "Settings")
        GameTooltip:Show()
    end)
    settingsButton:SetScript("OnLeave", function(button)
        button:SetBackdropColor(unpack(self.COLORS.panel))
        button:SetBackdropBorderColor(unpack(self.COLORS.border))
        settingsIcon:SetVertexColor(unpack(
            self.page == "settings" and self.COLORS.accent or self.COLORS.muted))
        GameTooltip:Hide()
    end)
    settingsButton:SetScript("OnClick", function()
        if self.page == "settings" then
            self:ShowInventory()
        else
            self:ShowSettings()
        end
    end)
    self.settingsButton = settingsButton

    local closeButton = CreateFrame("Button", nil, header, "BackdropTemplate")
    closeButton:SetSize(28, 28)
    closeButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", -4, -2)
    settingsButton:SetPoint("RIGHT", closeButton, "LEFT", -5, 0)
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
    closeButton:SetScript("OnClick", function() window:Hide() end)

    return header
end

function UI:CreateSummaryPanel(window, header)
    local summaryPanel = self:CreateBackdropFrame({
        parent = window,
        height = 34,
        points = {
            { "TOPLEFT", header, "BOTTOMLEFT", 0, -8 },
            { "TOPRIGHT", header, "BOTTOMRIGHT", 0, -8 },
        },
        backgroundColor = self.COLORS.panel,
        borderColor = self.COLORS.border,
        backdrop = { insets = false },
    })
    local summaryAccent = summaryPanel:CreateTexture(nil, "ARTWORK")
    summaryAccent:SetWidth(2)
    summaryAccent:SetPoint("TOPLEFT", summaryPanel, "TOPLEFT", 1, -7)
    summaryAccent:SetPoint("BOTTOMLEFT", summaryPanel, "BOTTOMLEFT", 1, 7)
    summaryAccent:SetColorTexture(unpack(self.COLORS.accent))
    self.summary = self:CreateFont(summaryPanel, "", "GameFontHighlightSmall",
        "LEFT", summaryPanel, "LEFT", 10, 0)
    self.value = self:CreateFont(summaryPanel, "", "GameFontNormal",
        "RIGHT", summaryPanel, "RIGHT", -10, 0)
    self.value:SetTextColor(unpack(self.COLORS.gold))

    return summaryPanel
end

function UI:CreateTabs(window, summaryPanel)
    local tabBar = CreateFrame("Frame", nil, window)
    self.tabBar = tabBar
    tabBar:SetHeight(30)
    tabBar:SetPoint("TOPLEFT", summaryPanel, "BOTTOMLEFT", 0, -8)
    tabBar:SetPoint("TOPRIGHT", summaryPanel, "BOTTOMRIGHT", 0, -8)
    self.modeButtons = {}
    for index, mode in ipairs(self.MODES) do
        local modeID, modeLabel = mode.id, mode.label
        local button = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        button:SetSize(1, 30)
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        button:SetBackdropColor(unpack(self.COLORS.background))
        button:SetBackdropBorderColor(unpack(self.COLORS.border))
        button.modeLabel = modeLabel
        button.label = self:CreateFont(button, modeLabel, "GameFontNormalSmall",
            "CENTER", button, "CENTER", 0, 0)
        button:SetScript("OnEnter", function(widget)
            widget:SetBackdropColor(unpack(self.COLORS.panelHover))
            widget:SetBackdropBorderColor(unpack(self.COLORS.accent))
            widget.label:SetTextColor(unpack(self.COLORS.text))
        end)
        button:SetScript("OnLeave", function(widget)
            local selected = self.mode == modeID
            widget:SetBackdropColor(unpack(selected and self.COLORS.panel or self.COLORS.background))
            widget:SetBackdropBorderColor(unpack(selected and self.COLORS.accent or self.COLORS.border))
            widget.label:SetTextColor(unpack(selected and self.COLORS.accent or self.COLORS.muted))
        end)
        button:SetScript("OnClick", function()
            self.mode = modeID
            self.scrollFrame:SetVerticalScroll(0)
            self:Refresh()
        end)
        self.modeButtons[mode.id] = button
    end
    self:LayoutModeButtons()
    tabBar:SetScript("OnSizeChanged", function()
        self:LayoutModeButtons()
    end)

    return tabBar
end
