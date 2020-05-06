---@type Button
local playerFrame = CreateFrame("Button", "WLK_PlayerFrame", UIParent, "SecureUnitButtonTemplate")
playerFrame.unit = "player"
playerFrame:SetSize(300, 60)
--- ChatFrame1Background 右边相对屏幕左边偏移 540px
playerFrame:SetPoint("BOTTOMLEFT", 540, 185)
playerFrame:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark", })
playerFrame:SetAttribute("unit", "player")
playerFrame:SetAttribute("*type1", "target")
playerFrame:SetAttribute("*type2", "togglemenu")
playerFrame:SetAttribute("toggleForVehicle", true)

playerFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

playerFrame:SetScript("OnEnter", function(self)
    UnitFrame_OnEnter(self)
end)

playerFrame:SetScript("OnLeave", function(self)
    UnitFrame_OnLeave(self)
end)

---@type PlayerModel
local playerPortrait = CreateFrame("PlayerModel", nil, playerFrame)
local height = playerFrame:GetHeight()
playerPortrait:SetSize(height - 1, height - 0.5)
playerPortrait:SetPoint("LEFT")
playerFrame.portrait = playerPortrait
playerPortrait:SetPortraitZoom(1)

--- 更新头像
local function UpdatePortrait(unitFrame)
    local unit = unitFrame.unit
    ---@type PlayerModel
    local portrait = unitFrame.portrait

    if not UnitIsVisible(unit) or not UnitIsConnected(unit) then
        portrait:ClearModel()
        portrait:SetModel("Interface/Buttons/talktomequestionmark.m2")
        portrait:SetPosition(0, 0, 0.25)
    else
        -- 使用 3D 动态头像
        portrait:ClearModel()
        portrait:SetUnit(unit)
        portrait:SetPosition(0, 0, 0)
    end
end

--- 更新 GUID
local function UpdateGUID(unitFrame)
    local unit = unitFrame.unit

    local guid = UnitGUID(unit)
    if unitFrame.guid ~= guid then
        -- guid 发生改变则更新头像
        UpdatePortrait(unitFrame)
    end
    unitFrame.guid = guid
end

---@type Texture
local playerRaidTargetIcon = playerPortrait:CreateTexture(nil, "OVERLAY")
playerRaidTargetIcon:SetScale(0.3)
playerRaidTargetIcon:SetPoint("TOPRIGHT")
playerFrame.raidTargetIcon = playerRaidTargetIcon

--- 更新 RaidTarget 图标
local function UpdateRaidTargetIcon(unitFrame)
    local unit = unitFrame.unit
    ---@type Texture
    local raidTargetIcon = unitFrame.raidTargetIcon

    local index = GetRaidTargetIndex(unit)
    if UnitExists(unit) and index then
        raidTargetIcon:SetTexture("Interface/TargetingFrame/UI-RaidTargetingIcon_" .. index)
        raidTargetIcon:Show()
    else
        raidTargetIcon:Hide()
    end
end

---@type Texture
local playerPvPIcon = playerPortrait:CreateTexture(nil, "OVERLAY")
playerPvPIcon:SetPoint("BOTTOMRIGHT", 10, -7)
playerFrame.pvpIcon = playerPvPIcon

--- 更新 PVP 图标
local function UpdatePvPIcon(unitFrame)
    local unit = unitFrame.unit
    ---@type Texture
    local pvpIcon = unitFrame.pvpIcon

    local faction = UnitFactionGroup(unit)
    if faction and faction ~= "Neutral" and UnitIsPVP(unit) then
        pvpIcon:SetTexture("Interface/GroupFrame/UI-Group-PVP-" .. faction)
        pvpIcon:Show()
    else
        pvpIcon:Hide()
    end
end

---@type Texture
local playerLeaderIcon = playerPortrait:CreateTexture(nil, "OVERLAY")
playerLeaderIcon:SetPoint("TOPLEFT")
playerFrame.leaderIcon = playerLeaderIcon

--- 更新队长图标
local function UpdateLeaderIcon(unitFrame)
    local unit = unitFrame.unit
    ---@type Texture
    local leaderIcon = unitFrame.leaderIcon

    if UnitIsGroupLeader(unit) then
        if HasLFGRestrictions() then
            leaderIcon:SetTexture("Interface/LFGFrame/UI-LFG-ICON-PORTRAITROLES")
            leaderIcon:SetTexCoord(0, 0.296875, 0.015625, 0.3125)
            leaderIcon:SetScale(0.3)
        else
            leaderIcon:SetTexture("Interface/GroupFrame/UI-Group-LeaderIcon")
            leaderIcon:SetTexCoord(0, 1, 0, 1)
            leaderIcon:SetScale(1)
        end
        leaderIcon:Show()
    elseif UnitIsGroupAssistant(unit) or UnitInRaid(unit) and IsEveryoneAssistant() then
        leaderIcon:SetTexture("Interface/GroupFrame/UI-Group-AssistantIcon")
        leaderIcon:SetTexCoord(0, 1, 0, 1)
        leaderIcon:SetScale(1)
        leaderIcon:Show()
    else
        leaderIcon:Hide()
    end
end

---@type Texture
local playerStatusIcon = playerPortrait:CreateTexture(nil, "OVERLAY")
playerStatusIcon:SetScale(0.4)
playerStatusIcon:SetTexture("Interface/CharacterFrame/UI-StateIcon")
playerFrame.statusIcon = playerStatusIcon

--- 更新状态图标
local function UpdateStatusIcon(unitFrame)
    local unit = unitFrame.unit
    ---@type Texture
    local statusIcon = unitFrame.statusIcon

    if UnitIsUnit(unit, "player") and IsResting() then
        statusIcon:SetTexCoord(0, 0.5, 0, 0.421875)
        statusIcon:ClearAllPoints()
        statusIcon:SetPoint("BOTTOMLEFT", -10, -3)
        statusIcon:Show()
    elseif UnitAffectingCombat(unit) then
        statusIcon:SetTexCoord(0.5, 1, 0, 0.484375)
        statusIcon:ClearAllPoints()
        statusIcon:SetPoint("BOTTOMLEFT", -8, -13)
        statusIcon:Show()
    else
        statusIcon:Hide()
    end
end

---@type FontString
local playerStatusLabel = playerPortrait:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
playerStatusLabel:SetPoint("CENTER")
playerFrame.statusLabel = playerStatusLabel

--- 更新状态标签
local function UpdateStatusLabel(unitFrame)
    local unit = unitFrame.unit
    ---@type FontString
    local statusLabel = unitFrame.statusLabel

    if UnitIsAFK(unit) then
        statusLabel:SetText(YELLOW_FONT_COLOR_CODE .. CHAT_FLAG_AFK .. FONT_COLOR_CODE_CLOSE)
    elseif UnitIsDND(unit) then
        statusLabel:SetText(RED_FONT_COLOR .. CHAT_FLAG_DND .. FONT_COLOR_CODE_CLOSE)
    else
        statusLabel:SetText("")
    end
end

---@type StatusBar
local playerHealthBar = CreateFrame("StatusBar", nil, playerFrame)
playerHealthBar:SetSize(playerFrame:GetWidth() - height, height * 2 / 3)
playerHealthBar:SetPoint("TOPRIGHT")
playerHealthBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill", "BORDER")
playerFrame.healthBar = playerHealthBar

---@type Texture
local playerHealthBarBackground = playerHealthBar:CreateTexture(nil, "BACKGROUND")
playerHealthBarBackground:SetAllPoints()
playerHealthBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-HP-Bg")
playerHealthBarBackground:SetTexCoord(0, 1, 0, 0.53125)

--- 更新最大生命值
local function UpdateMaxHealth(unitFrame)
    local unit = unitFrame.unit
    ---@type StatusBar
    local healthBar = unitFrame.healthBar

    healthBar:SetMinMaxValues(0, UnitHealthMax(unit))
end

--- 更新生命值
local function UpdateHealth(unitFrame)
    local unit = unitFrame.unit
    ---@type StatusBar
    local healthBar = unitFrame.healthBar

    healthBar:SetValue(UnitHealth(unit))
end

--- 更新生命条颜色
local function UpdateHealthBarColor(unitFrame)
    local unit = unitFrame.unit
    if not UnitExists(unit) then
        return
    end
    ---@type StatusBar
    local healthBar = unitFrame.healthBar

    local color
    if not UnitIsConnected(unit) then
        -- 离线单位
        color = DISABLED_FONT_COLOR
    elseif UnitIsUnit(unit, "vehicle") then
        -- 载具
        color = DIM_GREEN_FONT_COLOR
    elseif UnitIsPlayer(unit) then
        -- 玩家单位，使用职业着色
        local _, class = UnitClass(unit)
        color = C_ClassColor.GetClassColor(class)
    elseif not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
        -- 非玩家控制且无法点击的单位
        color = QUEST_OBJECTIVE_FONT_COLOR
    else
        local _, threatStatus = UnitDetailedThreatSituation("player", unit)
        if threatStatus ~= nil then
            -- 玩家在单位的威胁列表中
            color = RED_FONT_COLOR
        else
            -- 根据单位与玩家的关系着色
            local reaction = UnitReaction(unit, "player")
            if reaction == 4 then
                color = YELLOW_FONT_COLOR
            elseif reaction < 4 then
                color = RED_FONT_COLOR
            else
                color = GREEN_FONT_COLOR
            end
        end
    end
    healthBar:SetStatusBarColor(GetTableColor(color))
end

--- 创建 HealPrediction 纹理
---@param healthBar StatusBar
local function CreateHealPrediction(healthBar)
    ---@type Texture
    local myHealPrediction = healthBar:CreateTexture(nil, "BORDER", nil, 5)
    healthBar.myHealPrediction = myHealPrediction
    ---@type Texture
    local otherHealPrediction = healthBar:CreateTexture(nil, "BORDER", nil, 5)
    healthBar.otherHealPrediction = otherHealPrediction
    ---@type Texture
    local totalAbsorb = healthBar:CreateTexture(nil, "BORDER", nil, 5)
    healthBar.totalAbsorb = totalAbsorb
    ---@type Texture
    local totalAbsorbOverlay = healthBar:CreateTexture(nil, "BORDER", nil, 6)
    healthBar.totalAbsorbOverlay = totalAbsorbOverlay
    ---@type Texture
    local myHealAbsorb = healthBar:CreateTexture(nil, "ARTWORK", nil, 1)
    healthBar.myHealAbsorb = myHealAbsorb
    ---@type Texture
    local myHealAbsorbLeftShadow = healthBar:CreateTexture(nil, "ARTWORK", nil, 1)
    healthBar.myHealAbsorbLeftShadow = myHealAbsorbLeftShadow
    ---@type Texture
    local myHealAbsorbRightShadow = healthBar:CreateTexture(nil, "ARTWORK", nil, 1)
    healthBar.myHealAbsorbRightShadow = myHealAbsorbRightShadow
    ---@type Texture
    local overAbsorbGlow = healthBar:CreateTexture(nil, "ARTWORK", nil, 2)
    healthBar.overAbsorbGlow = overAbsorbGlow
    ---@type Texture
    local overHealAbsorbGlow = healthBar:CreateTexture(nil, "ARTWORK", nil, 2)
    healthBar.overHealAbsorbGlow = overHealAbsorbGlow

    -- 初始化
    myHealPrediction:SetColorTexture(GetTableColor(WHITE_FONT_COLOR))
    myHealPrediction:SetGradient("VERTICAL", 8 / 255, 93 / 255, 72 / 255, 11 / 255, 136 / 255, 105 / 255)
    otherHealPrediction:SetColorTexture(GetTableColor(WHITE_FONT_COLOR))
    otherHealPrediction:SetGradient("VERTICAL", 3 / 255, 72 / 255, 5 / 255, 2 / 255, 101 / 255, 18 / 255)
    totalAbsorb.overlay = totalAbsorbOverlay
    totalAbsorb:SetTexture("Interface/RaidFrame/Shield-Fill")
    totalAbsorbOverlay.tileSize = 32
    totalAbsorbOverlay:SetAllPoints(totalAbsorb)
    totalAbsorbOverlay:SetTexture("Interface/RaidFrame/Shield-Overlay", true, true)
    myHealAbsorb:SetTexture("Interface/RaidFrame/Absorb-Fill", true, true)
    myHealAbsorbLeftShadow:SetTexture("Interface/RaidFrame/Absorb-Edge")
    myHealAbsorbRightShadow:SetTexture("Interface/RaidFrame/Absorb-Edge")
    myHealAbsorbRightShadow:SetTexCoord(1, 0, 0, 1)
    overAbsorbGlow:SetWidth(16)
    overAbsorbGlow:SetPoint("BOTTOMLEFT", healthBar, "BOTTOMRIGHT", -7, 0)
    overAbsorbGlow:SetPoint("TOPLEFT", healthBar, "TOPRIGHT", -7, 0)
    overAbsorbGlow:SetTexture("Interface/RaidFrame/Shield-Overshield")
    overAbsorbGlow:SetBlendMode("ADD")
    overHealAbsorbGlow:SetWidth(16)
    overHealAbsorbGlow:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMLEFT", 7, 0)
    overHealAbsorbGlow:SetPoint("TOPRIGHT", healthBar, "TOPLEFT", 7, 0)
    overHealAbsorbGlow:SetTexture("Interface/RaidFrame/Absorb-Overabsorb")
    overHealAbsorbGlow:SetBlendMode("ADD")
end

CreateHealPrediction(playerHealthBar)

local maxIncomingHealOverflow = 1.05

