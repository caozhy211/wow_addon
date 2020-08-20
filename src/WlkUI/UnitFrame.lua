local function UpdateUnitFrameUnitName(unitFrame)
    ---@type FontString
    local label = unitFrame.nameLabel
    label:SetText(UnitName(unitFrame.unit))
end

local function UpdateUnitFrameUnitLevel(unitFrame)
    ---@type FontString
    local label = unitFrame.levelLabel
    local unit = unitFrame.unit
    if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
        label:SetText(UnitBattlePetLevel(unit))
    else
        local level = UnitLevel(unit)
        label:SetText(level > 0 and level or "??")
    end
end

local function UpdateUnitFrameUnitRace(unitFrame)
    ---@type FontString
    local label = unitFrame.raceLabel
    local unit = unitFrame.unit
    if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
        label:SetText(_G["BATTLE_PET_NAME_" .. UnitBattlePetType(unit)] .. PET)
    else
        label:SetText(UnitIsPlayer(unit) and UnitRace(unit) or UnitCreatureFamily(unit) or UnitCreatureType(unit))
    end
end

local function UpdateUnitFrameUnitClassification(unitFrame)
    ---@type Texture
    local icon = unitFrame.classificationIndicator
    if CompactUnitFrame_UpdatePvPClassificationIndicator(unitFrame) then
        return
    else
        local classification = UnitClassification(unitFrame.unit);
        if (classification == "elite" or classification == "worldboss") then
            icon:SetAtlas("nameplates-icon-elite-gold");
            icon:Show();
        elseif (classification == "rareelite") then
            icon:SetAtlas("nameplates-icon-elite-silver");
            icon:Show();
        else
            icon:Hide();
        end
    end
end

local function AbbreviateNumber(number)
    if number >= 1e8 then
        return format("%.2f%s", number / 1e8, SECOND_NUMBER_CAP)
    elseif number >= 1e6 then
        return format("%d%s", number / 1e4, FIRST_NUMBER_CAP)
    elseif number >= 1e4 then
        return format("%.1f%s", number / 1e4, FIRST_NUMBER_CAP)
    end
    return number
end

local function UpdateUnitFrameUnitHealthLabels(unitFrame, value, maxValue)
    ---@type FontString
    local healthLabel = unitFrame.healthLabel
    ---@type FontString
    local healthPercentLabel = unitFrame.healthPercentLabel
    healthLabel:SetFormattedText("%s/%s", AbbreviateNumber(value), AbbreviateNumber(maxValue))
    healthPercentLabel:SetText(FormatPercentage(PercentageBetween(value, 0, maxValue)))
end

local function UpdateUnitFrameUnitHealth(unitFrame)
    ---@type StatusBar
    local healthBar = unitFrame.healthbar
    if healthBar.lockValues then
        return
    end
    local unit = unitFrame.unit
    local maxValue = UnitHealthMax(unit)
    healthBar:SetMinMaxValues(0, maxValue)
    healthBar.disconnected = not UnitIsConnected(unit)
    if healthBar.disconnected then
        healthBar:SetValue(maxValue)
        healthBar.currValue = maxValue
    else
        local value = UnitHealth(unit)
        healthBar:SetValue(value)
        healthBar.currValue = value
    end
    UpdateUnitFrameUnitHealthLabels(unitFrame, healthBar.currValue, maxValue)
end

---@param self StatusBar
local function UnitFrameHealthBarOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.01 then
        return
    end
    self.elapsed = 0

    if not self.disconnected and not self.lockValues then
        local unitFrame = self:GetParent()
        local unit = unitFrame.unit
        local value = UnitHealth(unit)
        if value ~= self.currValue and UnitGUID(unit) then
            self:SetValue(value)
            self.currValue = value
            local maxValue = UnitHealthMax(unit)
            UpdateUnitFrameUnitHealthLabels(unitFrame, value, maxValue)
        end
    end
end

---@param self StatusBar
local function UnitFrameHealthBarOnEvent(self)
    local unitFrame = self:GetParent()
    if UnitGUID(unitFrame.unit) then
        UpdateUnitFrameUnitHealth(unitFrame)
    end
end

---@param self StatusBar
local function UnitFrameHealthBarOnSizeChanged(self)
    UnitFrameHealPredictionBars_UpdateSize(self:GetParent())
end

local function UpdateUnitFrameHealthAbsorbLabel(unitFrame)
    ---@type FontString
    local label = unitFrame.healthAbsorbLabel
    local absorb = UnitGetTotalAbsorbs(unitFrame.unit)
    label:SetText(absorb and absorb > 0 and ("+" .. AbbreviateNumber(absorb)) or "")
end

local function UpdateUnitFrameHealthBarColor(unitFrame)
    ---@type StatusBar
    local healthBar = unitFrame.healthbar
    if healthBar.lockColor then
        return
    end
    local unit = unitFrame.unit
    local r, g, b
    if not UnitIsConnected(unit) then
        r, g, b = 0.5, 0.5, 0.5
    else
        local _, class = UnitClass(unit)
        local classColor = RAID_CLASS_COLORS[class]
        if UnitIsPlayer(unit) and classColor then
            r, g, b = GetTableColor(classColor)
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
    if r ~= healthBar.r or g ~= healthBar.g or b ~= healthBar.b then
        healthBar:SetStatusBarColor(r, g, b)
        healthBar.r = r
        healthBar.g = g
        healthBar.b = b
    end
end

