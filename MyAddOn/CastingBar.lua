local font = GameFontNormal:GetFont()
local config
local target, focus, boss

local function MovePetCastingBar()
    local width = 228
    local height = 30
    PetCastingBarFrame:SetSize(width - height, height)
    PetCastingBarFrame:ClearAllPoints()
    PetCastingBarFrame:SetPoint("Bottom", height / 2, 143 + 7)
    PetCastingBarFrame.SetPoint = nop
end

local function MovePlayerCastingBar()
    local width = 228
    local height = 30
    CastingBarFrame:SetSize(width - height, height)
    CastingBarFrame:ClearAllPoints()
    CastingBarFrame:SetPoint("Bottom", height / 2, 143 + 7)
    CastingBarFrame.SetPoint = nop
end

local function HideLayers(castingBar)
    castingBar.Flash:SetTexture(nil)
    castingBar.Border:SetTexture(nil)
end

local function ShowIcon(castingBar)
    castingBar.Icon:Show()
    local size = castingBar:GetHeight()
    castingBar.Icon:SetSize(size, size)
    castingBar.Icon:SetPoint("Right", castingBar, "Left")
    castingBar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
end

local function GetCharSize(char)
    if not char then
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    end
    return 1
end

local function CutOffText(text, maxWidth)
    if #text * 5 <= maxWidth then
        return text
    end
    local length = 0
    local offset = 0
    for i = 1, #text do
        local index = i + offset
        local size = GetCharSize(strbyte(text, index))

        length = length + size
        if length * 5 > maxWidth then
            return strsub(text, 1, index - 1) .. "..."
        end

        offset = offset + size - 1
    end
end

local function MoveText(castingBar)
    castingBar.Text:SetFont(font, 12, "Outline")
    castingBar.Text:ClearAllPoints()
    castingBar.Text:SetPoint("Left", 5, 0)
    castingBar.Text:SetJustifyH("Left")
    castingBar:HookScript("OnEvent", function(self, event, unit)
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
            if self.unit ~= unit then
                return
            end

            local _, text
            if self.casting then
                _, text = UnitCastingInfo(self.unit)
            else
                _, text = UnitChannelInfo(self.unit)
            end

            local maxWidth = self:GetWidth() / 2
            self.Text:SetText(CutOffText(text, maxWidth))
        end
    end)
end

local function FormatTime(time)
    if time <= 10 then
        return format("%.1f", time)
    elseif time <= 60 then
        return format("%d", time)
    elseif time <= 3600 then
        return format("%d:%02d", time / 60, time % 60)
    end
    return format("%d:%02d", time / 3600, time % 3600 / 60)
end

local function GetCastingSpellInfo(castingBar)
    local spell, startTime, endTime, isTradeSkill, _
    if castingBar.casting then
        spell, _, _, startTime, endTime, isTradeSkill = UnitCastingInfo(castingBar.unit)
    else
        spell, _, _, startTime, endTime, isTradeSkill = UnitChannelInfo(castingBar.unit)
    end
    if startTime and endTime then
        return spell, startTime / 1000, endTime / 1000, isTradeSkill
    end
end

local function ShowTime(castingBar)
    local timeText = castingBar:CreateFontString()
    timeText:SetFont(font, 12, "Outline")
    timeText:SetPoint("Right")

    local delayText = castingBar:CreateFontString()
    delayText:SetFont(font, 12, "Outline")
    delayText:SetPoint("Right", timeText, "Left", -2, 0)
    delayText:SetTextColor(1, 0, 0)

    local delay, startTime, endTime, _
    castingBar:HookScript("OnEvent", function(self, event)
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
            _, startTime, endTime = GetCastingSpellInfo(self)
            if not startTime or not endTime then
                return
            end
            delay = 0
        elseif event == "UNIT_SPELLCAST_DELAYED" then
            local oldStartTime = startTime
            _, startTime, endTime = GetCastingSpellInfo(self)
            if not startTime or not endTime then
                return
            end
            if self.casting then
                delay = (delay or 0) + (startTime - (oldStartTime or startTime))
            else
                delay = (delay or 0) + ((oldStartTime or startTime) - startTime)
            end
        end
    end)

    castingBar:HookScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.01 then
            return
        end
        self.elapsed = 0

        local value
        local maxValue = self.maxValue
        if self.casting then
            value = max(maxValue - self.value, 0)
            timeText:SetFormattedText("%s/%s", FormatTime(value), FormatTime(maxValue))
        elseif self.channeling then
            value = max(self.value, 0)
            timeText:SetFormattedText("%s/%s", FormatTime(value), FormatTime(maxValue))
        end

        if delay and delay ~= 0 and (self.casting or self.channeling) then
            delayText:SetFormattedText("+%.1f", delay)
        else
            delayText:SetText("")
        end
    end)
