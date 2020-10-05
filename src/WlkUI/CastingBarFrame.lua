local addonName = ...
local width = 298
local height = 32
local divWidth = 2
local gcdWidth = width + height
local gcdHeight = 3
local lastStartTime, delayTime
local sendTime
local divEndTime, divDuration, numDivs, intervalTime
local merging, currentCount, totalCount
---@type Texture[]
local dividers = {}
local divTimes = {}
local spellTicks = {
    [198590] = 5,
    [234153] = 5,
    [755] = 5,
}

---@type Frame
local listener = CreateFrame("Frame")
local delayLabel = CastingBarFrame:CreateFontString("WlkCastingDelayLabel", "ARTWORK", "NumberFont_Shadow_Tiny")
local latency = CastingBarFrame:CreateTexture("WlkCastingLatency")
local latencyLabel = CastingBarFrame:CreateFontString("WlkCastingLatencyLabel", "ARTWORK", "NumberFont_Shadow_Tiny")
local countLabel = CastingBarFrame:CreateFontString("WlkCastingCountLabel", "ARTWORK", "NumberFont_Shadow_Small")
---@type Frame
local gcd = CreateFrame("Frame", "WlkGCDFrame", UIParent, "BackdropTemplate")
local spark = gcd:CreateTexture("WlkGCDFrameSpark")

local function getCastingInfo()
    local startTime, endTime, isTradeSkill, spellId, _
    if CastingBarFrame.channeling then
        _, _, _, startTime, endTime, isTradeSkill, _, spellId = UnitChannelInfo("player")
    elseif CastingBarFrame.casting then
        _, _, _, startTime, endTime, isTradeSkill, _, _, spellId = UnitCastingInfo("player")
    end
    if startTime and endTime then
        return startTime / 1000, endTime / 1000, isTradeSkill, spellId
    end
end

local function updateDividers(count, duration)
    for i = 1, count or 0 do
        local div = dividers[i]
        if not div then
            div = CastingBarFrame:CreateTexture("WlkCastingBarFrameDivider" .. i)
            div:SetSize(divWidth, height)
            div:SetColorTexture(1, 1, 1)
            dividers[i] = div
        else
            div:Show()
        end
        local xOffset = divTimes[i] / duration * width
        div:SetPoint("LEFT", CastingBarFrame, "RIGHT", -xOffset, 0)
    end
    for i = (count or 0) + 1, #dividers do
        dividers[i]:Hide()
    end
end

SLASH_SPELL_TICKS1 = "/st"

SlashCmdList["SPELL_TICKS"] = function(arg)
    local spellId, ticks = strsplit(" ", arg, 2)
    spellId = tonumber(spellId)
    ticks = tonumber(ticks)
    if spellId and ticks then
        spellTicks[spellId] = ticks
        ChatFrame1:AddMessage("添加成功", 1, 1, 0)
    end
end

listener:RegisterEvent("ADDON_LOADED")
listener:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
listener:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
listener:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        listener:UnregisterEvent(event)
        if not WlkSpellTicks then
            WlkSpellTicks = spellTicks
        else
            spellTicks = WlkSpellTicks
        end
    elseif event == "CURRENT_SPELL_CAST_CHANGED" then
        sendTime = GetTime()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        sendTime = nil
    end
end)

delayLabel:SetPoint("BOTTOMRIGHT")
delayLabel:SetTextColor(1, 0, 0)

latency:SetHeight(height)
latency:SetColorTexture(1, 0, 0)
latency:SetAlpha(0.4)

latencyLabel:SetPoint("TOPRIGHT")
latencyLabel:SetTextColor(1, 1, 0)