local function UpdateUnitFrameUnitManaLabels(unitFrame, value, maxValue)
    ---@type FontString
    local manaLabel = unitFrame.manaLabel
    ---@type FontString
    local manaPercentLabel = unitFrame.manaPercentLabel
    manaLabel:SetFormattedText("%s/%s", AbbreviateNumber(value), AbbreviateNumber(maxValue))
    manaPercentLabel:SetText(FormatPercentage(PercentageBetween(value, 0, maxValue)))
end

local function UpdateUnitFrameManaBarColor(unitFrame)
    ---@type StatusBar
    local manaBar = unitFrame.manaBar
    if not manaBar.lockColor then
        local unit = unitFrame.unit
        local r, g, b
        if not UnitIsConnected(unit) then
            r, g, b = 0.5, 0.5, 0.5
        else
            if manaBar.powerType then
                r, g, b = GetTableColor(PowerBarColor[manaBar.powerType])
            else
                local barInfo = GetUnitPowerBarInfo(unit)
                if barInfo and barInfo.showOnRaid then
                    r, g, b = 0.7, 0.7, 0.6
                else
                    local powerType, powerToken, altR, altG, altB = UnitPowerType(unit)
                    local info = PowerBarColor[powerToken]
                    if info then
                        r, g, b = GetTableColor(info)
                    else
                        if not altR then
                            info = PowerBarColor[powerType] or PowerBarColor["MANA"]
                            r, g, b = GetTableColor(info)
                        else
                            r, g, b = altR, altG, altB
                        end
                    end
                end
            end
        end
        manaBar:SetStatusBarColor(r, g, b)
    end
end

local function HideManaBar(unitFrame)
    ---@type StatusBar
    local manaBar = unitFrame.manaBar
    ---@type StatusBar
    local healthBar = unitFrame.healthbar
    manaBar:Hide()
    healthBar:SetHeight(unitFrame:GetHeight())
end

local function ShowManaBar(unitFrame)
    ---@type StatusBar
    local manaBar = unitFrame.manaBar
    ---@type StatusBar
    local healthBar = unitFrame.healthbar
    manaBar:Show()
    healthBar:SetHeight(unitFrame:GetHeight() * 2 / 3)
end

local function UpdateUnitFrameUnitMana(unitFrame)
    ---@type  StatusBar
    local manaBar = unitFrame.manaBar
    if manaBar.lockValues then
        return
    end
    local unit = unitFrame.unit
    UpdateUnitFrameManaBarColor(unitFrame)
    local maxValue = UnitPowerMax(unit, manaBar.powerType)
    if maxValue > 0 then
        if not manaBar:IsShown() then
            ShowManaBar(unitFrame)
        end
        manaBar:SetMinMaxValues(0, maxValue)
        manaBar.disconnected = not UnitIsConnected(unit)
        if manaBar.disconnected then
            manaBar:SetValue(maxValue)
            manaBar.currValue = maxValue
        else
            local value = UnitPower(unit, manaBar.powerType)
            manaBar:SetValue(value)
            manaBar.currValue = value
        end
        UpdateUnitFrameUnitManaLabels(unitFrame, manaBar.currValue, maxValue)
    else
        if manaBar:IsShown() then
            HideManaBar(unitFrame)
        end
    end
end

---@param self StatusBar
local function UnitFrameManaBarOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.01 then
        return
    end
    self.elapsed = 0

    if not self.disconnected and not self.lockValues then
        local unitFrame = self:GetParent()
        local unit = unitFrame.unit
        local maxValue = UnitPowerMax(unit, self.powerType)
        if maxValue > 0 then
            local value = UnitPower(unit, self.powerType)
            if value ~= self.currValue and UnitGUID(unit) then
                if not self:IsShown() then
                    ShowManaBar(unitFrame)
                end
                self:SetValue(value)
                self.currValue = value
                UpdateUnitFrameUnitManaLabels(unitFrame, value, maxValue)
            end
        else
            if self:IsShown() then
                HideManaBar(unitFrame)
            end
        end
    end
end

---@param self StatusBar
local function UnitFrameManaBarOnEvent(self)
    local unitFrame = self:GetParent()
    if UnitGUID(unitFrame.unit) then
        UpdateUnitFrameUnitMana(unitFrame)
    end
end

local function UpdateUnitFramePortrait(unitFrame)
    ---@type PlayerModel
    local portrait = unitFrame.portrait
    local unit = unitFrame.unit
    if UnitIsConnected(unit) and UnitIsVisible(unit) then
        portrait:SetUnit(unit)
    else
        portrait:ClearModel()
    end
end

local function UpdateUnitFrameSelectionHighlight(unitFrame)
    ---@type Texture
    local top = unitFrame.borderTop
    ---@type Texture
    local bottom = unitFrame.borderBottom
    ---@type Texture
    local left = unitFrame.borderLeft
    ---@type Texture
    local right = unitFrame.borderRight
    if unitFrame.showSelectionHighlight then
        if UnitIsUnit(unitFrame.unit, "target") then
            top:Show()
            bottom:Show()
            left:Show()
            right:Show()
        else
            top:Hide()
            bottom:Hide()
            left:Hide()
            right:Hide()
        end
    end
end

local function UpdateUnitFrameLeaderIcon(unitFrame)
    if unitFrame.showIndicators then
        ---@type Texture
        local icon = unitFrame.leaderIcon
        local unit = unitFrame.unit
        if UnitIsGroupLeader(unit) then
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

