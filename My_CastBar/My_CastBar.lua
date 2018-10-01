local function SetShortText(castBar)
    local name, text
    if castBar.casting then
        name, text = UnitCastingInfo(castBar.unit)
    else
        name, text = UnitChannelInfo(castBar.unit)
    end

    if text:len() * 5 > castBar:GetWidth() / 2 then
        local endIndex = floor(castBar:GetWidth() / 2 / 15) * 3
        local shortText = text:sub(1, endIndex) .. "..."
        castBar.Text:SetText(shortText)
    end
end

local function FormatTime(time)
    if time <= 10 then
        return "%.1f", time
    elseif time <= 60 then
        return "%d", time
    elseif time <= 3600 then
        return "%d:%02d", time / 60, time % 60
    end

    return "%d:%02d", time / 3600, time % 3600 / 60
end

local function UpdateCastBar(castBar)
    local value
    local maxValue = castBar.maxValue
    if castBar.merging then
        if castBar.casting then
            value = max(maxValue - castBar.value, 0)
            local currentCount = castBar.currentCount
            local totalCount = castBar.totalCount
            castBar.timeText:SetFormattedText("(%d/%d) %s/%s", totalCount - currentCount + 1, totalCount, format(FormatTime(value)), format(FormatTime(maxValue)))

            local x = (castBar.value / (maxValue / totalCount) - (currentCount - 1)) * castBar:GetWidth()
            castBar.tradeSkillSpark:SetPoint("Center", castBar, "Left", x, 2)
        end
    elseif castBar.casting then
        value = max(maxValue - castBar.value, 0)
        if castBar.delay and castBar.delay ~= 0 then
            castBar.timeText:SetFormattedText("|cffff0000+%.1f|r %s/%s", castBar.delay, format(FormatTime(value)), format(FormatTime(maxValue)))
        else
            castBar.timeText:SetFormattedText("%s/%s", format(FormatTime(value)), format(FormatTime(maxValue)))
        end
    elseif castBar.channeling then
        value = max(castBar.value, 0)
        if castBar.delay and castBar.delay ~= 0 then
            castBar.timeText:SetFormattedText("|cffff0000+%.1f|r %s/%s", castBar.delay, format(FormatTime(value)), format(FormatTime(maxValue)))
        else
            castBar.timeText:SetFormattedText("%s/%s", format(FormatTime(value)), format(FormatTime(maxValue)))
        end
    else
        castBar.timeText:SetText("")
    end
end

local playerWidth = 228
local playerHeight = 28
CastingBarFrame:SetSize(playerWidth - playerHeight, playerHeight)
CastingBarFrame:SetPoint("Center", playerHeight / 2, 0)

-- 延迟
local latency = CreateFrame("Frame", "CastBarLatencyFrame", CastingBarFrame)
latency:SetSize(CastingBarFrame:GetWidth(), CastingBarFrame:GetHeight())
latency:SetAllPoints()

latency.lagBox = latency:CreateTexture()
latency.lagBox:SetHeight(CastingBarFrame:GetHeight())
latency.lagBox:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
latency.lagBox:SetAlpha(0.5)
latency.lagBox:SetVertexColor(1, 0, 0)
latency.lagText = latency:CreateFontString()
latency.lagText:SetFont(GameFontNormal:GetFont(), 7, "Outline")

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
        self.lagBox:Hide()
        self.lagText:Hide()
    end
end)

-- 隱藏完成動畫
CastingBarFrame.Flash:SetTexture(nil)
-- 隱藏邊框
CastingBarFrame.Border:SetTexture(nil)

-- 顯示法術圖標
CastingBarFrame.Icon:Show()
CastingBarFrame.Icon:SetSize(playerHeight, playerHeight)
CastingBarFrame.Icon:SetPoint("Right", CastingBarFrame, "Left")

-- 顯示施法時間
CastingBarFrame.timeText = CastBarLatencyFrame:CreateFontString()
CastingBarFrame.timeText:SetFont(GameFontNormal:GetFont(), 12, "Outline")
CastingBarFrame.timeText:SetPoint("Right")
CastingBarFrame:HookScript("OnUpdate", UpdateCastBar)

