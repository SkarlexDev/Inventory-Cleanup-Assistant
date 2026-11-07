local _, addon = ...
local UI = addon.UI

local DISCORD_URL = "https://discord.gg/bPewYaEgnV"
local POPUP_ID = "INVENTORY_CLEANUP_ASSISTANT_DISCORD_INVITE"

StaticPopupDialogs[POPUP_ID] = {
    text = "Join the Inventory Cleanup Assistant Discord community. Press Ctrl+C to copy the invite link.",
    button1 = CLOSE,
    hasEditBox = true,
    editBoxWidth = 260,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(dialog, url)
        local editBox = dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox
        editBox:SetText(url)
        editBox:SetAutoFocus(true)
        editBox:HighlightText()
    end,
    OnHide = function(dialog)
        local editBox = dialog.GetEditBox and dialog:GetEditBox() or dialog.editBox
        editBox:SetText("")
        editBox:ClearFocus()
    end,
}

function UI:CreateDiscordSupport(parent, anchor)
    local heading = self:CreateFont(parent, "SUPPORT", "GameFontNormal",
        "TOPLEFT", anchor, "BOTTOMLEFT", 0, -28)
    heading:SetTextColor(unpack(self.COLORS.accent))

    local description = self:CreateFont(parent,
        "Need help, found an issue, or want to share feedback? Join the community on Discord.",
        "GameFontHighlightSmall", "TOPLEFT", heading, "BOTTOMLEFT", 0, -8)
    description:SetWidth(430)
    description:SetJustifyH("LEFT")
    description:SetTextColor(unpack(self.COLORS.muted))

    local button = self:CreateActionButton(parent, 160)
    button:SetSize(160, 30)
    button:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -14)
    button.label:SetText("JOIN DISCORD")
    button:SetScript("OnClick", function()
        StaticPopup_Show(POPUP_ID, nil, nil, DISCORD_URL)
    end)
end