local function UpdateUnitFrameCombatRoleIcon(unitFrame)
    if unitFrame.showIndicators then
        ---@type Texture
        local icon = unitFrame.combatRoleIcon
        local role = UnitGroupRolesAssigned(unitFrame.unit)
        if role == "NONE" then
            icon:Hide()
        else
            icon:SetTexCoord(GetTexCoordsForRoleSmallCircle(role))
            icon:Show()
        end
    end
end

local function UpdateUnitFrameRaidRoster(unitFrame)
    if unitFrame.showIndicators then
        ---@type Texture
        local roleIcon = unitFrame.roleIcon
        ---@type Texture
        local masterLooterIcon = unitFrame.masterLooterIcon
        ---@type FontString
        local groupLabel = unitFrame.groupLabel
        local unit = unitFrame.unit
        local raidId = UnitInRaid(unit)
        if raidId then
            local _, _, subgroup, _, _, _, _, _, _, role, isMasterLooter = GetRaidRosterInfo(raidId)
            groupLabel:SetFormattedText("(%s)", subgroup)
            groupLabel:Show()
            if role then
                roleIcon:SetTexture(strconcat("Interface/GroupFrame/UI-Group-", role, "Icon"))
                roleIcon:Show()
            else
                roleIcon:Hide()
            end
            if isMasterLooter then
                masterLooterIcon:Show()
            else
                masterLooterIcon:Hide()
            end
        else
            groupLabel:Hide()
            roleIcon:Hide()
            masterLooterIcon:Hide()
        end
    end
end

local function UpdateUnitFrameUnitFaction(unitFrame)
    if unitFrame.showIndicators then
        ---@type Texture
        local prestigePortrait = unitFrame.prestigePortrait
        ---@type Texture
        local prestigeBadge = unitFrame.prestigeBadge
        ---@type Texture
        local pvpIcon = unitFrame.pvpIcon
        local unit = unitFrame.unit
        local factionGroup = UnitFactionGroup(unit)
        if UnitIsPVPFreeForAll(unit) then
            local honorLevel = UnitHonorLevel(unit)
            local honorRewardInfo = C_PvP.GetHonorRewardInfo(honorLevel)
            if honorRewardInfo then
                prestigePortrait:SetAtlas("honorsystem-portrait-neutral", false)
                prestigeBadge:SetTexture(honorRewardInfo.badgeFileDataID)
                prestigePortrait:Show()
                prestigeBadge:Show()
                pvpIcon:Hide()
            else
                prestigePortrait:Hide()
                prestigeBadge:Hide()
                pvpIcon:SetTexture("Interface/TargetingFrame/UI-PVP-FFA")
            end
        elseif factionGroup and factionGroup ~= "Neutral" and UnitIsPVP(unit) then
            local honorLevel = UnitHonorLevel(unit)
            local honorRewardInfo = C_PvP.GetHonorRewardInfo(honorLevel)
            if honorRewardInfo then
                prestigePortrait:SetAtlas("honorsystem-portrait-" .. factionGroup, false)
                prestigeBadge:SetTexture(honorRewardInfo.badgeFileDataID)
                prestigePortrait:Show()
                prestigeBadge:Show()
                pvpIcon:Hide()
            else
                prestigePortrait:Hide()
                prestigeBadge:Hide()
                pvpIcon:SetTexture("Interface/TargetingFrame/UI-PVP-" .. factionGroup)
                pvpIcon:Show()
            end
        else
            prestigePortrait:Hide()
            prestigeBadge:Hide()
            pvpIcon:Hide()
        end
    end
end

local function UpdateUnitFrameStatusIcon(unitFrame)
    if unitFrame.showStatusIcon then
        ---@type Texture
        local icon = unitFrame.statusIcon
        if UnitHasVehiclePlayerFrameUI("player") then
            icon:Hide()
        elseif IsResting() then
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

local function UpdateUnitFrameQuestIcon(unitFrame)
    if unitFrame.showQuestIcon then
        ---@type Texture
        local icon = unitFrame.questIcon
        if UnitIsQuestBoss(unitFrame.unit) then
            icon:Show()
        else
            icon:Hide()
        end
    end
end

local function UpdateUnitFramePetBattleIcon(unitFrame)
    if unitFrame.showPetBattleIcon then
        ---@type Texture
        local icon = unitFrame.petBattleIcon
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

local function UpdateUnitFrame(unitFrame)
    UpdateUnitFrameUnitName(unitFrame)
    UpdateUnitFrameUnitLevel(unitFrame)
    UpdateUnitFrameUnitRace(unitFrame)
    UpdateUnitFrameUnitClassification(unitFrame)
    UpdateUnitFrameUnitHealth(unitFrame)
    UnitFrameHealPredictionBars_UpdateMax(unitFrame)
    UnitFrameHealPredictionBars_Update(unitFrame)
    UpdateUnitFrameHealthAbsorbLabel(unitFrame)
    UpdateUnitFrameHealthBarColor(unitFrame)
    UpdateUnitFrameUnitMana(unitFrame)
    UpdateUnitFrameManaBarColor(unitFrame)
    UpdateUnitFramePortrait(unitFrame)
    TargetFrame_UpdateRaidTargetIcon(unitFrame)
    UpdateUnitFrameSelectionHighlight(unitFrame)
    UpdateUnitFrameLeaderIcon(unitFrame)
    UpdateUnitFrameCombatRoleIcon(unitFrame)
    UpdateUnitFrameRaidRoster(unitFrame)
    UpdateUnitFrameUnitFaction(unitFrame)
    UpdateUnitFrameStatusIcon(unitFrame)
    UpdateUnitFrameQuestIcon(unitFrame)
    UpdateUnitFramePetBattleIcon(unitFrame)
    if unitFrame.totFrame and UnitExists(unitFrame.totFrame.unit) then
        UpdateUnitFrame(unitFrame.totFrame)
    end