--- 更新 HealPrediction 纹理
local function UpdateHealPrediction(unitFrame)
    local unit = unitFrame.unit
    ---@type StatusBar
    local healthBar = unitFrame.healthBar

    local _, maxHealth = healthBar:GetMinMaxValues()
    local health = healthBar:GetValue()
    if maxHealth <= 0 then
        return
    end

    local myIncomingHeal = UnitGetIncomingHeals(unit, "player") or 0
    local allIncomingHeal = UnitGetIncomingHeals(unit) or 0
    local totalAbsorb = UnitGetTotalAbsorbs(unit) or 0

    --We don't fill outside the health bar with healAbsorbs.  Instead, an overHealAbsorbGlow is shown.
    local myCurrentHealAbsorb = UnitGetTotalHealAbsorbs(unit) or 0
    ---@type Texture
    local overHealAbsorbGlow = healthBar.overHealAbsorbGlow
    if health < myCurrentHealAbsorb then
        overHealAbsorbGlow:Show()
        myCurrentHealAbsorb = health
    else
        overHealAbsorbGlow:Hide()
    end

    --See how far we're going over the health bar and make sure we don't go too far out of the frame.
    if health - myCurrentHealAbsorb + allIncomingHeal > maxHealth * maxIncomingHealOverflow then
        allIncomingHeal = maxHealth * maxIncomingHealOverflow - health + myCurrentHealAbsorb
    end

    local otherIncomingHeal = 0

    --Split up incoming heals.
    if allIncomingHeal >= myIncomingHeal then
        otherIncomingHeal = allIncomingHeal - myIncomingHeal
    else
        myIncomingHeal = allIncomingHeal
    end

    local overAbsorb = false
    --We don't fill outside the the health bar with absorbs.  Instead, an overAbsorbGlow is shown.
    if health - myCurrentHealAbsorb + allIncomingHeal + totalAbsorb >= maxHealth
            or health + totalAbsorb >= maxHealth then
        if totalAbsorb > 0 then
            overAbsorb = true
        end

        if allIncomingHeal > myCurrentHealAbsorb then
            totalAbsorb = max(0, maxHealth - (health - myCurrentHealAbsorb + allIncomingHeal))
        else
            totalAbsorb = max(0, maxHealth - health)
        end
    end
    ---@type Texture
    local overAbsorbGlow = healthBar.overAbsorbGlow
    if overAbsorb then
        overAbsorbGlow:Show()
    else
        overAbsorbGlow:Hide()
    end

    local healthTexture = healthBar:GetStatusBarTexture()

    local myCurrentHealAbsorbPercent = myCurrentHealAbsorb / maxHealth

    local healAbsorbTexture

    --If allIncomingHeal is greater than myCurrentHealAbsorb, then the current
    --heal absorb will be completely overlayed by the incoming heals so we don't show it.
    ---@type Texture
    local myHealAbsorb = healthBar.myHealAbsorb
    ---@type Texture
    local myHealAbsorbRightShadow = healthBar.myHealAbsorbRightShadow
    ---@type Texture
    local myHealAbsorbLeftShadow = healthBar.myHealAbsorbLeftShadow
    if myCurrentHealAbsorb > allIncomingHeal then
        local shownHealAbsorb = myCurrentHealAbsorb - allIncomingHeal
        local shownHealAbsorbPercent = shownHealAbsorb / maxHealth
        healAbsorbTexture = CompactUnitFrameUtil_UpdateFillBar(unitFrame, healthTexture, myHealAbsorb, shownHealAbsorb,
                -shownHealAbsorbPercent)

        --If there are incoming heals the left shadow would be overlayed by the incoming heals
        --so it isn't shown.
        if allIncomingHeal > 0 then
            myHealAbsorbLeftShadow:Hide()
        else
            myHealAbsorbLeftShadow:SetPoint("TOPLEFT", healAbsorbTexture)
            myHealAbsorbLeftShadow:SetPoint("BOTTOMLEFT", healAbsorbTexture)
            myHealAbsorbLeftShadow:Show()
        end

        -- The right shadow is only shown if there are absorbs on the health bar.
        if totalAbsorb > 0 then
            myHealAbsorbRightShadow:SetPoint("TOPLEFT", healAbsorbTexture, "TOPRIGHT", -8, 0)
            myHealAbsorbRightShadow:SetPoint("BOTTOMLEFT", healAbsorbTexture, "BOTTOMRIGHT", -8, 0)
            myHealAbsorbRightShadow:Show()
        else
            myHealAbsorbRightShadow:Hide()
        end
    else
        myHealAbsorb:Hide()
        myHealAbsorbRightShadow:Hide()
        myHealAbsorbLeftShadow:Hide()
    end

    --Show myIncomingHeal on the health bar.
    local incomingHealsTexture = CompactUnitFrameUtil_UpdateFillBar(unitFrame, healthTexture,
            healthBar.myHealPrediction, myIncomingHeal, -myCurrentHealAbsorbPercent)
    --Append otherIncomingHeal on the health bar.
    incomingHealsTexture = CompactUnitFrameUtil_UpdateFillBar(unitFrame, incomingHealsTexture,
            healthBar.otherHealPrediction, otherIncomingHeal)

    --Appen absorbs to the correct section of the health bar.
    local appendTexture
    if healAbsorbTexture then
        --If there is a healAbsorb part shown, append the absorb to the end of that.
        appendTexture = healAbsorbTexture
    else
        --Otherwise, append the absorb to the end of the the incomingHeals part;
        appendTexture = incomingHealsTexture
    end
    CompactUnitFrameUtil_UpdateFillBar(unitFrame, appendTexture, healthBar.totalAbsorb, totalAbsorb)
end

---@type FontString
local playerPercentHealthLabel = playerHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
playerPercentHealthLabel:SetPoint("BOTTOMRIGHT", 0, 2)
playerFrame.percentHealthLabel = playerPercentHealthLabel

--- 更新百分比生命值标签
local function UpdatePercentHealthLabel(unitFrame)
    local unit = unitFrame.unit
    ---@type FontString
    local percentHealthLabel = unitFrame.percentHealthLabel

    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    if maxHealth > 0 then
        percentHealthLabel:SetFormattedText("%d%%", health / maxHealth * 100)
    else
        percentHealthLabel:SetText("")
    end
end

---@type FontString
local playerHealthLabel = playerHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
playerHealthLabel:SetPoint("BOTTOMLEFT", 0, 2)
playerFrame.healthLabel = playerHealthLabel

--- 格式化数字
local function FormatNumber(number)
    if number >= 1e8 then
        return format("%.2f" .. SECOND_NUMBER_CAP, number / 1e8)
    elseif number >= 1e6 then
        return format("%d" .. SECOND_NUMBER, number / 1e4)
    elseif number >= 1e4 then
        return format("%.1f" .. SECOND_NUMBER, number / 1e4)
    end
    return number
end

--- 更新生命值标签
local function UpdateHealthLabel(unitFrame)
    local unit = unitFrame.unit
    ---@type FontString
    local healthLabel = unitFrame.healthLabel

    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    if maxHealth > 0 then
        healthLabel:SetText(FormatNumber(health) .. "/" .. FormatNumber(maxHealth))
    else
        healthLabel:SetText("")
    end
end

---@type FontString
local playerAbsorbLabel = playerHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
playerAbsorbLabel:SetPoint("LEFT", playerHealthLabel, "RIGHT")
playerFrame.absorbLabel = playerAbsorbLabel

--- 更新吸收值标签
local function UpdateAbsorbLabel(unitFrame)
    local unit = unitFrame.unit
    ---@type FontString
    local absorbLabel = unitFrame.absorbLabel

    local absorb = UnitGetTotalAbsorbs(unit)
    if absorb and absorb > 0 then
        absorbLabel:SetText("+" .. FormatNumber(absorb))
    else
        absorbLabel:SetText("")
    end
end

---@type FontString
local playerNameLabel = playerHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
playerNameLabel:SetPoint("TOPRIGHT", 0, -2)
playerFrame.nameLabel = playerNameLabel

--- 更新名字标签
local function UpdateNameLabel(unitFrame)
    local unit = unitFrame.unit
    ---@type FontString
    local nameLabel = unitFrame.nameLabel

    nameLabel:SetText(UnitName(unit))
end

---@type FontString
local playerGroupLabel = playerHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
playerGroupLabel:SetPoint("RIGHT", playerNameLabel, "LEFT")
playerFrame.groupLabel = playerGroupLabel

--- 更新队伍编号标签
local function UpdateGroupLabel(unitFrame)
    local unit = unitFrame.unit
    ---@type FontString
    local groupLabel = unitFrame.groupLabel

    local raidID = UnitInRaid(unit)
    if raidID then
        local _, _, group = GetRaidRosterInfo(raidID)
        groupLabel:SetFormattedText("(%d)", group)
    else
        groupLabel:SetText("")
    end
end

---@type FontString
local playerRaceLabel = playerHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
playerRaceLabel:SetPoint("TOPLEFT", 0, -2)
playerFrame.raceLabel = playerRaceLabel

--- 更新种族标签
local function UpdateRaceLabel(unitFrame)
    local unit = unitFrame.unit
    ---@type FontString
    local raceLabel = unitFrame.raceLabel

    if UnitIsPlayer(unit) then
        raceLabel:SetText(UnitRace(unit))
    else
        raceLabel:SetText(UnitCreatureFamily(unit) or UnitCreatureType(unit))
    end
end

---@type FontString
local playerLevelLabel = playerHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
playerLevelLabel:SetPoint("LEFT", playerRaceLabel, "RIGHT")
playerFrame.levelLabel = playerLevelLabel

--- 更新等级标签
local function UpdateLevelLabel(unitFrame)
    local unit = unitFrame.unit
    ---@type FontString
    local levelLabel = unitFrame.levelLabel

    local classification = UnitClassification(unit)
    if classification == "worldboss" then
        -- 世界首领
        levelLabel:SetText(BOSS)
    elseif UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
        -- 战斗宠物
        levelLabel:SetText(UnitBattlePetLevel(unit))
    else
        local level = UnitLevel(unit)
        if level <= 0 then
            -- 未知等级
            level = "??"
        end
        if classification == "elite" or classification == "rareelite" then
            -- 精英
            level = level .. "+"
        end
        levelLabel:SetText(level)
    end
end

---@type StatusBar
local playerPowerBar = CreateFrame("StatusBar", nil, playerFrame)
playerPowerBar:SetSize(playerFrame:GetWidth() - height, height / 3)
playerPowerBar:SetPoint("TOPRIGHT", playerHealthBar, "BOTTOMRIGHT")
playerPowerBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill", "BORDER")
playerFrame.powerBar = playerPowerBar

---@type Texture
local playerPowerBarBackground = playerPowerBar:CreateTexture(nil, "BACKGROUND")
playerPowerBarBackground:SetAllPoints()
playerPowerBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")

--- 更新最大能量值
local function UpdateMaxPower(unitFrame)
    local unit = unitFrame.unit
    ---@type StatusBar
    local powerBar = unitFrame.powerBar

    powerBar:SetMinMaxValues(0, UnitPowerMax(unit))
end

--- 更新能量值
local function UpdatePower(unitFrame)
    local unit = unitFrame.unit
    ---@type StatusBar
    local powerBar = unitFrame.powerBar

    powerBar:SetValue(UnitPower(unit))
end

--- 更新能量条颜色
local function UpdatePowerBarColor(unitFrame)
    local unit = unitFrame.unit
    ---@type StatusBar
    local powerBar = unitFrame.powerBar

    if not UnitIsConnected(unit) then
        powerBar:SetStatusBarColor(GetTableColor(DISABLED_FONT_COLOR))
    else
        local powerType, powerToken, altR, altG, altB = UnitPowerType(unit)
        local info = PowerBarColor[powerToken]
        if info then
            powerBar:SetStatusBarColor(GetTableColor(info))
        elseif not altR then
            info = PowerBarColor[powerType] or PowerBarColor["MANA"]
            powerBar:SetStatusBarColor(GetTableColor(info))
        else
            powerBar:SetStatusBarColor(altR, altG, altB)
        end
    end
end

---@type FontString
local playerPercentPowerLabel = playerPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
playerPercentPowerLabel:SetPoint("RIGHT")
playerFrame.percentPowerLabel = playerPercentPowerLabel

--- 更新百分比能量值标签
local function UpdatePercentPowerLabel(unitFrame)
    local unit = unitFrame.unit
    ---@type FontString
    local percentPowerLabel = unitFrame.percentPowerLabel

    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    if maxPower > 0 then
        percentPowerLabel:SetFormattedText("%d%%", power / maxPower * 100)
    else
        percentPowerLabel:SetText("")
    end
end

---@type FontString
local playerPowerLabel = playerPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
playerPowerLabel:SetPoint("LEFT")
playerFrame.powerLabel = playerPowerLabel

--- 更新能量值标签
local function UpdatePowerLabel(unitFrame)
    local unit = unitFrame.unit
    ---@type FontString
    local powerLabel = unitFrame.powerLabel

    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    if maxPower > 0 then
        powerLabel:SetText(FormatNumber(power) .. "/" .. FormatNumber(maxPower))
    else
        powerLabel:SetText("")
    end
end

---@type Frame
local playerComboPoints = CreateFrame("Frame", nil, playerFrame)
playerComboPoints:SetSize(playerFrame:GetWidth() - height, 9)
playerComboPoints:SetPoint("BOTTOMRIGHT")

---@param self Frame
playerComboPoints:SetScript("OnShow", function(self)
    playerPowerBar:SetHeight((height - self:GetHeight()) / 3)
    playerHealthBar:SetHeight(height - playerPowerBar:GetHeight() - self:GetHeight())
end)

playerComboPoints:SetScript("OnHide", function()
    playerPowerBar:SetHeight(height / 3)
    playerHealthBar:SetHeight(height * 2 / 3)
end)

playerFrame.comboPoints = {}
--- 连击点之间的水平间距
local spacing = 5

--- 更新 ComboPoints
local function UpdateComboPoints(unitFrame)
    local unit = unitFrame.unit

    local show
    if UnitIsUnit(unit, "vehicle") then
        show = PlayerVehicleHasComboPoints()
    else
        local _, class = UnitClass(unit)
        show = class == "ROGUE" or class == "DRUID"
    end
    if show then
        local maxPoints = UnitPowerMax(unit, Enum.PowerType.ComboPoints)
        if #(playerFrame.comboPoints) ~= maxPoints then
            -- 创建 ComboPoints 纹理
            for i = 1, maxPoints do
                ---@type Texture
                local point = playerComboPoints:CreateTexture()
                point:SetSize((playerComboPoints:GetWidth() - spacing * (maxPoints - 1)) / maxPoints,
                        playerComboPoints:GetHeight())
                point:SetPoint("LEFT", (point:GetWidth() + spacing) * (i - 1), 0)
                point:SetColorTexture(GetTableColor(PowerBarColor["COMBO_POINTS"]))
                playerFrame.comboPoints[i] = point
            end
        end

        -- 获取当前 ComboPoints
        local points
        if UnitExists("target") then
            points = GetComboPoints(unit)
        else
            points = UnitPower(unit, Enum.PowerType.ComboPoints)
        end

        -- 显示当前 ComboPoints
        for i = 1, #(playerFrame.comboPoints) do
            ---@type Texture
            local point = playerFrame.comboPoints[i]
            point:SetAlpha(i > points and 0.15 or 1)
        end
        playerComboPoints:Show()
    else
        playerComboPoints:Hide()
        wipe(playerFrame.comboPoints)
    end
end