-- 施法名稱
CastingBarFrame.Text:ClearAllPoints()
CastingBarFrame.Text:SetPoint("Left", 5, 0)
CastingBarFrame.Text:SetJustifyH("Left")

CastingBarFrame.tradeSkillSpark = CastingBarFrame:CreateTexture()
CastingBarFrame.tradeSkillSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
CastingBarFrame.tradeSkillSpark:SetBlendMode("Add")
CastingBarFrame.tradeSkillSpark:SetWidth(20)
CastingBarFrame.tradeSkillSpark:SetHeight(CastingBarFrame:GetHeight())

local sparkFactory = {
    __index = function(ticks, i)
        local spark = CastingBarFrame:CreateTexture()
        spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
        spark:SetBlendMode("Add")
        spark:SetWidth(20)
        spark:SetHeight(CastingBarFrame:GetHeight() * 2.2)
        ticks[i] = spark
        return spark
    end
}

local barTicks = setmetatable({}, sparkFactory)

local function SetBarTicks(numTicks, duration, ticks)
    if numTicks and numTicks > 0 then
        local width = CastingBarFrame:GetWidth()
        for i = 1, numTicks do
            local tick = barTicks[i]
            tick:ClearAllPoints()
            local x = ticks[i] / duration
            tick:SetPoint("Center", CastingBarFrame, "Right", -width * x, 0)
            tick:Show()
        end

        for i = numTicks + 1, #barTicks do
            barTicks[i]:Hide()
        end
    else
        barTicks[1].Hide = nil
        for i = 1, #barTicks do
            barTicks[i]:Hide()
        end
    end
end

local channelTicks = {
    -- 吸取生命
    [GetSpellInfo(234153)] = 6
}

local function GetChannelTicks(spell)
    return channelTicks[spell] or 0
end

