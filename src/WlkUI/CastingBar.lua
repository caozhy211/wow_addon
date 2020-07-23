local height = 28

--- 移动玩家施法条
---@param bar StatusBar
local function MovePlayerCastingBarFrame(bar)
    bar:SetSize(228 - height, height)
    bar:ClearAllPoints()
    bar:SetPoint("BOTTOM", height / 2, 185 - 1 - 3 - height)
    bar.SetPoint = nop
end

MovePlayerCastingBarFrame(CastingBarFrame)
MovePlayerCastingBarFrame(PetCastingBarFrame)

--- 设置施法条纹理
---@param bar StatusBar
local function SetTextures(bar)
    ---@type Texture
    local border = bar.Border
    border:Hide()
    ---@type Texture
    local flash = bar.Flash
    flash:SetTexture(nil)
    ---@type Texture
    local spark = bar.Spark
    spark:SetHeight(bar:GetHeight() + 32 - 13)
    spark.offsetY = 0
end

SetTextures(CastingBarFrame)
SetTextures(PetCastingBarFrame)

--- 显示施法条图标
---@param bar StatusBar
local function ShowIcon(bar)
    ---@type Texture
    local icon = bar.Icon
    icon:SetSize(bar:GetHeight(), bar:GetHeight())
    icon:SetPoint("RIGHT", bar, "LEFT")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:Show()
end

ShowIcon(CastingBarFrame)
ShowIcon(PetCastingBarFrame)

--- 移动施法条法术名称
---@param bar StatusBar
local function MoveText(bar)
    ---@type FontString
    local label = bar.Text
    label:SetFontObject("Game12Font")
    label:SetWidth(bar:GetWidth() / 2 + 5)
    label:SetJustifyH("LEFT")
    label:ClearAllPoints()
    label:SetPoint("LEFT", 5, 0)
end

MoveText(CastingBarFrame)
MoveText(PetCastingBarFrame)

--- 获取施法条法术信息
local function GetCastingSpellInfo(bar)
    local unit = bar.unit
    local startTime, endTime, isTradeSkill, spellID, _
    if bar.casting then
        startTime, endTime, isTradeSkill, _, _, spellID = select(4, UnitCastingInfo(unit))
    elseif bar.channeling then
        startTime, endTime, isTradeSkill, _, spellID = select(4, UnitChannelInfo(unit))
    end
    if startTime and endTime then
        return startTime / 1000, endTime / 1000, isTradeSkill, spellID
    end
end

--- 格式化时间
local function FormatTime(time)
    if time < 10 then
        return format("%.1f", time)
    elseif time < SECONDS_PER_MIN then
        return format("%d", time)
    end
    return format("%d:%02d", time / SECONDS_PER_MIN, time % SECONDS_PER_MIN)
end

--- 显示施法时间
---@param bar StatusBar
local function ShowTime(bar)
    ---@type FontString
    local timeLabel = bar:CreateFontString(nil, "ARTWORK", "Game12Font_o1")
    timeLabel:SetPoint("RIGHT")
    ---@type FontString
    local delayLabel = bar:CreateFontString(nil, "ARTWORK", "Game12Font_o1")
    delayLabel:SetPoint("RIGHT", timeLabel, "LEFT", -1, 0)
    delayLabel:SetTextColor(GetTableColor(RED_FONT_COLOR))

    local startTime, endTime, delayTime
    -- 计算施法延迟时间
    bar:HookScript("OnEvent", function(self, event, ...)
        local unit = ...
        if unit ~= self.unit then
            return
        end
        if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
            startTime, endTime = GetCastingSpellInfo(self)
            delayTime = 0
        elseif event == "UNIT_SPELLCAST_DELAYED" then
            local oldStartTime = startTime
            startTime, endTime = GetCastingSpellInfo(self)
            if startTime and endTime then
                if self.casting then
                    delayTime = (delayTime or 0) + (startTime - (oldStartTime or startTime))
                elseif self.channeling then
                    delayTime = (delayTime or 0) + ((oldStartTime or startTime) - startTime)
                end
            end
        end
    end)
    -- 显示施法时间和施法延迟时间
    bar:HookScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.01 then
            return
        end
        self.elapsed = 0

        local remainingTime
        local totalTime = self.maxValue
        if self.casting then
            remainingTime = max(0, totalTime - self.value)
            timeLabel:SetFormattedText("%s/%s", FormatTime(remainingTime), FormatTime(totalTime))
        elseif self.channeling then
            remainingTime = max(0, self.value)
            timeLabel:SetFormattedText("%s/%s", FormatTime(remainingTime), FormatTime(totalTime))
        end

        if delayTime and delayTime >= 0.1 and (self.casting or self.channeling) then
            delayLabel:SetFormattedText("+%.1f", delayTime)
        else
            delayLabel:SetText("")
        end
    end)