--- 更新光环按钮
local function UpdateAuraButton(auraFrame, index, name, icon, count, duration, expirationTime, source, spellID)
    local type = auraFrame.type
    -- 光环在黑名单中则不更新
    if WLK_UnitAuraFilter.blacklist[type][name] or WLK_UnitAuraFilter.blacklist[type][spellID] then
        return
    end

    local showAllSource = auraFrame.showAllSource
    local sourceIsPlayer = source == "player" or source == "vehicle" or source == "pet"
    -- 光环在白名单中或是由玩家施放则更新
    if WLK_UnitAuraFilter.whitelist[type][name] or WLK_UnitAuraFilter.whitelist[type][spellID] or showAllSource
            or not showAllSource and sourceIsPlayer then
        auraFrame.numAurasShown = auraFrame.numAurasShown + 1
        ---@type Button
        local button = auraFrame.buttons[auraFrame.numAurasShown]
        if button then
            button.slot = nil
            button.index = index
            button.icon:SetTexture(icon)
            button.stack:SetText(count > 1 and count or "")
            button.cooldown:SetCooldown(expirationTime - duration, duration)
            button:Show()
        end
    end
end

--- 更新图腾按钮
local function UpdateTotemButton(auraFrame, totemValue)
    auraFrame.numAurasShown = auraFrame.numAurasShown + 1
    ---@type Button
    local button = auraFrame.buttons[auraFrame.numAurasShown]
    if button then
        button.index = nil
        button.slot = totemValue.slot
        button.icon:SetTexture(totemValue.icon)
        local count = totemValue.count
        button.stack:SetText(count > 1 and count or "")
        button.cooldown:SetCooldown(totemValue.startTime, totemValue.duration)
        button:Show()
    end
end

--- 扫描单位所有光环
---@param auraFrame Frame
local function ScannerUnitAura(auraFrame)
    local unit = auraFrame:GetParent().unit
    local filter = auraFrame.type == "Buff" and "HELPFUL" or "HARMFUL"

    local index = 0
    while true do
        index = index + 1
        local name, icon, count, _, duration, expirationTime, source, _, _, spellID = UnitAura(unit, index, filter)
        if not name then
            break
        end
        UpdateAuraButton(auraFrame, index, name, icon, count, duration, expirationTime, source, tostring(spellID))
        if auraFrame.numAurasShown >= #(auraFrame.buttons) then
            break
        end
    end

    if unit == "player" and auraFrame.type == "Buff" and auraFrame.numAurasShown < #(auraFrame.buttons) then
        local totems = {}
        for i = 1, MAX_TOTEMS do
            local haveTotem, _, startTime, duration, icon = GetTotemInfo(i)
            if haveTotem then
                if not totems[icon] then
                    totems[icon] = { slot = i, startTime = startTime, duration = duration, icon = icon, count = 1, }
                else
                    totems[icon].count = totems[icon].count + 1
                end
            end
        end
        for _, value in pairs(totems) do
            UpdateTotemButton(auraFrame, value)
            if auraFrame.numAurasShown >= #(auraFrame.buttons) then
                break
            end
        end
    end

    -- 隐藏没有光环的按钮
    for i = auraFrame.numAurasShown + 1, #(auraFrame.buttons) do
        ---@type Button
        local button = auraFrame.buttons[i]
        button:Hide()
    end
end

--- 更新光环
local function UpdateAuras(unitFrame)
    local debuffFrame = unitFrame.debuffs
    local buffFrame = unitFrame.buffs

    if debuffFrame then
        debuffFrame.numAurasShown = 0
        ScannerUnitAura(debuffFrame)
    end

    if buffFrame then
        buffFrame.numAurasShown = 0
        ScannerUnitAura(buffFrame)
    end
end

---@type GameTooltip
local tooltip = CreateFrame("GameTooltip", "WLK_UnitAuraTooltip", UIParent, "GameTooltipTemplate")

hooksecurefunc(tooltip, "SetUnitAura", function(self, ...)
    local id = select(10, UnitAura(...))
    if id then
        self:AddLine(" ")
        self:AddLine(AURAS .. " " .. ID .. ": " .. HIGHLIGHT_FONT_COLOR_CODE .. id .. FONT_COLOR_CODE_CLOSE)
        self:Show()
    end
end)

--- 光环按钮大小
local size = 34

--- 创建光环按钮
---@param auraFrame Frame
local function CreateAuraButton(auraFrame)
    local filter = auraFrame.type == "Buff" and "HELPFUL" or "HARMFUL"

    ---@type Button
    local btn = CreateFrame("Button", nil, auraFrame)
    btn:SetSize(size, size)
    btn:Hide()

    ---@type Cooldown
    local cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetReverse(true)
    cooldown:SetDrawEdge(false)
    cooldown:SetDrawSwipe(true)
    cooldown:SetSwipeColor(BLACK_FONT_COLOR.r, BLACK_FONT_COLOR.g, BLACK_FONT_COLOR.b, 0.8)
    btn.cooldown = cooldown

    ---@type FontString
    local stack = btn:CreateFontString(nil, "ARTWORK", "NumberFont_Outline_Large")
    stack:SetPoint("BOTTOMRIGHT")
    btn.stack = stack

    ---@type Texture
    local icon = btn:CreateTexture()
    icon:SetAllPoints()
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    btn.icon = icon

    btn:SetScript("OnEnter", function(self)
        ---@type Button
        local unitFrame = auraFrame:GetParent()
        local unit = unitFrame.unit
        local index = self.index
        local slot = self.slot

        tooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 30, -30)
        if index then
            tooltip:SetUnitAura(unit, index, filter)
        elseif slot then
            tooltip:SetTotem(slot)
        end
        self.ticker = C_Timer.NewTicker(TOOLTIP_UPDATE_TIME, function()
            if index then
                tooltip:SetUnitAura(unit, index, filter)
            elseif slot then
                tooltip:SetTotem(slot)
            end
        end)
    end)

    btn:SetScript("OnLeave", function(self)
        ---@type TickerPrototype
        local ticker = self.ticker
        ticker:Cancel()
        ticker = nil
        tooltip:Hide()
    end)

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    btn:SetScript("OnClick", function(self, button)
        ---@type Button
        local unitFrame = auraFrame:GetParent()
        local unit = unitFrame.unit
        local index = self.index

        if index then
            if button == "LeftButton" then
                -- 鼠标左键点击光环将其加入黑名单中
                local auraName = UnitAura(unit, index, filter)
                WLK_UnitAuraFilter.blacklist[auraFrame.type][auraName] = true
                UpdateAuras(unitFrame)
            else
                -- 鼠标右键点击光环取消该增益
                if (UnitIsUnit(unit, "player") or UnitIsUnit(unit, "vehicle")) and not InCombatLockdown() then
                    CancelUnitBuff(unit, index, filter)
                end
            end
        elseif self.slot then
            TotemButton_OnClick(self, button)
        end
    end)

    return btn
end

local maxNum = 8
local numPerLine = 8
local rows = ceil(maxNum / numPerLine)
spacing = 4

---@type Frame
local playerDebuffFrame = CreateFrame("Frame", nil, playerFrame)
playerDebuffFrame.type = "Debuff"
playerDebuffFrame.numAurasShown = 0
playerDebuffFrame.showAllSource = true
playerDebuffFrame.buttons = {}
playerDebuffFrame:SetSize(size * numPerLine + spacing * (numPerLine - 1), size * rows)
playerDebuffFrame:SetPoint("TOPRIGHT", playerFrame, "BOTTOMRIGHT", 0, -1)
playerFrame.debuffs = playerDebuffFrame

for i = 1, maxNum do
    local button = CreateAuraButton(playerDebuffFrame)
    button:SetPoint("TOPRIGHT", -((size + spacing) * ((i - 1) % numPerLine)), (ceil(i / numPerLine) - 1) * size)
    tinsert(playerDebuffFrame.buttons, button)
end

maxNum = 16
rows = ceil(maxNum / numPerLine)
---@type Frame
local playerBuffFrame = CreateFrame("Frame", nil, playerFrame)
playerBuffFrame.type = "Buff"
playerBuffFrame.numAurasShown = 0
playerBuffFrame.showAllSource = false
playerBuffFrame.buttons = {}
playerBuffFrame:SetSize(size * numPerLine + spacing * (numPerLine - 1), size * rows)
playerBuffFrame:SetPoint("BOTTOMRIGHT", playerFrame, "TOPRIGHT", 0, 1)
playerFrame.buffs = playerBuffFrame

for i = 1, maxNum do
    local button = CreateAuraButton(playerBuffFrame)
    button:SetPoint("BOTTOMRIGHT", -((size + spacing) * ((i - 1) % numPerLine)), (ceil(i / numPerLine) - 1) * size)
    tinsert(playerBuffFrame.buttons, button)
end

--- 注册单位事件
---@param unitFrame Button
local function RegisterUnitEvents(unitFrame, events, unit)
    for i = 1, #events do
        unitFrame:RegisterUnitEvent(events[i], unit)
    end
end

local playerFrameUnitEvents = {
    "UNIT_PORTRAIT_UPDATE",
    "UNIT_MODEL_CHANGED",

    "UNIT_FACTION",

    "PLAYER_FLAGS_CHANGED",

    "UNIT_MAXHEALTH",

    "UNIT_HEALTH",
    "UNIT_HEALTH_FREQUENT",

    "UNIT_HEAL_PREDICTION",
    "UNIT_ABSORB_AMOUNT_CHANGED",
    "UNIT_HEAL_ABSORB_AMOUNT_CHANGED",

    "UNIT_NAME_UPDATE",

    "UNIT_CLASSIFICATION_CHANGED",

    "UNIT_MAXPOWER",

    "UNIT_POWER_UPDATE",

    "UNIT_DISPLAYPOWER",
    "UNIT_POWER_BAR_SHOW",
    "UNIT_POWER_BAR_HIDE",

    "UNIT_POWER_FREQUENT",

    "UNIT_AURA",
}

playerFrame:RegisterEvent("PLAYER_LOGIN")
playerFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
playerFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")

playerFrame:RegisterEvent("PORTRAITS_UPDATED")

playerFrame:RegisterEvent("RAID_TARGET_UPDATE")

playerFrame:RegisterEvent("PARTY_LEADER_CHANGED")
playerFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

playerFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
playerFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
playerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
playerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
playerFrame:RegisterEvent("PLAYER_UPDATE_RESTING")

playerFrame:RegisterEvent("PLAYER_LEVEL_CHANGED")

playerFrame:RegisterEvent("PLAYER_TOTEM_UPDATE")
playerFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
playerFrame:RegisterEvent("PLAYER_TALENT_UPDATE")

RegisterUnitEvents(playerFrame, playerFrameUnitEvents, "player")

--- 更新玩家框架
local function UpdatePlayerFrame()
    UpdateGUID(playerFrame)
    UpdateRaidTargetIcon(playerFrame)
    UpdatePvPIcon(playerFrame)
    UpdateLeaderIcon(playerFrame)
    UpdateStatusIcon(playerFrame)
    UpdateStatusLabel(playerFrame)
    UpdateMaxHealth(playerFrame)
    UpdateHealth(playerFrame)
    UpdateHealthBarColor(playerFrame)
    UpdateHealPrediction(playerFrame)
    UpdatePercentHealthLabel(playerFrame)
    UpdateHealthLabel(playerFrame)
    UpdateAbsorbLabel(playerFrame)
    UpdateNameLabel(playerFrame)
    UpdateGroupLabel(playerFrame)
    UpdateLevelLabel(playerFrame)
    UpdateRaceLabel(playerFrame)
    UpdateMaxPower(playerFrame)
    UpdatePower(playerFrame)
    UpdatePowerBarColor(playerFrame)
    UpdatePercentPowerLabel(playerFrame)
    UpdatePowerLabel(playerFrame)
    UpdateComboPoints(playerFrame)
    UpdateAuras(playerFrame)
end

---@param self Button
playerFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        UpdatePlayerFrame()
        self:UnregisterEvent(event)
    elseif event == "UNIT_ENTERED_VEHICLE" and UnitHasVehicleUI("player") and UnitHasVehiclePlayerFrameUI("player") then
        -- 进入载具且有载具界面时，更新 playerFrame.unit 为 "vehicle"
        self.unit = "vehicle"
        RegisterUnitEvents(self, playerFrameUnitEvents, "vehicle")
        UpdatePlayerFrame()
    elseif event == "UNIT_EXITING_VEHICLE" then
        -- 离开载具时，更新 playerFrame.unit 为 "player"
        self.unit = "player"
        RegisterUnitEvents(self, playerFrameUnitEvents, "player")
        UpdatePlayerFrame()
    elseif event == "UNIT_PORTRAIT_UPDATE" or event == "PORTRAITS_UPDATED" or event == "UNIT_MODEL_CHANGED" then
        UpdatePortrait(self)
    elseif event == "RAID_TARGET_UPDATE" then
        UpdateRaidTargetIcon(self)
    elseif event == "UNIT_FACTION" then
        UpdatePvPIcon(self)
    elseif event == "PARTY_LEADER_CHANGED" then
        UpdateLeaderIcon(self)
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdateLeaderIcon(self)
        UpdateGroupLabel(self)
    elseif event == "PLAYER_ENTER_COMBAT" or event == "PLAYER_LEAVE_COMBAT" or event == "PLAYER_REGEN_ENABLED"
            or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_UPDATE_RESTING" then
        UpdateStatusIcon(self)
    elseif event == "PLAYER_FLAGS_CHANGED" then
        UpdateStatusLabel(self)
    elseif event == "UNIT_MAXHEALTH" then
        UpdateMaxHealth(self)
        UpdateHealth(self)
        UpdateHealPrediction(self)
        UpdatePercentHealthLabel(self)
        UpdateHealthLabel(self)
    elseif event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        UpdateHealth(self)
        UpdateHealPrediction(self)
        UpdatePercentHealthLabel(self)
        UpdateHealthLabel(self)
    elseif event == "UNIT_HEAL_PREDICTION" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
        UpdateHealPrediction(self)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        UpdateHealPrediction(self)
        UpdateAbsorbLabel(self)
    elseif event == "UNIT_NAME_UPDATE" then
        UpdateNameLabel(self)
    elseif event == "PLAYER_LEVEL_CHANGED" then
        UpdateLevelLabel(self)
    elseif event == "UNIT_CLASSIFICATION_CHANGED" then
        UpdateRaceLabel(self)
    elseif event == "UNIT_MAXPOWER" or event == "UNIT_POWER_FREQUENT" then
        UpdateMaxPower(self)
        UpdatePower(self)
        UpdatePercentPowerLabel(self)
        UpdatePowerLabel(self)
        UpdateComboPoints(self)
    elseif event == "UNIT_POWER_UPDATE" then
        UpdatePower(self)
        UpdatePercentPowerLabel(self)
        UpdatePowerLabel(self)
    elseif event == "UNIT_DISPLAYPOWER" or event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" then
        UpdateMaxPower(self)
        UpdatePower(self)
        UpdatePowerBarColor(self)
        UpdatePercentPowerLabel(self)
        UpdatePowerLabel(self)
    elseif event == "UNIT_AURA" or event == "PLAYER_TOTEM_UPDATE" or event == "UPDATE_SHAPESHIFT_FORM"
            or event == "PLAYER_TALENT_UPDATE" then
        UpdateAuras(self)
    end
