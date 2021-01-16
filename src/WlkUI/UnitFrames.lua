local MAX_ARENA_FRAMES = 5
local TEXTURE_NUMBERS_INDEX = 6
local TEXTURE_FILL_INDEX = 3
local padding = 1
local borderSize = 2
local castBarHeight = 25
local auraSize1 = 29
local auraSize2 = 27
local auraSpacing = 3
local height1 = 42
local height2 = 54
local height3 = 18
local castingBarHeight = 32
local castingBarWidth = 330 - castingBarHeight
local bossSpacing1 = castBarHeight + borderSize * 2 + height3 + borderSize
local bossSpacing2 = height1 + borderSize + 2 + auraSize1 + 2
local arenaSpacing1 = bossSpacing1 - height3
local arenaSpacing2 = bossSpacing2
local defaultEvents = { "PLAYER_ENTERING_WORLD", "PORTRAITS_UPDATED", "UNIT_FACTION", }
local defaultUnitEvents = {
    "UNIT_NAME_UPDATE", "UNIT_LEVEL", "UNIT_PORTRAIT_UPDATE", "UNIT_MAXHEALTH", "UNIT_HEALTH", "UNIT_HEAL_PREDICTION",
    "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "UNIT_CONNECTION", "UNIT_THREAT_LIST_UPDATE",
}
local defaultUpdateFunctions
local playerFrame
local classSpells = {
    WARRIOR = { 355, },
    HUNTER = { 56641, 34477, 136, },
    MAGE = { 116, 130, },
    ROGUE = { 6770, 57934, },
    PRIEST = { 585, 2061, },
    WARLOCK = { 686, 20707, 755, },
    PALADIN = { 20271, 19750, },
    DRUID = { 5176, 8936, },
    SHAMAN = { 188196, 8004, },
    MONK = { 117952, 116670, },
    DEMONHUNTER = { 185245, },
    DEATHKNIGHT = { 49576, 61999, },
}
local rangeSpells = classSpells[select(2, UnitClass("player"))]
local playerConfig = {
    name = "WlkPlayerFrame",
    width = 273,
    height = height2,
    position = { "BOTTOMRIGHT", UIParent, "BOTTOM", -120, 154, },
    unit = "player",
    unit2 = "vehicle",
    events = {},
    classification = 1,
    raidTarget = 1,
    faction = 1,
    status = true,
    pvpTime = true,
    leader = 1,
    role = 1,
    group = true,
    altPower = { 198, "TOPRIGHT", "BOTTOMRIGHT", -66, 0, },
}
local petConfig = {
    name = "WlkPetFrame",
    width = 207,
    height = height1,
    position = { "BOTTOMRIGHT", UIParent, "BOTTOM", -192, 94, },
    unit = "pet",
    unit2 = "player",
    events = { { "UNIT_PET", "player", true, }, },
    power = true,
    classification = 1,
    raidTarget = 1,
    range = true,
}
local targetConfig = {
    name = "WlkTargetFrame",
    width = 273,
    height = height2,
    position = { "BOTTOMLEFT", UIParent, "BOTTOM", 120, 154, },
    unit = "target",
    events = { { "PLAYER_TARGET_CHANGED", nil, true }, },
    totConfig = {
        name = "WlkTotFrame",
        width = 207,
        height = height1,
        position = { "BOTTOMLEFT", UIParent, "BOTTOM", 192, 94, },
        unit = "targettarget",
        events = { { "UNIT_TARGET", "target", true, }, },
        power = true,
        classification = 2,
        raidTarget = 2,
        range = true,
    },
    power = true,
    classification = 2,
    raidTarget = 2,
    faction = 2,
    quest = true,
    petType = true,
    threat = { "TOPLEFT", "BOTTOMLEFT", 24, 0, },
    leader = 2,
    role = 2,
    group = true,
    altPower = { 198, "TOPLEFT", "BOTTOMLEFT", 66, 0, },
    buff = { auraSize2, 32, 8, "BOTTOMLEFT", "TOPRIGHT", height2 / 2, -25, },
    debuff = { auraSize2, 16, 8, "BOTTOMLEFT", "TOPLEFT", 61, 3, },
    range = true,
    castBar = { 267, "BOTTOMLEFT", "TOPLEFT", 29, 65, "PLAYER_TARGET_CHANGED", },
}
local focusConfig = {
    name = "WlkFocusFrame",
    width = 216,
    height = height1,
    position = { "BOTTOMLEFT", UIParent, "BOTTOM", 423, 79, },
    unit = "focus",
    events = { { "PLAYER_FOCUS_CHANGED", nil, true, }, },
    power = true,
    classification = 2,
    raidTarget = 2,
    threat = { "TOPLEFT", "BOTTOMLEFT", -2, -31, },
    group = true,
    altPower = { 199, "TOPLEFT", "BOTTOMLEFT", 40, -31, },
    buff = { auraSize2, 8, 8, "TOPLEFT", "BOTTOMLEFT", 0, -3, },
    debuff = { auraSize2, 8, 8, "BOTTOMLEFT", "TOPLEFT", 0, 5, },
    highlight = true,
    range = true,
    castBar = { 212, "TOPLEFT", "BOTTOMLEFT", 25, -52, "PLAYER_FOCUS_CHANGED", },
}

---@type Frame
local unitFrameParent = CreateFrame("Frame", "WlkUnitFrameParent", UIParent, "SecureHandlerStateTemplate")

---@param unitFrame WlkUnitFrame
local function updateName(unitFrame)
    unitFrame.nameLabel:SetText(GetUnitName(unitFrame.unit))
end

---@param unitFrame WlkUnitFrame
local function updateLevel(unitFrame)
    local unit = unitFrame.unit
    local level
    if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
        level = UnitBattlePetLevel(unit)
    else
        level = UnitEffectiveLevel(unit)
        level = level > 0 and level or "??"
    end
    unitFrame.levelLabel:SetText(level)
end

---@param unitFrame WlkUnitFrame
local function updateRace(unitFrame)
    local unit = unitFrame.unit
    local race
    if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
        race = _G["BATTLE_PET_NAME_" .. UnitBattlePetType(unit)]
    else
        race = UnitIsPlayer(unit) and UnitRace(unit) or UnitCreatureFamily(unit) or UnitCreatureType(unit)
    end
    unitFrame.raceLabel:SetText(race)
end

---@param unitFrame WlkUnitFrame
local function updatePortrait(unitFrame)
    local unit = unitFrame.unit
    if UnitIsConnected(unit) and UnitIsVisible(unit) then
        unitFrame.portrait:SetUnit(unit)
    else
        unitFrame.portrait:ClearModel()
    end
end

local function abbreviateNumber(value)
    if value >= 1e8 then
        return format("%.2f%s", value / 1e8, SECOND_NUMBER_CAP)
    elseif value >= 1e6 then
        return format("%.0f%s", value / 1e4, FIRST_NUMBER_CAP)
    elseif value >= 1e4 then
        return format("%.1f%s", value / 1e4, FIRST_NUMBER_CAP)
    end
    return value
end

---@param unitFrame WlkUnitFrame
local function updateHealthAbsorbLabel(unitFrame)
    local absorb = UnitGetTotalAbsorbs(unitFrame.unit)
    unitFrame.healthAbsorbLabel:SetText(absorb and absorb > 0 and ("+" .. abbreviateNumber(absorb)) or "")
end

---@param unitFrame WlkUnitFrame
local function updateHealthLabels(unitFrame)
    local unit = unitFrame.unit
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    unitFrame.healthLabel:SetFormattedText("%s/%s", abbreviateNumber(health), abbreviateNumber(maxHealth))
    unitFrame.healthPercentLabel:SetText(FormatPercentage(PercentageBetween(health, 0, maxHealth)))
end

local function updateHealth(unitFrame)
    PixelUtil.SetStatusBarValue(unitFrame.healthbar, UnitHealth(unitFrame.unit))
    updateHealthLabels(unitFrame)
end

---@param unitFrame WlkUnitFrame
local function updateMaxHealth(unitFrame)
    unitFrame.healthbar:SetMinMaxValues(0, UnitHealthMax(unitFrame.unit))
    updateHealthLabels(unitFrame)
    UnitFrameHealPredictionBars_Update(unitFrame)
end

local function unitExists(unit)
    return UnitExists(unit) or ShowBossFrameWhenUninteractable(unit)
