--- 获取计时器的设置参数
---@return string, number, number 剩余时间，缩放系数，更新时间间隔
local function GetSettingParameters(timeRemaining)
    local timeText, updateInterval, scale
    if timeRemaining < 5 then
        timeText = RED_FONT_COLOR_CODE .. floor(timeRemaining) .. FONT_COLOR_CODE_CLOSE
        scale = 1.5
        updateInterval = timeRemaining - floor(timeRemaining)
    elseif timeRemaining < 100 then
        timeText = YELLOW_FONT_COLOR_CODE .. floor(timeRemaining) .. FONT_COLOR_CODE_CLOSE
        scale = 1.2
        updateInterval = timeRemaining - floor(timeRemaining)
    elseif timeRemaining < 3600 then
        timeText = ceil(timeRemaining / 60) .. "m"
        scale = 1
        updateInterval = timeRemaining <= 120 and (timeRemaining - 100) or (timeRemaining % 60)
    elseif timeRemaining < 86400 then
        timeText = ceil(timeRemaining / 3600) .. "h"
        scale = 1
        updateInterval = timeRemaining % 3600
    else
        timeText = ceil(timeRemaining / 86400) .. "d"
        scale = 1
        updateInterval = timeRemaining % 86400
    end
    return timeText, scale, updateInterval
end

--- 创建冷却计时器
---@param cooldown Cooldown
local function CreateTimer(cooldown)
    ---@type Frame
    local timer = CreateFrame("Frame", nil, cooldown)
    timer:SetAllPoints()

    ---@type FontString
    local label = timer:CreateFontString(nil, "ARTWORK", "SystemFont_Outline")
    label:SetHeight(cooldown:GetHeight() * 0.5)
    label:SetPoint("CENTER")

    timer.updateInterval = 0.01

    ---@param self Frame
    timer:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < self.updateInterval then
            return
        end
        self.elapsed = 0

        local timeRemaining = self.duration - (GetTime() - self.start)
        if timeRemaining > 0 then
            local timeText, scale, updateInterval = GetSettingParameters(timeRemaining)
            label:SetText(timeText)
            label:SetScale(scale)
            self.updateInterval = updateInterval
        else
            self:Hide()
        end
    end)

    timer:SetScript("OnShow", function(self)
        -- 计时器显示时需要立即更新
        self.updateInterval = 0.01
    end)

    cooldown.timerFrame = timer
    return timer
end

--- 获取框架名称，如果没有名称则获取其父框架的名称，直到返回正确的框架名称
---@param frame Frame
local function GetFrameName(frame)
    local name = frame:GetName()
    while not name do
        frame = frame:GetParent()
        name = frame:GetName()
    end
    return name
end

local metatable = getmetatable(CreateFrame("Cooldown", nil, nil, "CooldownFrameTemplate")).__index
--- 调用 SetCooldown 方法后在冷却上显示计时
hooksecurefunc(metatable, "SetCooldown", function(self, start, duration)
    local name = GetFrameName(self)
    -- Compact 和 LossOfControl 的冷却不显示计时
    if strfind(name, "^Compact") or strfind(name, "^LossOfControl") then
        return
    end

    ---@type Frame
    local timer = self.timerFrame
    if duration > 1.5 then
        -- 持续时间大于全局冷却时间，则显示计时
        if not timer then
            timer = CreateTimer(self)
        end

        timer.start = start
        timer.duration = duration
        -- 使用 start 和 duration 作为冷却计时器的标识 id，当 id 发生变化时，需要立即更新
        local id = format("%s-%s", floor(start * 1000), floor(duration * 1000))
        if id ~= timer.id then
            timer.id = id
            -- 立即更新
            timer.updateInterval = 0.01
        end
        timer:Show()
    elseif timer then
        -- 持续时间小于等于全局冷却时间不显示计时
        timer:Hide()
    end
end)