end)

---@type Button
local petFrame = CreateFrame("Button", "WLK_PetFrame", UIParent, "SecureUnitButtonTemplate")
petFrame.unit = "pet"
petFrame:SetSize(200, 36)
--- MultiBarBottomLeft 左边相对屏幕左边偏移 566px
petFrame:SetPoint("LEFT", UIParent, "BOTTOMLEFT", 566, 112 + (185 - 34 - 1 - 112) / 2)
--- 提高层级，防止出现和 PetActionBarFrame 重叠导致无法点击的问题
petFrame:SetFrameStrata("HIGH")
petFrame:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark", })
petFrame:SetAttribute("unit", "pet")
petFrame:SetAttribute("*type1", "target")
petFrame:SetAttribute("*type2", "togglemenu")
petFrame:SetAttribute("toggleForVehicle", true)
--- 根据 petFrame 的 unit 是否存在来显示或隐藏 petFrame
RegisterUnitWatch(petFrame, false)

petFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

petFrame:SetScript("OnEnter", function(self)
    UnitFrame_OnEnter(self)
end)

petFrame:SetScript("OnLeave", function(self)
    UnitFrame_OnLeave(self)
end)

---@param self Button
petFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < TOOLTIP_UPDATE_TIME then
        return
    end
    self.elapsed = 0

    -- 755：生命通道，45 码
    self:SetAlpha(IsSpellInRange(GetSpellInfo(755), self.unit) == 1 and 1 or 0.55)
end)

---@type Texture
local petRaidTargetIcon = petFrame:CreateTexture()
petRaidTargetIcon:SetSize(566 - 540, 566 - 540)
petRaidTargetIcon:SetPoint("RIGHT", petFrame, "LEFT")
petFrame.raidTargetIcon = petRaidTargetIcon

---@type StatusBar
local petHealthBar = CreateFrame("StatusBar", nil, petFrame)
petHealthBar:SetSize(petFrame:GetWidth(), petFrame:GetHeight() * 2 / 3)
petHealthBar:SetPoint("TOP")
petHealthBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill", "BORDER")
petFrame.healthBar = petHealthBar

---@type Texture
local petHealthBarBackground = petHealthBar:CreateTexture(nil, "BACKGROUND")
petHealthBarBackground:SetAllPoints()
petHealthBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-HP-Bg")
petHealthBarBackground:SetTexCoord(0, 1, 0, 0.53125)

CreateHealPrediction(petHealthBar)

---@type FontString
local petPercentHealthLabel = petHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
petPercentHealthLabel:SetPoint("RIGHT")
petFrame.percentHealthLabel = petPercentHealthLabel

---@type FontString
local petHealthLabel = petHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
petHealthLabel:SetPoint("LEFT")
petFrame.healthLabel = petHealthLabel

---@type FontString
local petAbsorbLabel = petHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
petAbsorbLabel:SetPoint("LEFT", petHealthLabel, "RIGHT")
petFrame.absorbLabel = petAbsorbLabel

---@type StatusBar
local petPowerBar = CreateFrame("StatusBar", nil, petFrame)
petPowerBar:SetSize(petFrame:GetWidth(), petFrame:GetHeight() / 3)
petPowerBar:SetPoint("BOTTOM")
petPowerBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill", "BORDER")
petFrame.powerBar = petPowerBar

---@type Texture
local petPowerBarBackground = petPowerBar:CreateTexture(nil, "BACKGROUND")
petPowerBarBackground:SetAllPoints()
petPowerBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")

---@type FontString
local petPercentPowerLabel = petPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
petPercentPowerLabel:SetPoint("RIGHT")
petFrame.percentPowerLabel = petPercentPowerLabel

---@type FontString
local petNameLabel = petPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
petNameLabel:SetPoint("LEFT")
petFrame.nameLabel = petNameLabel

local petFrameUnitEvents = {
    "UNIT_MAXHEALTH",

    "UNIT_HEALTH",
    "UNIT_HEALTH_FREQUENT",

    "UNIT_HEAL_PREDICTION",
    "UNIT_ABSORB_AMOUNT_CHANGED",
    "UNIT_HEAL_ABSORB_AMOUNT_CHANGED",

    "UNIT_NAME_UPDATE",

    "UNIT_MAXPOWER",

    "UNIT_POWER_UPDATE",

    "UNIT_DISPLAYPOWER",
    "UNIT_POWER_BAR_SHOW",
    "UNIT_POWER_BAR_HIDE",
}

petFrame:RegisterUnitEvent("UNIT_PET", "player")
petFrame:RegisterUnitEvent("UNIT_ENTERING_VEHICLE", "player")
petFrame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")

petFrame:RegisterEvent("RAID_TARGET_UPDATE")

RegisterUnitEvents(petFrame, petFrameUnitEvents, "pet")

--- 更新宠物框架
local function UpdatePetFrame()
    UpdateRaidTargetIcon(petFrame)
    UpdateMaxHealth(petFrame)
    UpdateHealth(petFrame)
    UpdateHealthBarColor(petFrame)
    UpdateHealPrediction(petFrame)
    UpdatePercentHealthLabel(petFrame)
    UpdateHealthLabel(petFrame)
    UpdateAbsorbLabel(petFrame)
    UpdateNameLabel(petFrame)
    UpdateMaxPower(petFrame)
    UpdatePower(petFrame)
    UpdatePowerBarColor(petFrame)
    UpdatePercentPowerLabel(petFrame)
end

petFrame:SetScript("OnEvent", function(self, event)
    if event == "UNIT_PET" then
        UpdatePetFrame()
    elseif event == "UNIT_ENTERING_VEHICLE" and UnitHasVehicleUI("player")
            and UnitHasVehiclePlayerFrameUI("player") then
        self.unit = "player"
        RegisterUnitEvents(self, petFrameUnitEvents, "player")
        UpdatePetFrame()
    elseif event == "UNIT_EXITED_VEHICLE" then
        self.unit = "pet"
        RegisterUnitEvents(self, petFrameUnitEvents, "pet")
        UpdatePetFrame()
    elseif event == "RAID_TARGET_UPDATE" then
        UpdateRaidTargetIcon(self)
    elseif event == "UNIT_MAXHEALTH" then
        UpdateMaxHealth(self)
        UpdateHealth(self)
        UpdateHealPrediction(self)
        UpdatePercentHealthLabel(self)
        UpdateHealthLabel(self)
    elseif event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        UpdateHealth(self)
        UpdateHealPrediction(self)
        UpdatePercentHealthLabel(self)
        UpdateHealthLabel(self)
    elseif event == "UNIT_HEAL_PREDICTION" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
        UpdateHealPrediction(self)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        UpdateHealPrediction(self)
        UpdateAbsorbLabel(self)
    elseif event == "UNIT_NAME_UPDATE" then
        UpdateNameLabel(self)
    elseif event == "UNIT_MAXPOWER" then
        UpdateMaxPower(self)
        UpdatePower(self)
        UpdatePercentPowerLabel(self)
    elseif event == "UNIT_POWER_UPDATE" then
        UpdatePower(self)
        UpdatePercentPowerLabel(self)
    elseif event == "UNIT_DISPLAYPOWER" or event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" then
        UpdateMaxPower(self)
        UpdatePower(self)
        UpdatePowerBarColor(self)
        UpdatePercentPowerLabel(self)
    end
end)

---@type Button
local targetFrame = CreateFrame("Button", "WLK_TargetFrame", UIParent, "SecureUnitButtonTemplate")
targetFrame.unit = "target"
targetFrame:SetSize(300, 60)
--- 和 playerFrame 对称
targetFrame:SetPoint("BOTTOMRIGHT", -540, 185)
targetFrame:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark", })
targetFrame:SetAttribute("unit", "target")
targetFrame:SetAttribute("*type2", "togglemenu")
RegisterUnitWatch(targetFrame, false)

targetFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

targetFrame:SetScript("OnEnter", function(self)
    UnitFrame_OnEnter(self)
end)

targetFrame:SetScript("OnLeave", function(self)
    UnitFrame_OnLeave(self)
end)

--- 更新距离检查
---@param unitFrame Button
local function UpdateInRange(unitFrame, elapsed)
    unitFrame.elapsed = (unitFrame.elapsed or 0) + elapsed
    if unitFrame.elapsed < TOOLTIP_UPDATE_TIME then
        return
    end
    unitFrame.elapsed = 0

    local unit = unitFrame.unit

    local spell
    if UnitCanAssist("player", unit) then
        -- 20707：灵魂石，40 码
        spell = GetSpellInfo(20707)
    elseif UnitCanAttack("player", unit) then
        -- 232670：所有专精术士的暗影箭，40 码
        spell = GetSpellInfo(232670)
    end

    if spell and IsUsableSpell(spell) then
        unitFrame:SetAlpha(IsSpellInRange(spell, unit) == 1 and 1 or 0.55)
    else
        -- 不可施放法术的单位，根据是否在跟随范围内判断，28 码
        unitFrame:SetAlpha(CheckInteractDistance(unit, 4) and 1 or 0.55)
    end
end

targetFrame:SetScript("OnUpdate", UpdateInRange)

---@type PlayerModel
local targetPortrait = CreateFrame("PlayerModel", nil, targetFrame)
targetPortrait:SetSize(height - 1, height - 0.5)
targetPortrait:SetPoint("RIGHT")
targetFrame.portrait = targetPortrait
targetPortrait:SetPortraitZoom(1)

---@type Texture
local targetRaidTargetIcon = targetPortrait:CreateTexture(nil, "OVERLAY")
targetRaidTargetIcon:SetScale(0.3)
targetRaidTargetIcon:SetPoint("TOPLEFT")
targetFrame.raidTargetIcon = targetRaidTargetIcon

---@type Texture
local targetPvPIcon = targetPortrait:CreateTexture(nil, "OVERLAY")
targetPvPIcon:SetPoint("BOTTOMLEFT", -7, -7)
targetFrame.pvpIcon = targetPvPIcon

---@type Texture
local targetLeaderIcon = targetPortrait:CreateTexture(nil, "OVERLAY")
targetLeaderIcon:SetPoint("TOPRIGHT")
targetFrame.leaderIcon = targetLeaderIcon

---@type Texture
local targetQuestIcon = targetPortrait:CreateTexture(nil, "OVERLAY")
targetQuestIcon:SetScale(0.7)
targetQuestIcon:SetPoint("BOTTOMRIGHT", 5, 0)
targetQuestIcon:SetTexture("Interface/TargetingFrame/PortraitQuestBadge")
targetFrame.questIcon = targetQuestIcon

--- 更新任务图标
local function UpdateQuestIcon(unitFrame)
    local unit = unitFrame.unit
    ---@type Texture
    local questIcon = unitFrame.questIcon

    if UnitIsQuestBoss(unit) then
        questIcon:Show()
    else
        questIcon:Hide()
    end
end

---@type FontString
local targetStatusLabel = targetPortrait:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
targetStatusLabel:SetPoint("CENTER")
targetFrame.statusLabel = targetStatusLabel

---@type StatusBar
local targetHealthBar = CreateFrame("StatusBar", nil, targetFrame)
targetHealthBar:SetSize(targetFrame:GetWidth() - height, height * 2 / 3)
targetHealthBar:SetPoint("TOPLEFT")
targetHealthBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill", "BORDER")
targetFrame.healthBar = targetHealthBar

---@type Texture
local targetHealthBarBackground = targetHealthBar:CreateTexture(nil, "BACKGROUND")
targetHealthBarBackground:SetAllPoints()
targetHealthBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-HP-Bg")
targetHealthBarBackground:SetTexCoord(0, 1, 0, 0.53125)

CreateHealPrediction(targetHealthBar)

---@type FontString
local targetPercentHealthLabel = targetHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetPercentHealthLabel:SetPoint("BOTTOMLEFT", 0, 2)
targetFrame.percentHealthLabel = targetPercentHealthLabel

---@type FontString
local targetAbsorbLabel = targetHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetAbsorbLabel:SetPoint("BOTTOMRIGHT", 0, 2)
targetFrame.absorbLabel = targetAbsorbLabel

---@type FontString
local targetHealthLabel = targetHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetHealthLabel:SetPoint("BOTTOMRIGHT", targetAbsorbLabel, "BOTTOMLEFT")
targetFrame.healthLabel = targetHealthLabel

---@type FontString
local targetNameLabel = targetHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetNameLabel:SetPoint("TOPLEFT", 0, -2)
targetFrame.nameLabel = targetNameLabel

---@type FontString
local targetGroupLabel = targetHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetGroupLabel:SetPoint("LEFT", targetNameLabel, "RIGHT")
targetFrame.groupLabel = targetGroupLabel

---@type FontString
local targetRaceLabel = targetHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetRaceLabel:SetPoint("TOPRIGHT", 0, -2)
targetFrame.raceLabel = targetRaceLabel

---@type FontString
local targetLevelLabel = targetHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetLevelLabel:SetPoint("RIGHT", targetRaceLabel, "LEFT")
targetFrame.levelLabel = targetLevelLabel

---@type StatusBar
local targetPowerBar = CreateFrame("StatusBar", nil, targetFrame)
targetPowerBar:SetSize(targetFrame:GetWidth() - height, height / 3)
targetPowerBar:SetPoint("TOPLEFT", targetHealthBar, "BOTTOMLEFT")
targetPowerBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill", "BORDER")
targetFrame.powerBar = targetPowerBar

---@type Texture
local targetPowerBarBackground = targetPowerBar:CreateTexture(nil, "BACKGROUND")
targetPowerBarBackground:SetAllPoints()
targetPowerBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")

---@type FontString
local targetPercentPowerLabel = targetPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetPercentPowerLabel:SetPoint("LEFT")
targetFrame.percentPowerLabel = targetPercentPowerLabel

