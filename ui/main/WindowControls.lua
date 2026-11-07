local _, addon = ...
local UI = addon.UI

function UI:CreateFilters(window, tabBar)
    self.searchFrame = self:CreateBackdropFrame({
        parent = window,
        height = 26,
        points = {
            { "TOPLEFT", tabBar, "BOTTOMLEFT", 236, -8 },
            { "TOPRIGHT", tabBar, "BOTTOMRIGHT", -2, -8 },
        },
        backgroundColor = self.COLORS.background,
        borderColor = self.COLORS.border,
        backdrop = { insets = { left = 1, right = 1, top = 1, bottom = 1 } },
    })
    self.searchBox = CreateFrame("EditBox", nil, self.searchFrame)
    self.searchBox:SetPoint("TOPLEFT", self.searchFrame, "TOPLEFT", 9, -2)
    self.searchBox:SetPoint("BOTTOMRIGHT", self.searchFrame, "BOTTOMRIGHT", -8, 2)
    self.searchBox:SetAutoFocus(false)
    self.searchBox:SetMaxLetters(40)
    self.searchBox:SetFontObject(GameFontHighlight)
    self.searchBox:SetTextInsets(0, 0, 0, 0)
    self.searchPlaceholder = self:CreateFont(self.searchFrame, "Search items...", "GameFontDisableSmall",
        "LEFT", self.searchFrame, "LEFT", 10, 0)
    self.searchBox:SetScript("OnTextChanged", function(editBox)
        UI.search = editBox:GetText():lower()
        UI.scrollFrame:SetVerticalScroll(0)
        UI.searchPlaceholder:SetShown(editBox:GetText() == "")
        UI:Refresh()
    end)
    self.searchBox:SetScript("OnEditFocusGained", function()
        UI.searchFrame:SetBackdropBorderColor(unpack(self.COLORS.accent))
        UI.searchPlaceholder:Hide()
    end)
    self.searchBox:SetScript("OnEditFocusLost", function(editBox)
        UI.searchFrame:SetBackdropBorderColor(unpack(self.COLORS.border))
        UI.searchPlaceholder:SetShown(editBox:GetText() == "")
    end)
    self.searchBox:SetScript("OnEscapePressed", function(editBox)
        editBox:SetText("")
        editBox:ClearFocus()
    end)
    self.searchFrame:EnableMouse(true)
    self.searchFrame:SetScript("OnEnter", function()
        UI.searchFrame:SetBackdropBorderColor(unpack(self.COLORS.accent))
    end)
    self.searchFrame:SetScript("OnLeave", function()
        UI.searchFrame:SetBackdropBorderColor(unpack(
            UI.searchBox:HasFocus() and self.COLORS.accent or self.COLORS.border))
    end)
    self.searchFrame:SetScript("OnMouseDown", function()
        self.searchBox:SetFocus()
    end)

    self.zeroValueFilter = self:CreateActionButton(window, 128)
    self.zeroValueFilter:SetSize(128, 26)
    self.zeroValueFilter:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -8)
    self.zeroValueFilter:SetScript("OnClick", function()
        addon.db.showZeroValue = not addon.db.showZeroValue
        UI.scrollFrame:SetVerticalScroll(0)
        UI:Refresh()
    end)

    self.openBagsButton = self:CreateActionButton(window, 96)
    self.openBagsButton:SetPoint("LEFT", self.zeroValueFilter, "RIGHT", 6, 0)
    self.openBagsButton.label:SetText("OPEN BAGS")
    self.openBagsButton:SetScript("OnClick", ToggleAllBags)

end

function UI:UpdateOpenBagsButton()
    local bagFrame = _G.ContainerFrameCombinedBags
    if not bagFrame or not bagFrame:IsShown() then
        bagFrame = nil
        for index = 1, (NUM_CONTAINER_FRAMES or 13) do
            local frame = _G["ContainerFrame" .. index]
            if not bagFrame and frame and frame:IsShown() then
                bagFrame = frame
            end
        end
    end

    if self.openBagsButton then
        self.openBagsButton.label:SetText(bagFrame and "CLOSE BAGS" or "OPEN BAGS")
    end
end