end

ShowTime(CastingBarFrame)
ShowTime(PetCastingBarFrame)

---@type StatusBar
local castingBar = CastingBarFrame
---@type Texture
local latency = castingBar:CreateTexture(nil, "ARTWORK", nil, 1)
latency:SetHeight(castingBar:GetHeight())
latency:SetColorTexture(GetTableColor(RED_FONT_COLOR))
latency:SetAlpha(0.5)
---@type FontString
local latencyLabel = castingBar:CreateFontString(nil, "ARTWORK", "SystemFont_NamePlate")
latencyLabel:SetTextColor(GetTableColor(YELLOW_FONT_COLOR))
local sendTime

---@type Frame
local eventListener = CreateFrame("Frame")

eventListener:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
eventListener:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "vehicle")
eventListener:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player", "vehicle")

eventListener:SetScript("OnEvent", function(_, event)
    if event == "CURRENT_SPELL_CAST_CHANGED" then
        sendTime = GetTime()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        sendTime = nil
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        latency:Hide()
        latencyLabel:Hide()
    end
end)

--- 玩家施法条显示网络延迟
---@param self StatusBar
castingBar:HookScript("OnEvent", function(self, event, ...)
    local unit = ...
    if unit ~= self.unit then
        return
    end
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        local startTime, endTime = GetCastingSpellInfo(self)
        if startTime and endTime and sendTime then
            local diff = GetTime() - sendTime
            local duration = endTime - startTime
            local percent = min(diff, duration) / duration
            if percent > 0 then
                latency:SetWidth(self:GetWidth() * percent)
                latencyLabel:SetFormattedText("%dms", min(diff, duration) * 1000)
                latency:ClearAllPoints()
                latencyLabel:ClearAllPoints()
                if self.casting then
                    latency:SetPoint("RIGHT")
                    latencyLabel:SetPoint("BOTTOMRIGHT")
                elseif self.channeling then
                    latency:SetPoint("LEFT")
                    latencyLabel:SetPoint("BOTTOMLEFT")
                end
                latency:Show()
                latencyLabel:Show()
            else
                latency:Hide()
                latencyLabel:Hide()
            end
            sendTime = nil
        end
    end
end)

local spellTicks = {
    -- 吸取生命
    [234153] = 5,
    -- 吸取灵魂
    [198590] = 5,
    -- 生命通道
    [755] = 5,
}

---@type table<number, Texture>
local ticks = {}
local tickTime = {}

local width = castingBar:GetWidth()

--- 更新 tick
local function UpdateTicks(numTicks, duration)
    if numTicks and numTicks > 0 then
        for i = 1, numTicks do
            local tick = ticks[i]
            if not tick then
                ---@type Texture
                tick = castingBar:CreateTexture(nil, "ARTWORK", nil, 2)
                tick:SetSize(2, castingBar:GetHeight())
                tick:SetColorTexture(GetTableColor(HIGHLIGHT_FONT_COLOR))
                ticks[i] = tick
            end
            tick:ClearAllPoints()
            local xOffset = tickTime[i] / duration * width
            tick:SetPoint("CENTER", castingBar, "RIGHT", -xOffset, 0)
            tick:Show()
        end
        for i = numTicks + 1, #ticks do
            ticks[i]:Hide()
        end
    else
        for i = 1, #ticks do
            ticks[i]:Hide()
        end
    end