---@type FontString
local targetPowerLabel = targetPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetPowerLabel:SetPoint("RIGHT")
targetFrame.powerLabel = targetPowerLabel

---@type StatusBar
local targetAltPowerBar = CreateFrame("StatusBar", nil, targetFrame)
targetAltPowerBar:SetSize(targetFrame:GetWidth() - height, 9)
targetAltPowerBar:SetPoint("BOTTOMLEFT")
targetFrame.altPowerBar = targetAltPowerBar

---@type FontString
local targetAltPowerLabel = targetAltPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetAltPowerLabel:SetPoint("CENTER")
targetFrame.altPowerLabel = targetAltPowerLabel

---@param self StatusBar
targetAltPowerBar:SetScript("OnShow", function(self)
    targetPowerBar:SetHeight((height - self:GetHeight()) / 3)
    targetHealthBar:SetHeight(height - targetPowerBar:GetHeight() - self:GetHeight())
end)

targetAltPowerBar:SetScript("OnHide", function()
    targetPowerBar:SetHeight(height / 3)
    targetHealthBar:SetHeight(height * 2 / 3)
end)

--- 更新 AlternatePowerBar
local function UpdateAltPowerBar(unitFrame)
    local unit = unitFrame.unit
    ---@type StatusBar
    local altPowerBar = unitFrame.altPowerBar
    ---@type FontString
    local altPowerLabel = unitFrame.altPowerLabel

    local barType, _, _, _, _, hideFromOthers = UnitAlternatePowerInfo(unit)
    if barType and not hideFromOthers and barType ~= ALT_POWER_TYPE_COUNTER then
        --- 使用 UnitPowerBarAlt.fill 的纹理和颜色
        local texture, r, g, b = UnitAlternatePowerTextureInfo(unit, 2)
        altPowerBar:SetStatusBarTexture(texture)
        altPowerBar:SetStatusBarColor(r, g, b)
        altPowerBar:Show()
    else
        altPowerBar:Hide()
    end

    if altPowerBar:IsShown() then
        local _, minPower = UnitAlternatePowerInfo(unit)
        local maxPower = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)
        local power = UnitPower(unit, ALTERNATE_POWER_INDEX)
        altPowerBar:SetMinMaxValues(minPower, maxPower)
        altPowerBar:SetValue(power)
        altPowerLabel:SetFormattedText("(%d) %d/%d", power / maxPower * 100, power, maxPower)
    end
end

maxNum = 8
numPerLine = 8
rows = ceil(maxNum / numPerLine)

---@type Frame
local targetDebuffFrame = CreateFrame("Frame", nil, targetFrame)
targetDebuffFrame.type = "Debuff"
targetDebuffFrame.numAurasShown = 0
targetDebuffFrame.showAllSource = false
targetDebuffFrame.buttons = {}
targetDebuffFrame:SetSize(size * numPerLine + spacing * (numPerLine - 1), size * rows)
targetDebuffFrame:SetPoint("BOTTOMLEFT", targetFrame, "TOPLEFT", 0, 1)
targetFrame.debuffs = targetDebuffFrame

for i = 1, maxNum do
    local button = CreateAuraButton(targetDebuffFrame)
    button:SetPoint("BOTTOMLEFT", (size + spacing) * ((i - 1) % numPerLine), (ceil(i / numPerLine) - 1) * size)
    tinsert(targetDebuffFrame.buttons, button)
end

maxNum = 8
rows = ceil(maxNum / numPerLine)

---@type Frame
local targetBuffFrame = CreateFrame("Frame", nil, targetFrame)
targetBuffFrame.type = "Buff"
targetBuffFrame.numAurasShown = 0
targetBuffFrame.showAllSource = true
targetBuffFrame.buttons = {}
targetBuffFrame:SetSize(size * numPerLine + spacing * (numPerLine - 1), size * rows)
targetBuffFrame:SetPoint("TOPLEFT", targetFrame, "BOTTOMLEFT", 0, -1)
targetFrame.buffs = targetBuffFrame

for i = 1, maxNum do
    local button = CreateAuraButton(targetBuffFrame)
    button:SetPoint("TOPLEFT", (size + spacing) * (i - 1), (1 - ceil(i / numPerLine)) * size)
    tinsert(targetBuffFrame.buttons, button)
end

targetFrame:RegisterEvent("PLAYER_LOGIN")
targetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
targetFrame:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "target")

targetFrame:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "target")
targetFrame:RegisterUnitEvent("UNIT_MODEL_CHANGED", "target")
targetFrame:RegisterEvent("PORTRAITS_UPDATED")

targetFrame:RegisterEvent("RAID_TARGET_UPDATE")

targetFrame:RegisterUnitEvent("UNIT_FACTION", "target")

targetFrame:RegisterEvent("PARTY_LEADER_CHANGED")
targetFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

targetFrame:RegisterUnitEvent("UNIT_CLASSIFICATION_CHANGED", "target")

targetFrame:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", "target")

targetFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "target")

targetFrame:RegisterUnitEvent("UNIT_HEALTH", "target")
targetFrame:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "target")

targetFrame:RegisterUnitEvent("UNIT_CONNECTION", "target")
targetFrame:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", "target")
targetFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", "target")

targetFrame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "target")
targetFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "target")
targetFrame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "target")

targetFrame:RegisterUnitEvent("UNIT_LEVEL", "target")

targetFrame:RegisterUnitEvent("UNIT_MAXPOWER", "target")

targetFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "target")

targetFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "target")
targetFrame:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "target")
targetFrame:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "target")

targetFrame:RegisterUnitEvent("UNIT_AURA", "target")

--- 更新目标框架
local function UpdateTargetFrame()
    UpdateGUID(targetFrame)
    UpdateRaidTargetIcon(targetFrame)
    UpdatePvPIcon(targetFrame)
    UpdateLeaderIcon(targetFrame)
    UpdateQuestIcon(targetFrame)
    UpdateStatusLabel(targetFrame)
    UpdateMaxHealth(targetFrame)
    UpdateHealth(targetFrame)
    UpdateHealthBarColor(targetFrame)
    UpdateHealPrediction(targetFrame)
    UpdatePercentHealthLabel(targetFrame)
    UpdateHealthLabel(targetFrame)
    UpdateAbsorbLabel(targetFrame)
    UpdateNameLabel(targetFrame)
    UpdateGroupLabel(targetFrame)
    UpdateLevelLabel(targetFrame)
    UpdateRaceLabel(targetFrame)
    UpdateMaxPower(targetFrame)
    UpdatePower(targetFrame)
    UpdatePowerBarColor(targetFrame)
    UpdatePercentPowerLabel(targetFrame)
    UpdatePowerLabel(targetFrame)
    UpdateAltPowerBar(targetFrame)
    UpdateAuras(targetFrame)
end

---@param self Button
targetFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        UpdateTargetFrame()
        self:UnregisterEvent(event)
    elseif event == "PLAYER_TARGET_CHANGED" or event == "UNIT_TARGETABLE_CHANGED" then
        UpdateTargetFrame()
    elseif event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED" or event == "PORTRAITS_UPDATED" then
        UpdatePortrait(self)
    elseif event == "RAID_TARGET_UPDATE" then
        UpdateRaidTargetIcon(self)
    elseif event == "UNIT_FACTION" then
        UpdatePvPIcon(self)
        UpdateHealthBarColor(self)
    elseif event == "PARTY_LEADER_CHANGED" then
        UpdateLeaderIcon(self)
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdateLeaderIcon(self)
        UpdateGroupLabel(self)
    elseif event == "UNIT_CLASSIFICATION_CHANGED" then
        UpdateQuestIcon(self)
        UpdateRaceLabel(self)
        UpdateLevelLabel(self)
    elseif event == "PLAYER_FLAGS_CHANGED" then
        UpdateStatusLabel(self)
    elseif event == "UNIT_MAXHEALTH" then
        UpdateMaxHealth(self)
        UpdateHealth(self)
        UpdateHealPrediction(self)
        UpdatePercentHealthLabel(self)
        UpdateHealthLabel(self)
    elseif event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        UpdateHealth(self)
        UpdateHealPrediction(self)
        UpdatePercentHealthLabel(self)
        UpdateHealthLabel(self)
    elseif event == "UNIT_CONNECTION" then
        UpdateHealthBarColor(self)
        UpdatePowerBarColor(self)
    elseif event == "UNIT_THREAT_LIST_UPDATE" then
        UpdateHealthBarColor(self)
    elseif event == "UNIT_NAME_UPDATE" then
        UpdateNameLabel(self)
        UpdateHealthBarColor(self)
    elseif event == "UNIT_HEAL_PREDICTION" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
        UpdateHealPrediction(self)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        UpdateHealPrediction(self)
        UpdateAbsorbLabel(self)
    elseif event == "UNIT_LEVEL" then
        UpdateLevelLabel(self)
    elseif event == "UNIT_MAXPOWER" then
        local _, powerType = ...
        if powerType == "ALTERNATE" then
            UpdateAltPowerBar(self)
        else
            UpdateMaxPower(self)
            UpdatePower(self)
            UpdatePercentPowerLabel(self)
            UpdatePowerLabel(self)
        end
    elseif event == "UNIT_POWER_UPDATE" then
        local _, powerType = ...
        if powerType == "ALTERNATE" then
            UpdateAltPowerBar(self)
        else
            UpdatePower(self)
            UpdatePercentPowerLabel(self)
            UpdatePowerLabel(self)
        end
    elseif event == "UNIT_DISPLAYPOWER" then
        UpdateMaxPower(self)
        UpdatePower(self)
        UpdatePowerBarColor(self)
        UpdatePercentPowerLabel(self)
        UpdatePowerLabel(self)
    elseif event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" then
        local _, powerType = ...
        if powerType == "ALTERNATE" then
            UpdateAltPowerBar(self)
        else
            UpdateMaxPower(self)
            UpdatePower(self)
            UpdatePowerBarColor(self)
            UpdatePercentPowerLabel(self)
            UpdatePowerLabel(self)
        end
    elseif event == "UNIT_AURA" then
        UpdateAuras(self)
    end
end)

---@type Button
local targetTargetFrame = CreateFrame("Button", "WLK_TargetTargetFrame", UIParent, "SecureUnitButtonTemplate")
targetTargetFrame.unit = "targetTarget"
targetTargetFrame:SetSize(200, 36)
--- 和 petFrame 对称
targetTargetFrame:SetPoint("RIGHT", UIParent, "BOTTOMRIGHT", -566, 131)
targetTargetFrame:SetFrameStrata("HIGH")
targetTargetFrame:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark", })
targetTargetFrame:SetAttribute("unit", "targetTarget")
targetTargetFrame:SetAttribute("*type1", "target")
targetTargetFrame:SetAttribute("*type2", "togglemenu")
RegisterUnitWatch(targetTargetFrame, false)

targetTargetFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

targetTargetFrame:SetScript("OnEnter", function(self)
    UnitFrame_OnEnter(self)
end)

targetTargetFrame:SetScript("OnLeave", function(self)
    UnitFrame_OnLeave(self)
end)

targetTargetFrame:SetScript("OnUpdate", UpdateInRange)

---@type Texture
local targetTargetRaidTargetIcon = targetTargetFrame:CreateTexture()
targetTargetRaidTargetIcon:SetSize(26, 26)
targetTargetRaidTargetIcon:SetPoint("LEFT", targetTargetFrame, "RIGHT")
targetTargetFrame.raidTargetIcon = targetTargetRaidTargetIcon

---@type StatusBar
local targetTargetHealthBar = CreateFrame("StatusBar", nil, targetTargetFrame)
targetTargetHealthBar:SetSize(targetTargetFrame:GetWidth(), targetTargetFrame:GetHeight() * 2 / 3)
targetTargetHealthBar:SetPoint("TOP")
targetTargetHealthBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill", "BORDER")
targetTargetFrame.healthBar = targetTargetHealthBar

---@type Texture
local targetTargetHealthBarBackground = targetTargetHealthBar:CreateTexture(nil, "BACKGROUND")
targetTargetHealthBarBackground:SetAllPoints()
targetTargetHealthBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-HP-Bg")
targetTargetHealthBarBackground:SetTexCoord(0, 1, 0, 0.53125)

CreateHealPrediction(targetTargetHealthBar)

---@type FontString
local targetTargetPercentHealthLabel = targetTargetHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetTargetPercentHealthLabel:SetPoint("LEFT")
targetTargetFrame.percentHealthLabel = targetTargetPercentHealthLabel

---@type FontString
local targetTargetAbsorbLabel = targetTargetHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetTargetAbsorbLabel:SetPoint("RIGHT")
targetTargetFrame.absorbLabel = targetTargetAbsorbLabel

---@type FontString
local targetTargetHealthLabel = targetTargetHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetTargetHealthLabel:SetPoint("RIGHT", targetTargetAbsorbLabel, "LEFT")
targetTargetFrame.healthLabel = targetTargetHealthLabel

---@type StatusBar
local targetTargetPowerBar = CreateFrame("StatusBar", nil, targetTargetFrame)
targetTargetPowerBar:SetSize(targetTargetFrame:GetWidth(), targetTargetFrame:GetHeight() / 3)
targetTargetPowerBar:SetPoint("BOTTOM")
targetTargetPowerBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill", "BORDER")
targetTargetFrame.powerBar = targetTargetPowerBar

---@type Texture
local targetTargetPowerBarBackground = targetTargetPowerBar:CreateTexture(nil, "BACKGROUND")
targetTargetPowerBarBackground:SetAllPoints()
targetTargetPowerBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")

---@type FontString
local targetTargetPercentPowerLabel = targetTargetPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetTargetPercentPowerLabel:SetPoint("LEFT")
targetTargetFrame.percentPowerLabel = targetTargetPercentPowerLabel

---@type FontString
local targetTargetNameLabel = targetTargetPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
targetTargetNameLabel:SetPoint("RIGHT")
targetTargetFrame.nameLabel = targetTargetNameLabel

targetTargetFrame:RegisterEvent("PLAYER_LOGIN")
targetTargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
targetTargetFrame:RegisterUnitEvent("UNIT_TARGET", "target")

targetTargetFrame:RegisterEvent("RAID_TARGET_UPDATE")

targetTargetFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "targetTarget")

targetTargetFrame:RegisterUnitEvent("UNIT_HEALTH", "targetTarget")
targetTargetFrame:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "targetTarget")

targetTargetFrame:RegisterUnitEvent("UNIT_CONNECTION", "targetTarget")
targetTargetFrame:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", "targetTarget")
targetTargetFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", "targetTarget")
targetTargetFrame:RegisterUnitEvent("UNIT_FACTION", "targetTarget")