CastingBarFrame:HookScript("OnEvent", function(self, event, unit)
    if self.unit ~= unit then
        return
    end

    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        SetShortText(self)

        local spell, displayName, icon, startTime, endTime, isTradeSkill
        if self.casting then
            spell, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo(unit)
        else
            spell, displayName, icon, startTime, endTime, isTradeSkill = UnitChannelInfo(unit)
        end

        -- 交易技能
        if isTradeSkill then
            if self.casting then
                local repeatCount = C_TradeSkillUI.GetRecipeRepeatCount()
                if not self.merging and repeatCount > 1 then
                    self.merging = true
                    self.currentCount = 0
                    self.totalCount = repeatCount
                end

                if self.merging then
                    self.value = self.value + self.maxValue * self.currentCount
                    self.maxValue = self.maxValue * self.totalCount
                    self:SetMinMaxValues(0, self.maxValue)
                    self.currentCount = self.currentCount + 1
                    self.tradeSkillSpark:Show()
                end
            end
        else
            self.delay = 0
            -- 通道法術
            self.startTime = startTime / 1000
            self.endTime = endTime / 1000

            if self.channeling then
                self.channelingEnd = self.endTime
                self.channelingDuration = self.endTime - self.startTime
                self.channelingTicks = GetChannelTicks(spell)
                self.channelingTickTime = self.channelingTicks > 0 and (self.channelingDuration / self.channelingTicks) or 0
                self.ticks = self.ticks or {}
                for i = 1, self.channelingTicks do
                    self.ticks[i] = self.channelingDuration - (i - 1) * self.channelingTickTime
                end
                SetBarTicks(self.channelingTicks, self.channelingDuration, self.ticks)
            else
                SetBarTicks(0)
                self.channelingDuration = nil
            end

            if not latency.sendTime or not self.endTime then
                return
            end

            -- 網絡延遲
            latency.timeDiff = GetTime() - latency.sendTime
            local castLength = self.endTime - self.startTime
            latency.timeDiff = latency.timeDiff > castLength and castLength or latency.timeDiff
            local percent = latency.timeDiff / castLength

            if percent > 0 then
                latency.lagBox:ClearAllPoints()
                latency.lagText:ClearAllPoints()
                if self.casting then
                    latency.lagBox:SetPoint("Right")
                    latency.lagText:SetPoint("BottomRight", latency.lagBox)
                    latency.lagText:SetJustifyH("Right")
                else
                    latency.lagBox:SetPoint("Left")
                    latency.lagText:SetPoint("BottomLeft", latency.lagBox)
                    latency.lagText:SetJustifyH("Left")
                end

                latency.lagBox:SetWidth(self:GetWidth() * percent)
                latency.lagBox:Show()
                latency.lagText:SetFormattedText("%dms", latency.timeDiff * 1000)
                latency.lagText:Show()
            else
                latency.lagBox:Hide()
                latency.lagText:Hide()
            end

            latency.sendTime = nil
        end
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        -- 通道法術
        SetBarTicks(0)
        self.channelingDuration = nil
        -- 交易技能
        if self.merging then
            if self.currentCount == self.totalCount then
                self.merging = nil
                self.tradeSkillSpark:Hide()
            else
                self.value = self.maxValue * self.currentCount / self.totalCount
                self:SetValue(self.value)
                self.holdTime = GetTime() + 1
                local x = self.value / self.maxValue * self:GetWidth()
                self.Spark:SetPoint("Center", self, "Left", x, 2)
                self.Spark:Show()
            end
        end
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        -- 通道法術
        SetBarTicks(0)
        self.channelingDuration = nil
        -- 交易技能
        self.merging = nil
        self.tradeSkillSpark:Hide()
    elseif event == "UNIT_SPELLCAST_DELAYED" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        local oldStartTime = self.startTime

        local spell, displayName, icon, startTime, endTime
        if self.casting then
            spell, displayName, icon, startTime, endTime = UnitCastingInfo(unit)
        else
            spell, displayName, icon, startTime, endTime = UnitChannelInfo(unit)
        end

        self.startTime = startTime / 1000
        self.endTime = endTime / 1000

        if self.casting then
            self.delay = (self.delay or 0) + (self.startTime - (oldStartTime or self.startTime))
        else
            self.delay = (self.delay or 0) + ((oldStartTime or self.startTime) - self.startTime)
        end

        -- 通道法術
        if self.channeling and self.endTime > self.channelingEnd then
            local duration = self.endTime - self.startTime

            if self.channelingDuration and duration > self.channelingDuration and self.channelingTicks > 0 then
                local extraTime = duration - self.channelingDuration

                for i = 1, self.channelingTicks do
                    self.ticks[i] = self.ticks[i] + extraTime
                end

                while self.ticks[self.channelingTicks] > self.channelingTickTime do
                    self.channelingTicks = self.channelingTicks + 1
                    self.ticks[self.channelingTicks] = self.ticks[self.channelingTicks - 1] - self.channelingTickTime
                end

                self.channelingDuration = duration
                self.channelingEnd = self.endTime
                SetBarTicks(self.channelingTicks, self.channelingDuration, self.ticks)
            end
        end
    end
end)

-- GCD
local gcd = CreateFrame("Frame", "GCDBar", UIParent)

gcd:SetSize(playerWidth, 3)
gcd:SetPoint("TopRight", CastingBarFrame, "BottomRight")

gcd.bg = gcd:CreateTexture(nil, "Background")
gcd.bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
gcd.bg:SetColorTexture(0, 0, 0)
gcd.bg:SetAllPoints()
gcd.bg:Hide()

gcd.spark = gcd:CreateTexture(nil, "Dialog")
gcd.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
gcd.spark:SetBlendMode("Add")
gcd.spark:SetSize(25, gcd:GetHeight() * 2.5)

function gcd:Update()
    if not self.startTime then
        self:SetScript("OnUpdate", nil)
        self.bg:Hide()
        self.spark:Hide()
        return
    end

    self.spark:ClearAllPoints()
    local percent = (GetTime() - self.startTime) / self.duration
    if percent > 1 then
        self:SetScript("OnUpdate", nil)
        self.bg:Hide()
        self.spark:Hide()
    else
        self.spark:SetPoint("Center", self, "Left", self:GetWidth() * percent, 0)
    end