end

---@param unitFrame WlkUnitFrame
local function updateHealthColor(unitFrame)
    local unit = unitFrame.unit
    if unitExists(unit) then
        local healthBar = unitFrame.healthbar
        local r, g, b
        if not UnitIsConnected(unit) then
            r, g, b = 0.5, 0.5, 0.5
        elseif unitFrame.unit == "vehicle" then
            r, g, b = 0, 0.5, 0.5
        else
            if UnitIsPlayer(unit) then
                r, g, b = GetClassColor(select(2, UnitClass(unit)))
            elseif not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
                r, g, b = 0.9, 0.9, 0.9
            elseif CompactUnitFrame_IsOnThreatListWithPlayer(unit) then
                r, g, b = 1, 0, 0
            elseif UnitIsPlayer(unit) and UnitIsFriend("player", unit) then
                r, g, b = 0.667, 0.667, 1
            else
                r, g, b = UnitSelectionColor(unit, true)
            end
        end
        healthBar:SetStatusBarColor(r, g, b)
    end
end

---@param unitFrame WlkUnitFrame
local function updatePowerLabels(unitFrame)
    local unit = unitFrame.unit
    local power = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    unitFrame.powerLabel:SetFormattedText("%s/%s", abbreviateNumber(power), abbreviateNumber(maxPower))
    unitFrame.powerPercentLabel:SetText(FormatPercentage(PercentageBetween(power, 0, maxPower)))
end

---@param unitFrame WlkUnitFrame
local function updatePower(unitFrame)
    if unitFrame.powerBar then
        PixelUtil.SetStatusBarValue(unitFrame.powerBar, UnitPower(unitFrame.unit))
        updatePowerLabels(unitFrame)
    end
end

---@param unitFrame WlkUnitFrame
local function updateMaxPower(unitFrame)
    if unitFrame.powerBar then
        local maxPower = UnitPowerMax(unitFrame.unit)
        if maxPower > 0 then
            unitFrame.powerBar:SetMinMaxValues(0, maxPower)
            updatePowerLabels(unitFrame)
            if not unitFrame.powerBar:IsShown() then
                unitFrame.powerBar:Show()
                unitFrame.healthbar:SetPoint("BOTTOMRIGHT", 0, unitFrame.powerBar:GetHeight())
            end
        else
            if unitFrame.powerBar:IsShown() then
                unitFrame.powerBar:Hide()
                unitFrame.healthbar:SetPoint("BOTTOMRIGHT")
            end
        end
    end
end

---@param unitFrame WlkUnitFrame
local function updatePowerColor(unitFrame)
    if unitFrame.powerBar then
        local r, g, b
        local unit = unitFrame.unit
        if not UnitIsConnected(unit) then
            r, g, b = 0.5, 0.5, 0.5
        else
            local powerType, powerToken, altR, altG, altB = UnitPowerType(unit)
            local info = PowerBarColor[powerToken]
            if info then
                r, g, b = info.r, info.g, info.b
            else
                if not altR then
                    info = PowerBarColor[powerType] or PowerBarColor["MANA"]
                    r, g, b = info.r, info.g, info.b
                else
                    r, g, b = altR, altG, altB
                end
            end
        end
        unitFrame.powerBar:SetStatusBarColor(r, g, b)
    end
end

---@param unitFrame WlkUnitFrame
local function updateClassification(unitFrame)
    local icon = unitFrame.classificationIndicator
    if icon then
        if CompactUnitFrame_UpdatePvPClassificationIndicator(unitFrame) then
            return
        end
        local classification = UnitClassification(unitFrame.unit)
        if classification == "elite" or classification == "worldboss" then
            icon:SetAtlas("nameplates-icon-elite-gold")
            icon:Show()
        elseif classification == "rareelite" or classification == "rare" then
            icon:SetAtlas("nameplates-icon-elite-silver")
            icon:Show()
        else
            icon:Hide()
        end
    end
end

---@param unitFrame WlkUnitFrame
local function updateFaction(unitFrame)
    if unitFrame.pvpIcon then
        local unit = unitFrame.unit
        local factionGroup = UnitFactionGroup(unit)
        if UnitIsPVPFreeForAll(unit) then
            local honorRewardInfo = C_PvP.GetHonorRewardInfo(UnitHonorLevel(unit))
            if honorRewardInfo then
                unitFrame.prestigePortrait:SetAtlas("honorsystem-portrait-neutral")
                unitFrame.prestigeBadge:SetTexture(honorRewardInfo.badgeFileDataID)
                unitFrame.prestigePortrait:Show()
                unitFrame.prestigeBadge:Show()
                unitFrame.pvpIcon:Hide()
            else
                unitFrame.prestigePortrait:Hide()
                unitFrame.prestigeBadge:Hide()
                unitFrame.pvpIcon:SetTexture("Interface/TargetingFrame/UI-PVP-FFA")
                unitFrame.pvpIcon:Show()
            end
            if unitFrame.pvpTimeLabel then
                unitFrame.pvpTimeLabel:Hide()
                unitFrame.pvpTimeLabel.timeLeft = nil
            end
        elseif factionGroup and factionGroup ~= "Neutral" and UnitIsPVP(unit) then
            local honorRewardInfo = C_PvP.GetHonorRewardInfo(UnitHonorLevel(unit))
            if honorRewardInfo then
                unitFrame.prestigePortrait:SetAtlas("honorsystem-portrait-" .. factionGroup)
                unitFrame.prestigeBadge:SetTexture(honorRewardInfo.badgeFileDataID)
                unitFrame.prestigePortrait:Show()
                unitFrame.prestigeBadge:Show()
                unitFrame.pvpIcon:Hide()
            else
                unitFrame.prestigePortrait:Hide()
                unitFrame.prestigeBadge:Hide()
                unitFrame.pvpIcon:SetTexture("Interface/TargetingFrame/UI-PVP-" .. factionGroup)
                unitFrame.pvpIcon:Show()
            end
        else
            unitFrame.prestigePortrait:Hide()
            unitFrame.prestigeBadge:Hide()
            unitFrame.pvpIcon:Hide()
            if unitFrame.pvpTimeLabel then
                unitFrame.pvpTimeLabel:Hide()
                unitFrame.pvpTimeLabel.timeLeft = nil
            end
        end
    end
end

---@param unitFrame WlkUnitFrame
local function updateStatus(unitFrame)
    local icon = unitFrame.statusIcon
    local unit = unitFrame.unit
    if icon and (unit == "player" or unit == "vehicle") then
        if IsResting() then
            icon:SetTexCoord(0, 0.5, 0, 0.421875)
            icon:Show()
        elseif UnitAffectingCombat("player") then
            icon:SetTexCoord(0.5, 1, 0, 0.484375)
            icon:Show()
        else
            icon:Hide()
        end
    end
end

---@param unitFrame WlkUnitFrame
local function updateQuest(unitFrame)
    local icon = unitFrame.questIcon
    if icon then
        if UnitIsQuestBoss(unitFrame.unit) then
            icon:Show()
        else
            icon:Hide()
        end
    end
end

---@param unitFrame WlkUnitFrame
local function updatePetType(unitFrame)
    local icon = unitFrame.petTypeIcon
    if icon then
        local unit = unitFrame.unit
        if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
            local petType = UnitBattlePetType(unit)
            icon:SetTexture("Interface/TargetingFrame/PetBadge-" .. PET_TYPE_SUFFIX[petType])
            icon:Show()
        else
            icon:Hide()
        end
    end
end

---@param unitFrame WlkUnitFrame
local function updatePvpTimer(unitFrame)
    local label = unitFrame.pvpTimeLabel
    if label then
        if IsPVPTimerRunning() then
            C_Timer.After(1, function()
                label:Show()
            end)
            label.timeLeft = GetPVPTimer()
        else
            label:Hide()
            label.timeLeft = nil
        end
    end
end