end

local function ShowShieldBorder(castingBar, size)
    local width = castingBar:GetWidth() + castingBar:GetHeight()
    local height = castingBar:GetHeight() + size * 2

    local top = castingBar:CreateTexture()
    top:SetSize(width, size)
    top:SetPoint("BottomRight", castingBar, "TopRight")
    top:SetColorTexture(1, 1, 1)

    local bottom = castingBar:CreateTexture()
    bottom:SetSize(width, size)
    bottom:SetPoint("TopRight", castingBar, "BottomRight")
    bottom:SetColorTexture(1, 1, 1)

    local left = castingBar:CreateTexture()
    left:SetSize(size, height)
    left:SetPoint("Right", castingBar.Icon, "Left")
    left:SetColorTexture(1, 1, 1)

    local right = castingBar:CreateTexture()
    right:SetSize(size, height)
    right:SetPoint("Left", castingBar, "Right")
    right:SetColorTexture(1, 1, 1)

    hooksecurefunc(castingBar.BorderShield, "Show", function()
        top:Show()
        bottom:Show()
        left:Show()
        right:Show()
    end)

    hooksecurefunc(castingBar.BorderShield, "Hide", function()
        top:Hide()
        bottom:Hide()
        left:Hide()
        right:Hide()
    end)
end

local function CreateCastingBar(cfg)
    local bar = CreateFrame("StatusBar", cfg.name, UIParent, "CastingBarFrameTemplate")
    bar:Hide()
    bar:SetSize(cfg.width - cfg.height, cfg.height)

    CastingBarFrame_OnLoad(bar, cfg.unit, cfg.showTradeSkills, cfg.showShield)

    bar.BorderShield:SetTexture(nil)
    HideLayers(bar)
    ShowIcon(bar)
    ShowShieldBorder(bar, cfg.border)

    bar:RegisterEvent(cfg.event)

    bar:SetScript("OnEvent", function(self, event, unit, castID)
        if event == cfg.event then
            event, unit = self:UpdateEventAndUnit(event, unit)
        end
        CastingBarFrame_OnEvent(self, event, unit, castID)
    end)

    ShowTime(bar)
    MoveText(bar)

    function bar:UpdateEventAndUnit(event, unit)
        local nameChannel = UnitChannelInfo(self.unit)
        local nameSpell = UnitCastingInfo(self.unit)
        if nameChannel then
            return "UNIT_SPELLCAST_CHANNEL_START", self.unit
        elseif nameSpell then
            return "UNIT_SPELLCAST_START", self.unit
        else
            self.casting = nil
            self.channeling = nil
            self:SetMinMaxValues(0, 0)
            self:SetValue(0)
            self:Hide()
            return event, unit
        end
    end

    return bar
end

