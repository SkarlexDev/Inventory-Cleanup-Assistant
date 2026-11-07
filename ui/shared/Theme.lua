local _, addon = ...

local MODES = {
    { id = "review", label = "Review" },
    { id = "sell", label = "Sell" },
    { id = "kept", label = "Ignore" },
}
local QUALITY_COLORS = {
    [0] = { 0.62, 0.62, 0.62 },
    [1] = { 1, 1, 1 },
    [2] = { 0.12, 1, 0 },
    [3] = { 0, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 },
}
local ROW_HEIGHT = 40
local COLORS = {
    background = { 0.035, 0.047, 0.071, 0.99 },
    panel = { 0.067, 0.086, 0.125, 1 },
    row = { 0.086, 0.114, 0.161, 1 },
    hover = { 0.12, 0.16, 0.21, 1 },
    accent = { 0.33, 0.78, 0.72, 1 },
    text = { 0.92, 0.95, 0.98, 1 },
    muted = { 0.61, 0.68, 0.77, 1 },
    panelHover = { 0.102, 0.133, 0.184, 1 },
    border = { 0.16, 0.21, 0.29, 1 },
    gold = { 1, 0.82, 0.2, 1 },
    toggleOn = { 0.26, 0.66, 0.51, 1 },
    toggleOff = { 0.88, 0.35, 0.38, 1 },
}

local UI = { mode = "review", search = "", rows = {} }
addon.UI = UI
UI.MODES = MODES
UI.QUALITY_COLORS = QUALITY_COLORS
UI.ROW_HEIGHT = ROW_HEIGHT
UI.COLORS = COLORS

function UI:FormatMoney(value)
    if type(GetMoneyString) == "function" then
        local formatted = GetMoneyString(value, true)
        if formatted then
            return formatted
        end
    end
    return ("%dg %02ds %02dc"):format(
        math.floor(value / 10000),
        math.floor(value / 100) % 100,
        value % 100)
end