end

local tickEndTime, tickDuration, numTicks, intervalTime

--- 显示引导法术 tick
castingBar:HookScript("OnEvent", function(self, event, arg)
    if event == "UNIT_SPELLCAST_CHANNEL_START" and arg == "player" then
        local startTime, endTime, _, spellID = GetCastingSpellInfo(self)
        if not startTime or not endTime then
            return
        end
        if self.channeling and spellTicks[spellID] then
            tickEndTime = endTime
            tickDuration = endTime - startTime
            numTicks = spellTicks[spellID]
            intervalTime = tickDuration / numTicks
            for i = 1, numTicks do
                tickTime[i] = i * intervalTime
            end
            UpdateTicks(numTicks, tickDuration)
        else
            UpdateTicks()
            tickDuration = nil
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" and arg == "player" then
        local startTime, endTime = GetCastingSpellInfo(self)
        if self.channeling and startTime and endTime and tickEndTime and endTime > tickEndTime then
            local duration = endTime - startTime
            if tickDuration and duration > tickDuration and numTicks and numTicks > 0 then
                local extraTime = duration - tickDuration
                for i = 1, numTicks do
                    tickTime[i] = tickTime[i] + extraTime
                end
                while tickTime[numTicks] > intervalTime do
                    numTicks = numTicks + 1
                    tickTime[numTicks] = tickTime[numTicks - 1] - intervalTime
                end
                tickDuration = duration
                tickEndTime = endTime
                UpdateTicks(numTicks, duration)
            end
        end
    elseif (event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_INTERRUPTED") and arg == "player" then
        UpdateTicks()
        tickDuration = nil
    end
end)

---@type FontString
local tradeSkillCountLabel = castingBar:CreateFontString(nil, "ARTWORK", "SystemFont_NamePlate")
tradeSkillCountLabel:SetPoint("BOTTOMLEFT")
tradeSkillCountLabel:SetTextColor(GetTableColor(YELLOW_FONT_COLOR))

local merging, currentCount, totalCount

--- 合并制造物品施法条
---@param self StatusBar
castingBar:HookScript("OnEvent", function(self, event, arg)
    if event == "UNIT_SPELLCAST_START" and arg == "player" then
        local startTime, endTime, isTradeSkill = GetCastingSpellInfo(self)
        if isTradeSkill and self.casting then
            local repeatCount = C_TradeSkillUI.GetRecipeRepeatCount()
            if not merging and repeatCount > 1 then
                currentCount = 0
                totalCount = repeatCount
                merging = true
                intervalTime = endTime - startTime
                for i = 1, totalCount do
                    tickTime[i] = (i - 1) * intervalTime
                end
                UpdateTicks(totalCount, intervalTime * totalCount)
            end
            if merging then
                currentCount = currentCount + 1
                tradeSkillCountLabel:SetFormattedText("(%d/%d)", currentCount, totalCount)
                self.value = self.maxValue * (currentCount - 1) + self.value
                self.maxValue = self.maxValue * totalCount
                self:SetMinMaxValues(0, self.maxValue)
            end
        end
    elseif event == "UNIT_SPELLCAST_STOP" and arg == "player" then
        if merging then
            if currentCount == totalCount then
                merging = nil
                tradeSkillCountLabel:SetText("")
                UpdateTicks()
            else
                self:SetValue(self.maxValue * currentCount / totalCount)
                self.holdTime = GetTime() + 1
            end
        end
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" and arg == "player" then
        if merging then
            merging = nil
            tradeSkillCountLabel:SetText("")
            UpdateTicks()
        end
    end
end)

---@type StatusBar
local gcd = CreateFrame("StatusBar", "WLK_GCDBar", UIParent)
gcd:SetSize(228, 3)
gcd:SetPoint("BOTTOMRIGHT", castingBar, "TOPRIGHT")
gcd:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
gcd:SetStatusBarColor(GetTableColor(YELLOW_FONT_COLOR))
gcd:SetMinMaxValues(0, 1)
gcd:SetAlpha(0)

---@type Texture
local gcdBackground = gcd:CreateTexture(nil, "BACKGROUND")
gcdBackground:SetAllPoints()
gcdBackground:SetTexture("Interface/DialogFrame/UI-DialogBox-Background-Dark")

--- 隐藏 GCD
local function HideGCD()
    gcd:SetAlpha(0)
    gcd:SetScript("OnUpdate", nil)
end

--- 显示 GCD
local function ShowGCD()
    gcd:SetAlpha(1)
    gcd:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.01 then
            return
        end
        self.elapsed = 0

        if not self.startTime then
            HideGCD()
        end
        local percent = (GetTime() - self.startTime) / self.duration
        if percent > 1 then
            HideGCD()
        else
            gcd:SetValue(percent)
        end
    end)
