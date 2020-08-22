local function GetTimerInfo(seconds)
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

local function HookCooldownOnUpdate(self, elapsed)
    ---@type FontString
    local timer = self.cdTimer
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < timer.updateInterval then
        return
    end
    self.elapsed = 0

    local timeLeft = timer.duration - (GetTime() - timer.start)
    if timeLeft > 0 then
        local text, scale, updateInterval, r, g, b = GetTimerInfo(timeLeft)
        timer:SetFont("Fonts/blei00d.TTF", timer.height * scale, "OUTLINE")
        timer:SetText(text)
        timer:SetTextColor(r, g, b)
        timer.updateInterval = updateInterval
    else
        timer:Hide()
    end
end

local function HookCooldownOnHide(self)
    ---@type FontString
    local timer = self.cdTimer
    timer:Hide()
end

local function HookCooldownOnShow(self)
    ---@type FontString
    local timer = self.cdTimer
    timer.updateInterval = 0
    timer:Show()
end

local NAMEPLATE_BUFF_HEIGHT = 14

local mt = getmetatable(CreateFrame("Cooldown", nil, nil, "CooldownFrameTemplate")).__index
---@param self Cooldown
hooksecurefunc(mt, "SetCooldown", function(self, start, duration)
    local height = self:GetHeight()
    if duration > 1.5 and height > NAMEPLATE_BUFF_HEIGHT or abs(height - NAMEPLATE_BUFF_HEIGHT) < 0.001 then
        ---@type FontString
        local timer = self.cdTimer
        if not timer then
            timer = self:CreateFontString()
            self.cdTimer = timer
            timer:SetPoint("CENTER")
            self:HookScript("OnUpdate", HookCooldownOnUpdate)
            self:HookScript("OnHide", HookCooldownOnHide)
            self:HookScript("OnShow", HookCooldownOnShow)
        end
        if timer.start ~= start or timer.duration ~= duration then
            timer.start = start
            timer.duration = duration
            timer.height = height / 2
            timer.updateInterval = 0
        end
    end
end)