targetTargetFrame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "targetTarget")
targetTargetFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "targetTarget")
targetTargetFrame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "targetTarget")

targetTargetFrame:RegisterUnitEvent("UNIT_MAXPOWER", "targetTarget")

targetTargetFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "targetTarget")

targetTargetFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "targetTarget")
targetTargetFrame:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "targetTarget")
targetTargetFrame:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "targetTarget")

--- 更新目标的目标框架
local function UpdateTargetTargetFrame()
    UpdateRaidTargetIcon(targetTargetFrame)
    UpdateMaxHealth(targetTargetFrame)
    UpdateHealth(targetTargetFrame)
    UpdateHealthBarColor(targetTargetFrame)
    UpdateHealPrediction(targetTargetFrame)
    UpdatePercentHealthLabel(targetTargetFrame)
    UpdateHealthLabel(targetTargetFrame)
    UpdateAbsorbLabel(targetTargetFrame)
    UpdateNameLabel(targetTargetFrame)
    UpdateMaxPower(targetTargetFrame)
    UpdatePower(targetTargetFrame)
    UpdatePowerBarColor(targetTargetFrame)
    UpdatePercentPowerLabel(targetTargetFrame)
end

---@param self Button
targetTargetFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        UpdateTargetTargetFrame()
        self:UnregisterEvent(event)
    elseif event == "PLAYER_TARGET_CHANGED" or event == "UNIT_TARGET" then
        UpdateTargetTargetFrame()
    elseif event == "RAID_TARGET_UPDATE" then
        UpdateRaidTargetIcon(self)
    elseif event == "UNIT_MAXHEALTH" then
        UpdateMaxHealth(self)
        UpdateHealth(self)
        UpdateHealPrediction(self)
        UpdatePercentHealthLabel(self)
        UpdateHealthLabel(self)
    elseif event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        UpdateHealth(self)
        UpdateHealPrediction(self)
        UpdatePercentHealthLabel(self)
        UpdateHealthLabel(self)
    elseif event == "UNIT_CONNECTION" then
        UpdateHealthBarColor(self)
        UpdatePowerBarColor(self)
    elseif event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_FACTION" then
        UpdateHealthBarColor(self)
    elseif event == "UNIT_NAME_UPDATE" then
        UpdateNameLabel(self)
        UpdateHealthBarColor(self)
    elseif event == "UNIT_HEAL_PREDICTION" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
        UpdateHealPrediction(self)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        UpdateHealPrediction(self)
        UpdateAbsorbLabel(self)
    elseif event == "UNIT_MAXPOWER" then
        UpdateMaxPower(self)
        UpdatePower(self)
        UpdatePercentPowerLabel(self)
    elseif event == "UNIT_POWER_UPDATE" then
        UpdatePower(self)
        UpdatePercentPowerLabel(self)
    elseif event == "UNIT_DISPLAYPOWER" or event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" then
        UpdateMaxPower(self)
        UpdatePower(self)
        UpdatePowerBarColor(self)
        UpdatePercentPowerLabel(self)
    end
end)

--- 焦点光环大小
size = 30
--- 焦点光环之间的水平间距
spacing = 5
maxNum = 7
numPerLine = 7
rows = ceil(maxNum / numPerLine)

---@type Button
local focusFrame = CreateFrame("Button", "WLK_FocusFrame", UIParent, "SecureUnitButtonTemplate")
focusFrame.unit = "focus"
--- targetFrame 右边相对屏幕右边偏移 -540px，MicroButtonAndBagsBar 左边相对屏幕右边偏移 -298px，raidTarget 的大小是
---（26px，26px），高亮边框宽度是 2px
focusFrame:SetSize(540 - 298 - 1 * 2 - 26 - 2 * 2, 42)
--- NoticeFrame 顶部相对屏幕底部偏移 156px，焦点施法条的高度是 22px
focusFrame:SetPoint("BOTTOMRIGHT", -298 - 1 - 26 - 2, 156 + 2 + 22 + 1 + size + 1 + 2)
focusFrame:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark", })
focusFrame:SetAttribute("unit", "focus")
focusFrame:SetAttribute("*type1", "target")
focusFrame:SetAttribute("*type2", "togglemenu")
RegisterUnitWatch(focusFrame, false)

focusFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

focusFrame:SetScript("OnEnter", function(self)
    UnitFrame_OnEnter(self)
end)

focusFrame:SetScript("OnLeave", function(self)
    UnitFrame_OnLeave(self)
end)

focusFrame:SetScript("OnUpdate", UpdateInRange)

--- 创建高亮边框
---@param unitFrame Button
local function CreateHighlight(unitFrame)
    local highlightSize = 2
    local unitFrameWidth, unitFrameHeight = unitFrame:GetSize()
    local r, g, b = GetTableColor(YELLOW_FONT_COLOR)

    ---@type Texture
    local highlightTop = unitFrame:CreateTexture()
    highlightTop:SetSize(unitFrameWidth + highlightSize * 2, highlightSize)
    highlightTop:SetPoint("BOTTOM", unitFrame, "TOP")
    highlightTop:SetColorTexture(r, g, b)
    unitFrame.highlightTop = highlightTop
    ---@type Texture
    local highlightBottom = unitFrame:CreateTexture()
    highlightBottom:SetSize(unitFrameWidth + highlightSize * 2, highlightSize)
    highlightBottom:SetPoint("TOP", unitFrame, "BOTTOM")
    highlightBottom:SetColorTexture(r, g, b)
    unitFrame.highlightBottom = highlightBottom
    ---@type Texture
    local highlightLeft = unitFrame:CreateTexture()
    highlightLeft:SetSize(highlightSize, unitFrameHeight)
    highlightLeft:SetPoint("RIGHT", unitFrame, "LEFT")
    highlightLeft:SetColorTexture(r, g, b)
    unitFrame.highlightLeft = highlightLeft
    ---@type Texture
    local highlightRight = unitFrame:CreateTexture()
    highlightRight:SetSize(highlightSize, unitFrameHeight)
    highlightRight:SetPoint("LEFT", unitFrame, "RIGHT")
    highlightRight:SetColorTexture(r, g, b)
    unitFrame.highlightRight = highlightRight
end

CreateHighlight(focusFrame)

--- 更新高亮边框
local function UpdateHighlight(unitFrame)
    local unit = unitFrame.unit
    ---@type Texture
    local highlightTop = unitFrame.highlightTop
    ---@type Texture
    local highlightBottom = unitFrame.highlightBottom
    ---@type Texture
    local highlightLeft = unitFrame.highlightLeft
    ---@type Texture
    local highlightRight = unitFrame.highlightRight

    if UnitIsUnit(unit, "target") then
        highlightTop:Show()
        highlightBottom:Show()
        highlightLeft:Show()
        highlightRight:Show()
    else
        highlightTop:Hide()
        highlightBottom:Hide()
        highlightLeft:Hide()
        highlightRight:Hide()
    end
end

---@type Texture
local focusRaiTargetIcon = focusFrame:CreateTexture()
focusRaiTargetIcon:SetSize(26, 26)
focusRaiTargetIcon:SetPoint("LEFT", focusFrame, "RIGHT", 2, 0)
focusFrame.raidTargetIcon = focusRaiTargetIcon

---@type StatusBar
local focusHealthBar = CreateFrame("StatusBar", nil, focusFrame)
focusHealthBar:SetSize(focusFrame:GetWidth(), focusFrame:GetHeight() * 2 / 3)
focusHealthBar:SetPoint("TOP")
focusHealthBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill", "BORDER")
focusFrame.healthBar = focusHealthBar

---@type Texture
local focusHealthBarBackground = focusHealthBar:CreateTexture(nil, "BACKGROUND")
focusHealthBarBackground:SetAllPoints()
focusHealthBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-HP-Bg")
focusHealthBarBackground:SetTexCoord(0, 1, 0, 0.53125)

CreateHealPrediction(focusHealthBar)

---@type FontString
local focusPercentHealthLabel = focusHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
focusPercentHealthLabel:SetPoint("LEFT")
focusFrame.percentHealthLabel = focusPercentHealthLabel

---@type FontString
local focusAbsorbLabel = focusHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
focusAbsorbLabel:SetPoint("RIGHT")
focusFrame.absorbLabel = focusAbsorbLabel

---@type FontString
local focusHealthLabel = focusHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
focusHealthLabel:SetPoint("RIGHT", focusAbsorbLabel, "LEFT")
focusFrame.healthLabel = focusHealthLabel

---@type StatusBar
local focusPowerBar = CreateFrame("StatusBar", nil, focusFrame)
focusPowerBar:SetSize(focusFrame:GetWidth(), focusFrame:GetHeight() / 3)
focusPowerBar:SetPoint("TOP", focusHealthBar, "BOTTOM")
focusPowerBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill", "BORDER")
focusFrame.powerBar = focusPowerBar

---@type Texture
local focusPowerBarBackground = focusPowerBar:CreateTexture(nil, "BACKGROUND")
focusPowerBarBackground:SetAllPoints()
focusPowerBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")

---@type FontString
local focusPercentPowerLabel = focusPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
focusPercentPowerLabel:SetPoint("LEFT")
focusFrame.percentPowerLabel = focusPercentPowerLabel

---@type FontString
local focusNameLabel = focusPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
focusNameLabel:SetPoint("RIGHT")
focusFrame.nameLabel = focusNameLabel

---@type StatusBar
local focusAltPowerBar = CreateFrame("StatusBar", nil, focusFrame)
focusAltPowerBar:SetSize(focusFrame:GetWidth(), 9)
focusAltPowerBar:SetPoint("BOTTOM")
focusFrame.altPowerBar = focusAltPowerBar

focusAltPowerBar:SetScript("OnShow", function(self)
    focusPowerBar:SetHeight(max(12, (focusFrame:GetHeight() - self:GetHeight()) / 3))
    focusHealthBar:SetHeight(focusFrame:GetHeight() - focusPowerBar:GetHeight() - self:GetHeight())
end)

focusAltPowerBar:SetScript("OnHide", function()
    focusPowerBar:SetHeight(focusFrame:GetHeight() / 3)
    focusHealthBar:SetHeight(focusFrame:GetHeight() * 2 / 3)
end)

---@type FontString
local focusAltPowerLabel = focusAltPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
focusAltPowerLabel:SetPoint("CENTER")
focusFrame.altPowerLabel = focusAltPowerLabel

---@type Frame
local focusDebuffFrame = CreateFrame("Frame", nil, focusFrame)
focusDebuffFrame.type = "Debuff"
focusDebuffFrame.numAurasShown = 0
focusDebuffFrame.showAllSource = false
focusDebuffFrame.buttons = {}
focusDebuffFrame:SetSize(size * numPerLine + spacing * (numPerLine - 1), size * rows)
focusDebuffFrame:SetPoint("BOTTOMLEFT", focusFrame, "TOPLEFT", -2, 2 + 1)
focusFrame.debuffs = focusDebuffFrame

for i = 1, maxNum do
    local button = CreateAuraButton(focusDebuffFrame)
    button:SetPoint("BOTTOMLEFT", (size + spacing) * ((i - 1) % numPerLine), (ceil(i / numPerLine) - 1) * size)
    tinsert(focusDebuffFrame.buttons, button)
end

---@type Frame
local focusBuffFrame = CreateFrame("Frame", nil, focusFrame)
focusBuffFrame.type = "Buff"
focusBuffFrame.numAurasShown = 0
focusBuffFrame.showAllSource = true
focusBuffFrame.buttons = {}
focusBuffFrame:SetSize(size * numPerLine + spacing * (numPerLine - 1), size * rows)
focusBuffFrame:SetPoint("TOPLEFT", focusFrame, "BOTTOMLEFT", -2, -(2 + 1))
focusFrame.buffs = focusBuffFrame

for i = 1, maxNum do
    local button = CreateAuraButton(focusBuffFrame)
    button:SetPoint("TOPLEFT", (size + spacing) * (i - 1), (1 - ceil(i / numPerLine)) * size)
    tinsert(focusBuffFrame.buttons, button)
end

focusFrame:RegisterEvent("PLAYER_LOGIN")
focusFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
focusFrame:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "focus")

focusFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

focusFrame:RegisterEvent("RAID_TARGET_UPDATE")

focusFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "focus")

focusFrame:RegisterUnitEvent("UNIT_HEALTH", "focus")
focusFrame:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "focus")

focusFrame:RegisterUnitEvent("UNIT_CONNECTION", "focus")
focusFrame:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", "focus")
focusFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", "focus")
focusFrame:RegisterUnitEvent("UNIT_FACTION", "focus")

focusFrame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "focus")
focusFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "focus")
focusFrame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "focus")

focusFrame:RegisterUnitEvent("UNIT_MAXPOWER", "focus")

focusFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "focus")

focusFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "focus")
focusFrame:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "focus")
focusFrame:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "focus")

focusFrame:RegisterUnitEvent("UNIT_AURA", "focus")

--- 更新焦点框架
local function UpdateFocusFrame()
    UpdateHighlight(focusFrame)
    UpdateRaidTargetIcon(focusFrame)
    UpdateMaxHealth(focusFrame)
    UpdateHealth(focusFrame)
    UpdateHealthBarColor(focusFrame)
    UpdateHealPrediction(focusFrame)
    UpdatePercentHealthLabel(focusFrame)
    UpdateHealthLabel(focusFrame)
    UpdateAbsorbLabel(focusFrame)
    UpdateNameLabel(focusFrame)
    UpdateMaxPower(focusFrame)
    UpdatePower(focusFrame)
    UpdatePowerBarColor(focusFrame)
    UpdatePercentPowerLabel(focusFrame)
    UpdateAltPowerBar(focusFrame)
    UpdateAuras(focusFrame)
end