end

gcd:RegisterUnitEvent("UNIT_SPELLCAST_START", "player", "vehicle")
gcd:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "vehicle")

gcd:SetScript("OnEvent", function(self, ...)
    local _, _, _, spellID = ...
    local startTime, duration = GetSpellCooldown(spellID)
    if duration and duration > 0 and duration <= 1.5 then
        self.startTime = startTime
        self.duration = duration
        ShowGCD()
    end
end)

---@type Frame
local swing = CreateFrame("Frame", "WLK_SwingBar", UIParent)
swing:SetSize(228, 6)
swing:SetPoint("TOPRIGHT", castingBar, "BOTTOMRIGHT")

---@type StatusBar
local mainSwing = CreateFrame("StatusBar", "WLK_MainSwingBar", swing)
mainSwing:SetSize(swing:GetWidth() / 2, swing:GetHeight())
mainSwing:SetPoint("LEFT")
mainSwing:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
mainSwing:SetStatusBarColor(GetTableColor(YELLOW_FONT_COLOR))
mainSwing:SetMinMaxValues(0, 1)
mainSwing:SetAlpha(0)
---@type Texture
mainSwing.background = mainSwing:CreateTexture(nil, "BACKGROUND")
mainSwing.background:SetAllPoints()
mainSwing.background:SetTexture("Interface/DialogFrame/UI-DialogBox-Background-Dark")
---@type FontString
mainSwing.label = mainSwing:CreateFontString()
mainSwing.label:SetFont("Fonts/blei00d.TTF", 9, "OUTLINE")
mainSwing.label:SetPoint("CENTER")
mainSwing.label:SetTextColor(GetTableColor(HIGHLIGHT_FONT_COLOR))

---@type StatusBar
local offSwing = CreateFrame("StatusBar", "WLK_OffSwingBar", swing)
offSwing:SetSize(swing:GetWidth() / 2, swing:GetHeight())
offSwing:SetPoint("RIGHT")
offSwing:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
offSwing:SetStatusBarColor(GetTableColor(YELLOW_FONT_COLOR))
offSwing:SetMinMaxValues(0, 1)
offSwing:SetAlpha(0)
---@type Texture
offSwing.background = offSwing:CreateTexture(nil, "BACKGROUND")
offSwing.background:SetAllPoints()
offSwing.background:SetTexture("Interface/DialogFrame/UI-DialogBox-Background-Dark")
---@type FontString
offSwing.label = offSwing:CreateFontString()
offSwing.label:SetFont("Fonts/blei00d.TTF", 9, "OUTLINE")
offSwing.label:SetPoint("CENTER")
offSwing.label:SetTextColor(GetTableColor(HIGHLIGHT_FONT_COLOR))

mainSwing.remainTime = 0
mainSwing.prevSpeed = 0
mainSwing.speed = 0
mainSwing.itemID = GetInventoryItemID("player", INVSLOT_MAINHAND)
offSwing.remainTime = 0
offSwing.prevSpeed = 0
offSwing.speed = 0
offSwing.itemID = GetInventoryItemID("player", INVSLOT_OFFHAND)