end

local checkRangeSpells = {
    WARRIOR = {
        attack = { 355, 355, 355 },
        assist = {},
    },
    PALADIN = {
        attack = { 20271, 20271, 20271, },
        assist = { 19750, 19750, 19750, },
    },
    HUNTER = {
        attack = { 193455, 185358, 259491, },
        assist = {},
        pet = 136,
    },
    ROGUE = {
        attack = { 185565, 185763, 114014, },
        assist = {},
    },
    PRIEST = {
        attack = { 585, 585, 589, },
        assist = { 17, 2061, 17, },
    },
    SHAMAN = {
        attack = { 187837, 187837, 187837, },
        assist = { 188070, 188070, 188070, },
    },
    MAGE = {
        attack = { 44425, 133, 116, },
        assist = { 130, 130, 130, },
    },
    WARLOCK = {
        attack = { 232670, 232670, 232670, },
        assist = { 20707, 20707, 20707, },
        pet = 755,
    },
    MONK = {
        attack = { 115546, 115546, 115546, },
        assist = { 116670, 116670, 116670, },
    },
    DRUID = {
        attack = { 190984, 8921, 8921, 8921, },
        assist = { 8936, 8936, 8936, 8936, },
    },
    DEMONHUNTER = {
        attack = { 185123, 185123, },
        assist = {},
    },
    DEATHKNIGHT = {
        attack = { 49576, 49576, 49576, },
        assist = { 61999, 61999, 61999, },
    },
}

local _, class = UnitClass("player")

---@param self Button
local function UnitFrameOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.01 then
        return
    end
    self.elapsed = 0

    local unit = self.unit
    local spellName, spellId
    if unit == "pet" then
        spellId = checkRangeSpells[class].pet
    else
        local spec = GetSpecialization()
        spellId = UnitCanAssist("player", unit) and checkRangeSpells[class].assist[spec]
                or UnitCanAttack("player", unit) and checkRangeSpells[class].attack[spec]
    end
    spellName = spellId and GetSpellInfo(spellId)
    if spellName and IsUsableSpell(spellName) then
        self:SetAlpha(IsSpellInRange(spellName, unit) == 1 and 1 or 0.55)
    else
        self:SetAlpha(CheckInteractDistance(unit, 1) and 1 or 0.55)
    end
end

---@param unitFrame Button
local function UnitFrameSwitchUnit(unitFrame)
    local temp = unitFrame.unit
    unitFrame.unit = unitFrame.unit2
    unitFrame.unit2 = temp
    for _, event in ipairs(unitFrame.unitEvents) do
        unitFrame:RegisterUnitEvent(event, unitFrame.unit)
    end
    ---@type StatusBar
    local healthBar = unitFrame.healthbar
    healthBar:RegisterUnitEvent("UNIT_MAXHEALTH", unitFrame.unit)
    ---@type StatusBar
    local manaBar = unitFrame.manaBar
    manaBar:RegisterUnitEvent("UNIT_DISPLAYPOWER", unitFrame.unit)
    manaBar:RegisterUnitEvent("UNIT_MAXPOWER", unitFrame.unit)
    unitFrame:SetAttribute("unit", unitFrame.unit)
end

local unitEvents = {
    "UNIT_NAME_UPDATE", "UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "UNIT_MAXHEALTH", "UNIT_LEVEL", "UNIT_HEAL_PREDICTION",
    "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_CLASSIFICATION_CHANGED", "UNIT_THREAT_LIST_UPDATE", "UNIT_CONNECTION",
    "UNIT_DISPLAYPOWER", "UNIT_PORTRAIT_UPDATE",
}

