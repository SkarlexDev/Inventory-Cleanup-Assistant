local _, addon = ...
local UI = addon.UI

local DEFAULT_INSETS = { left = 1, right = 1, top = 1, bottom = 1 }

function UI:ConfigureFrame(frame, params)
    if params.width ~= nil then frame:SetWidth(params.width) end
    if params.height ~= nil then frame:SetHeight(params.height) end

    if params.points then
        frame:ClearAllPoints()
        for _, point in ipairs(params.points) do
            frame:SetPoint(unpack(point))
        end
    elseif params.point then
        frame:ClearAllPoints()
        frame:SetPoint(unpack(params.point))
    end
end

function UI:CreateBackdropFrame(params)
    local frame = CreateFrame(
        params.frameType or "Frame",
        params.name,
        params.parent,
        params.template or "BackdropTemplate")
    self:ConfigureFrame(frame, params)

    if params.backdrop ~= false then
        local backdrop = params.backdrop or {}
        local backdropInfo = {
            bgFile = backdrop.bgFile or "Interface\\Buttons\\WHITE8x8",
            edgeFile = backdrop.edgeFile or "Interface\\Buttons\\WHITE8x8",
            edgeSize = backdrop.edgeSize or 1,
        }
        if backdrop.insets ~= false then
            backdropInfo.insets = backdrop.insets or DEFAULT_INSETS
        end
        frame:SetBackdrop(backdropInfo)
        frame:SetBackdropColor(unpack(
            params.backgroundColor or self.COLORS.panel))
        frame:SetBackdropBorderColor(unpack(
            params.borderColor or self.COLORS.border))
    end

    return frame
end

function UI:CreateFont(parent, text, template, point, relativeTo, relativePoint, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", template)
    label:SetPoint(point, relativeTo, relativePoint, x, y)
    label:SetText(text)
    return label
end

function UI:CreateActionButton(parent, width, name)
    local button = self:CreateBackdropFrame({
        frameType = "Button",
        name = name,
        parent = parent,
        width = width,
        height = 26,
        backgroundColor = self.COLORS.panel,
        borderColor = self.COLORS.border,
        backdrop = { insets = DEFAULT_INSETS },
    })
    button.label = self:CreateFont(button, "", "GameFontNormalSmall",
        "CENTER", button, "CENTER", 0, 0)
    button.label:SetTextColor(unpack(self.COLORS.muted))
    button:SetScript("OnEnter", function(widget)
        widget:SetBackdropColor(unpack(UI.COLORS.panelHover))
        widget:SetBackdropBorderColor(unpack(UI.COLORS.accent))
        widget.label:SetTextColor(unpack(UI.COLORS.text))
    end)
    button:SetScript("OnLeave", function(widget)
        widget:SetBackdropColor(unpack(UI.COLORS.panel))
        widget:SetBackdropBorderColor(unpack(UI.COLORS.border))
        widget.label:SetTextColor(unpack(UI.COLORS.muted))
    end)
    return button
end

function UI:CreateItemRow(parent, options)
    local row = self:CreateBackdropFrame({
        parent = parent,
        height = options.height,
        backgroundColor = self.COLORS.row,
        borderColor = self.COLORS.border,
        backdrop = { insets = DEFAULT_INSETS },
    })
    row:EnableMouse(true)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(options.iconSize, options.iconSize)
    row.icon:SetPoint("LEFT", row, "LEFT", options.iconInset, 0)
    row.name = self:CreateFont(row, "", options.nameTemplate,
        "TOPLEFT", row.icon, "TOPRIGHT", options.nameGap, options.nameTop)
    row.name:SetWidth(options.nameWidth)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    if options.nameVerticalJustify then
        row.name:SetJustifyV(options.nameVerticalJustify)
    end

    row.value = self:CreateFont(row, "", options.valueTemplate,
        "RIGHT", row, "RIGHT", -options.valueRightInset, 0)
    row.value:SetJustifyH(options.valueJustify or "RIGHT")
    row.value:SetWordWrap(false)
    row.value:SetTextColor(unpack(self.COLORS.gold))

    row:SetScript("OnEnter", function(widget)
        if not widget.item then return end
        widget:SetBackdropColor(unpack(UI.COLORS.panelHover))
        widget:SetBackdropBorderColor(unpack(UI.COLORS.accent))
        GameTooltip:SetOwner(widget, options.tooltipAnchor or "ANCHOR_LEFT")
        if widget.item.bag and widget.item.slot then
            GameTooltip:SetBagItem(widget.item.bag, widget.item.slot)
        else
            GameTooltip:SetHyperlink(
                widget.item.link or ("item:" .. widget.item.itemID))
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(widget)
        widget:SetBackdropColor(unpack(UI.COLORS.row))
        widget:SetBackdropBorderColor(unpack(UI.COLORS.border))
        GameTooltip:Hide()
    end)
    return row
end