end

gcd:RegisterEvent("UNIT_SPELLCAST_START")
gcd:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
gcd:SetScript("OnEvent", function(self, event, unit, guid, spell)
    if unit == "player" then
        local start, duration = GetSpellCooldown(spell)
        if duration and duration > 0 and duration <= 1.5 then
            self.startTime = start
            self.duration = duration
            self:SetScript("OnUpdate", self.Update)
            self.bg:Show()
            self.spark:Show()
        end
    end
end)

-- 揮擊
local swing = CreateFrame("Frame", "SwingBar", UIParent)
swing:Hide()

swing:SetSize(playerWidth, 3)
swing:SetPoint("BottomRight", CastingBarFrame, "TopRight")

swing:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16 })
swing:SetBackdropColor(0, 0, 0)

swing.bar = CreateFrame("StatusBar", nil, swing)
swing.bar:SetAllPoints()
swing.bar:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground")
swing.bar:SetMinMaxValues(0, 1)

swing.bar.durationText = swing.bar:CreateFontString()
swing.bar.durationText:SetFont(GameFontNormal:GetFont(), 9, "Outline")
swing.bar.durationText:SetPoint("BottomLeft", swing)
swing.bar.durationText:SetJustifyH("Left")
swing.bar.remainingText = swing.bar:CreateFontString()
swing.bar.remainingText:SetFont(GameFontNormal:GetFont(), 9, "Outline")
swing.bar.remainingText:SetPoint("BottomRight", swing)
swing.bar.durationText:SetJustifyH("Right")

function swing:Update()
    if self.slamStart then
        return
    end

    if self.startTime then
        local spent = GetTime() - self.startTime
        self.bar.remainingText:SetFormattedText("%.1f", self.duration - spent)

        local percent = spent / self.duration
        if percent > 1 then
            self:SetScript("OnUpdate", nil)
            self:Hide()
        else
            self.bar:SetValue(percent)
        end
    end
end

function swing:MeleeSwing()
    self.duration = UnitAttackSpeed("player")
    if not self.duration or self.duration == 0 then
        self.duration = nil
        self.startTime = nil
        self:SetScript("OnUpdate", nil)
        self:Hide()
        return
    end

    self.bar.durationText:SetFormattedText("%.1f", self.duration)
    self.startTime = GetTime()
    self:SetScript("OnUpdate", self.Update)
    self:Show()
end

function swing:Shoot()
    self.duration = UnitRangedDamage("player")
    if not self.duration or self.duration == 0 then
        self.duration = nil
        self.startTime = nil
        self:SetScript("OnUpdate", nil)
        self:Hide()
        return
    end

    self.bar.durationText:SetFormattedText("%.1f", self.duration)
    self.startTime = GetTime()
    self:SetScript("OnUpdate", self.Update)
    self:Show()
end

local playerClass
local autoShotName = GetSpellInfo(75)
local slam = GetSpellInfo(1464)

local resetAutoShotSpells = {
    --[GetSpellInfo(19434)] = true, -- Aimed Shot
}

swing:RegisterEvent("PLAYER_ENTER_COMBAT")
swing:RegisterEvent("PLAYER_LEAVE_COMBAT")
swing:RegisterEvent("START_AUTOREPEAT_SPELL")
swing:RegisterEvent("STOP_AUTOREPEAT_SPELL")
swing:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
swing:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
swing:RegisterEvent("UNIT_ATTACK")
swing:RegisterEvent("PLAYER_LOGIN")