CastingBarFrame:HookScript("OnEvent", function(self, event, ...)
    local arg1, arg2 = ...
    if arg1 == "player" then
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
            local startTime, endTime, isTradeSkill, spellId = getCastingInfo()

            lastStartTime = startTime
            delayTime = 0
            delayLabel:SetText("")

            if sendTime then
                local diff = GetTime() - sendTime
                local duration = endTime - startTime
                local latencyValue = min(diff, duration)
                local percent = latencyValue / duration
                if percent > 0 then
                    latency:SetWidth(width * percent)
                    latencyLabel:SetFormattedText("%dms", latencyValue * 1000)
                    latency:ClearAllPoints()
                    latencyLabel:ClearAllPoints()
                    if self.casting then
                        latency:SetPoint("RIGHT")
                        latencyLabel:SetPoint("TOPRIGHT")
                    elseif self.channeling then
                        latency:SetPoint("LEFT")
                        latencyLabel:SetPoint("TOPLEFT")
                    end
                    latency:Show()
                else
                    latency:Hide()
                    latencyLabel:SetText("")
                end
                sendTime = nil
            end

            if spellTicks[spellId] and self.channeling then
                divEndTime = endTime
                divDuration = endTime - startTime
                numDivs = spellTicks[spellId]
                intervalTime = divDuration / numDivs
                for i = 1, numDivs do
                    divTimes[i] = i * intervalTime
                end
                updateDividers(numDivs, divDuration)
            end

            if isTradeSkill and self.casting then
                local repeatCount = C_TradeSkillUI.GetRecipeRepeatCount()
                if not merging and repeatCount > 1 then
                    currentCount = 0
                    totalCount = repeatCount
                    merging = true
                    intervalTime = endTime - startTime
                    for i = 1, totalCount do
                        divTimes[i] = (i - 1) * intervalTime
                    end
                    updateDividers(totalCount, intervalTime * totalCount)
                end
                if merging then
                    currentCount = currentCount + 1
                    countLabel:SetFormattedText("(%d/%d)", currentCount, totalCount)
                    countLabel:SetPoint("LEFT", CastingBarFrame.Text, CastingBarFrame.Text:GetStringWidth(), 0)
                    self.value = self.value + self.maxValue * (currentCount - 1)
                    self.maxValue = self.maxValue * totalCount
                    CastingBarFrame:SetMinMaxValues(0, self.maxValue)
                end
            end
        elseif event == "UNIT_SPELLCAST_DELAYED" and arg2 == self.castID then
            local startTime = getCastingInfo()
            delayTime = delayTime + startTime - lastStartTime
            if delayTime >= 0.1 then
                delayLabel:SetFormattedText("+%.2f", delayTime)
            end
        elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
            local startTime, endTime = getCastingInfo()
            if divEndTime and divEndTime < endTime then
                local duration = endTime - startTime
                if divDuration and divDuration < duration and numDivs and numDivs > 0 then
                    local extraTime = duration - divDuration
                    for i = 1, numDivs do
                        divTimes[i] = divTimes[i] + extraTime
                    end
                    while divTimes[numDivs] > intervalTime do
                        numDivs = numDivs + 1
                        divTimes[numDivs] = divTimes[numDivs - 1] - intervalTime
                    end
                    divDuration = duration
                    divEndTime = endTime
                    updateDividers(numDivs, divDuration)
                end
            end
        elseif event == "UNIT_SPELLCAST_STOP" and arg2 == self.castID then
            if merging then
                if currentCount == totalCount then
                    merging = nil
                    countLabel:SetText("")
                    updateDividers()
                else
                    CastingBarFrame:SetValue(self.maxValue * currentCount / totalCount)
                    self.holdTime = GetTime() + CASTING_BAR_HOLD_TIME
                end
            end
        elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            divDuration = nil
            updateDividers()
        elseif (event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED")
                and (arg2 == nil or arg2 == self.castID) then
            delayLabel:SetText("")
            latency:Hide()
            latencyLabel:SetText("")
            divDuration = nil
            updateDividers()
            if merging then
                merging = nil
                countLabel:SetText("")
            end
        end
    end
end)

spark:SetSize(32, 8)
spark:SetTexture("Interface/CastingBar/UI-CastingBar-Spark")
spark:SetBlendMode("ADD")

gcd:Hide()
gcd:SetSize(gcdWidth, gcdHeight)
gcd:SetPoint("BOTTOM", 0, 268)
gcd:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark", })
gcd:RegisterUnitEvent("UNIT_SPELLCAST_START", "player", "vehicle")
gcd:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "vehicle")
gcd:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player", "vehicle")
gcd:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spellId = ...
        local start, duration = GetSpellCooldown(spellId)
        if duration and duration > 0 and duration <= 1.5 and start and GetTime() - start <= 0.4 then
            self.start = start
            self.duration = duration
            gcd:Show()
        end
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        gcd:Hide()
    end
end)
gcd:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.01 then
        return
    end
    self.elapsed = 0

    local percent = (GetTime() - self.start) / self.duration
    if percent > 1 then
        gcd:Hide()
    else
        spark:SetPoint("CENTER", gcd, "LEFT", percent * gcdWidth, 0)
    end
end)
