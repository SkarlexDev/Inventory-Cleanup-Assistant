local addonName, addon = ...
_G.InventoryCleanupAssistant = addon

addon.constants = {
    bagCount = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4,
    maxQuality = 4,
    maxItemInfoRequests = 2,
    questItemClass = Enum and Enum.ItemClass and Enum.ItemClass.Questitem or 12,
    tradeGoodsItemClass = Enum and Enum.ItemClass and Enum.ItemClass.Tradegoods or 7,
    excludedNameParts = { "hearthstone" },
}

addon.items = {}
addon.bagItemIDs = {}
addon.itemInfoCache = {}
addon.requestedItems = {}
addon.itemInfoAttempts = {}
addon.failedItemInfo = {}
addon.scanQueued = false
addon.statusText = "Selected items are sold when you open a vendor."
addon.merchantOpen = false
addon.isSelling = false
addon.pendingItemInfo = false
addon.farmItems = {}
addon.farmBagCounts = {}
addon.farmCurrentItems = {}
addon.farmTracking = false
addon.farmInitialized = false
addon.farmBaselinePending = false
addon.farmBaselineGeneration = 0
addon.farmWindowShouldBeOpen = false
addon.farmAutoSell = false

function addon:ScheduleScan()
    if addon.scanQueued then
        return
    end
    addon.scanQueued = true
    C_Timer.After(0, function()
        addon.scanQueued = false
        addon:ScanBags()
        if addon.merchantOpen then
            addon:StartSelling()
        end
    end)
end