---@param self Button
focusFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        UpdateFocusFrame()
        self:UnregisterEvent(event)
    elseif event == "PLAYER_FOCUS_CHANGED" or event == "UNIT_TARGETABLE_CHANGED" then
        UpdateFocusFrame()
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateHighlight(self)
    elseif event == "RAID_TARGET_UPDATE" then
        UpdateRaidTargetIcon(self)
    elseif event == "UNIT_MAXHEALTH" then
        UpdateMaxHealth(self)
        UpdateHealth(self)
        UpdateHealPrediction(self)
        UpdatePercentHealthLabel(self)
        UpdateHealthLabel(self)
    elseif event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        UpdateHealth(self)
        UpdateHealPrediction(self)
        UpdatePercentHealthLabel(self)
        UpdateHealthLabel(self)
    elseif event == "UNIT_CONNECTION" then
        UpdateHealthBarColor(self)
        UpdatePowerBarColor(self)
    elseif event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_FACTION" then
        UpdateHealthBarColor(self)
    elseif event == "UNIT_NAME_UPDATE" then
        UpdateNameLabel(self)
        UpdateHealthBarColor(self)
    elseif event == "UNIT_HEAL_PREDICTION" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
        UpdateHealPrediction(self)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        UpdateHealPrediction(self)
        UpdateAbsorbLabel(self)
    elseif event == "UNIT_MAXPOWER" then
        local _, powerType = ...
        if powerType == "ALTERNATE" then
            UpdateAltPowerBar(self)
        else
            UpdateMaxPower(self)
            UpdatePower(self)
            UpdatePercentPowerLabel(self)
        end
    elseif event == "UNIT_POWER_UPDATE" then
        local _, powerType = ...
        if powerType == "ALTERNATE" then
            UpdateAltPowerBar(self)
        else
            UpdatePower(self)
            UpdatePercentPowerLabel(self)
        end
    elseif event == "UNIT_DISPLAYPOWER" then
        UpdateMaxPower(self)
        UpdatePower(self)
        UpdatePowerBarColor(self)
        UpdatePercentPowerLabel(self)
    elseif event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" then
        local _, powerType = ...
        if powerType == "ALTERNATE" then
            UpdateAltPowerBar(self)
        else
            UpdateMaxPower(self)
            UpdatePower(self)
            UpdatePowerBarColor(self)
            UpdatePercentPowerLabel(self)
        end
    elseif event == "UNIT_AURA" then
        UpdateAuras(self)
    end
end)

maxNum = 8
numPerLine = 8
size = 33
spacing = 1
rows = ceil(maxNum / numPerLine)

-- 更新首领框架
local function UpdateBossFrame(unitFrame)
    UpdateHighlight(unitFrame)
    UpdateRaidTargetIcon(unitFrame)
    UpdateMaxHealth(unitFrame)
    UpdateHealth(unitFrame)
    UpdateHealthBarColor(unitFrame)
    UpdateHealPrediction(unitFrame)
    UpdatePercentHealthLabel(unitFrame)
    UpdateHealthLabel(unitFrame)
    UpdateAbsorbLabel(unitFrame)
    UpdateNameLabel(unitFrame)
    UpdateMaxPower(unitFrame)
    UpdatePower(unitFrame)
    UpdatePowerBarColor(unitFrame)
    UpdatePercentPowerLabel(unitFrame)
    UpdateAltPowerBar(unitFrame)
    UpdateAuras(unitFrame)
end

--- 创建首领单位框架
local function CreateBossFrame(i)
    ---@type Button
    local bossFrame = CreateFrame("Button", "WLK_Boss" .. i .. "Frame", UIParent, "SecureUnitButtonTemplate")
    bossFrame.unit = "boss" .. i
    --- 左边界相对屏幕左边偏移 1350px
    bossFrame:SetSize(GetScreenWidth() - 1350 - 298 - 1 - 26 - 2 * 2, 36)

    bossFrame:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark", })
    bossFrame:SetAttribute("unit", "boss" .. i)
    bossFrame:SetAttribute("*type1", "target")
    bossFrame:SetAttribute("*type2", "togglemenu")
    RegisterUnitWatch(bossFrame, false)

    bossFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    bossFrame:SetScript("OnEnter", function(self)
        UnitFrame_OnEnter(self)
    end)

    bossFrame:SetScript("OnLeave", function(self)
        UnitFrame_OnLeave(self)
    end)

    bossFrame:SetScript("OnUpdate", UpdateInRange)

    CreateHighlight(bossFrame)

    ---@type Texture
    local bossRaiTargetIcon = bossFrame:CreateTexture()
    bossRaiTargetIcon:SetSize(26, 26)
    bossRaiTargetIcon:SetPoint("LEFT", bossFrame, "RIGHT", 2, 0)
    bossFrame.raidTargetIcon = bossRaiTargetIcon

    ---@type StatusBar
    local bossHealthBar = CreateFrame("StatusBar", nil, bossFrame)
    bossHealthBar:SetSize(bossFrame:GetWidth(), bossFrame:GetHeight() * 2 / 3)
    bossHealthBar:SetPoint("TOP")
    bossHealthBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill", "BORDER")
    bossFrame.healthBar = bossHealthBar

    ---@type Texture
    local bossHealthBarBackground = bossHealthBar:CreateTexture(nil, "BACKGROUND")
    bossHealthBarBackground:SetAllPoints()
    bossHealthBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-HP-Bg")
    bossHealthBarBackground:SetTexCoord(0, 1, 0, 0.53125)

    CreateHealPrediction(bossHealthBar)

    ---@type FontString
    local bossPercentHealthLabel = bossHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
    bossPercentHealthLabel:SetPoint("LEFT")
    bossFrame.percentHealthLabel = bossPercentHealthLabel

    ---@type FontString
    local bossAbsorbLabel = bossHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
    bossAbsorbLabel:SetPoint("RIGHT")
    bossFrame.absorbLabel = bossAbsorbLabel

    ---@type FontString
    local bossHealthLabel = bossHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
    bossHealthLabel:SetPoint("RIGHT", bossAbsorbLabel, "LEFT")
    bossFrame.healthLabel = bossHealthLabel

    ---@type StatusBar
    local bossPowerBar = CreateFrame("StatusBar", nil, bossFrame)
    bossPowerBar:SetSize(bossFrame:GetWidth(), bossFrame:GetHeight() / 3)
    bossPowerBar:SetPoint("TOP", bossHealthBar, "BOTTOM")
    bossPowerBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill", "BORDER")
    bossFrame.powerBar = bossPowerBar

    ---@type Texture
    local bossPowerBarBackground = bossPowerBar:CreateTexture(nil, "BACKGROUND")
    bossPowerBarBackground:SetAllPoints()
    bossPowerBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")

    ---@type FontString
    local bossPercentPowerLabel = bossPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
    bossPercentPowerLabel:SetPoint("LEFT")
    bossFrame.percentPowerLabel = bossPercentPowerLabel

    ---@type FontString
    local bossNameLabel = bossPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
    bossNameLabel:SetPoint("RIGHT")
    bossFrame.nameLabel = bossNameLabel

    ---@type StatusBar
    local bossAltPowerBar = CreateFrame("StatusBar", nil, bossFrame)
    bossAltPowerBar:SetSize(bossFrame:GetWidth(), 9)
    bossAltPowerBar:SetPoint("BOTTOM")
    bossFrame.altPowerBar = bossAltPowerBar

    ---@param self StatusBar
    bossAltPowerBar:SetScript("OnShow", function(self)
        bossPowerBar:SetHeight(max(12, (bossFrame:GetHeight() - self:GetHeight()) / 3))
        bossHealthBar:SetHeight(bossFrame:GetHeight() - bossPowerBar:GetHeight() - self:GetHeight())
    end)

    bossAltPowerBar:SetScript("OnHide", function()
        bossPowerBar:SetHeight(bossFrame:GetHeight() / 3)
        bossHealthBar:SetHeight(bossFrame:GetHeight() * 2 / 3)
    end)

    ---@type FontString
    local bossAltPowerLabel = bossAltPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
    bossAltPowerLabel:SetPoint("CENTER")
    bossFrame.altPowerLabel = bossAltPowerLabel

    ---@type Frame
    local bossDebuffFrame = CreateFrame("Frame", nil, bossFrame)
    bossDebuffFrame.type = "Debuff"
    bossDebuffFrame.numAurasShown = 0
    bossDebuffFrame.showAllSource = false
    bossDebuffFrame.buttons = {}
    bossDebuffFrame:SetSize(size * numPerLine + spacing * (numPerLine - 1), size * rows)
    bossDebuffFrame:SetPoint("BOTTOMLEFT", bossFrame, "TOPLEFT", -2, 2)
    bossFrame.debuffs = bossDebuffFrame

    for j = 1, maxNum do
        local button = CreateAuraButton(bossDebuffFrame)
        button:SetPoint("BOTTOMLEFT", (size + spacing) * ((j - 1) % numPerLine), (ceil(j / numPerLine) - 1) * size)
        tinsert(bossDebuffFrame.buttons, button)
    end

    bossFrame:RegisterEvent("PLAYER_LOGIN")
    bossFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    bossFrame:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "boss" .. i)

    bossFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

    bossFrame:RegisterEvent("RAID_TARGET_UPDATE")

    bossFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "boss" .. i)

    bossFrame:RegisterUnitEvent("UNIT_HEALTH", "boss" .. i)
    bossFrame:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "boss" .. i)

    bossFrame:RegisterUnitEvent("UNIT_CONNECTION", "boss" .. i)
    bossFrame:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", "boss" .. i)
    bossFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", "boss" .. i)
    bossFrame:RegisterUnitEvent("UNIT_FACTION", "boss" .. i)

    bossFrame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "boss" .. i)
    bossFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "boss" .. i)
    bossFrame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "boss" .. i)

    bossFrame:RegisterUnitEvent("UNIT_MAXPOWER", "boss" .. i)

    bossFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "boss" .. i)

    bossFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "boss" .. i)
    bossFrame:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "boss" .. i)
    bossFrame:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "boss" .. i)

    bossFrame:RegisterUnitEvent("UNIT_AURA", "boss" .. i)

    ---@param self Button
    bossFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" then
            UpdateBossFrame(self)
            self:UnregisterEvent(event)
        elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" or event == "UNIT_TARGETABLE_CHANGED" then
            UpdateBossFrame(self)
        elseif event == "PLAYER_TARGET_CHANGED" then
            UpdateHighlight(self)
        elseif event == "RAID_TARGET_UPDATE" then
            UpdateRaidTargetIcon(self)
        elseif event == "UNIT_MAXHEALTH" then
            UpdateMaxHealth(self)
            UpdateHealth(self)
            UpdateHealPrediction(self)
            UpdatePercentHealthLabel(self)
            UpdateHealthLabel(self)
        elseif event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
            UpdateHealth(self)
            UpdateHealPrediction(self)
            UpdatePercentHealthLabel(self)
            UpdateHealthLabel(self)
        elseif event == "UNIT_CONNECTION" then
            UpdateHealthBarColor(self)
            UpdatePowerBarColor(self)
        elseif event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_FACTION" then
            UpdateHealthBarColor(self)
        elseif event == "UNIT_NAME_UPDATE" then
            UpdateNameLabel(self)
            UpdateHealthBarColor(self)
        elseif event == "UNIT_HEAL_PREDICTION" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
            UpdateHealPrediction(self)
        elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
            UpdateHealPrediction(self)
            UpdateAbsorbLabel(self)
        elseif event == "UNIT_MAXPOWER" then
            local _, powerType = ...
            if powerType == "ALTERNATE" then
                UpdateAltPowerBar(self)
            else
                UpdateMaxPower(self)
                UpdatePower(self)
                UpdatePercentPowerLabel(self)
            end
        elseif event == "UNIT_POWER_UPDATE" then
            local _, powerType = ...
            if powerType == "ALTERNATE" then
                UpdateAltPowerBar(self)
            else
                UpdatePower(self)
                UpdatePercentPowerLabel(self)
            end
        elseif event == "UNIT_DISPLAYPOWER" then
            UpdateMaxPower(self)
            UpdatePower(self)
            UpdatePowerBarColor(self)
            UpdatePercentPowerLabel(self)
        elseif event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" then
            local _, powerType = ...
            if powerType == "ALTERNATE" then
                UpdateAltPowerBar(self)
            else
                UpdateMaxPower(self)
                UpdatePower(self)
                UpdatePowerBarColor(self)
                UpdatePercentPowerLabel(self)
            end
        elseif event == "UNIT_AURA" then
            UpdateAuras(self)
        end
    end)

    return bossFrame
end

for i = 1, MAX_BOSS_FRAMES do
    local bossFrame = CreateBossFrame(i)
    --- 下边界（包括施法条）相对屏幕底部偏移 314 + 1 = 315px，首领施法条的高度是 17px
    bossFrame:SetPoint("BOTTOMLEFT", 1350 + 2, 315 + 17 + 2 + (i - 1) * (bossFrame:GetHeight() + 2 + size + 17 + 2))
end

--- 更新解控技能
local function UpdateCrowdControl(unitFrame)
    local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unitFrame.unit)
    if spellID then
        if spellID ~= unitFrame.CC.spellID then
            local _, spellTextureNoOverride = GetSpellTexture(spellID)
            unitFrame.CC.spellID = spellID
            ---@type Texture
            local icon = unitFrame.CC.icon
            icon:SetTexture(spellTextureNoOverride)
        end
        ---@type Cooldown
        local cooldown = unitFrame.CC.cooldown
        if startTime ~= 0 and duration ~= 0 then
            cooldown:SetCooldown(startTime / 1000.0, duration / 1000.0)
        else
            cooldown:Clear()
        end
    end
end

--- 重置解控技能
local function ResetCrowdControl(unitFrame)
    unitFrame.CC.spellID = nil;
    ---@type Texture
    local icon = unitFrame.CC.icon
    icon:SetTexture(nil);
    ---@type Cooldown
    local cooldown = unitFrame.CC.cooldown
    cooldown:Clear();
    UpdateCrowdControl(unitFrame);
end

--- 隐藏竞技场单位预览框架
---@param unitFrame Button
local function HideArenaPrepFrame(unitFrame)
    if UnitGUID(unitFrame.unit) then
        local i = strmatch(unitFrame:GetName(), "(%d)")
        ---@type Frame
        local prepFrame = _G["WLK_ArenaPrepFrame" .. i]
        prepFrame:Hide()
    end
end

--- 更新 PvP 图标或专精标签
---@param unitFrame Button
local function ShowPvPIconOrSpecLabel(unitFrame)
    local _, instanceType = IsInInstance()
    -- 在竞技场显示专精标签，否则显示 PvP 图标
    if instanceType == "arena" then
        ---@type FontString
        local specLabel = unitFrame.specLabel
        local i = strmatch(unitFrame:GetName(), "(%d)")
        local specID = GetArenaOpponentSpec(i)
        if specID and specID > 0 then
            local _, name = GetSpecializationInfoByID(specID)
            specLabel:SetText(name)
        end
    else
        UpdatePvPIcon(unitFrame)
    end
end