local _, class = UnitClass("player")
local hasOffhand
local isRangeAttack

--- 具有攻击速度的法术
local spellsWithSpeed = {
    DRUID = {
        6807, -- 槌击
    },
    HUNTER = {
        186270, -- 猛禽一击
    },
    WARRIOR = {
        1464, -- 猛击
        845, -- 顺劈斩
    },
}
local spellSpeed -- 法术的攻击速度
local checkSpeedChange = true -- 是否要检查攻击速度变化

--- 检查法术是否具有攻击速度
local function IsSpellWithSpeed(spellID)
    local spells = spellsWithSpeed[class]
    if spells then
        for i = 1, #spells do
            if spellID == spells[i] then
                return true
            end
        end
    end
    return false
end

--- 更新主手攻击速度
local function UpdateMainSpeed()
    mainSwing.prevSpeed = mainSwing.speed
    -- 法术攻击速度存在时，使用法术攻击速度，远程攻击使用 UnitRangedDamage 获取攻击速度，近战攻击使用 UnitAttackSpeed 获取
    mainSwing.speed = spellSpeed or isRangeAttack and UnitRangedDamage("player") or UnitAttackSpeed("player")
    -- 跳过一次攻击速度变化检查，检查之后的变化
    if checkSpeedChange then
        mainSwing.speedChanged = mainSwing.speed ~= mainSwing.prevSpeed
    elseif mainSwing.speed ~= mainSwing.prevSpeed then
        checkSpeedChange = true
    end
end

--- 更新副手攻击速度
local function UpdateOffSpeed()
    offSwing.prevSpeed = offSwing.speed
    offSwing.speed = select(2, UnitAttackSpeed("player"))
    offSwing.speedChanged = offSwing.speed ~= offSwing.prevSpeed
    hasOffhand = offSwing.speed and offSwing.speed ~= 0
end

--- 重置主手剩余时间为主手攻击速度
local function ResetMainRemainTime()
    mainSwing.remainTime = mainSwing.speed
end

--- 重置副手剩余时间为副手攻击速度
local function ResetOffRemainTime()
    if hasOffhand then
        offSwing.remainTime = offSwing.speed
    end
end

--- 更新主手剩余时间
local function UpdateMainRemainTime(elapsed)
    if mainSwing.remainTime > 0 then
        mainSwing.remainTime = mainSwing.remainTime - elapsed
        if mainSwing.remainTime < 0 then
            mainSwing.remainTime = 0
        end
    end
end

--- 更新副手剩余时间
local function UpdateOffRemainTime(elapsed)
    if offSwing.remainTime > 0 then
        offSwing.remainTime = offSwing.remainTime - elapsed
        if offSwing.remainTime < 0 then
            offSwing.remainTime = 0
        end
    end
end

--- 显示 swing 计时条
---@param bar StatusBar
local function ShowSwing(bar)
    bar:SetAlpha(1)
    bar:SetValue((bar.speed - bar.remainTime) / bar.speed)
    bar.label:SetFormattedText("%.1f/%.1f", bar.remainTime, bar.speed)
end

--- 隐藏 swing 计时条
---@param bar StatusBar
local function HideSwing(bar)
    bar:SetAlpha(0)
    bar:SetValue(0)
    bar.label:SetText("")
end

--- 更新 swing 计时条显示
local function UpdateSwingVisibility()
    if mainSwing.remainTime > 0 then
        if hasOffhand and offSwing.remainTime > 0 then
            ShowSwing(offSwing)
            mainSwing:SetWidth(swing:GetWidth() / 2)
        else
            HideSwing(offSwing)
            mainSwing:SetWidth(swing:GetWidth())
        end
        ShowSwing(mainSwing)
    else
        HideSwing(mainSwing)
        HideSwing(offSwing)
        swing:SetScript("OnUpdate", nil)
    end
end