---@param self WlkUnitFrame
local function updatePvpTime(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 1 then
        return
    end
    self.elapsed = 0

    local label = self.pvpTimeLabel
    if label.timeLeft then
        label.timeLeft = label.timeLeft - 1 * 1000
        if label.timeLeft < 0 then
            label:Hide()
        end
        label:SetFormattedText(SecondsToTimeAbbrev(floor(label.timeLeft / 1000)))
    else
        label:Hide()
    end
end

---@param unitFrame WlkUnitFrame
local function updateThreat(unitFrame)
    local label = unitFrame.threatLabel
    if label then
        local unit = unitFrame.unit
        local _, status, _, rawPercent = UnitDetailedThreatSituation("player", unit)
        if status then
            label:SetFormattedText("%1.0f%%", rawPercent)
            label:SetTextColor(GetThreatStatusColor(status))
            label:Show()
        else
            label:Hide()
        end
    end
end

---@param unitFrame WlkUnitFrame
local function updateLeader(unitFrame)
    local icon = unitFrame.leaderIcon
    if icon then
        local unit = unitFrame.unit
        if UnitLeadsAnyGroup(unit) then
            if HasLFGRestrictions() then
                icon:SetTexture("Interface/LFGFrame/UI-LFG-ICON-PORTRAITROLES")
                icon:SetTexCoord(0, 0.296875, 0.015625, 0.3125)
            else
                icon:SetTexture("Interface/GroupFrame/UI-Group-LeaderIcon")
                icon:SetTexCoord(0, 1, 0, 1)
            end
            icon:Show()
        elseif UnitIsGroupAssistant(unit) then
            icon:SetTexture("Interface/GroupFrame/UI-Group-AssistantIcon")
            icon:SetTexCoord(0, 1, 0, 1)
            icon:Show()
        else
            icon:Hide()
        end
    end
end

---@param unitFrame WlkUnitFrame
local function updateRole(unitFrame)
    local icon = unitFrame.roleIcon
    if icon then
        local unit = unitFrame.unit
        local raidId = UnitInRaid(unit)
        local role = raidId and select(10, GetRaidRosterInfo(raidId))
        if role then
            icon:SetTexture("Interface/GroupFrame/UI-Group-" .. role .. "Icon")
            icon:SetTexCoord(0, 1, 0, 1)
            icon:Show()
        else
            role = UnitGroupRolesAssigned(unit)
            if role == "TANK" or role == "HEALER" or role == "DAMAGER" then
                icon:SetTexture("Interface/LFGFrame/UI-LFG-ICON-PORTRAITROLES")
                icon:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
                icon:Show()
            else
                icon:Hide()
            end
        end
    end
end

---@param unitFrame WlkUnitFrame
local function updateGroup(unitFrame)
    local label = unitFrame.groupLabel
    if label then
        local unit = unitFrame.unit
        local raidId = UnitInRaid(unit)
        if raidId then
            local _, _, group = GetRaidRosterInfo(raidId)
            label:SetFormattedText("[%d]", group)
            label:Show()
        else
            label:Hide()
        end
    end
end

---@param bar WlkUnitAltPowerBar
local function updateAltPower(bar)
    local label = bar.label
    local currentPower = UnitPower(bar.unit, ALTERNATE_POWER_INDEX)
    bar:SetValue(currentPower)
    local minValue, maxValue = bar:GetMinMaxValues()
    label:SetFormattedText("%s/%s(%s)", abbreviateNumber(currentPower), abbreviateNumber(maxValue), FormatPercentage(
            PercentageBetween(currentPower, minValue, maxValue)))
end

---@param bar WlkUnitAltPowerBar
local function updateMaxAltPower(bar)
    local unit = bar.unit
    local info = GetUnitPowerBarInfo(unit)
    local minPower = info and info.minPower or 0
    local maxPower = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)
    bar:SetMinMaxValues(minPower, maxPower)
    updateAltPower(bar)
end

local function altPowerBarOnEvent(self, event, ...)
    local _, arg2 = ...
    if event == "UNIT_MAXPOWER" and arg2 == "ALTERNATE" then
        updateMaxAltPower(self)
    elseif event == "UNIT_POWER_UPDATE" and arg2 == "ALTERNATE" then
        updateAltPower(self)
    end
end

---@param unitFrame WlkUnitFrame
local function updateAltPowerBar(unitFrame)
    local bar = unitFrame.altPowerBar
    if bar then
        local unit = bar.unit
        local info = GetUnitPowerBarInfo(unit)
        if info then
            bar:RegisterUnitEvent("UNIT_POWER_UPDATE", unit)
            bar:RegisterUnitEvent("UNIT_MAXPOWER", unit)
            local _, r, g, b = GetUnitPowerBarTextureInfo(unit, info.barType == ALT_POWER_TYPE_COUNTER
                    and TEXTURE_NUMBERS_INDEX or TEXTURE_FILL_INDEX)
            bar:SetStatusBarColor(r, g, b)
            updateMaxAltPower(bar)
            bar:Show()
        else
            bar:Hide()
            bar:UnregisterEvent("UNIT_POWER_UPDATE")
            bar:UnregisterEvent("UNIT_MAXPOWER")
        end
    end
end

local function createAuraFrame(unitFrame, ...)
    local buttonSize, maxButtons, buttonsPerRow, point, relativePoint, xOffset, yOffset = ...
    local width = (buttonSize + auraSpacing) * buttonsPerRow - auraSpacing
    local height = (buttonSize + auraSpacing) * ceil(maxButtons / buttonsPerRow) - auraSpacing
    ---@class WlkUnitAuraFrame:Frame
    local frame = CreateFrame("Frame", nil, unitFrame)

    frame:SetSize(width, height)
    frame:SetPoint(point, unitFrame, relativePoint, xOffset, yOffset)

    frame.buttonSize = buttonSize
    frame.maxButtons = maxButtons
    frame.buttonsPerRow = buttonsPerRow

    return frame
end

local function updateAuraButtonsLayout(auraFrame)
    ---@type Button[]
    local buttons = auraFrame.Buff or auraFrame.Debuff
    for i, button in ipairs(buttons) do
        if not button:IsShown() then
            break
        end
        local xOffset = (auraFrame.buttonSize + auraSpacing) * ((i - 1) % auraFrame.buttonsPerRow)
        local yOffset = (auraFrame.buttonSize + auraSpacing) * floor((i - 1) / auraFrame.buttonsPerRow)
        button:SetPoint("BOTTOMLEFT", xOffset, yOffset)
    end
end

---@param auraFrame WlkUnitAuraFrame
local function createAuraButton(auraFrame, index)
    local size = auraFrame.buttonSize
    ---@type Button
    local unitFrame = auraFrame:GetParent()
    local name = unitFrame:GetName()
    ---@type TargetBuffFrameTemplate|TargetDebuffFrameTemplate
    local button = CreateFrame("Button", name .. auraFrame.auraType .. index, auraFrame, auraFrame.buttonTemplate)

    button:SetSize(size, size)
    if button.Stealable then
        button.Stealable:SetSize(size + 3, size + 3)
    end
    button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.Count:ClearAllPoints()
    button.Count:SetPoint("BOTTOMRIGHT", 3, 0)
    button.Count:SetFontObject("Game12Font_o1")

    return button
end

local function updateBuffs(unitFrame)
    local buffFrame = unitFrame.buffFrame
    if buffFrame then
        local unit = unitFrame.unit
        local index = 0
        local unitIsPlayer = UnitIsUnit(unit, playerFrame.unit)
        local id = 1
        local maxBuffs = buffFrame.maxButtons
        AuraUtil.ForEachAura(unit, "HELPFUL", maxBuffs, function(...)
            local _, icon, count, _, duration, expirationTime, _, canStealOrPurge = ...
            if icon then
                index = index + 1
                ---@class WlkUnitBuffButton:TargetBuffFrameTemplate
                local button = buffFrame.Buff and buffFrame.Buff[index]
                if not button then
                    button = createAuraButton(buffFrame, index)
                    button.unit = unit
                end

                button:SetID(id)
                button.Icon:SetTexture(icon)
                if count > 1 then
                    button.Count:SetText(count)
                    button.Count:Show()
                else
                    button.Count:Hide()
                end
                CooldownFrame_Set(button.Cooldown, expirationTime - duration, duration, duration > 0, true)
                button.Stealable:SetShown(not unitIsPlayer and canStealOrPurge)
                button:ClearAllPoints()
                button:Show()
            end
            id = id + 1
            return index >= maxBuffs
        end)
        if buffFrame.Buff then
            for i = index + 1, maxBuffs do
                ---@type Button
                local button = buffFrame.Buff[i]
                if button then
                    button:Hide()
                else
                    break
                end
            end
            updateAuraButtonsLayout(buffFrame)
        end
    end
end