--- 更新竞技场单位框架
local function UpdateArenaFrame(unitFrame)
    UpdateHighlight(unitFrame)
    UpdateMaxHealth(unitFrame)
    UpdateHealth(unitFrame)
    UpdateHealthBarColor(unitFrame)
    UpdateHealPrediction(unitFrame)
    UpdatePercentHealthLabel(unitFrame)
    UpdateHealthLabel(unitFrame)
    UpdateAbsorbLabel(unitFrame)
    UpdateNameLabel(unitFrame)
    UpdateMaxPower(unitFrame)
    UpdatePower(unitFrame)
    UpdatePowerBarColor(unitFrame)
    UpdatePercentPowerLabel(unitFrame)
    UpdateAuras(unitFrame)
    HideArenaPrepFrame(unitFrame)
    ShowPvPIconOrSpecLabel(unitFrame)
end

--- 创建竞技场单位框架
local function CreateArenaFrame(i)
    ---@type Button
    local arenaFrame = CreateFrame("Button", "WLK_Arena" .. i .. "Frame", UIParent, "SecureUnitButtonTemplate")
    arenaFrame.unit = "arena" .. i
    arenaFrame:SetSize(GetScreenWidth() - 1350 - 298 - 1 - 30 - 2 * 2 - 30, 36)

    arenaFrame:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark", })
    arenaFrame:SetAttribute("unit", "arena" .. i)
    arenaFrame:SetAttribute("*type1", "target")
    arenaFrame:SetAttribute("*type2", "togglemenu")
    RegisterUnitWatch(arenaFrame, false)

    arenaFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    arenaFrame:SetScript("OnEnter", function(self)
        UnitFrame_OnEnter(self)
    end)

    arenaFrame:SetScript("OnLeave", function(self)
        UnitFrame_OnLeave(self)
    end)

    arenaFrame:SetScript("OnUpdate", UpdateInRange)

    CreateHighlight(arenaFrame)

    ---@type Texture
    local arenaPvPIcon = arenaFrame:CreateTexture()
    arenaPvPIcon:SetSize(30, 30)
    arenaPvPIcon:SetPoint("LEFT", arenaFrame, "RIGHT", 2, 0)
    arenaFrame.pvpIcon = arenaPvPIcon

    ---@type FontString
    local arenaSpecLabel = arenaFrame:CreateFontString(nil, "ARTWORK", "Game12Font_o1")
    arenaSpecLabel:SetWidth(30)
    arenaSpecLabel:SetPoint("LEFT", arenaFrame, "RIGHT", 2, 0)
    arenaSpecLabel:SetJustifyH("LEFT")
    arenaFrame.specLabel = arenaSpecLabel

    ---@type StatusBar
    local arenaHealthBar = CreateFrame("StatusBar", nil, arenaFrame)
    arenaHealthBar:SetSize(arenaFrame:GetWidth(), arenaFrame:GetHeight() * 2 / 3)
    arenaHealthBar:SetPoint("TOP")
    arenaHealthBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill", "BORDER")
    arenaFrame.healthBar = arenaHealthBar

    ---@type Texture
    local arenaHealthBarBackground = arenaHealthBar:CreateTexture(nil, "BACKGROUND")
    arenaHealthBarBackground:SetAllPoints()
    arenaHealthBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-HP-Bg")
    arenaHealthBarBackground:SetTexCoord(0, 1, 0, 0.53125)

    CreateHealPrediction(arenaHealthBar)

    ---@type FontString
    local arenaPercentHealthLabel = arenaHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
    arenaPercentHealthLabel:SetPoint("LEFT")
    arenaFrame.percentHealthLabel = arenaPercentHealthLabel

    ---@type FontString
    local arenaAbsorbLabel = arenaHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
    arenaAbsorbLabel:SetPoint("RIGHT")
    arenaFrame.absorbLabel = arenaAbsorbLabel

    ---@type FontString
    local arenaHealthLabel = arenaHealthBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
    arenaHealthLabel:SetPoint("RIGHT", arenaAbsorbLabel, "LEFT")
    arenaFrame.healthLabel = arenaHealthLabel

    ---@type StatusBar
    local arenaPowerBar = CreateFrame("StatusBar", nil, arenaFrame)
    arenaPowerBar:SetSize(arenaFrame:GetWidth(), arenaFrame:GetHeight() / 3)
    arenaPowerBar:SetPoint("TOP", arenaHealthBar, "BOTTOM")
    arenaPowerBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill", "BORDER")
    arenaFrame.powerBar = arenaPowerBar

    ---@type Texture
    local arenaPowerBarBackground = arenaPowerBar:CreateTexture(nil, "BACKGROUND")
    arenaPowerBarBackground:SetAllPoints()
    arenaPowerBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")

    ---@type FontString
    local arenaPercentPowerLabel = arenaPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
    arenaPercentPowerLabel:SetPoint("LEFT")
    arenaFrame.percentPowerLabel = arenaPercentPowerLabel

    ---@type FontString
    local arenaNameLabel = arenaPowerBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
    arenaNameLabel:SetPoint("RIGHT")
    arenaFrame.nameLabel = arenaNameLabel

    ---@type Frame
    local arenaDebuffFrame = CreateFrame("Frame", nil, arenaFrame)
    arenaDebuffFrame.type = "Debuff"
    arenaDebuffFrame.numAurasShown = 0
    arenaDebuffFrame.showAllSource = false
    arenaDebuffFrame.buttons = {}
    arenaDebuffFrame:SetSize(size * numPerLine + spacing * (numPerLine - 1), size * rows)
    arenaDebuffFrame:SetPoint("BOTTOMLEFT", arenaFrame, "TOPLEFT", -2 - 30, 2)
    arenaFrame.debuffs = arenaDebuffFrame

    for j = 1, maxNum do
        local button = CreateAuraButton(arenaDebuffFrame)
        button:SetPoint("BOTTOMLEFT", (size + spacing) * ((j - 1) % numPerLine), (ceil(j / numPerLine) - 1) * size)
        tinsert(arenaDebuffFrame.buttons, button)
    end

    ---@type Frame
    local arenaCCFrame = CreateFrame("Frame", nil, arenaFrame)
    arenaCCFrame:SetSize(30, 30)
    arenaCCFrame:SetPoint("RIGHT", arenaFrame, "LEFT", -2, 0)
    arenaFrame.CC = arenaCCFrame
    ---@type Texture
    local arenaCCIcon = arenaCCFrame:CreateTexture()
    arenaCCIcon:SetAllPoints()
    arenaFrame.CC.icon = arenaCCIcon
    ---@type Cooldown
    local arenaCCCooldown = CreateFrame("Cooldown", nil, arenaCCFrame, "CooldownFrameTemplate")
    arenaCCCooldown:SetAllPoints()
    arenaFrame.CC.cooldown = arenaCCCooldown
    ResetCrowdControl(arenaFrame)

    arenaFrame:RegisterEvent("PLAYER_LOGIN")
    arenaFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
    arenaFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", "arena" .. i)

    arenaFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

    arenaFrame:RegisterUnitEvent("UNIT_FACTION", "arena" .. i)

    arenaFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "arena" .. i)

    arenaFrame:RegisterUnitEvent("UNIT_HEALTH", "arena" .. i)
    arenaFrame:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "arena" .. i)

    arenaFrame:RegisterUnitEvent("UNIT_CONNECTION", "arena" .. i)
    arenaFrame:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", "arena" .. i)

    arenaFrame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "arena" .. i)
    arenaFrame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "arena" .. i)
    arenaFrame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "arena" .. i)

    arenaFrame:RegisterUnitEvent("UNIT_MAXPOWER", "arena" .. i)

    arenaFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "arena" .. i)

    arenaFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "arena" .. i)
    arenaFrame:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "arena" .. i)
    arenaFrame:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "arena" .. i)

    arenaFrame:RegisterUnitEvent("UNIT_AURA", "arena" .. i)

    arenaFrame:RegisterUnitEvent("ARENA_COOLDOWNS_UPDATE", "arena" .. i)
    arenaFrame:RegisterUnitEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE", "arena" .. i)

    ---@param self Button
    arenaFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" then
            UpdateArenaFrame(self)
            ResetCrowdControl(self)
            self:UnregisterEvent(event)
        elseif event == "ARENA_OPPONENT_UPDATE" or event == "UNIT_NAME_UPDATE" then
            UpdateArenaFrame(self)
        elseif event == "PLAYER_TARGET_CHANGED" then
            UpdateHighlight(self)
        elseif event == "UNIT_FACTION" then
            UpdateHealthBarColor(self)
        elseif event == "UNIT_MAXHEALTH" then
            UpdateMaxHealth(self)
            UpdateHealth(self)
            UpdateHealPrediction(self)
            UpdatePercentHealthLabel(self)
            UpdateHealthLabel(self)
        elseif event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
            UpdateHealth(self)
            UpdateHealPrediction(self)
            UpdatePercentHealthLabel(self)
            UpdateHealthLabel(self)
        elseif event == "UNIT_CONNECTION" then
            UpdateHealthBarColor(self)
            UpdatePowerBarColor(self)
        elseif event == "UNIT_THREAT_LIST_UPDATE" then
            UpdateHealthBarColor(self)
        elseif event == "UNIT_HEAL_PREDICTION" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
            UpdateHealPrediction(self)
        elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
            UpdateHealPrediction(self)
            UpdateAbsorbLabel(self)
        elseif event == "UNIT_MAXPOWER" then
            UpdateMaxPower(self)
            UpdatePower(self)
            UpdatePercentPowerLabel(self)
        elseif event == "UNIT_POWER_UPDATE" then
            UpdatePower(self)
            UpdatePercentPowerLabel(self)
        elseif event == "UNIT_DISPLAYPOWER" then
            UpdateMaxPower(self)
            UpdatePower(self)
            UpdatePowerBarColor(self)
            UpdatePercentPowerLabel(self)
        elseif event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" then
            UpdateMaxPower(self)
            UpdatePower(self)
            UpdatePowerBarColor(self)
            UpdatePercentPowerLabel(self)
        elseif event == "UNIT_AURA" then
            UpdateAuras(self)
        elseif event == "ARENA_COOLDOWNS_UPDATE" then
            UpdateCrowdControl(self)
        elseif event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" then
            local _, spellID = ...
            if spellID ~= self.CC.spellID then
                local _, spellTextureNoOverride = GetSpellTexture(spellID)
                self.CC.spellID = spellID
                self.CC.icon:SetTexture(spellTextureNoOverride)
            end
        end
    end)

    return arenaFrame
end

for i = 1, MAX_ARENA_ENEMIES do
    local arenaFrame = CreateArenaFrame(i)
    arenaFrame:SetPoint("BOTTOMLEFT", 1350 + 2 + 30, 315 + 17 + 2 + (arenaFrame:GetHeight() + 2 + size + 17 + 2)
            * (i - 1))
end

local prepFrameHeight = 36
for i = 1, MAX_ARENA_ENEMIES do
    ---@type Frame
    local arenaPrepFrame = CreateFrame("Frame", "WLK_ArenaPrepFrame" .. i, UIParent)
    arenaPrepFrame:SetSize(GetScreenWidth() - 1350 - 298 - 1 - 30 - prepFrameHeight, prepFrameHeight)
    arenaPrepFrame:SetPoint("BOTTOMLEFT", 1350, 315 + 17 + 2 + (prepFrameHeight + 2 + size + 17 + 2) * (i - 1))
    arenaPrepFrame:SetBackdrop({ bgFile = "Interface/RaidFrame/Raid-Bar-Hp-Fill", })
    arenaPrepFrame:Hide()
    ---@type Texture
    local classIcon = arenaPrepFrame:CreateTexture()
    classIcon:SetSize(prepFrameHeight, prepFrameHeight)
    classIcon:SetPoint("LEFT", arenaPrepFrame, "RIGHT")
    arenaPrepFrame.classIcon = classIcon
    ---@type Texture
    local specIcon = arenaPrepFrame:CreateTexture()
    specIcon:SetSize(30, 30)
    specIcon:SetPoint("LEFT", classIcon, "RIGHT")
    arenaPrepFrame.specIcon = specIcon
    ---@type FontString
    local specLabel = arenaPrepFrame:CreateFontString(nil, "ARTWORK", "Game15Font_o1")
    specLabel:SetPoint("CENTER")
    arenaPrepFrame.specLabel = specLabel
end

--- 更新竞技场单位预览框架
local function UpdateArenaPrepFrames()
    local numOpps = GetNumArenaOpponentSpecs()
    for i = 1, MAX_ARENA_ENEMIES do
        ---@type Frame
        local prepFrame = _G["WLK_ArenaPrepFrame" .. i]
        if i <= numOpps then
            local specID, gender = GetArenaOpponentSpec(i)
            if specID > 0 then
                local _, name, _, icon, _, class = GetSpecializationInfoByID(specID, gender)
                if class then
                    ---@type Texture
                    local classIcon = prepFrame.classIcon
                    classIcon:SetTexture("Interface/TargetingFrame/UI-Classes-Circles")
                    classIcon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
                    local r, g, b = GetClassColor(class)
                    prepFrame:SetBackdropColor(r, g, b)
                end
                ---@type Texture
                local specIcon = prepFrame.specIcon
                specIcon:SetTexture(icon)
                ---@type FontString
                local specLabel = prepFrame.specLabel
                specLabel:SetText(name)
                prepFrame:Show()
            else
                prepFrame:Hide()
            end
        else
            prepFrame:Hide()
        end
    end
end

local addonName = ...
---@type Frame
local eventListener = CreateFrame("Frame")

eventListener:RegisterEvent("ADDON_LOADED")
eventListener:RegisterEvent("PLAYER_ENTERING_WORLD")
eventListener:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")

---@param self Frame
eventListener:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        -- 将光环过滤器保存在文件中
        if not WLK_UnitAuraFilter then
            WLK_UnitAuraFilter = {
                ["blacklist"] = {
                    ["Buff"] = {},
                    ["Debuff"] = {},
                },
                ["whitelist"] = {
                    ["Buff"] = {
                        -- 嗜血術
                        ["2825"] = true,
                        -- 英勇氣概
                        ["32182"] = true,
                        -- 時間扭曲
                        ["80353"] = true,
                        -- 靈風
                        ["160452"] = true,
                        -- 上古狂亂
                        ["90355"] = true,
                        -- 野性之怒
                        ["264667"] = true,
                        -- 狂怒之鼓
                        ["178207"] = true,
                    },
                    ["Debuff"] = {},
                },
            }
        end
        self:UnregisterEvent(event)
    elseif event == "PLAYER_ENTERING_WORLD" then
        local numOpps = GetNumArenaOpponentSpecs()
        if numOpps and numOpps > 0 then
            UpdateArenaPrepFrames()
        end
    elseif event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        UpdateArenaPrepFrames()
    end
end)
