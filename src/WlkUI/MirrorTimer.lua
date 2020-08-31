for i = 1, MIRRORTIMER_NUMTIMERS do
    ---@type Texture
    local border = _G["MirrorTimer" .. i .. "Border"]
    border:Hide()
end

---@param frame Frame
hooksecurefunc("MirrorTimerFrame_OnUpdate", function(frame)
    if frame.paused then
        return
    end
    local name = frame:GetName()
    ---@type FontString
    local label = _G[name .. "Text"]
    local text = strsplit(" ", label:GetText())
    ---@type StatusBar
    local statusbar = _G[name .. "StatusBar"]
    local _, maxValue = statusbar:GetMinMaxValues()
    local value = statusbar:GetValue()
    ---@type ColorMixin
    local color = value > 30 and GREEN_FONT_COLOR or RED_FONT_COLOR
    label:SetFormattedText("%s %s/%s", text, color:WrapTextInColorCode(SecondsToClock(value)), SecondsToClock(maxValue))
end)