local function UnitFrameOnEvent(unitFrame, event, ...)
    local unit = unitFrame.unit
    if not UnitExists(unit) and (event ~= "UNIT_EXITING_VEHICLE" or unit ~= "vehicle") then
        return
    end
    local arg1 = ...
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" or event == "UNIT_TARGETABLE_CHANGED"
            or event == "UNIT_PET" or event == "UNIT_TARGET" or event == "PLAYER_FOCUS_CHANGED" then
        UpdateUnitFrame(unitFrame)
    elseif event == "UNIT_ENTERED_VEHICLE" and UnitInVehicle("player") and UnitHasVehicleUI("player") then
        UnitFrameSwitchUnit(unitFrame)
        unitFrame.switched = true
        UpdateUnitFrame(unitFrame)
    elseif event == "UNIT_EXITING_VEHICLE" then
        if unitFrame.switched then
            UnitFrameSwitchUnit(unitFrame)
            unitFrame.switched = false
        end
        UpdateUnitFrame(unitFrame)
    elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
        for i = 1, MAX_BOSS_FRAMES do
            local frame = _G[strconcat("WlkBoss", i, "Frame")]
            if UnitExists(frame.unit) then
                UpdateUnitFrame(frame)
            end
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        if unit == "focus" then
            UpdateUnitFrame(unitFrame)
        elseif unitFrame.totFrame and UnitExists(unitFrame.totFrame.unit) then
            UpdateUnitFrame(unitFrame.totFrame)
        end
    elseif event == "UNIT_NAME_UPDATE" then
        UpdateUnitFrameUnitName(unitFrame)
        UpdateUnitFrameHealthBarColor(unitFrame)
    elseif event == "UNIT_LEVEL" then
        UpdateUnitFrameUnitLevel(unitFrame)
    elseif event == "UNIT_CLASSIFICATION_CHANGED" then
        UpdateUnitFrameUnitClassification(unitFrame)
        UpdateUnitFrameUnitRace(unitFrame)
    elseif event == "UNIT_FACTION" then
        if arg1 == unit then
            UpdateUnitFrameUnitLevel(unitFrame)
            UpdateUnitFrameHealthBarColor(unitFrame)
        elseif arg1 == "player" then
            UpdateUnitFrameUnitLevel(unitFrame)
        end
    elseif event == "UNIT_MAXHEALTH" then
        UnitFrameHealPredictionBars_UpdateMax(unitFrame)
        UnitFrameHealPredictionBars_Update(unitFrame)
    elseif event == "UNIT_HEAL_PREDICTION" or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
        UnitFrameHealPredictionBars_Update(unitFrame)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        UnitFrameHealPredictionBars_Update(unitFrame)
        UpdateUnitFrameHealthAbsorbLabel(unitFrame)
    elseif event == "UNIT_THREAT_LIST_UPDATE" then
        UpdateUnitFrameHealthBarColor(unitFrame)
    elseif event == "UNIT_CONNECTION" then
        UpdateUnitFrameHealthBarColor(unitFrame)
        UpdateUnitFrameManaBarColor(unitFrame)
    elseif event == "UNIT_DISPLAYPOWER" then
        UpdateUnitFrameManaBarColor(unitFrame)
    elseif event == "UNIT_PORTRAIT_UPDATE" or event == "PORTRAITS_UPDATED" then
        UpdateUnitFramePortrait(unitFrame)
    elseif event == "RAID_TARGET_UPDATE" then
        TargetFrame_UpdateRaidTargetIcon(unitFrame)
    end

    if event == "PLAYER_TARGET_CHANGED" then
        UpdateUnitFrameSelectionHighlight(unitFrame)
    end

    if event == "PLAYER_ROLES_ASSIGNED" then
        UpdateUnitFrameCombatRoleIcon(unitFrame)
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdateUnitFrameLeaderIcon(unitFrame)
        UpdateUnitFrameRaidRoster(unitFrame)
        if unit ~= "focus" then
            UpdateUnitFrameUnitFaction(unitFrame)
        end
    elseif event == "UNIT_FACTION" and (arg1 == unit or arg1 == "player") then
        UpdateUnitFrameUnitFaction(unitFrame)
    elseif event == "PLAYER_ENTER_COMBAT" or event == "PLAYER_LEAVE_COMBAT" or event == "PLAYER_REGEN_DISABLED" or
            event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_UPDATE_RESTING" then
        UpdateUnitFrameStatusIcon(unitFrame)
    elseif event == "UNIT_CLASSIFICATION_CHANGED" then
        UpdateUnitFrameQuestIcon(unitFrame)
    end
end

local font = "ChatFontSmall"

