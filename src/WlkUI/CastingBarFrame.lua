local lastStartTime, delayTime, sendTime
local width = 330
local height = 30
local divWidth = 2
---@type Texture[]
local dividers = {}
local divTimes = {}
local divEndTime, divDuration, numDivs, intervalTime
local merging, currentCount, totalCount
local numSpellDivs = {
    -- 术士
    [234153] = 5, -- 吸取生命
    [198590] = 5, -- 吸取灵魂
    [755] = 5, -- 生命通道
    -- 法师
    [5143] = 5, -- 秘法飞弹
    [205021] = 5, -- 冰霜射线
    -- 德鲁伊
    [740] = 5, -- 宁静
    -- 武僧
    [117952] = 5, -- 碎玉轰雷掌
    [191837] = 3, -- 精华之泉
    [115175] = 8, -- 舒和之雾
    [101546] = 4, -- 鹤旋踢
    [113656] = 5, -- 狂拳连打
    -- 牧师
    [15407] = 4, -- 精神鞭笞
    [48045] = 4, -- 心灵烙印
    [263165] = 6, -- 虚无洪流
    [47758] = 2, -- 忏悟
    [64843] = 5, -- 神圣礼颂
    -- 恶魔猎手
    [198013] = 10, -- 魔眼光束
    [258925] = 16, -- 魔化弹幕
    [212084] = 12, -- 魔化破灭
    [205630] = 1, --
    -- 猎人
    [257044] = 10, -- 急速射击
    [120360] = 16, -- 弹幕
    [212640] = 6, -- 愈合弹幕
    -- 萨满
    [204437] = 5, -- 闪电套索
    -- 亡灵
    [20578] = 5, -- 食尸
}
---@type Frame
local eventFrame = CreateFrame("Frame")
---@type FontString
local delayLabel = CastingBarFrame:CreateFontString("WlkCastingBarFrameDelayLabel", "ARTWORK", "NumberFont_Shadow_Tiny")
---@type Texture
local latency = CastingBarFrame:CreateTexture("WlkCastingBarFrameLatency", "ARTWORK")
---@type FontString
local latencyLabel = CastingBarFrame:CreateFontString("WlkCastingBarFrameLatencyLabel", "ARTWORK",
        "NumberFont_Shadow_Tiny")
---@type FontString
local countLabel = CastingBarFrame:CreateFontString("WlkCastingBarFrameCountLabel", "ARTWORK", "ChatFontSmall")

local function GetPlayerCastingInfo()
    local startTime, endTime, isTradeSkill, castId, _
    if CastingBarFrame.channeling then
        _, _, _, startTime, endTime, isTradeSkill, _, castId = UnitChannelInfo("player")
    elseif CastingBarFrame.casting then
        _, _, _, startTime, endTime, isTradeSkill, _, _, castId = UnitCastingInfo("player")
    end
    if startTime and endTime then
        return startTime / 1000, endTime / 1000, isTradeSkill, castId
    end
end

local function UpdateDividers(count, duration)
    for i = 1, count or 0 do
        local div = dividers[i]
        if not div then
            div = CastingBarFrame:CreateTexture("WlkCastingBarFrameDivider" .. i, "ARTWORK")
            dividers[i] = div
            div:SetSize(divWidth, height)
            div:SetColorTexture(1, 1, 1)
        else
            div:Show()
        end
        local offsetX = divTimes[i] / duration * width
        div:SetPoint("LEFT", CastingBarFrame, "RIGHT", -offsetX, 0)
    end
    for i = (count or 0) + 1, #dividers do
        dividers[i]:Hide()
    end
end

delayLabel:SetPoint("BOTTOMRIGHT")
delayLabel:SetTextColor(1, 0, 0)

latency:SetHeight(height)
latency:SetColorTexture(1, 0, 0)
latency:SetAlpha(0.4)

latencyLabel:SetPoint("TOPRIGHT")
latencyLabel:SetTextColor(1, 1, 0)

eventFrame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "CURRENT_SPELL_CAST_CHANGED" then
        sendTime = GetTime()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        sendTime = nil
    end
end)

CastingBarFrame:HookScript("OnEvent", function(self, event, ...)
    local unit = ...
    if unit ~= "player" then
        return
    end
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        local startTime, endTime, isTradeSkill, spellId = GetPlayerCastingInfo()

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

        if numSpellDivs[spellId] and self.channeling then
            divEndTime = endTime
            divDuration = endTime - startTime
            numDivs = numSpellDivs[spellId]
            intervalTime = divDuration / numDivs
            for i = 1, numDivs do
                divTimes[i] = i * intervalTime
            end
            UpdateDividers(numDivs, divDuration)
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
                UpdateDividers(totalCount, intervalTime * totalCount)
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
    elseif event == "UNIT_SPELLCAST_DELAYED" then
        local startTime = GetPlayerCastingInfo()
        delayTime = (delayTime or 0) + (startTime - (lastStartTime or startTime))
        if delayTime >= 0.1 then
            delayLabel:SetFormattedText("+%.2f", delayTime)
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        local startTime, endTime = GetPlayerCastingInfo()
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
                UpdateDividers(numDivs, divDuration)
            end
        end
    elseif event == "UNIT_SPELLCAST_STOP" then
        if merging then
            if currentCount == totalCount then
                merging = nil
                countLabel:SetText("")
                UpdateDividers()
            else
                CastingBarFrame:SetValue(self.maxValue * currentCount / totalCount)
                self.holdTime = GetTime() + CASTING_BAR_HOLD_TIME
            end
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        divDuration = nil
        UpdateDividers()
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        latency:Hide()
        latencyLabel:SetText("")
        divDuration = nil
        if merging then
            merging = nil
            countLabel:SetText("")
        end
        UpdateDividers()
    end
end)
