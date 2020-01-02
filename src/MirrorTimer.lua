--- 隐藏镜像计时条边框
for i = 1, MIRRORTIMER_NUMTIMERS do
    ---@type Texture
    local border = _G["MirrorTimer" .. i .. "Border"]
    border:Hide()
end

--- 镜像计时条显示时间数据
---@param self Frame
hooksecurefunc("MirrorTimerFrame_OnUpdate", function(self)
    local name = self:GetName()
    ---@type FontString
    local label = _G[name .. "Text"]
    local text = label:GetText()
    text = strsplit(" ", text)

    ---@type StatusBar
    local statusBar = _G[name .. "StatusBar"]
    -- 获取最大时间
    local _, maxValue = statusBar:GetMinMaxValues()
    local maxMinutes = floor(maxValue / 60)
    local maxSeconds = floor(maxValue - maxMinutes * 60)
    -- 获取当前时间
    local value = Clamp(self.value, 0, maxValue)
    local minutes = floor(value / 60)
    local seconds = floor(value - minutes * 60)

    label:SetFormattedText("%s %02d:%02d/%02d:%02d", text, minutes, seconds, maxMinutes, maxSeconds)
end)
