local _, addon = ...
local eventFrame = CreateFrame("Frame")

function addon:RefreshUI()
    if self.UI and self.UI.Refresh then
        self.UI:Refresh()
    end
end

function InventoryCleanupAssistant_Toggle()
    if addon.UI then
        addon.UI:Toggle()
    end
end

function InventoryCleanupAssistant_Command()
    InventoryCleanupAssistant_Toggle()
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("BAG_OPEN")
eventFrame:RegisterEvent("BAG_CLOSED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        addon:InitializeDatabase()
        addon:ScanBags()
        addon.UI:Create()
        addon.UI.window:Show()
    elseif event == "BAG_OPEN" or event == "BAG_CLOSED" then
        C_Timer.After(0, function()
            if addon.UI then
                addon.UI:UpdateOpenBagsButton()
            end
        end)
    elseif event == "BAG_UPDATE_DELAYED" then
        addon:ScanBags()
    elseif event == "GET_ITEM_INFO_RECEIVED" or event == "ITEM_DATA_LOAD_RESULT" then
        local itemID, success = ...
        if addon.requestedItems[itemID] then
            addon.requestedItems[itemID] = nil
            if success then
                addon.itemInfoCache[itemID] = nil
                addon.failedItemInfo[itemID] = nil
            elseif (addon.itemInfoAttempts[itemID] or 0) >= addon.constants.maxItemInfoRequests then
                addon.failedItemInfo[itemID] = true
            end
            addon:ScheduleScan()
        end
    elseif event == "MERCHANT_SHOW" then
        addon.merchantOpen = true
        addon:ScanBags()
        addon:StartSelling()
    elseif event == "MERCHANT_CLOSED" then
        addon.merchantOpen = false
        addon:StopSelling()
    end
end)

SLASH_INVENTORYCLEANUPASSISTANT1 = "/ica"
SlashCmdList.INVENTORYCLEANUPASSISTANT = InventoryCleanupAssistant_Command