local function ShowLatency()
    local latency = CreateFrame("Frame", nil, CastingBarFrame)
    latency:SetAllPoints()
    latency:SetFrameLevel(CastingBarFrame:GetFrameLevel())

    latency.box = latency:CreateTexture()
    latency.box:SetHeight(latency:GetHeight())
    latency.box:SetColorTexture(1, 0, 0, 0.5)

    latency.text = latency:CreateFontString()
    latency.text:SetFont(font, 8, "Outline")

    latency:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
    latency:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    latency:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

    latency:SetScript("OnEvent", function(self, event, unit)
        if event == "CURRENT_SPELL_CAST_CHANGED" then
            self.sendTime = GetTime()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            if unit ~= "player" and unit ~= "vehicle" then
                return
            end
            self.sendTime = nil
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            if unit ~= "player" and unit ~= "vehicle" then
                return
            end
            self.box:Hide()
            self.text:Hide()
        end
    end)

    CastingBarFrame:HookScript("OnEvent", function(self, event)
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
            local _, startTime, endTime = GetCastingSpellInfo(self)
            if not latency.sendTime or not endTime then
                return
            end
            local timeDiff = GetTime() - latency.sendTime
            local castLength = endTime - startTime
            local percent = min(timeDiff, castLength) / castLength
            if percent > 0 then
                latency.box:SetWidth(self:GetWidth() * percent)
                latency.box:ClearAllPoints()
                latency.box:SetPoint(self.casting and "Right" or "Left")
                latency.box:Show()

                latency.text:ClearAllPoints()
                latency.text:SetPoint(self.casting and "BottomRight" or "BottomLeft")
                latency.text:SetFormattedText("%dms", min(timeDiff, castLength) * 1000)
                latency.text:Show()
            else
                latency.box:Hide()
                latency.text:Hide()
            end
            latency.sendTime = nil
        end
    end)
end

local function ShowChannelTicks()
    local barTicks = setmetatable({}, {
        __index = function(ticks, i)
            local spark = CastingBarFrame:CreateTexture()
            spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
            spark:SetBlendMode("Add")
            spark:SetSize(20, CastingBarFrame:GetHeight() * 2.2)
            ticks[i] = spark
            return spark
        end
    })
    local spellTicks = {
        [GetSpellInfo(234153)] = 6,
    }
    local channelEndTime, channelDuration, numTicks, tickTime, ticks

    function barTicks:Update(num, duration, total)
        if num and num > 0 then
            local width = CastingBarFrame:GetWidth()
            for i = 1, num do
                local tick = self[i]
                tick:ClearAllPoints()
                local xOffset = total[i] / duration
                tick:SetPoint("Center", CastingBarFrame, "Right", -width * xOffset, 0)
                tick:Show()
            end

            for i = num + 1, #self do
                self[i]:Hide()
            end
        else
            for i = 1, #self do
                self[i]:Hide()
            end
        end
    end

    CastingBarFrame:HookScript("OnEvent", function(self, event)
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
            local spell, startTime, endTime = GetCastingSpellInfo(self)
            if not startTime or not endTime then
                return
            end
            if self.channeling then
                channelEndTime = endTime
                channelDuration = endTime - startTime
                numTicks = spellTicks[spell] or 0
                tickTime = numTicks > 0 and (channelDuration / numTicks) or 0
                ticks = ticks or {}
                for i = 1, numTicks do
                    ticks[i] = channelDuration - (i - 1) * tickTime
                end
                barTicks:Update(numTicks, channelDuration, ticks)
            else
                barTicks:Update(0)
                channelDuration = nil
            end
        elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED" then
            barTicks:Update(0)
            channelDuration = nil
        elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
            local _, startTime, endTime = GetCastingSpellInfo(self)
            if not startTime or not endTime then
                return
            end
            if self.channeling and endTime > channelEndTime then
                local duration = endTime - startTime
                if channelDuration and duration > channelDuration and numTicks > 0 then
                    local extraTime = duration - channelDuration
                    for i = 1, numTicks do
                        ticks[i] = ticks[i] + extraTime
                    end
                    while ticks[numTicks] > tickTime do
                        numTicks = numTicks + 1
                        ticks[numTicks] = ticks[numTicks - 1] - tickTime
                    end

                    channelDuration = duration
                    channelEndTime = endTime
                    barTicks:Update(numTicks, channelDuration, ticks)
                end
            end
        end
    end)
end