local function updateDebuffs(unitFrame)
    local debuffFrame = unitFrame.debuffFrame
    if debuffFrame then
        local unit = unitFrame.unit
        local index = 0
        local maxDebuffs = debuffFrame.maxButtons
        local id = 1
        AuraUtil.ForEachAura(unit, "HARMFUL|INCLUDE_NAME_PLATE_ONLY", maxDebuffs, function(...)
            local _, icon, count, debuffType, duration, expirationTime, caster, _, _, _, _, _, casterIsPlayer,
            nameplateShowAll = ...
            if icon and TargetFrame_ShouldShowDebuffs(unit, caster, nameplateShowAll, casterIsPlayer) then
                index = index + 1
                ---@class WlkUnitDebuffButton:TargetDebuffFrameTemplate
                local button = debuffFrame.Debuff and debuffFrame.Debuff[index]
                if not button then
                    button = createAuraButton(debuffFrame, index)
                    button.unit = unit
                end

                button:SetID(id)
                button.Icon:SetTexture(icon)
                if count > 1 then
                    button.Count:SetText(count)
                    button.Count:Show()
                else
                    button.Count:Hide()
                end
                CooldownFrame_Set(button.Cooldown, expirationTime - duration, duration, duration > 0, true)
                local color = DebuffTypeColor[debuffType or "none"]
                button.Border:SetVertexColor(GetTableColor(color))
                button:ClearAllPoints()
                button:Show()
            end
            id = id + 1
            return index >= maxDebuffs
        end)
        if debuffFrame.Debuff then
            for i = index + 1, maxDebuffs do
                ---@type Button
                local button = debuffFrame.Debuff[i]
                if button then
                    button:Hide()
                else
                    break
                end
            end
            updateAuraButtonsLayout(debuffFrame)
        end
    end
end

---@param frame WlkUnitFrame|WlkCastBar
---@param color ColorMixin
local function createBorder(frame, color, isCastBar)
    local r, g, b = color:GetRGB()
    local width, height = frame:GetSize()
    local borderWidth = width + borderSize + (isCastBar and height or 0)
    local borderHeight = height + borderSize
    local xOffset = isCastBar and -height or 0

    local top = frame:CreateTexture()
    local bottom = frame:CreateTexture()
    local left = frame:CreateTexture()
    local right = frame:CreateTexture()

    top:SetSize(borderWidth, borderSize)
    top:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", xOffset, 0)
    top:SetColorTexture(r, g, b)

    bottom:SetSize(borderWidth, borderSize)
    bottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT")
    bottom:SetColorTexture(r, g, b)

    left:SetSize(borderSize, borderHeight)
    left:SetPoint("TOPLEFT", frame, "TOPRIGHT")
    left:SetColorTexture(r, g, b)

    right:SetSize(borderSize, borderHeight)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", xOffset, 0)
    right:SetColorTexture(r, g, b)

    frame.borderTop = top
    frame.borderBottom = bottom
    frame.borderLeft = left
    frame.borderRight = right
end

---@param frame WlkUnitFrame|WlkCastBar
local function showBorder(frame)
    frame.borderTop:Show()
    frame.borderBottom:Show()
    frame.borderLeft:Show()
    frame.borderRight:Show()
end

---@param frame WlkUnitFrame|WlkCastBar
local function hideBorder(frame)
    frame.borderTop:Hide()
    frame.borderBottom:Hide()
    frame.borderLeft:Hide()
    frame.borderRight:Hide()
end

---@param unitFrame WlkUnitFrame
local function updateHighlight(unitFrame)
    if unitFrame.highlight then
        if UnitIsUnit(unitFrame.unit, "target") then
            showBorder(unitFrame)
        else
            hideBorder(unitFrame)
        end
    end
end