--- 更新数据
local function SwingOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.005 then
        return
    end
    self.elapsed = 0

    -- 更新攻击速度
    UpdateMainSpeed()
    UpdateOffSpeed()

    -- 攻击速度变化时，剩余时间按照比例变化
    if mainSwing.speedChanged or offSwing.speedChanged then
        mainSwing.remainTime = mainSwing.remainTime * mainSwing.speed / mainSwing.prevSpeed
        if hasOffhand then
            offSwing.remainTime = offSwing.remainTime * offSwing.speed / offSwing.prevSpeed
        end
    end

    -- 更新剩余时间
    UpdateMainRemainTime(elapsed)
    UpdateOffRemainTime(elapsed)

    UpdateSwingVisibility()
end

swing:SetScript("OnUpdate", SwingOnUpdate)

swing:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
swing:RegisterEvent("START_AUTOREPEAT_SPELL")
swing:RegisterEvent("STOP_AUTOREPEAT_SPELL")
swing:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
swing:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")

---@param self Frame
swing:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local info = { CombatLogGetCurrentEventInfo() }
        local _, combatEvent, _, srcGUID = unpack(info)
        if srcGUID == UnitGUID("player") then
            if combatEvent == "SWING_DAMAGE" or combatEvent == "SWING_MISSED" then
                -- 如果法术攻击速度存在，则应该更新为近战攻击速度
                if spellSpeed then
                    spellSpeed = nil
                    -- 攻击速度由法术变为近战，不检查此次攻速变化
                    checkSpeedChange = false
                    -- 更新攻击速度
                    UpdateMainSpeed()
                end

                local index = combatEvent == "SWING_DAMAGE" and 21 or 13
                local isOffhand = select(index, unpack(info))
                if isOffhand then
                    ResetOffRemainTime()
                else
                    ResetMainRemainTime()
                end

                if not self:GetScript("OnUpdate") then
                    self:SetScript("OnUpdate", SwingOnUpdate)
                end
            elseif combatEvent == "SPELL_DAMAGE" or combatEvent == "SPELL_MISSED" then
                local spellID = select(12, unpack(info))
                -- 施放具有攻速的法术，修改攻击速度为法术攻速
                if IsSpellWithSpeed(spellID) then
                    -- 法术攻速为此次攻击的剩余时间
                    spellSpeed = mainSwing.remainTime
                    -- 攻速由近战变为法术，不检查此次攻速变化
                    checkSpeedChange = false
                    UpdateMainSpeed()
                    ResetMainRemainTime()
                end
            end
        elseif UnitExists("target") and srcGUID == UnitGUID("target") then
            if combatEvent == "SWING_MISSED" then
                local missType = select(12, unpack(info))
                if missType == "PARRY" then
                    local minRemainTime = mainSwing.speed * 0.2
                    if mainSwing.remainTime > minRemainTime then
                        mainSwing.remainTime = minRemainTime
                    end
                end
            end
        end
    elseif event == "START_AUTOREPEAT_SPELL" then
        isRangeAttack = true
    elseif event == "STOP_AUTOREPEAT_SPELL" then
        isRangeAttack = false
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spellID = ...
        if isRangeAttack and spellID == 5019 or spellID == 75 then
            -- 5019：魔杖的射击，75：远程武器的自动射击
            ResetMainRemainTime()
            if not self:GetScript("OnUpdate") then
                self:SetScript("OnUpdate", SwingOnUpdate)
            end
        end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        local mainItemID = GetInventoryItemID("player", INVSLOT_MAINHAND)
        local offItemID = GetInventoryItemID("player", INVSLOT_OFFHAND)
        if mainItemID ~= mainSwing.itemID then
            UpdateMainSpeed()
            ResetMainRemainTime()
        end
        mainSwing.itemID = mainItemID
        if offItemID ~= offSwing.itemID then
            UpdateOffSpeed()
            ResetOffRemainTime()
        end
        offSwing.itemID = offItemID
    end
end)

