hooksecurefunc("MirrorTimerFrame_OnUpdate", function(self)
    local name = self:GetName()
    local label = _G[name .. "Text"]:GetText()
    local index = label:find(" ")
    label = index and label:sub(1, index - 1) or label

    local _, maxValue = _G[name .. "StatusBar"]:GetMinMaxValues()
    local maxMinutes = floor(maxValue / 60)
    local maxSeconds = floor(maxValue - maxMinutes * 60)

    local currentValue = min(max(self.value, 0), maxValue)
    local currentMinutes = floor(currentValue / 60)
    local currentSeconds = floor(currentValue - currentMinutes * 60)
    local time = format("%02d:%02d/%02d:%02d", currentMinutes, currentSeconds, maxMinutes, maxSeconds)

    _G[name .. "Text"]:SetText(label .. " " .. time)
end)