---@param self WlkUnitFrame
local function updateRange(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.2 then
        return
    end
    self.elapsed = 0

    local unit = self.unit
    local index = unit == "pet" and 3 or UnitCanAttack("player", unit) and 1 or UnitCanAssist("player", unit) and 2
    local spellId = rangeSpells[index]
    local spellName = spellId and GetSpellInfo(spellId)
    if spellName and IsSpellKnown(spellId) then
        self:SetAlpha(IsSpellInRange(spellName, unit) == 1 and 1 or 0.55)
    else
        self:SetAlpha(CheckInteractDistance(unit, 1) and 1 or 0.55)
    end
end

---@param frame WlkUnitCCFrame
local function updateCrowdControlIcon(frame, spellId)
    if spellId ~= frame.spellId then
        local _, spellTextureNoOverride = GetSpellTexture(spellId)
        frame.spellId = spellId
        frame.icon:SetTexture(spellTextureNoOverride)
    end
end

---@param frame WlkUnitCCFrame
local function updateCrowdControl(frame)
    local spellId, startTime, duration = C_PvP.GetArenaCrowdControlInfo(frame.unit)
    if spellId then
        updateCrowdControlIcon(frame, spellId)
        if startTime ~= 0 and duration ~= 0 then
            frame.cooldown:SetCooldown(startTime / 1000, duration / 1000)
        else
            frame.cooldown:Clear()
        end
    end
end

---@param frame WlkUnitCCFrame
local function resetCrowdControl(frame)
    frame.spellId = nil
    frame.icon:SetTexture(nil)
    frame.cooldown:Clear()
    updateCrowdControl(frame)
end

---@param self WlkUnitCCFrame
local function crowdControlFrameOnEvent(self, event, ...)
    local arg1, arg2 = ...
    if event == "ARENA_COOLDOWNS_UPDATE" and arg1 == self.unit then
        updateCrowdControl(self)
    elseif event == "ARENA_CROWD_CONTROL_SPELL_UPDATE" and arg1 == self.unit then
        updateCrowdControlIcon(self, arg2)
    elseif event == "PLAYER_ENTERING_WORLD" then
        resetCrowdControl(self)
    end
end

---@param unitFrame WlkUnitFrame
local function updateArenaIndicator(unitFrame)
    if unitFrame.arenaIndicator then
        local unit = unitFrame.unit
        local _, instanceType = IsInInstance()
        if instanceType == "arena" then
            local id = tonumber(strmatch(unit, "(%d)"))
            local specId = GetArenaOpponentSpec(id)
            if specId and specId > 0 then
                local _, specName = GetSpecializationInfoByID(specId)
                unitFrame.arenaSpecLabel:SetText(specName)
            end
        else
            local faction = UnitFactionGroup(unit)
            if faction and faction ~= "Neutral" and UnitIsPVP(unit) then
                unitFrame.arenaPvpIcon:SetTexture("Interface/TargetingFrame/UI-PVP-" .. faction)
                unitFrame.arenaPvpIcon:Show()
            else
                unitFrame.arenaPvpIcon:Hide()
            end
        end
    end
end

---@param self WlkArenaPrepFrame
local function arenaPrepFrameOnEvent(self, event)
    if event == "PLAYER_ENTERING_WORLD" or event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        local numOpps = GetNumArenaOpponentSpecs()
        if numOpps and numOpps > 0 and self.id <= numOpps then
            local specId, gender = GetArenaOpponentSpec(self.id)
            if specId > 0 then
                local _, name, _, icon, _, class = GetSpecializationInfoByID(specId, gender)
                if class then
                    self.classIcon:SetTexture("Interface/Glues/CharacterCreate/UI-CharacterCreate-Classes")
                    local l, r, t, b = unpack(CLASS_ICON_TCOORDS[class])
                    local adj = 0.02
                    self.classIcon:SetTexCoord(l + adj, r - adj, t + adj, b - adj)
                    self:SetBackdropColor(GetClassColor(class))
                end
                self.specIcon:SetTexture(icon)
                self.specIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                self.specLabel:SetText(name)
                self:Show()
            end
        end
    end
end

---@param self WlkUnitFrame
local function hideArenaPrepFrame(self)
    self.prepFrame:Hide()
end

---@param self Texture
local function hookBorderShieldShow(self)
    showBorder(self:GetParent())
end

---@param self Texture
local function hookBorderShieldHide(self)
    hideBorder(self:GetParent())
end

local function formatTime(seconds)
    if seconds < 10 then
        return format("%.1f", seconds)
    elseif seconds < SECONDS_PER_MIN then
        return format("%d", seconds)
    end
    return SecondsToClock(seconds)
end

---@param self WlkCastBar
local function castBarOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.05 then
        return
    end
    self.elapsed = 0

    if self.casting then
        self.timeLabel:SetFormattedText("%s/%s", formatTime(self.maxValue - self.value), formatTime(self.maxValue))
    elseif self.channeling then
        self.timeLabel:SetFormattedText("%s/%s", formatTime(self.value), formatTime(self.maxValue))
    end
end

---@param bar WlkCastBar
local function setCastBar(bar, border)
    local width, height = bar:GetSize()
    local label = bar:CreateFontString(nil, "ARTWORK", "NumberFont_Shadow_Small")

    bar.Border:Hide()
    bar.Flash:SetTexture(nil)
    bar.Spark:SetTexture(nil)
    bar.BorderShield:SetTexture(nil)
    bar.Text:ClearAllPoints()
    bar.Text:SetPoint("LEFT", 5, 0)
    bar.Text:SetJustifyH("LEFT")
    bar.Text:SetWidth(width * 2 / 3)
    bar.Text:SetFontObject("NumberFont_Shadow_Small")
    bar.Icon:SetSize(height, height)
    bar.Icon:SetPoint("RIGHT", bar, "LEFT")
    bar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    bar.Icon:Show()

    bar:SetStatusBarTexture("Interface/Tooltips/UI-Tooltip-Background")
    bar:HookScript("OnUpdate", castBarOnUpdate)

    label:SetPoint("RIGHT")

    bar.timeLabel = label

    if border then
        createBorder(bar, HIGHLIGHT_FONT_COLOR, true)

        hooksecurefunc(bar.BorderShield, "Show", hookBorderShieldShow)
        hooksecurefunc(bar.BorderShield, "Hide", hookBorderShieldHide)
    end
end

local function castBarOnEvent(self, event, ...)
    local arg1 = ...
    if event == self.updateEvent then
        local nameChannel = UnitChannelInfo(self.unit)
        local nameSpell = UnitCastingInfo(self.unit)
        if nameChannel then
            event = "UNIT_SPELLCAST_CHANNEL_START"
            arg1 = self.unit
        elseif nameSpell then
            event = "UNIT_SPELLCAST_START"
            arg1 = self.unit
        else
            self.casting = nil
            self.channeling = nil
            self:SetMinMaxValues(0, 0)
            self:SetValue(0)
            self:Hide()
            return
        end
    end
    CastingBarFrame_OnEvent(self, event, arg1, select(2, ...))
end

local function switchUnit(unitFrame)
    unitFrame.switched = not unitFrame.switched
    local temp = unitFrame.unit
    unitFrame.unit = unitFrame.unit2
    unitFrame.unit2 = temp
    FrameUtil.RegisterFrameForUnitEvents(unitFrame, unitFrame.unitEvents, unitFrame.unit)
end

local function updateUnitFrame(unitFrame)
    for _, func in ipairs(unitFrame.updateFunctions) do
        func(unitFrame)
    end
    if unitFrame.totFrame and unitExists(unitFrame.totFrame.unit) then
        updatePortrait(unitFrame.totFrame)
        updateUnitFrame(unitFrame.totFrame)
    end
end

local function totFrameOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.5 then
        return
    end
    self.elapsed = 0

    updateUnitFrame(self)
end

local function unitFrameOnEvent(self, event, ...)
    if unitExists(self.unit) or ((event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITING_VEHICLE")
            and self.unit2) then
        local arg1 = ...
        if event == self.updateEvent or event == "PLAYER_ENTERING_WORLD" or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT"
                or (event == "ARENA_OPPONENT_UPDATE" and arg1 == self.unit) then
            if strmatch(self.unit, "^%a+target$") then
                updatePortrait(self)
            end
            updateUnitFrame(self)
        elseif event == "UNIT_ENTERED_VEHICLE" then
            if UnitInVehicle("player") and UnitHasVehicleUI("player") and self.unit2 and not self.switched then
                switchUnit(self)
                updateUnitFrame(self)
            else
                updateHealthColor(self)
            end
        elseif event == "UNIT_EXITING_VEHICLE" then
            if self.switched then
                switchUnit(self)
                updateUnitFrame(self)
            else
                updateHealthColor(self)
            end
        elseif event == "UNIT_NAME_UPDATE" then
            updateName(self)
            updateRace(self)
        elseif event == "UNIT_LEVEL" then
            updateLevel(self)
        elseif event == "UNIT_PORTRAIT_UPDATE" or event == "PORTRAITS_UPDATED" then
            updatePortrait(self)
        elseif event == "UNIT_MAXHEALTH" then
            updateMaxHealth(self)
            updateHealth(self)
            UnitFrameHealPredictionBars_Update(self)
        elseif event == "UNIT_HEALTH" then
            updateHealth(self)
            UnitFrameHealPredictionBars_Update(self)
        elseif (event == "UNIT_FACTION" and (arg1 == self.unit or arg1 == "player")) or event == "UNIT_CONNECTION"
                or event == "UNIT_THREAT_LIST_UPDATE" then
            updateHealthColor(self)
        elseif event == "UNIT_HEAL_PREDICTION" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
            UnitFrameHealPredictionBars_Update(self)
        elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
            updateHealthAbsorbLabel(self)
            UnitFrameHealPredictionBars_Update(self)
        end

        if event == "UNIT_MAXPOWER" then
            updateMaxPower(self)
            updatePower(self)
        elseif event == "UNIT_POWER_FREQUENT" then
            updatePower(self)
        elseif event == "UNIT_DISPLAYPOWER" or event == "UNIT_CONNECTION" then
            updatePowerColor(self)
        end

        if event == "UNIT_CLASSIFICATION_CHANGED" then
            updateClassification(self)
        end

        if event == "RAID_TARGET_UPDATE" then
            TargetFrame_UpdateRaidTargetIcon(self)
        end

        if event == "UNIT_FACTION" and arg1 == self.unit or event == "HONOR_LEVEL_UPDATE" then
            updateFaction(self)
        end

        if event == "PLAYER_ENTER_COMBAT" or event == "PLAYER_LEAVE_COMBAT" or event == "PLAYER_REGEN_DISABLED"
                or event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_UPDATE_RESTING" then
            updateStatus(self)
        end

        if event == "UNIT_CLASSIFICATION_CHANGED" then
            updateQuest(self)
        end

        if event == "PVP_TIMER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
            updatePvpTimer(self)
        end

        if event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then
            updateThreat(self)
        end

        if event == "GROUP_ROSTER_UPDATE" then
            updateLeader(self)
        end

        if event == "GROUP_ROSTER_UPDATE" then
            updateRole(self)
        end

        if event == "GROUP_ROSTER_UPDATE" then
            updateGroup(self)
        end

        if event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" then
            updateAltPowerBar(self)
        end

        if event == "UNIT_AURA" then
            updateBuffs(self)
        end

        if event == "UNIT_AURA" then
            updateDebuffs(self)
        end

        if event == "PLAYER_TARGET_CHANGED" then
            updateHighlight(self)
        end
    end
end

local function createUnitFrame(config)
    local prefix = strsub(config.name, 1, -6)

    ---@class WlkUnitFrame:Button
    local unitFrame = CreateFrame("Button", config.name, unitFrameParent, "SecureUnitButtonTemplate")
    ---@type StatusBar
    local healthBar = CreateFrame("StatusBar", nil, unitFrame)
    local healthBackground = healthBar:CreateTexture(prefix .. "HealthBackground", "BACKGROUND")
    local myHealPredictionBar = healthBar:CreateTexture(prefix .. "MyHealPrediction", "BORDER", nil, 1)
    local otherHealPredictionBar = healthBar:CreateTexture(prefix .. "OtherHealPrediction", "BORDER", nil, 1)
    local totalAbsorbBar = healthBar:CreateTexture(prefix .. "TotalAbsorb", "BORDER", nil, 1)
    local totalAbsorbBarOverlay = healthBar:CreateTexture(prefix .. "TotalAbsorbOverlay", "BORDER", nil, 2)
    local healAbsorbBar = healthBar:CreateTexture(prefix .. "HealAbsorb", "ARTWORK", nil, 1)
    local healAbsorbBarLeftShadow = healthBar:CreateTexture(prefix .. "HealAbsorbLeftShadow", "ARTWORK", nil, 1)
    local healAbsorbBarRightShadow = healthBar:CreateTexture(prefix .. "HealAbsorbRightShadow", "ARTWORK", nil, 1)
    local overAbsorbGlow = healthBar:CreateTexture(prefix .. "OverAbsorbGlow", "ARTWORK", nil, 2)
    local overHealAbsorbGlow = healthBar:CreateTexture(prefix .. "OverHealAbsorbGlow", "ARTWORK", nil, 2)
    local nameLabel = healthBar:CreateFontString(prefix .. "NameLabel", "ARTWORK", "NumberFont_Shadow_Small")
    local levelLabel = healthBar:CreateFontString(prefix .. "LevelLabel", "ARTWORK", "NumberFont_Shadow_Small")
    local raceLabel = healthBar:CreateFontString(prefix .. "RaceLabel", "ARTWORK", "NumberFont_Shadow_Small")
    local healthLabel = healthBar:CreateFontString(prefix .. "HealthLabel", "ARTWORK", "NumberFont_Shadow_Small")
    local healthPercentLabel = healthBar:CreateFontString(prefix .. "HealthPercentLabel", "ARTWORK",
            "NumberFont_Shadow_Small")
    local healthAbsorbLabel = healthBar:CreateFontString(prefix .. "HealthAbsorbLabel", "ARTWORK",
            "NumberFont_Shadow_Small")
    ---@type PlayerModel
    local portrait = CreateFrame("PlayerModel", nil, unitFrame)

    RegisterUnitWatch(unitFrame)
    unitFrame:SetSize(config.width, config.height)
    unitFrame:SetPoint(unpack(config.position))
    if config.frameLevel then
        unitFrame:SetFrameLevel(config.frameLevel)
    end
    unitFrame:SetAttribute("unit", config.unit)
    if config.unit2 then
        unitFrame:SetAttribute("toggleForVehicle", true)
    end
    unitFrame:SetAttribute("*type1", "target")
    unitFrame:SetAttribute("*type2", "togglemenu")
    unitFrame:SetAttribute("shift-type1", "focus")
    unitFrame:SetScript("OnEnter", UnitFrame_OnEnter)
    unitFrame:SetScript("OnLeave", UnitFrame_OnLeave)
    unitFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    FrameUtil.RegisterFrameForEvents(unitFrame, defaultEvents)
    FrameUtil.RegisterFrameForUnitEvents(unitFrame, defaultUnitEvents, config.unit)
    unitFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    unitFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
    for _, event in ipairs(config.events) do
        local eventName, eventUnit, isUpdateEvent = unpack(event)
        if eventUnit then
            unitFrame:RegisterUnitEvent(eventName, eventUnit)
        else
            unitFrame:RegisterEvent(eventName)
        end
        if isUpdateEvent then
            unitFrame.updateEvent = eventName
        end
    end
    unitFrame:SetScript("OnEvent", unitFrameOnEvent)

    healthBar:SetPoint("TOPLEFT")
    healthBar:SetPoint("BOTTOMRIGHT")
    healthBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill", "BORDER")

    healthBackground:SetAllPoints()
    healthBackground:SetTexture("Interface/RaidFrame/Raid-Bar-Hp-Bg")
    healthBackground:SetTexCoord(0, 1, 0, 0.53125)

    myHealPredictionBar:SetColorTexture(1, 1, 1)
    myHealPredictionBar:SetGradient("VERTICAL", 8 / 255, 93 / 255, 72 / 255, 11 / 255, 136 / 255, 105 / 255)

    otherHealPredictionBar:SetColorTexture(1, 1, 1)
    otherHealPredictionBar:SetGradient("VERTICAL", 3 / 255, 72 / 255, 5 / 255, 2 / 255, 101 / 255, 18 / 255)

    totalAbsorbBar:SetTexture("Interface/RaidFrame/Shield-Fill")

    totalAbsorbBarOverlay:SetAllPoints(totalAbsorbBar)
    totalAbsorbBarOverlay:SetTexture("Interface/RaidFrame/Shield-Overlay", true, true)

    healAbsorbBar:SetTexture("Interface/RaidFrame/Absorb-Fill", true, true)

    healAbsorbBarLeftShadow:SetTexture("Interface/RaidFrame/Absorb-Edge")

    healAbsorbBarRightShadow:SetTexture("Interface/RaidFrame/Absorb-Edge")
    healAbsorbBarRightShadow:SetTexCoord(1, 0, 0, 1)

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

    nameLabel:SetPoint("TOPLEFT", padding, -padding)

    levelLabel:SetPoint("TOPRIGHT", -padding, -padding)

    raceLabel:SetPoint("RIGHT", levelLabel, "LEFT", -1, 0)

    healthLabel:SetPoint("BOTTOMLEFT", padding, padding)

    healthAbsorbLabel:SetPoint("LEFT", healthLabel, "RIGHT", 1, 0)

    healthPercentLabel:SetPoint("BOTTOMRIGHT", -padding, padding)

    portrait:SetAllPoints()
    portrait:SetPortraitZoom(1)
    portrait:SetCamDistanceScale(3)
    portrait:SetAlpha(0.55)

    unitFrame.unit = config.unit
    unitFrame.unit2 = config.unit2
    unitFrame.updateFunctions = CopyTable(defaultUpdateFunctions)
    unitFrame.unitEvents = config.unit2 and CopyTable(defaultUnitEvents)
    unitFrame.healthbar = healthBar
    unitFrame.healthBackground = healthBackground
    unitFrame.myHealPredictionBar = myHealPredictionBar
    unitFrame.otherHealPredictionBar = otherHealPredictionBar
    unitFrame.totalAbsorbBar = totalAbsorbBar
    unitFrame.totalAbsorbBarOverlay = totalAbsorbBarOverlay
    unitFrame.healAbsorbBar = healAbsorbBar
    unitFrame.healAbsorbBarLeftShadow = healAbsorbBarLeftShadow
    unitFrame.healAbsorbBarRightShadow = healAbsorbBarRightShadow
    unitFrame.overAbsorbGlow = overAbsorbGlow
    unitFrame.overHealAbsorbGlow = overHealAbsorbGlow
    unitFrame.nameLabel = nameLabel
    unitFrame.levelLabel = levelLabel
    unitFrame.raceLabel = raceLabel
    unitFrame.healthLabel = healthLabel
    unitFrame.healthAbsorbLabel = healthAbsorbLabel
    unitFrame.healthPercentLabel = healthPercentLabel
    unitFrame.portrait = portrait
    if config.totConfig then
        unitFrame.totFrame = createUnitFrame(config.totConfig)
        unitFrame.totFrame:UnregisterAllEvents()
        unitFrame.totFrame:RegisterEvent("PORTRAITS_UPDATED")
        unitFrame.totFrame:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", config.totConfig.unit)
        for _, event in ipairs(config.totConfig.events) do
            local eventName, eventUnit, isUpdateEvent = unpack(event)
            if isUpdateEvent then
                if eventUnit then
                    unitFrame.totFrame:RegisterUnitEvent(eventName, eventUnit)
                else
                    unitFrame.totFrame:RegisterEvent(eventName)
                end
                break
            end
        end
        tDeleteItem(unitFrame.totFrame.updateFunctions, updatePortrait)
        unitFrame.totFrame:SetScript("OnUpdate", totFrameOnUpdate)
    end

    totalAbsorbBar.overlay = totalAbsorbBarOverlay

    totalAbsorbBarOverlay.tileSize = 32

    if config.power then
        local unitEvents = { "UNIT_MAXPOWER", "UNIT_POWER_FREQUENT", "UNIT_DISPLAYPOWER", "UNIT_CONNECTION", }
        local updateFunctions = { updateMaxPower, updatePower, updatePowerColor, }

        ---@type StatusBar
        local bar = CreateFrame("StatusBar", nil, unitFrame)
        local background = bar:CreateTexture(prefix .. "PowerBackground", "BACKGROUND")
        local label = bar:CreateFontString(prefix .. "PowerLabel", "ARTWORK", "NumberFont_Shadow_Small")
        local percentLabel = bar:CreateFontString(prefix .. "PowerPercentLabel", "ARTWORK", "NumberFont_Shadow_Small")

        healthBar:SetPoint("BOTTOMRIGHT", 0, config.height / 3)

        bar:SetPoint("TOPLEFT", 0, -config.height * 2 / 3)
        bar:SetPoint("BOTTOMRIGHT")
        bar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill")

        background:SetAllPoints()
        background:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")

        label:SetPoint("LEFT", padding, 0)

        percentLabel:SetPoint("RIGHT", -padding, 0)

        FrameUtil.RegisterFrameForUnitEvents(unitFrame, unitEvents, config.unit)

        if unitFrame.unitEvents then
            tAppendAll(unitFrame.unitEvents, unitEvents)
        end
        tAppendAll(unitFrame.updateFunctions, updateFunctions)
        unitFrame.powerBar = bar
        unitFrame.powerLabel = label
        unitFrame.powerPercentLabel = percentLabel
    end

    if config.classification then
        local size = config.height / 2
        local xOffset = config.highlight and borderSize or 0
        local position = {
            [1] = { "TOPRIGHT", unitFrame, "TOPLEFT", xOffset, 0, },
            [2] = { "TOPLEFT", unitFrame, "TOPRIGHT", xOffset, 0, },
        }
        local icon = unitFrame:CreateTexture()

        icon:SetSize(size, size)
        icon:SetPoint(unpack(position[config.classification]))

        unitFrame:RegisterUnitEvent("UNIT_CLASSIFICATION_CHANGED", config.unit)

        if unitFrame.unitEvents then
            tinsert(unitFrame.unitEvents, "UNIT_CLASSIFICATION_CHANGED")
        end
        tinsert(unitFrame.updateFunctions, updateClassification)
        unitFrame.classificationIndicator = icon
    end

    if config.raidTarget then
        local size = config.height / 2
        local xOffset = config.highlight and borderSize or 0
        local position = {
            [1] = { "BOTTOMRIGHT", unitFrame, "BOTTOMLEFT", xOffset, 0 },
            [2] = { "BOTTOMLEFT", unitFrame, "BOTTOMRIGHT", xOffset, 0 },
        }
        local icon = unitFrame:CreateTexture()

        icon:SetSize(size, size)
        icon:SetPoint(unpack(position[config.raidTarget]))
        icon:SetTexture("Interface/TargetingFrame/UI-RaidTargetingIcons")

        unitFrame:RegisterEvent("RAID_TARGET_UPDATE")

        tinsert(unitFrame.updateFunctions, TargetFrame_UpdateRaidTargetIcon)
        unitFrame.raidTargetIcon = icon
    end

    if config.faction then
        local position = {
            [1] = { "LEFT", unitFrame, "RIGHT", },
            [2] = { "RIGHT", unitFrame, "LEFT", },
        }
        local prestigePortrait = unitFrame:CreateTexture(nil, "BORDER")
        local prestigeBadge = unitFrame:CreateTexture()
        local pvpIcon = unitFrame:CreateTexture()

        prestigePortrait:SetSize(50, 52)
        prestigePortrait:SetPoint(unpack(position[config.faction]))

        prestigeBadge:SetSize(30, 30)
        prestigeBadge:SetPoint("CENTER", prestigePortrait)

        pvpIcon:SetSize(42, 42)
        pvpIcon:SetPoint(unpack(position[config.faction]))
        pvpIcon:SetTexCoord(0, 0.65625, 0, 0.65625)

        unitFrame:RegisterEvent("UNIT_FACTION")
        if unitFrame.unit == "player" then
            unitFrame:RegisterEvent("HONOR_LEVEL_UPDATE")
        end

        tinsert(unitFrame.updateFunctions, updateFaction)
        unitFrame.prestigePortrait = prestigePortrait
        unitFrame.prestigeBadge = prestigeBadge
        unitFrame.pvpIcon = pvpIcon
    end

    if config.status then
        local events = {
            "PLAYER_ENTER_COMBAT", "PLAYER_LEAVE_COMBAT", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
            "PLAYER_UPDATE_RESTING",
        }
        local icon = unitFrame:CreateTexture()

        icon:SetSize(24, 24)
        icon:SetPoint("TOPRIGHT", unitFrame, "BOTTOMRIGHT")
        icon:SetTexture("Interface/CharacterFrame/UI-StateIcon")

        FrameUtil.RegisterFrameForEvents(unitFrame, events)

        tinsert(unitFrame.updateFunctions, updateStatus)
        unitFrame.statusIcon = icon
    end

    if config.quest then
        local icon = unitFrame:CreateTexture()

        icon:SetSize(24, 24)
        icon:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT")
        icon:SetTexture("Interface/TargetingFrame/PortraitQuestBadge")

        unitFrame:RegisterUnitEvent("UNIT_CLASSIFICATION_CHANGED", config.unit)

        tinsert(unitFrame.updateFunctions, updateQuest)
        unitFrame.questIcon = icon
    end

    if config.petType then
        local icon = unitFrame:CreateTexture()

        icon:SetSize(24, 24)
        icon:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT")

        tinsert(unitFrame.updateFunctions, updatePetType)
        unitFrame.petTypeIcon = icon
    end

    if config.pvpTime then
        local label = unitFrame:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med3")

        label:SetSize(42, height3)
        label:SetPoint("TOPRIGHT", unitFrame, "BOTTOMRIGHT", -24, 0)
        label:SetTextColor(1, 0.8, 0)

        unitFrame:RegisterUnitEvent("PVP_TIMER_UPDATE", "player")
        unitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        unitFrame:HookScript("OnUpdate", updatePvpTime)

        unitFrame.pvpTimeLabel = label
    end

    if config.threat then
        local point, relativePoint, x, y = unpack(config.threat)
        local label = unitFrame:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med3")

        label:SetSize(42, height3)
        label:SetPoint(point, unitFrame, relativePoint, x, y)

        unitFrame:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", config.unit)
        unitFrame:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", config.unit)

        tinsert(unitFrame.updateFunctions, updateThreat)
        unitFrame.threatLabel = label
    end

    if config.leader then
        local position = {
            [1] = { "TOPLEFT", unitFrame, "BOTTOMLEFT", -config.height / 2, 0, },
            [2] = { "TOPRIGHT", unitFrame, "BOTTOMRIGHT", config.height / 2, 0, },
        }
        local icon = unitFrame:CreateTexture()

        icon:SetSize(height3, height3)
        icon:SetPoint(unpack(position[config.leader]))

        unitFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

        tinsert(unitFrame.updateFunctions, updateLeader)
        unitFrame.leaderIcon = icon
    end

    if config.role then
        local position = {
            [1] = { "TOPLEFT", unitFrame, "BOTTOMLEFT", -config.height / 2 + height3, 0, },
            [2] = { "TOPRIGHT", unitFrame, "BOTTOMRIGHT", config.height / 2 - height3, 0, },
        }
        local icon = unitFrame:CreateTexture()

        icon:SetSize(height3, height3)
        icon:SetPoint(unpack(position[config.role]))

        unitFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

        tinsert(unitFrame.updateFunctions, updateRole)
        unitFrame.roleIcon = icon
    end

    if config.group then
        local label = healthBar:CreateFontString(prefix .. "GroupLabel", "ARTWORK", "NumberFont_Shadow_Small")

        label:SetPoint("LEFT", nameLabel, "RIGHT", padding, 0)

        unitFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

        tinsert(unitFrame.updateFunctions, updateGroup)
        unitFrame.groupLabel = label
    end

    if config.altPower then
        local width, point, relativePoint, xOffset, yOffset = unpack(config.altPower)

        ---@class WlkUnitAltPowerBar:StatusBar
        local bar = CreateFrame("StatusBar", nil, unitFrame)
        local background = bar:CreateTexture(nil, "BACKGROUND")
        local label = bar:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med3")

        bar:SetSize(width, height3)
        bar:SetPoint(point, unitFrame, relativePoint, xOffset, yOffset)
        bar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill")
        bar:SetScript("OnEnter", UnitPowerBarAlt_OnEnter)
        bar:SetScript("OnLeave", GameTooltip_Hide)
        bar:SetScript("OnEvent", altPowerBarOnEvent)

        background:SetAllPoints()
        background:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")

        label:SetPoint("CENTER")

        unitFrame:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", config.unit)
        unitFrame:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", config.unit)

        bar.unit = config.unit
        bar.statusFrame = {}
        bar.background = background
        bar.label = label

        tinsert(unitFrame.updateFunctions, updateAltPowerBar)
        unitFrame.altPowerBar = bar
    end

    if config.buff then
        local frame = createAuraFrame(unitFrame, unpack(config.buff))

        unitFrame:RegisterUnitEvent("UNIT_AURA", config.unit)

        tinsert(unitFrame.updateFunctions, updateBuffs)
        unitFrame.buffFrame = frame

        frame.auraType = "Buff"
        frame.buttonTemplate = "TargetBuffFrameTemplate"
    end

    if config.debuff then
        local frame = createAuraFrame(unitFrame, unpack(config.debuff))

        unitFrame:RegisterUnitEvent("UNIT_AURA", config.unit)

        tinsert(unitFrame.updateFunctions, updateDebuffs)
        unitFrame.debuffFrame = frame

        frame.auraType = "Debuff"
        frame.buttonTemplate = "TargetDebuffFrameTemplate"
    end

    if config.highlight then
        createBorder(unitFrame, YELLOW_FONT_COLOR)

        unitFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

        tinsert(unitFrame.updateFunctions, updateHighlight)
        unitFrame.highlight = true
    end

    if config.range then
        unitFrame:HookScript("OnUpdate", updateRange)
    end

    if config.cc then
        ---@class WlkUnitCCFrame:Frame
        local frame = CreateFrame("Frame", nil, unitFrame)
        local icon = frame:CreateTexture()
        ---@type Cooldown
        local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")

        frame:SetSize(36, 36)
        frame:SetPoint("RIGHT", unitFrame, "LEFT", -borderSize, 0)

        icon:SetAllPoints()

        frame:RegisterUnitEvent("ARENA_COOLDOWNS_UPDATE", config.unit)
        frame:RegisterUnitEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE", config.unit)
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:SetScript("OnEvent", crowdControlFrameOnEvent)

        frame.unit = config.unit
        frame.icon = icon
        frame.cooldown = cooldown

        unitFrame.ccFrame = frame
    end

    if config.arena then
        local icon = unitFrame:CreateTexture()
        local label = unitFrame:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med1")

        icon:SetSize(36, 36)
        icon:SetPoint("LEFT", unitFrame, "RIGHT", borderSize, 0)
        icon:SetTexCoord(0, 0.65625, 0, 0.65625)

        label:SetSize(36, 36)
        label:SetPoint("LEFT", unitFrame, "RIGHT", borderSize, 0)
        label:SetJustifyV("MIDDLE")
        label:SetJustifyH("CENTER")

        tinsert(unitFrame.updateFunctions, updateArenaIndicator)
        unitFrame.arenaIndicator = true
        unitFrame.arenaPvpIcon = icon
        unitFrame.arenaSpecLabel = label
    end

    if config.prep then
        local yOffset = config.position[5]
        ---@class WlkArenaPrepFrame:Frame
        local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        local classIcon = frame:CreateTexture()
        local specIcon = frame:CreateTexture()
        local specLabel = frame:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Huge1")

        frame:Hide()
        frame:SetSize(298, height1)
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 364, yOffset)
        frame:SetBackdrop({ bgFile = "Interface/RaidFrame/Raid-Bar-Hp-Fill", })

        classIcon:SetSize(height1, height1)
        classIcon:SetPoint("LEFT")

        specIcon:SetSize(height1, height1)
        specIcon:SetPoint("RIGHT")

        specLabel:SetPoint("CENTER")

        frame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:SetScript("OnEvent", arenaPrepFrameOnEvent)

        unitFrame:HookScript("OnShow", hideArenaPrepFrame)

        frame.id = tonumber(strmatch(config.unit, "(%d)"))
        frame.classIcon = classIcon
        frame.specIcon = specIcon
        frame.specLabel = specLabel

        unitFrame.prepFrame = frame
    end

    if config.castBar then
        local width, point, relativePoint, xOffset, yOffset, event = unpack(config.castBar)
        ---@class WlkCastBar:CastingBarFrameTemplate
        local bar = CreateFrame("StatusBar", nil, unitFrame, "CastingBarFrameTemplate")
        bar:Hide()

        bar:SetSize(width, castBarHeight)
        bar:SetPoint(point, unitFrame, relativePoint, xOffset, yOffset)
        bar:RegisterEvent(event)
        bar:SetScript("OnEvent", castBarOnEvent)

        CastingBarFrame_SetUnit(bar, config.unit, true, true)
        setCastBar(bar, true)

        bar.updateEvent = event

        unitFrame.castBar = bar
    end

    return unitFrame
end

---@param frame Button
local function hideFrame(frame)
    frame:Hide()
    frame:UnregisterAllEvents()
end

defaultUpdateFunctions = {
    updateName, updateLevel, updateRace, updatePortrait, updateMaxHealth, updateHealth, updateHealthColor,
    updateHealthAbsorbLabel, UnitFrameHealPredictionBars_Update,
}

unitFrameParent:SetAllPoints()
unitFrameParent:SetFrameStrata("LOW")
RegisterStateDriver(unitFrameParent, "visibility", "[petbattle] hide; show")

playerFrame = createUnitFrame(playerConfig)
createUnitFrame(petConfig)
createUnitFrame(targetConfig)
createUnitFrame(focusConfig)
for i = 1, MAX_BOSS_FRAMES do
    local bossConfig = {
        name = "WlkBoss" .. i .. "Frame",
        width = 273,
        height = height1,
        position = { "BOTTOMLEFT", UIParent, "BOTTOM", 366, 305 + i * bossSpacing1 + (i - 1) * bossSpacing2, },
        unit = "boss" .. i,
        events = { { "UNIT_TARGETABLE_CHANGED", "boss" .. i, true }, { "INSTANCE_ENCOUNTER_ENGAGE_UNIT", }, },
        power = true,
        classification = 2,
        raidTarget = 2,
        threat = { "BOTTOMLEFT", "TOPLEFT", 126, 2, },
        altPower = { 298, "TOPLEFT", "BOTTOMLEFT", -2, -31, },
        buff = { auraSize1, 4, 4, "BOTTOMLEFT", "TOPLEFT", 169, 4, },
        debuff = { auraSize1, 4, 4, "BOTTOMLEFT", "TOPLEFT", 0, 4, },
        highlight = true,
        range = true,
        castBar = { 269, "TOPLEFT", "BOTTOMLEFT", 25, -4, "INSTANCE_ENCOUNTER_ENGAGE_UNIT", },
    }
    createUnitFrame(bossConfig)
end
for i = 1, MAX_ARENA_FRAMES do
    local arenaConfig = {
        name = "WlkArena" .. i .. "Frame",
        width = 222,
        height = height1,
        position = { "BOTTOMLEFT", UIParent, "BOTTOM", 402, 305 + i * arenaSpacing1 + (i - 1) * arenaSpacing2, },
        unit = "arena" .. i,
        events = { { "ARENA_OPPONENT_UPDATE", }, },
        power = true,
        buff = { auraSize1, 4, 4, "BOTTOMLEFT", "TOPLEFT", 133, 4, },
        debuff = { auraSize1, 4, 4, "BOTTOMLEFT", "TOPLEFT", -36, 4, },
        highlight = true,
        range = true,
        cc = true,
        arena = true,
        prep = true,
        castBar = { 269, "TOPLEFT", "BOTTOMLEFT", 25 - 36, -4, "ARENA_OPPONENT_UPDATE", },
    }
    createUnitFrame(arenaConfig)
end

unitFrameParent:RegisterEvent("PLAYER_LOGIN")
unitFrameParent:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        CastingBarFrame:ClearAllPoints()
        CastingBarFrame:SetPoint("BOTTOM", castingBarHeight / 2, 236)

        PetCastingBarFrame:ClearAllPoints()
        PetCastingBarFrame:SetPoint("BOTTOM", castingBarHeight / 2, 236)

        CastingBarFrame.SetPoint = nop
        PetCastingBarFrame.SetPoint = nop
    end
end)

CastingBarFrame:SetSize(castingBarWidth, castingBarHeight)

PetCastingBarFrame:SetSize(castingBarWidth, castingBarHeight)

setCastBar(CastingBarFrame)
setCastBar(PetCastingBarFrame)

PlayerFrame:Hide()

hideFrame(TargetFrame)
hideFrame(FocusFrame)
hideFrame(ArenaEnemyFrames)
hideFrame(ArenaPrepFrames)
for i = 1, MAX_BOSS_FRAMES do
    hideFrame(_G["Boss" .. i .. "TargetFrame"])
    hideFrame(_G["ArenaEnemyFrame" .. i])
end

ArenaEnemyFrames = nil
ArenaPrepFrames = nil