local function MergeTradeSkill()
    local barWidth = CastingBarFrame:GetWidth()

    local spark = CastingBarFrame:CreateTexture()
    spark:Hide()
    spark:SetSize(20, CastingBarFrame:GetHeight() * 2)
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetBlendMode("Add")

    local text = CastingBarFrame:CreateFontString()
    text:SetFont(font, 9, "Outline")
    text:SetPoint("Bottom")

    local merging, current, total

    CastingBarFrame:HookScript("OnHide", function()
        merging = nil
        text:SetText("")
        spark:Hide()
    end)

    CastingBarFrame:HookScript("OnEvent", function(self, event)
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
            local _, _, _, isTradeSkill = GetCastingSpellInfo(self)
            if isTradeSkill and self.casting then
                local repeatCount = C_TradeSkillUI.GetRecipeRepeatCount()
                if not merging and repeatCount > 1 then
                    merging = true
                    current = 0
                    total = repeatCount
                    spark:Show()
                end

                if merging then
                    text:SetFormattedText("(%d / %d)", total - current, total)
                    spark:SetPoint("Center", self, "Left", 0, 2)
                    self.value = self.value + self.maxValue * current
                    self.maxValue = self.maxValue * total
                    self:SetMinMaxValues(0, self.maxValue)
                    current = current + 1
                end
            end
        elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            if merging then
                if current == total then
                    merging = nil
                    text:SetText("")
                    spark:Hide()
                else
                    self.value = self.maxValue * current / total
                    self:SetValue(self.value)
                    self.holdTime = GetTime() + 1
                    spark:SetPoint("Center", self, "Left", barWidth, 2)
                    self.Spark:Show()
                end
            end
        elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
            merging = nil
            text:SetText("")
            spark:Hide()
        end
    end)

    CastingBarFrame:HookScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.01 then
            return
        end
        self.elapsed = 0

        if merging and self.casting then
            local percent = (self.value - self.maxValue / total * (current - 1)) / (self.maxValue / total)
            local xOffset = min(percent, 1) * barWidth
            spark:SetPoint("Center", self, "Left", xOffset, 2)
        end
    end)
end

local function ShowGCD()
    local gcd = CreateFrame("Frame", "MyGCDBar", UIParent)
    gcd:SetSize(CastingBarFrame:GetWidth() + CastingBarFrame:GetHeight(), 3)
    gcd:SetPoint("BottomRight", CastingBarFrame, "TopRight")

    local bg = gcd:CreateTexture()
    bg:Hide()
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0)

    local spark = gcd:CreateTexture()
    spark:SetSize(25, gcd:GetHeight() * 2.5)
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetBlendMode("Add")

    local startTime, duration

    gcd:RegisterEvent("UNIT_SPELLCAST_START")
    gcd:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

    gcd:SetScript("OnEvent", function(self, _, unit, _, spell)
        if unit ~= "player" then
            return
        end
        startTime, duration = GetSpellCooldown(spell)
        if duration and duration > 0 and duration <= 1.5 then
            self:OnShow()
        end
    end)

    function gcd:OnShow()
        bg:Show()
        spark:Show()
        self:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            if self.elapsed < 0.01 then
                return
            end
            self.elapsed = 0

            if not startTime then
                self:OnHide()
                return
            end
            local percent = (GetTime() - startTime) / duration
            if percent > 1 then
                self:OnHide()
            else
                spark:ClearAllPoints()
                spark:SetPoint("Center", self, "Left", self:GetWidth() * percent, 0)
            end
        end)
    end

    function gcd:OnHide()
        bg:Hide()
        spark:Hide()
        self:SetScript("OnUpdate", nil)
    end
end

