local font = GameFontNormal:GetFont()
local cooldown = CreateFrame("Cooldown", nil, nil, "CooldownFrameTemplate")
local table = getmetatable(cooldown).__index
local timers = {}

local function GetCooldownName(cooldown)
    local frame = cooldown
    local name = frame:GetName()
    while not name do
        frame = frame:GetParent()
        name = frame:GetName()
    end
    return name
end

local function GetTimeInfo(time)
    if time < 5 then
        return "|cffff0000" .. floor(time) .. "|r", 0.2, 1.3
    elseif time < 100 then
        return "|cffffff00" .. floor(time) .. "|r", time - floor(time), 1.2
    elseif time < 3600 then
        local updateTime = time < 120 and (time - 100) or (time % 60)
        return ceil(time / 60) .. "m", updateTime, 1
    elseif time < 86400 then
        return ceil(time / 3600) .. "h", time % 3600, 1
    end
    return ceil(time / 86400) .. "d", time % 86400, 1
end

local function CreateTimer(cooldown)
    local name = GetCooldownName(cooldown)
    if strfind(name, "Compact") or strfind(name, "LossOfControl") then
        return
    end

    local timer = CreateFrame("Frame", nil, cooldown)
    timer:SetAllPoints()
    timers[cooldown] = timer

    timer.updateTime = 0.01
    local text = timer:CreateFontString()
    local height = min(max(floor(cooldown:GetParent():GetHeight() * 0.4), 7), 21)
    text:SetFont(font, height, "Outline")
    local type = (strfind(name, "MyUnit") or strfind(name, "NamePlate")) and "Aura" or "Action"
    text:SetPoint(type == "Aura" and "TopRight" or "Center")

    timer:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < self.updateTime then
            return
        end
        self.elapsed = 0

        local remaining = self.start + self.duration - GetTime()
        if remaining > 0.25 then
            local time, updateTime, coefficient = GetTimeInfo(remaining)
            text:SetFont(font, height * coefficient, "Outline")
            text:SetText(time)
            self.updateTime = updateTime
        else
            self:Hide()
        end
    end)

    timer:SetScript("OnShow", function(self)
        self.updateTime = 0.01
    end)

    return timer
end

hooksecurefunc(table, "SetCooldown", function(cooldown, start, duration)
    if duration > 1.5 then
        local timer = timers[cooldown] or CreateTimer(cooldown)
        if timer then
            local id = format("%s-%s", floor(start * 1000), floor(duration * 1000))
            timer.start = start
            timer.duration = duration
            if timer.id ~= id then
                timer.id = id
                timer.updateTime = 0.01
            end
            timer:Show()
        end
    elseif timers[cooldown] then
        timers[cooldown]:Hide()
    end
end)