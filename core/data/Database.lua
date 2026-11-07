local _, addon = ...

function addon:InitializeDatabase()
    if type(InventoryCleanupAssistantDB) ~= "table" then
        InventoryCleanupAssistantDB = {}
    end
    self.db = InventoryCleanupAssistantDB
    if type(self.db.saleRules) ~= "table" then
        self.db.saleRules = type(self.db.autoSellItemIDs) == "table"
            and self.db.autoSellItemIDs or {}
    end
    if type(self.db.keptItemIDs) ~= "table" then
        self.db.keptItemIDs = {}
    end
    if type(self.db.windowPositions) ~= "table" then
        self.db.windowPositions = {}
    end
    if self.db.showZeroValue == nil then
        self.db.showZeroValue = self.db.ignoreZeroValue ~= true
    end
    if self.db.sellFarmReagents == nil then
        self.db.sellFarmReagents = false
    end
    if self.db.enableFarmLoot == nil then
        self.db.enableFarmLoot = true
    end
    self.db.ignoreZeroValue = nil
    self.db.windowWidth = nil
    self.db.windowHeight = nil
    self.db.rulesVersion = 3
end

function addon:SaveWindowPosition(key, frame)
    if not self.db then return end
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    if not point or not relativePoint or type(x) ~= "number" or type(y) ~= "number" then
        return
    end
    self.db.windowPositions[key] = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
end

function addon:RestoreWindowPosition(key, frame)
    local position = self.db
        and self.db.windowPositions
        and self.db.windowPositions[key]
    if type(position) ~= "table"
        or type(position.point) ~= "string"
        or type(position.relativePoint) ~= "string"
        or type(position.x) ~= "number"
        or type(position.y) ~= "number" then
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
end

function addon:GetItemStatus(item)
    if self.db.keptItemIDs[item.itemID] then
        return "kept"
    end
    local rule = self.db.saleRules[item.itemID]
    if rule ~= nil then
        return rule and "sell" or "review"
    end
    return item.quality == 0 and "sell" or "review"
end

function addon:IsExcluded(item)
    local name = item.name and item.name:lower() or ""
    local link = item.link and item.link:lower() or ""
    for _, excludedText in ipairs(self.constants.excludedNameParts) do
        if name:find(excludedText, 1, true) or link:find(excludedText, 1, true) then
            return true
        end
    end
    return false
end

function addon:SetItemStatus(item, status)
    if self:IsExcluded(item) then
        return
    end
    self.db.keptItemIDs[item.itemID] = status == "kept" and true or nil
    self.db.saleRules[item.itemID] = status == "sell"
    self:RefreshUI()
    if self.merchantOpen then
        self:StartSelling()
    end
end