function UI:CreateItemList(window, tabBar)
    local scroll = CreateFrame("ScrollFrame", "InventoryCleanupAssistantScrollFrame", window)
    scroll:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -38)
    scroll:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -28, 44)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local range = math.max(UI.content:GetHeight() - self:GetHeight(), 0)
        local offset = math.max(0, math.min(self:GetVerticalScroll() - delta * UI.ROW_HEIGHT * 2, range))
        self:SetVerticalScroll(offset)
    end)
    self.scrollFrame = scroll
    self.content = CreateFrame("Frame", nil, scroll)
    self.content:SetSize(450, 1)
    scroll:SetScrollChild(self.content)
    scroll:SetScript("OnVerticalScroll", function()
        UI:UpdateScrollBar()
        UI:RenderRows()
    end)

    self.scrollTrack = CreateFrame("Frame", nil, window)
    self.scrollTrack:SetWidth(10)
    self.scrollTrack:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, 0)
    self.scrollTrack:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 6, 0)
    local track = self.scrollTrack:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(2)
    track:SetPoint("TOP", self.scrollTrack, "TOP")
    track:SetPoint("BOTTOM", self.scrollTrack, "BOTTOM")
    track:SetColorTexture(0.10, 0.13, 0.18, 0.85)

    self.scrollBar = CreateFrame("Slider", nil, self.scrollTrack)
    self.scrollBar:SetOrientation("VERTICAL")
    self.scrollBar:SetPoint("TOPLEFT", self.scrollTrack, "TOPLEFT", 1, 0)
    self.scrollBar:SetPoint("BOTTOMRIGHT", self.scrollTrack, "BOTTOMRIGHT", -1, 0)
    self.scrollBar:SetMinMaxValues(0, 0)
    self.scrollBar:SetValueStep(1)
    self.scrollBar:SetObeyStepOnDrag(true)
    self.scrollBar:SetValue(0)
    self.scrollBar:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    self.scrollThumb = self.scrollBar:GetThumbTexture()
    self.scrollThumb:SetSize(8, 28)
    self.scrollThumb:SetColorTexture(0.20, 0.45, 0.45, 1)
    self.scrollBar:SetScript("OnValueChanged", function(_, value)
        if not UI.syncingScrollBar then
            scroll:SetVerticalScroll(value)
        end
    end)
    self.scrollBar:SetScript("OnEnter", function()
        self.scrollThumb:SetColorTexture(unpack(self.COLORS.accent))
    end)
    self.scrollBar:SetScript("OnLeave", function()
        self.scrollThumb:SetColorTexture(0.20, 0.45, 0.45, 1)
    end)
    self.scrollFrame = scroll
    scroll:HookScript("OnSizeChanged", function()
        UI:Refresh()
    end)
    self.emptyState = self:CreateFont(self.content, "", "GameFontNormal",
        "TOP", self.content, "TOP", 0, -72)
    self.emptyState:SetWidth(430)
    self.emptyState:SetJustifyH("CENTER")
    self.emptyState:SetTextColor(unpack(self.COLORS.muted))

end

function UI:CreateFooter(window)
    self.status = self:CreateFont(window, "", "GameFontHighlightSmall",
        "BOTTOMLEFT", window, "BOTTOMLEFT", 14, 15)
    self.status:SetWidth(350)
    self.status:SetTextColor(unpack(self.COLORS.muted))

end

function UI:CreateSettingsPanel(window)
    local panel = CreateFrame("Frame", nil, window, "BackdropTemplate")
    panel:SetPoint("TOPLEFT", self.header, "BOTTOMLEFT", 0, -8)
    panel:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -12, 12)
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    panel:SetBackdropColor(unpack(self.COLORS.panel))
    panel:SetBackdropBorderColor(unpack(self.COLORS.border))
    panel:Hide()
    self.settingsPanel = panel

    local heading = self:CreateFont(panel, "SETTINGS", "GameFontNormalLarge",
        "TOPLEFT", panel, "TOPLEFT", 16, -16)
    heading:SetTextColor(unpack(self.COLORS.accent))
    local description = self:CreateFont(panel, "Inventory and Farm Loot options.",
        "GameFontHighlightSmall", "TOPLEFT", heading, "BOTTOMLEFT", 0, -8)
    description:SetTextColor(unpack(self.COLORS.muted))

    self.farmLootToggle = self:CreateActionButton(panel, 172)
    self.farmLootToggle:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -18)
    self.farmLootToggle:SetScript("OnClick", function()
        addon:SetFarmLootEnabled(not addon.db.enableFarmLoot)
    end)

    self.farmLootDescription = self:CreateFont(panel,
        "Automatically tracks bag loot and opens Farm Loot when entering an instance.",
        "GameFontHighlightSmall", "TOPLEFT", self.farmLootToggle, "BOTTOMLEFT", 0, -8)
    self.farmLootDescription:SetWidth(420)
    self.farmLootDescription:SetJustifyH("LEFT")
    self.farmLootDescription:SetTextColor(unpack(self.COLORS.muted))
    self:CreateDiscordSupport(panel, self.farmLootDescription)
    self:RefreshSettings()
end

function UI:RefreshSettings()
    if not self.farmLootToggle or not addon.db then
        return
    end

    local enabled = addon.db.enableFarmLoot
    self.farmLootToggle.label:SetText(enabled
        and "FARM LOOT  |cff42a882ENABLED|r"
        or "FARM LOOT  |cffe05a61DISABLED|r")
    self.farmLootDescription:SetText(enabled
        and "Automatically tracks bag loot and opens Farm Loot when entering an instance."
        or "Automatic tracking, auto-sell, and instance popups are disabled.")
end