---@type StatusBar
local targetCastingBar = CreateFrame("StatusBar", "WLK_TargetCastingBar", UIParent, "CastingBarFrameTemplate")
--- 上边界相对屏幕底部偏移 315px，下边界相对屏幕底部偏移 280px，左边界相对屏幕右边偏移 -840px，右边界相对屏幕右边偏移 -570px
height = 315 - 280 - 2 * 2 - 2 * 2
targetCastingBar:SetSize(840 - 570 - 2 * 2 - 2 - height, height)
targetCastingBar:SetPoint("BOTTOMRIGHT", -570 - 2 - 2, 280 + 2 + 2)
targetCastingBar:Hide()

--- 创建施法条不可打断边框
---@param bar StatusBar
local function CreateShieldBorder(bar)
    local size = 2
    local borderWidth = bar:GetWidth() + bar:GetHeight() + 2 * size
    local borderHeight = bar:GetHeight()

    ---@type Texture
    local topBorder = bar:CreateTexture()
    topBorder:SetSize(borderWidth, size)
    topBorder:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", size, 0)
    topBorder:SetColorTexture(GetTableColor(HIGHLIGHT_FONT_COLOR))
    bar.topBorder = topBorder
    ---@type Texture
    local bottomBorder = bar:CreateTexture()
    bottomBorder:SetSize(borderWidth, size)
    bottomBorder:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", size, 0)
    bottomBorder:SetColorTexture(GetTableColor(HIGHLIGHT_FONT_COLOR))
    bar.bottomBorder = bottomBorder
    ---@type Texture
    local leftBorder = bar:CreateTexture()
    leftBorder:SetSize(size, borderHeight)
    leftBorder:SetPoint("RIGHT", bar.Icon, "LEFT")
    leftBorder:SetColorTexture(GetTableColor(HIGHLIGHT_FONT_COLOR))
    bar.leftBorder = leftBorder
    ---@type Texture
    local rightBorder = bar:CreateTexture()
    rightBorder:SetSize(size, borderHeight)
    rightBorder:SetPoint("LEFT", bar, "RIGHT")
    rightBorder:SetColorTexture(GetTableColor(HIGHLIGHT_FONT_COLOR))
    bar.rightBorder = rightBorder
end

CastingBarFrame_OnLoad(targetCastingBar, "target", true, true)
SetTextures(targetCastingBar)
ShowIcon(targetCastingBar)
ShowTime(targetCastingBar)
MoveText(targetCastingBar)
---@type Texture
local targetShield = targetCastingBar.BorderShield
targetShield:SetTexture(nil)
CreateShieldBorder(targetCastingBar)

hooksecurefunc(targetShield, "Show", function()
    targetCastingBar.topBorder:Show()
    targetCastingBar.bottomBorder:Show()
    targetCastingBar.leftBorder:Show()
    targetCastingBar.rightBorder:Show()
end)

hooksecurefunc(targetShield, "Hide", function()
    targetCastingBar.topBorder:Hide()
    targetCastingBar.bottomBorder:Hide()
    targetCastingBar.leftBorder:Hide()
    targetCastingBar.rightBorder:Hide()
end)

---@type StatusBar
local focusCastingBar = CreateFrame("StatusBar", "WLK_FocusCastingBar", UIParent, "CastingBarFrameTemplate")
height = 18
--- 左边界相对屏幕右边偏移 -540px，右边界相对屏幕右边偏移 -298px
focusCastingBar:SetSize(540 - 298 - 2 - 2 * 2 - height, height)
--- 下边界相对屏幕底部偏移 156px
focusCastingBar:SetPoint("BOTTOMRIGHT", -298 - 1 - 2, 156 + 2 + 2)
focusCastingBar:Hide()

CastingBarFrame_OnLoad(focusCastingBar, "focus", true, true)
SetTextures(focusCastingBar)
ShowIcon(focusCastingBar)
ShowTime(focusCastingBar)
MoveText(focusCastingBar)
---@type Texture
local focusShield = focusCastingBar.BorderShield
focusShield:SetTexture(nil)
CreateShieldBorder(focusCastingBar)