---@param unitFrame Button
local function InitializeUnitFrame(unitFrame)
    local unit = unitFrame.unit
    local unit2 = unitFrame.unit2
    local name = unitFrame:GetName()

    unitFrame:SetAttribute("unit", unit)
    if unit2 then
        unitFrame:SetAttribute("toggleForVehicle", true)
    end
    unitFrame:SetAttribute("*type1", "target")
    unitFrame:SetAttribute("*type2", "togglemenu")
    unitFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    unitFrame:SetScript("OnEnter", UnitFrame_OnEnter)
    unitFrame:SetScript("OnLeave", UnitFrame_OnLeave)
    RegisterUnitWatch(unitFrame)

    ---@type StatusBar
    local healthBar = CreateFrame("StatusBar", name .. "HealthBar", unitFrame)
    unitFrame.healthbar = healthBar
    healthBar:SetSize(unitFrame:GetWidth(), unitFrame:GetHeight() * 2 / 3)
    healthBar:SetPoint("TOP")
    healthBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill", "BORDER")

    ---@type Texture
    local healthBarBackground = healthBar:CreateTexture(name .. "HealthBarBackground", "BACKGROUND")
    healthBarBackground:SetAllPoints()
    healthBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-Hp-Bg")
    healthBarBackground:SetTexCoord(0, 1, 0, 0.53125)

    ---@type Texture
    local myHealPredictionBar = healthBar:CreateTexture(name .. "MyHealPredictionBar", "BORDER", nil, 3)
    unitFrame.myHealPredictionBar = myHealPredictionBar
    ---@type Texture
    local otherHealPredictionBar = healthBar:CreateTexture(name .. "OtherHealPredictionBar", "BORDER", nil, 3)
    unitFrame.otherHealPredictionBar = otherHealPredictionBar
    ---@type Texture
    local totalAbsorbBar = healthBar:CreateTexture(name .. "TotalAbsorbBar", "BORDER", nil, 3)
    unitFrame.totalAbsorbBar = totalAbsorbBar
    ---@type Texture
    local totalAbsorbBarOverlay = healthBar:CreateTexture(name .. "TotalAbsorbBarOverlay", "BORDER", nil, 4)
    unitFrame.totalAbsorbBarOverlay = totalAbsorbBarOverlay
    ---@type Texture
    local healAbsorbBar = healthBar:CreateTexture(name .. "HealAbsorbBar", "ARTWORK", nil, 1)
    unitFrame.healAbsorbBar = healAbsorbBar
    ---@type Texture
    local healAbsorbBarLeftShadow = healthBar:CreateTexture(name .. "HealAbsorbBarLeftShadow", "ARTWORK", nil, 1)
    unitFrame.healAbsorbBarLeftShadow = healAbsorbBarLeftShadow
    ---@type Texture
    local healAbsorbBarRightShadow = healthBar:CreateTexture(name .. "HealAbsorbBarRightShadow", "ARTWORK", nil, 1)
    unitFrame.healAbsorbBarRightShadow = healAbsorbBarRightShadow
    ---@type Texture
    local overAbsorbGlow = healthBar:CreateTexture(name .. "OverAbsorbGlow", "ARTWORK", nil, 2)
    unitFrame.overAbsorbGlow = overAbsorbGlow
    ---@type Texture
    local overHealAbsorbGlow = healthBar:CreateTexture(name .. "OverHealAbsorbGlow", "ARTWORK", nil, 2)
    unitFrame.overHealAbsorbGlow = overHealAbsorbGlow

    myHealPredictionBar:SetColorTexture(1, 1, 1)
    myHealPredictionBar:SetGradient("VERTICAL", 8 / 255, 93 / 255, 72 / 255, 11 / 255, 136 / 255, 105 / 255)
    otherHealPredictionBar:SetColorTexture(1, 1, 1)
    otherHealPredictionBar:SetGradient("VERTICAL", 3 / 255, 72 / 255, 5 / 255, 2 / 255, 101 / 255, 18 / 255)
    totalAbsorbBar.overlay = totalAbsorbBarOverlay
    totalAbsorbBar:SetTexture("Interface/RaidFrame/Shield-Fill")
    totalAbsorbBarOverlay.tileSize = 32
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

    ---@type FontString
    local nameLabel = healthBar:CreateFontString(name .. "UnitName", "ARTWORK", font)
    unitFrame.nameLabel = nameLabel
    nameLabel:SetPoint("TOPLEFT", 1, -1)
    ---@type FontString
    local levelLabel = healthBar:CreateFontString(name .. "UnitLevel", "ARTWORK", font)
    unitFrame.levelLabel = levelLabel
    levelLabel:SetPoint("TOPRIGHT", -1, -1)
    ---@type FontString
    local raceLabel = healthBar:CreateFontString(name .. "UnitRace", "ARTWORK", font)
    unitFrame.raceLabel = raceLabel
    raceLabel:SetPoint("TOPRIGHT", levelLabel, "TOPLEFT", -1, 0)
    ---@type FontString
    local healthLabel = healthBar:CreateFontString(name .. "UnitHealth", "ARTWORK", font)
    unitFrame.healthLabel = healthLabel
    healthLabel:SetPoint("BOTTOMLEFT", 1, 1)
    ---@type FontString
    local healthPercentLabel = healthBar:CreateFontString(name .. "UnitHealthPercent", "ARTWORK", font)
    unitFrame.healthPercentLabel = healthPercentLabel
    healthPercentLabel:SetPoint("BOTTOMRIGHT", -1, 1)
    ---@type FontString
    local healthAbsorbLabel = healthBar:CreateFontString(name .. "UnitHealthAbsorb", "ARTWORK", font)
    unitFrame.healthAbsorbLabel = healthAbsorbLabel
    healthAbsorbLabel:SetPoint("LEFT", healthLabel, "RIGHT", 1, 0)

    ---@type StatusBar
    local manaBar = CreateFrame("StatusBar", name .. "ManaBar", unitFrame)
    unitFrame.manaBar = manaBar
    manaBar:SetSize(unitFrame:GetWidth(), unitFrame:GetHeight() / 3)
    manaBar:SetPoint("BOTTOM")
    manaBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill", "BORDER")

    ---@type Texture
    local manaBarBackground = manaBar:CreateTexture(name .. "ManaBarBackground", "BACKGROUND")
    manaBarBackground:SetAllPoints()
    manaBarBackground:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")

    ---@type FontString
    local manaLabel = manaBar:CreateFontString(name .. "UnitMana", "ARTWORK", font)
    unitFrame.manaLabel = manaLabel
    manaLabel:SetPoint("LEFT", 1, 0)
    ---@type FontString
    local manaPercentLabel = manaBar:CreateFontString(name .. "UnitManaPercent", "ARTWORK", font)
    unitFrame.manaPercentLabel = manaPercentLabel
    manaPercentLabel:SetPoint("RIGHT", -1, 0)

    ---@type Texture
    local raidTargetIcon = unitFrame:CreateTexture(name .. "RaidTargetIcon")
    unitFrame.raidTargetIcon = raidTargetIcon
    raidTargetIcon:SetSize(26, 26)
    raidTargetIcon:SetPoint("BOTTOMLEFT", unitFrame, "BOTTOMRIGHT")
    raidTargetIcon:SetTexture("Interface/TargetingFrame/UI-RaidTargetingIcons")

    ---@type Texture
    local classification = unitFrame:CreateTexture(name .. "Classification")
    unitFrame.classificationIndicator = classification
    classification:SetSize(16, 16)
    classification:SetPoint("TOPLEFT", unitFrame, "TOPRIGHT")
    classification:SetTexture("Interface/TargetingFrame/Nameplates")

    ---@type PlayerModel
    local portrait = CreateFrame("PlayerModel", "WlkUnitFramePortraitModel", unitFrame)
    unitFrame.portrait = portrait
    portrait:SetAllPoints()
    portrait:SetPortraitZoom(1)
    portrait:SetCamDistanceScale(3)
    portrait:SetAlpha(0.55)

    healthBar:SetScript("OnUpdate", UnitFrameHealthBarOnUpdate)
    healthBar:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
    healthBar:SetScript("OnEvent", UnitFrameHealthBarOnEvent)
    healthBar:SetScript("OnSizeChanged", UnitFrameHealthBarOnSizeChanged)
    manaBar:SetScript("OnUpdate", UnitFrameManaBarOnUpdate)
    manaBar:RegisterUnitEvent("UNIT_DISPLAYPOWER", unit)
    manaBar:RegisterUnitEvent("UNIT_MAXPOWER", unit)
    manaBar:SetScript("OnEvent", UnitFrameManaBarOnEvent)

    unitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    unitFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    unitFrame:RegisterEvent("RAID_TARGET_UPDATE")
    unitFrame:RegisterEvent("UNIT_FACTION")
    unitFrame:RegisterEvent("PORTRAITS_UPDATED")
    for _, event in ipairs(unitEvents) do
        unitFrame:RegisterUnitEvent(event, unit)
    end

    unitFrame:SetScript("OnEvent", UnitFrameOnEvent)

    if unit ~= "player" then
        unitFrame:SetScript("OnUpdate", UnitFrameOnUpdate)
    end
    if unitFrame.showSelectionHighlight then
        ---@type Texture
        local borderTop = unitFrame:CreateTexture()
        unitFrame.borderTop = borderTop
        borderTop:SetSize(unitFrame:GetWidth(), 2)
        borderTop:SetPoint("BOTTOM", unitFrame, "TOP")
        borderTop:SetColorTexture(1, 1, 0)
        ---@type Texture
        local borderBottom = unitFrame:CreateTexture()
        unitFrame.borderBottom = borderBottom
        borderBottom:SetSize(unitFrame:GetWidth(), 2)
        borderBottom:SetPoint("TOP", unitFrame, "BOTTOM")
        borderBottom:SetColorTexture(1, 1, 0)
        ---@type Texture
        local borderLeft = unitFrame:CreateTexture()
        unitFrame.borderLeft = borderLeft
        borderLeft:SetSize(2, unitFrame:GetHeight() + 2 * 2)
        borderLeft:SetPoint("RIGHT", unitFrame, "LEFT")
        borderLeft:SetColorTexture(1, 1, 0)
        ---@type Texture
        local borderRight = unitFrame:CreateTexture()
        unitFrame.borderRight = borderRight
        borderRight:SetSize(2, unitFrame:GetHeight() + 2 * 2)
        borderRight:SetPoint("LEFT", unitFrame, "RIGHT")
        borderRight:SetColorTexture(1, 1, 0)
        unitFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    end
    if unitFrame.showIndicators then
        ---@type Texture
        local leaderIcon = unitFrame:CreateTexture(name .. "LeaderIcon")
        unitFrame.leaderIcon = leaderIcon
        leaderIcon:SetSize(21, 21)
        leaderIcon:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT", 21 * 2, 0)

        ---@type Texture
        local combatRoleIcon = unitFrame:CreateTexture(name .. "CombatRoleIcon")
        unitFrame.combatRoleIcon = combatRoleIcon
        combatRoleIcon:SetSize(21, 21)
        combatRoleIcon:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT", 21 * 3, 0)
        combatRoleIcon:SetTexture("Interface/LFGFrame/UI-LFG-ICON-PORTRAITROLES")

        ---@type Texture
        local roleIcon = unitFrame:CreateTexture(name .. "RoleIcon")
        unitFrame.roleIcon = roleIcon
        roleIcon:SetSize(21, 21)
        roleIcon:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT", 21 * 4, 0)

        ---@type Texture
        local masterLooterIcon = unitFrame:CreateTexture(name .. "MasterLooterIcon")
        unitFrame.masterLooterIcon = masterLooterIcon
        masterLooterIcon:SetSize(21, 21)
        masterLooterIcon:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT", 21 * 5, 0)
        masterLooterIcon:SetTexture("Interface/GroupFrame/UI-Group-MasterLooter")

        ---@type FontString
        local groupLabel = unitFrame:CreateFontString(name .. "GroupLabel", "ARTWORK", font)
        unitFrame.groupLabel = groupLabel
        groupLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 1, 0)

        ---@type Texture
        local prestigePortrait = unitFrame:CreateTexture(name .. "PrestigePortrait", "BORDER")
        unitFrame.prestigePortrait = prestigePortrait
        prestigePortrait:SetSize(21, 21)
        prestigePortrait:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT", 21, 0)
        prestigePortrait:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        ---@type Texture
        local prestigeBadge = unitFrame:CreateTexture(name .. "PrestigeBadge")
        unitFrame.prestigeBadge = prestigeBadge
        prestigeBadge:SetSize(16, 16)
        prestigeBadge:SetPoint("CENTER", prestigePortrait)
        ---@type Texture
        local pvpIcon = unitFrame:CreateTexture(name .. "PvpIcon")
        unitFrame.pvpIcon = pvpIcon
        pvpIcon:SetSize(21, 21)
        pvpIcon:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT", 21, 0)
        pvpIcon:SetTexCoord(0.08, 0.59, 0, 0.56)

        unitFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    end
    if unitFrame.showStatusIcon then
        ---@type Texture
        local statusIcon = unitFrame:CreateTexture(name .. "StatusIcon")
        unitFrame.statusIcon = statusIcon
        statusIcon:SetSize(21, 21)
        statusIcon:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT")
        statusIcon:SetTexture("Interface/CharacterFrame/UI-StateIcon")
        unitFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
        unitFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
        unitFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        unitFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        unitFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
    end
    if unitFrame.showQuestIcon then
        ---@type Texture
        local questIcon = unitFrame:CreateTexture(name .. "QuestIcon")
        unitFrame.questIcon = questIcon
        questIcon:SetSize(21, 21)
        questIcon:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT")
        questIcon:SetTexture("Interface/TargetingFrame/PortraitQuestBadge")
    end
    if unitFrame.showPetBattleIcon then
        ---@type Texture
        local petBattleIcon = unitFrame:CreateTexture(name .. "PetBattleIcon")
        unitFrame.petBattleIcon = petBattleIcon
        petBattleIcon:SetSize(21, 21)
        petBattleIcon:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT")
    end
