local _, addon = ...
local UI = addon.UI

function UI:Toggle()
    if not self.window then return end
    if self.window:IsShown() then
        self.window:Hide()
    else
        self:ShowInventory()
        addon:ScanBags()
        self.window:Show()
    end
end

function UI:SetMainViewShown(shown)
    for _, frame in ipairs({
        self.summaryPanel,
        self.tabBar,
        self.searchFrame,
        self.zeroValueFilter,
        self.openBagsButton,
        self.scrollFrame,
        self.scrollTrack,
        self.status,
        self.farmButton,
    }) do
        frame:SetShown(shown)
    end
end

function UI:ShowSettings()
    self.page = "settings"
    self:SetMainViewShown(false)
    self.settingsPanel:Show()
    self.title:SetText("SETTINGS")
    self.subtitle:SetText("Configure your inventory lists")
    self:Refresh()
end

function UI:ShowInventory()
    self.page = "inventory"
    self.settingsPanel:Hide()
    self:SetMainViewShown(true)
    self.title:SetText("INVENTORY CLEANUP")
    self.subtitle:SetText("Review bag items before selling")
    self:Refresh()
end

function UI:LayoutModeButtons()
    if not self.tabBar or not self.tabBar:GetWidth() or self.tabBar:GetWidth() <= 0 then
        return
    end
    local gap = 8
    local buttonWidth = (self.tabBar:GetWidth() - gap * (#self.MODES - 1)) / #self.MODES
    for index, mode in ipairs(self.MODES) do
        local button = self.modeButtons[mode.id]
        button:ClearAllPoints()
        button:SetSize(buttonWidth, 30)
        button:SetPoint("LEFT", self.tabBar, "LEFT", (index - 1) * (buttonWidth + gap), 0)
    end
end

function UI:Create()
    local window = self:CreateWindowFrame()
    local header = self:CreateHeader(window)
    local summaryPanel = self:CreateSummaryPanel(window, header)
    self.summaryPanel = summaryPanel
    local tabBar = self:CreateTabs(window, summaryPanel)
    self:CreateFilters(window, tabBar)
    self:CreateItemList(window, tabBar)
    self:CreateFooter(window)
    self:CreateFarmButton(window)
    self.header = header
    self:CreateSettingsPanel(window)
    self.page = "inventory"
    self:Refresh()
end