swing:SetScript("OnEvent", function(self, event, unit, spell)
    if event == "PLAYER_LOGIN" then
        _, playerClass = UnitClass("player")
        if playerClass == "WARRIOR" then
            self:RegisterEvent("UNIT_SPELLCAST_START")
            self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        end
    elseif event == "PLAYER_ENTER_COMBAT" then
        local _, _, offhandlow, offhandhigh = UnitDamage("player")
        if math.abs(offhandlow - offhandhigh) <= 0.1 or playerClass == "DRUID" then
            self.mode = 0 -- shouldn"t be dual-wielding
        end
    elseif event == "PLAYER_LEAVE_COMBAT" then
        if not self.mode or self.mode == 0 then
            self.mode = nil
        end
    elseif event == "START_AUTOREPEAT_SPELL" then
        self.mode = 1
    elseif event == "STOP_AUTOREPEAT_SPELL" then
        if not self.mode or self.mode == 1 then
            self.mode = nil
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if self.mode ~= 0 then
            return
        end
        local _, combatevent, _, _, _, srcFlags, _, _, _, dstFlags, _, spellID = CombatLogGetCurrentEventInfo()
        if (combatevent == "SWING_DAMAGE" or combatevent == "SWING_MISSED") and (bit.band(srcFlags, COMBATLOG_FILTER_ME) == COMBATLOG_FILTER_ME) then
            self:MeleeSwing()
        elseif (combatevent == "SWING_MISSED") and (bit.band(dstFlags, COMBATLOG_FILTER_ME) == COMBATLOG_FILTER_ME) and spellID == "PARRY" and self.duration then
            self.duration = self.duration * 0.6
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if unit ~= "player" then
            return
        end
        if self.mode == 0 then
            if spell == slam and self.slamStart then
                self.startTime = self.startTime + GetTime() - self.slamStart
                self.slamStart = nil
            end
        elseif self.mode == 1 then
            if spell == autoShotName then
                self:Shoot()
            end
        end
        if resetAutoShotSpells[spell] then
            self.mode = 1
            self:Shoot()
        end
    elseif event == "UNIT_SPELLCAST_START" then
        if unit == "player" and spell == slam then
            self.slamStart = GetTime()
        end
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        if unit == "player" and spell == slam and self.slamStart then
            self.slamStart = nil
        end
    elseif event == "UNIT_ATTACK" then
        if unit == "player" then
            if not self.mode then
                return
            elseif self.mode == 0 then
                self.duration = UnitAttackSpeed("player")
            else
                self.duration = UnitRangedDamage("player")
            end
            self.bar.durationText:SetFormattedText("%.1f", self.duration)
        end
    end
end)

local border = 2

local function OnChanged(castBar, event, arg1)
    local nameChannel = UnitChannelInfo(castBar.unit)
    local nameSpell = UnitCastingInfo(castBar.unit)
    if nameChannel then
        return "UNIT_SPELLCAST_CHANNEL_START", castBar.unit
    elseif nameSpell then
        return "UNIT_SPELLCAST_START", castBar.unit
    else
        castBar.casting = nil
        castBar.channeling = nil
        castBar:SetMinMaxValues(0, 0)
        castBar:SetValue(0)
        castBar:Hide()
        return event, arg1
    end
end

local function SetCastBar(bar, width, height)
    -- 隱藏完成動畫
    bar.Flash:SetTexture(nil)
    -- 隱藏邊框
    bar.Border:SetTexture(nil)
    -- 隱藏不可打斷邊框
    bar.BorderShield:SetTexture(nil)

    -- 顯示法術圖標
    bar.Icon:Show()
    bar.Icon:SetSize(bar:GetHeight(), bar:GetHeight())
    bar.Icon:SetPoint("Right", bar, "Left")

    -- 顯示施法時間
    bar.timeText = bar:CreateFontString()
    bar.timeText:SetFont(GameFontNormal:GetFont(), 12, "Outline")
    bar.timeText:SetPoint("Right")
    bar:HookScript("OnUpdate", UpdateCastBar)

    -- 施法名稱
    bar.Text:ClearAllPoints()
    bar.Text:SetPoint("Left", 5, 0)
    bar.Text:SetJustifyH("Left")

    -- 不可打斷邊框
    bar.topBorder = bar:CreateTexture()
    bar.topBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bar.topBorder:SetSize(width - border * 2, border)
    bar.topBorder:SetPoint("BottomRight", bar, "TopRight")

    bar.bottomBorder = bar:CreateTexture()
    bar.bottomBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bar.bottomBorder:SetSize(width - border * 2, border)
    bar.bottomBorder:SetPoint("TopRight", bar, "BottomRight")

    bar.leftBorder = bar:CreateTexture()
    bar.leftBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bar.leftBorder:SetSize(border, height)
    bar.leftBorder:SetPoint("Right", bar.Icon, "Left")

    bar.rightBorder = bar:CreateTexture()
    bar.rightBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bar.rightBorder:SetSize(border, height)
    bar.rightBorder:SetPoint("Left", bar, "Right")

    hooksecurefunc(bar.BorderShield, "Show", function()
        bar.topBorder:Show()
        bar.bottomBorder:Show()
        bar.leftBorder:Show()
        bar.rightBorder:Show()
    end)
    hooksecurefunc(bar.BorderShield, "Hide", function()
        bar.topBorder:Hide()
        bar.bottomBorder:Hide()
        bar.leftBorder:Hide()
        bar.rightBorder:Hide()
    end)