local function ShowSwing()
    local swing = CreateFrame("Frame", "MySwingBar", UIParent)
    swing:SetSize(CastingBarFrame:GetWidth() + CastingBarFrame:GetHeight(), 3)
    swing:SetPoint("TopRight", CastingBarFrame, "BottomRight")

    local bg = swing:CreateTexture()
    bg:Hide()
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0)

    local bar = CreateFrame("StatusBar", nil, swing)
    bar:Hide()
    bar:SetAllPoints()
    bar:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)

    local durationText = bar:CreateFontString()
    durationText:SetFont(font, 7, "Outline")
    durationText:SetPoint("TopLeft")
    local remainingText = bar:CreateFontString()
    remainingText:SetFont(font, 7, "Outline")
    remainingText:SetPoint("TopRight")

    swing:RegisterEvent("PLAYER_LEAVE_COMBAT")
    swing:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    swing:RegisterEvent("UNIT_ATTACK_SPEED")
    swing:RegisterEvent("UNIT_RANGEDDAMAGE")
    swing:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    swing:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    local extraAttacks, extraInhibit, duration, startTime

    swing:SetScript("OnEvent", function(self, event, unit, _, _, _, spellID)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            self:OnCombatEvent(CombatLogGetCurrentEventInfo())
        elseif event == "UNIT_ATTACK_SPEED" and unit == "player" then
            duration = UnitAttackSpeed("player")
        elseif event == "UNIT_RANGEDDAMAGE" and unit == "player" then
            duration = UnitRangedDamage("player")
        elseif event == "PLAYER_LEAVE_COMBAT" or event == "STOP_AUTOREPEAT_SPELL" then
            self:OnHide()
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
            if spellID == 75 or spellID == 5019 then
                duration = UnitRangedDamage("player")
                startTime = GetTime()
                self:OnShow()
            end
        end
    end)

    function swing:OnCombatEvent(_, event, _, srcGUID, _, _, _, dstGUID, ...)
        local playerGUID = UnitGUID("player")
        if srcGUID == playerGUID then
            if event == "SPELL_EXTRA_ATTACKS" then
                _, _, _, _, _, _, extraAttacks = ...
                extraInhibit = true
            elseif event == "SWING_DAMAGE" or event == "SWING_MISSED" then
                if (extraAttacks or 0) > 0 and not extraInhibit then
                    extraAttacks = (extraAttacks or 0) - 1
                elseif not self:IsDualWielding() then
                    extraInhibit = false
                    duration = UnitAttackSpeed("player")
                    startTime = GetTime()
                    self:OnShow()
                end
            end
        elseif dstGUID == playerGUID and event == "SWING_MISSED" then
            local _, _, _, missType = ...
            if missType == "PARRY" and duration then
                duration = duration * 0.6
            end
        end
    end

    function swing:IsDualWielding()
        local _, _, offhandLow, offhandHigh = UnitDamage("player")
        local _, class = UnitClass("player")
        return class ~= "DRUID" and offhandLow ~= offhandHigh
    end

    function swing:OnShow()
        bg:Show()
        bar:Show()
        durationText:SetFormattedText("%.1f", duration)
        self:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            if self.elapsed < 0.01 then
                return
            end
            self.elapsed = 0

            if startTime then
                local spent = GetTime() - startTime
                remainingText:SetFormattedText("%.1f", duration - spent < 0 and 0 or duration - spent)
                local percent = spent / duration
                if percent > 1 then
                    self:OnHide()
                    return
                else
                    bar:SetValue(percent)
                end
            end
        end)
    end

    function swing:OnHide()
        bg:Hide()
        bar:Hide()
        self:SetScript("OnUpdate", nil)
    end
end

config = {
    name = "MyTargetCastingBar",
    unit = "target",
    showTradeSkills = true,
    showShield = true,
    border = 2,
    width = 260,
    height = 26,
    event = "PLAYER_TARGET_CHANGED",
}
target = CreateCastingBar(config)
target:SetPoint("TopLeft", 1080 + config.border + config.height, -765 - config.border)

config = {
    name = "MyFocusCastingBar",
    unit = "focus",
    showTradeSkills = true,
    showShield = true,
    border = 2,
    width = 226,
    height = 19,
    event = "PLAYER_FOCUS_CHANGED",
}
focus = CreateCastingBar(config)
focus:SetPoint("BottomLeft", 1380 + 10 + config.border + config.height, 130 + 1 + config.border)

config = {
    showTradeSkills = false,
    showShield = true,
    border = 2,
    width = 255,
    height = 16,
    event = "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
}
for i = 1, MAX_BOSS_FRAMES do
    config.name = "MyBoss" .. i .. "CastingBar"
    config.unit = "boss" .. i
    boss = CreateCastingBar(config)
    boss:SetPoint("BottomLeft", 1350 + config.border + config.height, (282 + 1 + config.border) + (i - 1) * (config.height + config.border * 2 + 1 + 70 + 3))
end

MovePetCastingBar()
HideLayers(PetCastingBarFrame)
ShowIcon(PetCastingBarFrame)
MoveText(PetCastingBarFrame)
ShowTime(PetCastingBarFrame)

MovePlayerCastingBar()
HideLayers(CastingBarFrame)
ShowIcon(CastingBarFrame)
MoveText(CastingBarFrame)
ShowTime(CastingBarFrame)
ShowLatency()
ShowChannelTicks()
MergeTradeSkill()
ShowGCD()
ShowSwing()