end

---@type Button
local petFrame = CreateFrame("Button", "WlkPetFrame", UIParent, "SecureUnitButtonTemplate")
petFrame:SetFrameStrata("HIGH")
petFrame:SetSize(200, 42)
petFrame:SetPoint("BOTTOMLEFT", 566, 100)
petFrame.unit = "pet"
petFrame.unit2 = "player"
petFrame.unitEvents = CopyTable(unitEvents)
petFrame:RegisterUnitEvent("UNIT_PET", "player")
petFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
petFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
InitializeUnitFrame(petFrame)
petFrame.raidTargetIcon:ClearAllPoints()
petFrame.raidTargetIcon:SetPoint("BOTTOMRIGHT", petFrame, "BOTTOMLEFT")
petFrame.classificationIndicator:ClearAllPoints()
petFrame.classificationIndicator:SetPoint("TOPRIGHT", petFrame, "TOPLEFT")

---@type Button
local totFrame = CreateFrame("Button", "WlkTotFrame", UIParent, "SecureUnitButtonTemplate")
totFrame:SetFrameStrata("HIGH")
totFrame:SetSize(200, 42)
totFrame:SetPoint("BOTTOMRIGHT", -566, 100)
totFrame.unit = "targetTarget"
totFrame.isTotFrame = true
totFrame:RegisterUnitEvent("UNIT_TARGET", "target")
totFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
InitializeUnitFrame(totFrame)