end

local targetCastBar = CreateFrame("StatusBar", "TargetCastBar", UIParent, "CastingBarFrameTemplate")
-- 重載介面後不顯示
targetCastBar:Hide()
CastingBarFrame_OnLoad(targetCastBar, "target", true, true)

local targetWidth = 270
local targetHeight = 30
targetCastBar:SetSize(targetWidth - targetHeight, targetHeight - border * 2)
targetCastBar:SetPoint("TopLeft", UIParent, "Center", 120 + targetHeight - border, -215 - border)

SetCastBar(targetCastBar, targetWidth, targetHeight)

targetCastBar:RegisterEvent("PLAYER_TARGET_CHANGED")
targetCastBar:SetScript("OnEvent", function(self, event, unit, spell)
    if event == "PLAYER_TARGET_CHANGED" then
        event, unit = OnChanged(self, event, unit)
    end
    CastingBarFrame_OnEvent(self, event, unit, spell)
    if (event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START") and unit == self.unit then
        SetShortText(self)
    end
end)

local focusCastBar = CreateFrame("StatusBar", "focusCastBar", UIParent, "CastingBarFrameTemplate")
-- 重載介面後不顯示
focusCastBar:Hide()
CastingBarFrame_OnLoad(focusCastBar, "focus", true, true)

local focusWidth = 226
local focusHeight = 30
focusCastBar:SetSize(focusWidth - focusHeight, focusHeight - border * 2)
focusCastBar:SetPoint("TopLeft", UIParent, "Center", 423 + focusHeight - border, -370 - border)

SetCastBar(focusCastBar, focusWidth, focusHeight)

focusCastBar:RegisterEvent("PLAYER_FOCUS_CHANGED")
focusCastBar:SetScript("OnEvent", function(self, event, unit, spell)
    if event == "PLAYER_FOCUS_CHANGED" then
        event, unit = OnChanged(self, event, unit)
    end
    CastingBarFrame_OnEvent(self, event, unit, spell)
    if (event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START") and unit == self.unit then
        SetShortText(self)
    end
end)

local bossCastBar = {}
local bossWidth = 259
local bossHeight = 20
for i = 1, 5 do
    bossCastBar[i] = CreateFrame("StatusBar", "Boss" .. i .. "CastBar", UIParent, "CastingBarFrameTemplate")
    -- 重載介面後不顯示
    bossCastBar[i]:Hide()
    CastingBarFrame_OnLoad(bossCastBar[i], "boss" .. i, false, true)

    bossCastBar[i]:SetSize(bossWidth - bossHeight, bossHeight - border * 2)
    if i == 1 then
        bossCastBar[i]:SetPoint("BottomLeft", UIParent, "Center", 390 + bossHeight - border, -255 + border)
    else
        bossCastBar[i]:SetPoint("Bottom", bossCastBar[i - 1], "Top", 0, 78)
    end

    SetCastBar(bossCastBar[i], bossWidth, bossHeight)

    bossCastBar[i]:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    bossCastBar[i]:SetScript("OnEvent", function(self, event, unit, spell)
        if event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
            event, unit = OnChanged(self, event, unit)
        end
        CastingBarFrame_OnEvent(self, event, unit, spell)
        if (event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START") and unit == self.unit then
            SetShortText(self)
        end
    end)
end