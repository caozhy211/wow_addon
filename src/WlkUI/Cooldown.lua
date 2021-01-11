local NAMEPLATE_BUFF_HEIGHT = 14

---@class WlkCooldown:Cooldown
local mt = getmetatable(CreateFrame("Cooldown", nil, nil, "CooldownFrameTemplate")).__index

local function getTimerInfo(seconds)
    local color = HIGHLIGHT_FONT_COLOR
    local scale = 0.8
    local text, updateInterval
    if seconds < 100 then
        color = seconds < 5 and RED_FONT_COLOR or NORMAL_FONT_COLOR
        scale = seconds < 5 and 1.2 or 1
        text = floor(seconds)
        updateInterval = seconds - floor(seconds)
    elseif seconds < SECONDS_PER_HOUR then
        text = ceil(SecondsToMinutes(seconds)) .. "m"
        updateInterval = seconds <= 120 and (seconds - 100) or (seconds % SECONDS_PER_MIN)
    elseif seconds < SECONDS_PER_DAY then
        text = ceil(seconds / SECONDS_PER_HOUR) .. "h"
        updateInterval = seconds % SECONDS_PER_HOUR
    else
        text = ceil(seconds / SECONDS_PER_DAY) .. "d"
        updateInterval = seconds % SECONDS_PER_DAY
    end
    return text, scale, updateInterval, color.r, color.g, color.b
end

---@param self WlkCooldownTimer
local function timerOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < self.updateInterval then
        return
    end
    self.elapsed = 0

    local timeLeft = self.duration - (GetTime() - self.start)
    if timeLeft > 0 then
        local text, scale, updateInterval, r, g, b = getTimerInfo(timeLeft)
        self.label:SetFont(STANDARD_TEXT_FONT, self.label.height * scale, "OUTLINE")
        self.label:SetText(text)
        self.label:SetTextColor(r, g, b)
        self.updateInterval = updateInterval
    else
        self:Hide()
    end
end

---@param self WlkCooldown
local function cooldownOnShow(self)
    local timer = self.wlkTimer
    if timer and timer.duration - (GetTime() - timer.start) > 0 then
        -- 延迟显示，如果立即显示，把冷却中的技能从动作栏移出再放回时，会显示之前的冷却时间
        C_Timer.After(0.01, function()
            timer:Show()
        end)
    end
end

---@param self WlkCooldown
local function cooldownOnHide(self)
    local timer = self.wlkTimer
    if timer then
        timer:Hide()
    end
end

---@param frame Frame
local function getFrameHeight(frame)
    local height = frame:GetHeight()
    while height <= 0 do
        frame = frame:GetParent()
        height = frame:GetHeight()
    end
    return height
end

---@param self WlkCooldown
hooksecurefunc(mt, "SetCooldown", function(self, start, duration)
    local height = getFrameHeight(self)
    ---@class WlkCooldownTimer:Frame
    local timer = self.wlkTimer
    if duration > 1.5 and height - NAMEPLATE_BUFF_HEIGHT > -0.005 then
        if not timer then
            timer = CreateFrame("Frame", nil, self)

            timer:SetAllPoints()
            timer:SetScript("OnUpdate", timerOnUpdate)

            self:HookScript("OnHide", cooldownOnHide)
            self:HookScript("OnShow", cooldownOnShow)

            timer.label = timer:CreateFontString()
            timer.label:SetPoint("CENTER")

            self.wlkTimer = timer
        end
        if timer.start ~= start or timer.duration ~= duration then
            timer.start = start
            timer.duration = duration
            timer.updateInterval = 0.01
            timer.label.height = max(height / 2, 10)
        end
        if not timer:IsShown() then
            timer.updateInterval = 0.01
            timer:Show()
        end
    elseif timer and timer:IsShown() then
        timer:Hide()
    end
end)