hooksecurefunc(focusShield, "Show", function()
    focusCastingBar.topBorder:Show()
    focusCastingBar.bottomBorder:Show()
    focusCastingBar.leftBorder:Show()
    focusCastingBar.rightBorder:Show()
end)

hooksecurefunc(focusShield, "Hide", function()
    focusCastingBar.topBorder:Hide()
    focusCastingBar.bottomBorder:Hide()
    focusCastingBar.leftBorder:Hide()
    focusCastingBar.rightBorder:Hide()
end)

height = 13

--- 创建首领施法条
local function CreateBossCastingBar(i)
    ---@type StatusBar
    local bossCastingBar = CreateFrame("StatusBar", "WLK_Boss" .. i .. "CastingBar", UIParent,
            "CastingBarFrameTemplate")
    --- 左边界相对屏幕右边偏移 -570px，右边界相对屏幕右边偏移 -298px
    bossCastingBar:SetSize(570 - 298 - 1 - 2 * 2 - height, height)
    --- 下边界相对屏幕底部偏移 314px
    bossCastingBar:SetPoint("BOTTOMRIGHT", -298 - 1 - 2, 314 + 1 + 2 + (i - 1) * (13 + 2 + 2 + 36 + 2 + 33 + 2))
    bossCastingBar:Hide()

    CastingBarFrame_OnLoad(bossCastingBar, "boss" .. i, false, true)
    SetTextures(bossCastingBar)
    ShowIcon(bossCastingBar)
    ShowTime(bossCastingBar)
    MoveText(bossCastingBar)
    ---@type Texture
    local bossShield = bossCastingBar.BorderShield
    bossShield:SetTexture(nil)
    CreateShieldBorder(bossCastingBar)

    hooksecurefunc(bossShield, "Show", function()
        bossCastingBar.topBorder:Show()
        bossCastingBar.bottomBorder:Show()
        bossCastingBar.leftBorder:Show()
        bossCastingBar.rightBorder:Show()
    end)

    hooksecurefunc(bossShield, "Hide", function()
        bossCastingBar.topBorder:Hide()
        bossCastingBar.bottomBorder:Hide()
        bossCastingBar.leftBorder:Hide()
        bossCastingBar.rightBorder:Hide()
    end)
end

for i = 1, MAX_BOSS_FRAMES do
    CreateBossCastingBar(i)
end

--- 创建竞技场单位施法条
local function CreateArenaCastingBar(i)
    ---@type StatusBar
    local arenaCastingBar = CreateFrame("StatusBar", "WLK_Arena" .. i .. "CastingBar", UIParent,
            "CastingBarFrameTemplate")
    arenaCastingBar:SetSize(570 - 298 - 1 - 2 * 2 - height, height)
    arenaCastingBar:SetPoint("BOTTOMRIGHT", -298 - 1 - 2, 314 + 1 + 2 + (i - 1) * (13 + 2 + 2 + 36 + 2 + 33 + 2))
    arenaCastingBar:Hide()

    CastingBarFrame_OnLoad(arenaCastingBar, "arena" .. i, false, true)
    SetTextures(arenaCastingBar)
    ShowIcon(arenaCastingBar)
    ShowTime(arenaCastingBar)
    MoveText(arenaCastingBar)
    ---@type Texture
    local arenaShield = arenaCastingBar.BorderShield
    arenaShield:SetTexture(nil)
    CreateShieldBorder(arenaCastingBar)

    hooksecurefunc(arenaShield, "Show", function()
        arenaCastingBar.topBorder:Show()
        arenaCastingBar.bottomBorder:Show()
        arenaCastingBar.leftBorder:Show()
        arenaCastingBar.rightBorder:Show()
    end)

    hooksecurefunc(arenaShield, "Hide", function()
        arenaCastingBar.topBorder:Hide()
        arenaCastingBar.bottomBorder:Hide()
        arenaCastingBar.leftBorder:Hide()
        arenaCastingBar.rightBorder:Hide()
    end)
end

for i = 1, MAX_ARENA_ENEMIES do
    CreateArenaCastingBar(i)
end