---@type Button
local playerFrame = CreateFrame("Button", "WlkPlayerFrame", UIParent, "SecureUnitButtonTemplate")
playerFrame:SetSize(300, 56)
playerFrame:SetPoint("BOTTOMLEFT", 566, 185)
playerFrame.unit = "player"
playerFrame.unit2 = "vehicle"
playerFrame.unitEvents = CopyTable(unitEvents)
playerFrame.showIndicators = 1
playerFrame.showStatusIcon = 1
playerFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
playerFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
InitializeUnitFrame(playerFrame)
playerFrame.raidTargetIcon:ClearAllPoints()
playerFrame.raidTargetIcon:SetPoint("BOTTOMRIGHT", playerFrame, "BOTTOMLEFT")
playerFrame.classificationIndicator:ClearAllPoints()
playerFrame.classificationIndicator:SetPoint("TOPRIGHT", playerFrame, "TOPLEFT")

---@type Button
local targetFrame = CreateFrame("Button", "WlkTargetFrame", UIParent, "SecureUnitButtonTemplate")
targetFrame:SetSize(300, 56)
targetFrame:SetPoint("BOTTOMRIGHT", -566, 185)
targetFrame.unit = "target"
targetFrame.totFrame = totFrame
targetFrame.showIndicators = 1
targetFrame.showQuestIcon = 1
targetFrame.showPetBattleIcon = 1
targetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
targetFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
InitializeUnitFrame(targetFrame)

---@type Button
local focusFrame = CreateFrame("Button", "WlkFocusFrame", UIParent, "SecureUnitButtonTemplate")
focusFrame:SetSize(210, 48)
focusFrame:SetPoint("BOTTOMLEFT", 1380, 185)
focusFrame.unit = "focus"
focusFrame.showSelectionHighlight = 1
focusFrame.showIndicators = 1
focusFrame.showQuestIcon = 1
focusFrame.showPetBattleIcon = 1
focusFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
focusFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
InitializeUnitFrame(focusFrame)

for i = 1, MAX_BOSS_FRAMES do
    ---@type Button
    local bossFrame = CreateFrame("Button", strconcat("WlkBoss", i, "Frame"), UIParent, "SecureUnitButtonTemplate")
    bossFrame:SetSize(240, 48)
    bossFrame:SetPoint("BOTTOMRIGHT", -330, 311 + 100 * (i - 1))
    bossFrame.unit = "boss" .. i
    bossFrame.showSelectionHighlight = 1
    if i == 1 then
        bossFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    end
    bossFrame:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "boss" .. i)
    bossFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
    InitializeUnitFrame(bossFrame)
end

