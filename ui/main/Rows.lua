local _, addon = ...
local UI = addon.UI

function UI:CreateRow(index)
    local row = self:CreateItemRow(self.content, {
        height = self.ROW_HEIGHT,
        iconSize = 28,
        iconInset = 7,
        nameTemplate = "GameFontNormal",
        nameGap = 8,
        nameTop = -5,
        nameWidth = 125,
        nameVerticalJustify = "MIDDLE",
        valueTemplate = "GameFontHighlightSmall",
        valueJustify = "LEFT",
        valueRightInset = 135,
        tooltipAnchor = "ANCHOR_LEFT",
    })
    row.value:ClearAllPoints()
    row.value:SetPoint("LEFT", row.name, "RIGHT", 12, 0)
    row.value:SetPoint("RIGHT", row, "RIGHT", -135, 0)

    row.ignoreAction = self:CreateActionButton(row, 55)
    row.ignoreAction:SetPoint("RIGHT", row, "RIGHT", -7, 0)
    row.ignoreAction.label:SetText("Ignore")
    row.ignoreAction:SetScript("OnClick", function()
        if row.item then
            addon:SetItemStatus(row.item, row.ignoreAction.actionStatus)
        end
    end)

    row.action = self:CreateActionButton(row, 55)
    row.action:SetPoint("RIGHT", row.ignoreAction, "LEFT", -4, 0)
    row.action.label:SetText("Sell")
    row.action:SetScript("OnClick", function()
        if row.item then
            addon:SetItemStatus(row.item, row.action.actionStatus)
        end
    end)

    row.index = index
    return row
end
