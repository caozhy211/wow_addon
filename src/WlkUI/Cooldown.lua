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

---@param self Frame
local function TimerFrameOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < self.updateInterval then
        return
    end
    self.elapsed = 0

    local timeLeft = self.duration - (GetTime() - self.start)
    if timeLeft > 0 then
        local label = self.label
        local text, scale, updateInterval, r, g, b = GetTimerInfo(timeLeft)
        label:SetFont("Fonts/blei00d.TTF", label.height * scale, "OUTLINE")
        label:SetText(text)
        label:SetTextColor(r, g, b)
        self.updateInterval = updateInterval
    else
        self:Hide()
    end
end

local function HookCooldownOnHide(self)
    ---@type Frame
    local timerFrame = self.timerFrame
    if timerFrame and timerFrame:IsShown() then
        timerFrame:Hide()
    end
end

local NAMEPLATE_BUFF_HEIGHT = 14

---@param frame Frame
local function GetTimerParentHeight(frame)
    local height = frame:GetHeight()
    while height <= 0 do
        frame = frame:GetParent()
        height = frame:GetHeight()
    end
    return height
end

local mt = getmetatable(CreateFrame("Cooldown", nil, nil, "CooldownFrameTemplate")).__index
---@param self Cooldown
hooksecurefunc(mt, "SetCooldown", function(self, start, duration)
    local height = GetTimerParentHeight(self)
    ---@type Frame
    local timerFrame = self.timerFrame
    if duration > 1.5 and height > NAMEPLATE_BUFF_HEIGHT or abs(height - NAMEPLATE_BUFF_HEIGHT) < 0.005 then
        if not timerFrame then
            timerFrame = CreateFrame("Frame", nil, self)
            self.timerFrame = timerFrame
            timerFrame:SetAllPoints()
            ---@type FontString
            local label = timerFrame:CreateFontString()
            timerFrame.label = label
            label:SetPoint("CENTER")
            timerFrame:SetScript("OnUpdate", TimerFrameOnUpdate)
            self:HookScript("OnHide", HookCooldownOnHide)
        end
        if timerFrame.start ~= start or timerFrame.duration ~= duration then
            timerFrame.start = start
            timerFrame.duration = duration
            timerFrame.updateInterval = 0.01
            timerFrame.label.height = height / 2
        end
        if not timerFrame:IsShown() then
            timerFrame.updateInterval = 0.01
            timerFrame:Show()
        end
    elseif timerFrame and timerFrame:IsShown() then
        timerFrame:Hide()
    end
end)
