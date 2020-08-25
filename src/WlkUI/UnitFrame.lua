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
        local classification = UnitClassification(unitFrame.unit)
        if (classification == "elite" or classification == "worldboss") then
            icon:SetAtlas("nameplates-icon-elite-gold")
            icon:Show()
        elseif (classification == "rareelite") then
            icon:SetAtlas("nameplates-icon-elite-silver")
            icon:Show()
        else
            icon:Hide()
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

local function SetFrameBorderShown(frame, show)
    ---@type Texture
    local top = frame.borderTop
    ---@type Texture
    local bottom = frame.borderBottom
    ---@type Texture
    local left = frame.borderLeft
    ---@type Texture
    local right = frame.borderRight
    if show then
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

---@param frame Frame
---@param color ColorMixin
local function CreateFrameBorder(frame, color, size)
    local r, g, b = color:GetRGB()
    local width = frame:GetWidth()
    local height = frame:GetHeight()
    ---@type Texture
    local borderTop = frame:CreateTexture()
    frame.borderTop = borderTop
    borderTop:SetSize(width, size)
    borderTop:SetPoint("BOTTOM", frame, "TOP")
    borderTop:SetColorTexture(r, g, b)
    ---@type Texture
    local borderBottom = frame:CreateTexture()
    frame.borderBottom = borderBottom
    borderBottom:SetSize(width, size)
    borderBottom:SetPoint("TOP", frame, "BOTTOM")
    borderBottom:SetColorTexture(r, g, b)
    ---@type Texture
    local borderLeft = frame:CreateTexture()
    frame.borderLeft = borderLeft
    borderLeft:SetSize(size, height + size * 2)
    borderLeft:SetPoint("RIGHT", frame, "LEFT")
    borderLeft:SetColorTexture(r, g, b)
    ---@type Texture
    local borderRight = frame:CreateTexture()
    frame.borderRight = borderRight
    borderRight:SetSize(size, height + size * 2)
    borderRight:SetPoint("LEFT", frame, "RIGHT")
    borderRight:SetColorTexture(r, g, b)
end

local function UpdateUnitFrameSelectionHighlight(unitFrame)
    if unitFrame.showSelectionHighlight then
        SetFrameBorderShown(unitFrame, UnitIsUnit(unitFrame.unit, "target"))
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

---@param bar StatusBar
local function UpdateUnitFrameUnitPowerBarAltValue(bar, unit)
    if bar then
        ---@type FontString
        local valueLabel = bar.valueLabel
        ---@type FontString
        local valuePercentLabel = bar.valuePercentLabel
        local currentPower = UnitPower(unit, ALTERNATE_POWER_INDEX)
        bar:SetValue(currentPower)
        local minValue, maxValue = bar:GetMinMaxValues()
        valueLabel:SetFormattedText("%s/%s", AbbreviateNumber(currentPower), AbbreviateNumber(maxValue))
        valuePercentLabel:SetText(FormatPercentage(PercentageBetween(currentPower, minValue, maxValue)))
    end
end

---@param bar StatusBar
local function UpdateUnitFrameUnitPowerBarAltMax(bar, unit)
    if bar then
        local barInfo = GetUnitPowerBarInfo(unit)
        local minPower = barInfo and barInfo.minPower or 0
        local maxPower = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)
        bar:SetMinMaxValues(minPower, maxPower)
        UpdateUnitFrameUnitPowerBarAltValue(bar, unit)
    end
end

local TEXTURE_FILL_INDEX = 3
local TEXTURE_NUMBERS_INDEX = 6

---@param unitFrame Button
local function UpdateUnitFrameUnitPowerBarAlt(unitFrame)
    if unitFrame.showPowerBarAlt then
        ---@type StatusBar
        local bar = unitFrame.powerBarAlt
        local unit = unitFrame.unit
        local barInfo = GetUnitPowerBarInfo(unit)
        if barInfo then
            unitFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", unit)
            unitFrame:RegisterUnitEvent("UNIT_MAXPOWER", unit)
            local _, r, g, b = GetUnitPowerBarTextureInfo(unit, barInfo.barType == ALT_POWER_TYPE_COUNTER
                    and TEXTURE_NUMBERS_INDEX or TEXTURE_FILL_INDEX)
            bar:SetStatusBarColor(r, g, b)
            UpdateUnitFrameUnitPowerBarAltMax(bar, unit)
            bar:Show()
        else
            bar:Hide()
            unitFrame:UnregisterEvent("UNIT_POWER_UPDATE")
            unitFrame:UnregisterEvent("UNIT_MAXPOWER")
        end
    end
end

---@param self StatusBar
local function UnitFrameUnitPowerBarAltOnEnter(self)
    local unit = self:GetParent().unit
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    local name, tooltip = GetUnitPowerBarStrings(unit)
    GameTooltip_SetTitle(GameTooltip, name)
    GameTooltip_AddNormalLine(GameTooltip, tooltip)
    GameTooltip:Show()
end

local function UnitFrameUnitPowerBarAltOnLeave()
    GameTooltip:Hide()
end

---@param auraFrame Frame
local function CreateUnitFrameUnitAuraButton(auraFrame, num)
    local template = auraFrame.type == "Buff" and "TargetBuffFrameTemplate" or "TargetDebuffFrameTemplate"
    ---@type Button|TargetBuffFrameTemplate|TargetDebuffFrameTemplate
    local button = CreateFrame("Button", strconcat(auraFrame:GetName(), auraFrame.type, num), auraFrame, template)
    local size = auraFrame.buttonSize
    button:SetSize(size, size)
    if button.Stealable then
        button.Stealable:SetSize(size + 3, size + 3)
    end
    button.Count:ClearAllPoints()
    button.Count:SetPoint("BOTTOMRIGHT", 3, 0)
    button.Count:SetFontObject("Game12Font_o1")
    button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    return button
end

local spacing = 3

local function UpdateUnitFrameUnitAuraButtonAnchor(auraFrame)
    ---@type Button[]
    local buttons = auraFrame.Buff or auraFrame.Debuff
    local orientation = auraFrame.orientation
    local point, signX, signY
    if orientation == "toLeftTop" then
        point = "BOTTOMRIGHT"
        signX = -1
        signY = 1
    elseif orientation == "toRightTop" then
        point = "BOTTOMLEFT"
        signX = 1
        signY = 1
    end
    local countPerLine = auraFrame.countPerLine
    for i, auraButton in ipairs(buttons) do
        if not auraButton:IsShown() then
            break
        end
        auraButton:SetPoint(point, auraFrame, (auraFrame.buttonSize + spacing) * ((i - 1) % countPerLine) * signX,
                (auraFrame.buttonSize + spacing) * floor((i - 1) / countPerLine) * signY)
    end
end

local function UpdateUnitFrameUnitAuras(unitFrame)
    local unit = unitFrame.unit

    if unitFrame.buffFrame then
        ---@type Frame
        local buffFrame = unitFrame.buffFrame
        local maxBuffs = buffFrame.maxCount
        local unitIsPlayer = UnitIsUnit(unit, UnitInVehicle("player") and UnitHasVehicleUI("player")
                and "vehicle" or "player")
        local index = 1
        local numBuffs = 0
        AuraUtil.ForEachAura(unit, "HELPFUL", maxBuffs, function(...)
            local _, icon, count, _, duration, expirationTime, _, canStealOrPurge = ...
            if icon then
                numBuffs = numBuffs + 1
                ---@type Button|TargetBuffFrameTemplate
                local buffButton = buffFrame.Buff and buffFrame.Buff[numBuffs]
                if not buffButton then
                    buffButton = CreateUnitFrameUnitAuraButton(buffFrame, numBuffs)
                    buffButton.unit = unit
                end
                buffButton:SetID(index)
                buffButton.Icon:SetTexture(icon)
                if count > 1 then
                    buffButton.Count:SetText(count)
                    buffButton.Count:Show()
                else
                    buffButton.Count:Hide()
                end
                CooldownFrame_Set(buffButton.Cooldown, expirationTime - duration, duration, duration > 0, true)
                buffButton.Stealable:SetShown(not unitIsPlayer and canStealOrPurge)
                buffButton:ClearAllPoints()
                buffButton:Show()
            end
            index = index + 1
            return numBuffs >= maxBuffs
        end)

        if buffFrame.Buff then
            for i = numBuffs + 1, maxBuffs do
                ---@type Button
                local buffButton = buffFrame.Buff[i]
                if buffButton then
                    buffButton:Hide()
                else
                    break
                end
            end
            UpdateUnitFrameUnitAuraButtonAnchor(unitFrame.buffFrame)
        end
    end

    if unitFrame.debuffFrame then
        ---@type Frame
        local debuffFrame = unitFrame.debuffFrame
        local maxDebuffs = debuffFrame.maxCount
        local index = 1
        local numDebuffs = 0
        AuraUtil.ForEachAura(unit, "HARMFUL|INCLUDE_NAME_PLATE_ONLY", maxDebuffs, function(...)
            local _, icon, count, debuffType, duration, expirationTime, caster, _, _, _, _, _, casterIsPlayer,
            nameplateShowAll = ...
            if TargetFrame_ShouldShowDebuffs(unit, caster, nameplateShowAll, casterIsPlayer) then
                if icon then
                    numDebuffs = numDebuffs + 1
                    ---@type Button|TargetDebuffFrameTemplate
                    local debuffButton = debuffFrame.Debuff and debuffFrame.Debuff[numDebuffs]
                    if not debuffButton then
                        debuffButton = CreateUnitFrameUnitAuraButton(debuffFrame, numDebuffs)
                        debuffButton.unit = unit
                    end
                    debuffButton:SetID(index)
                    debuffButton.Icon:SetTexture(icon)
                    if count > 1 then
                        debuffButton.Count:SetText(count)
                        debuffButton.Count:Show()
                    else
                        debuffButton.Count:Hide()
                    end
                    CooldownFrame_Set(debuffButton.Cooldown, expirationTime - duration, duration, duration > 0, true)
                    local color
                    if debuffType then
                        color = DebuffTypeColor[debuffType]
                    else
                        color = DebuffTypeColor["none"]
                    end
                    debuffButton.Border:SetVertexColor(GetTableColor(color))
                    debuffButton:ClearAllPoints()
                    debuffButton:Show()
                end
            end
            index = index + 1
            return numDebuffs >= maxDebuffs
        end)

        if debuffFrame.Debuff then
            for i = numDebuffs + 1, maxDebuffs do
                ---@type Button
                local debuffButton = debuffFrame.Debuff[i]
                if debuffButton then
                    debuffButton:Hide()
                else
                    break
                end
            end
            UpdateUnitFrameUnitAuraButtonAnchor(unitFrame.debuffFrame)
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
    UpdateUnitFrameUnitPowerBarAlt(unitFrame)
    UpdateUnitFrameUnitAuras(unitFrame)
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
end

local unitEvents = {
    "UNIT_NAME_UPDATE", "UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "UNIT_MAXHEALTH", "UNIT_LEVEL", "UNIT_HEAL_PREDICTION",
    "UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_CLASSIFICATION_CHANGED", "UNIT_THREAT_LIST_UPDATE", "UNIT_CONNECTION",
    "UNIT_DISPLAYPOWER", "UNIT_PORTRAIT_UPDATE",
}

local function UnitFrameOnEvent(unitFrame, event, ...)
    local unit = unitFrame.unit
    if not UnitExists(unit) and (event ~= "UNIT_EXITING_VEHICLE" or unit ~= "vehicle")
            and not ShowBossFrameWhenUninteractable(unit) then
        return
    end
    local arg1, arg2 = ...
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
            UpdateUnitFrame(unitFrame)
        else
            UpdateUnitFrameHealthBarColor(unitFrame)
        end
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
        else
            UpdateUnitFrameHealthBarColor(unitFrame)
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

    if event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" then
        UpdateUnitFrameUnitPowerBarAlt(unitFrame)
    elseif event == "UNIT_MAXPOWER" and arg2 == "ALTERNATE" then
        UpdateUnitFrameUnitPowerBarAltMax(unitFrame.powerBarAlt, unit)
    elseif event == "UNIT_POWER_UPDATE" and arg2 == "ALTERNATE" then
        UpdateUnitFrameUnitPowerBarAltValue(unitFrame.powerBarAlt, unit)
    end

    if event == "UNIT_AURA" then
        UpdateUnitFrameUnitAuras(unitFrame)
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

    local size = unitFrame:GetHeight() / 2
    local offset = unitFrame.showSelectionHighlight and 2 or 0
    local point = unitFrame.position
    local sign = point == "LEFT" and -1 or 1

    ---@type Texture
    local raidTargetIcon = unitFrame:CreateTexture(name .. "RaidTargetIcon")
    unitFrame.raidTargetIcon = raidTargetIcon
    raidTargetIcon:SetSize(size, size)
    raidTargetIcon:SetPoint("BOTTOM" .. point, (offset + size) * sign, 0)
    raidTargetIcon:SetTexture("Interface/TargetingFrame/UI-RaidTargetingIcons")

    ---@type Texture
    local classification = unitFrame:CreateTexture(name .. "Classification")
    unitFrame.classificationIndicator = classification
    classification:SetSize(size, size)
    classification:SetPoint("TOP" .. point, (offset + size) * sign, 0)
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
        CreateFrameBorder(unitFrame, YELLOW_FONT_COLOR, 2)
        unitFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    end
    if unitFrame.showIndicators then
        sign = point == "LEFT" and 1 or -1

        ---@type Texture
        local prestigePortrait = unitFrame:CreateTexture(name .. "PrestigePortrait", "BORDER")
        unitFrame.prestigePortrait = prestigePortrait
        prestigePortrait:SetSize(size, size)
        prestigePortrait:SetPoint("BOTTOM" .. point, -offset * sign, -offset - size)
        prestigePortrait:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        ---@type Texture
        local prestigeBadge = unitFrame:CreateTexture(name .. "PrestigeBadge")
        unitFrame.prestigeBadge = prestigeBadge
        prestigeBadge:SetSize(size - 5, size - 5)
        prestigeBadge:SetPoint("CENTER", prestigePortrait)
        ---@type Texture
        local pvpIcon = unitFrame:CreateTexture(name .. "PvpIcon")
        unitFrame.pvpIcon = pvpIcon
        pvpIcon:SetSize(size, size)
        pvpIcon:SetPoint("BOTTOM" .. point, -offset * sign, -offset - size)
        pvpIcon:SetTexCoord(0.08, 0.59, 0, 0.56)

        ---@type Texture
        local leaderIcon = unitFrame:CreateTexture(name .. "LeaderIcon")
        unitFrame.leaderIcon = leaderIcon
        leaderIcon:SetSize(size, size)
        leaderIcon:SetPoint("BOTTOM" .. point, (size - offset) * sign, -offset - size)

        ---@type Texture
        local combatRoleIcon = unitFrame:CreateTexture(name .. "CombatRoleIcon")
        unitFrame.combatRoleIcon = combatRoleIcon
        combatRoleIcon:SetSize(size, size)
        combatRoleIcon:SetPoint("BOTTOM" .. point, (size * 2 - offset) * sign, -offset - size)
        combatRoleIcon:SetTexture("Interface/LFGFrame/UI-LFG-ICON-PORTRAITROLES")

        ---@type Texture
        local roleIcon = unitFrame:CreateTexture(name .. "RoleIcon")
        unitFrame.roleIcon = roleIcon
        roleIcon:SetSize(size, size)
        roleIcon:SetPoint("BOTTOM" .. point, (size * 3 - offset) * sign, -offset - size)

        ---@type Texture
        local masterLooterIcon = unitFrame:CreateTexture(name .. "MasterLooterIcon")
        unitFrame.masterLooterIcon = masterLooterIcon
        masterLooterIcon:SetSize(size, size)
        masterLooterIcon:SetPoint("BOTTOM" .. point, (size * 4 - offset) * sign, -offset - size)
        masterLooterIcon:SetTexture("Interface/GroupFrame/UI-Group-MasterLooter")

        ---@type FontString
        local groupLabel = unitFrame:CreateFontString(name .. "GroupLabel", "ARTWORK", font)
        unitFrame.groupLabel = groupLabel
        groupLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 1, 0)

        unitFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    end
    if unitFrame.showStatusIcon then
        ---@type Texture
        local statusIcon = unitFrame:CreateTexture(name .. "StatusIcon")
        unitFrame.statusIcon = statusIcon
        statusIcon:SetSize(size, size)
        statusIcon:SetPoint("TOPRIGHT", unitFrame, "BOTTOMLEFT")
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
        questIcon:SetSize(size, size)
        questIcon:SetPoint("TOPLEFT", unitFrame, "BOTTOMRIGHT", offset, -offset)
        questIcon:SetTexture("Interface/TargetingFrame/PortraitQuestBadge")
    end
    if unitFrame.showPetBattleIcon then
        ---@type Texture
        local petBattleIcon = unitFrame:CreateTexture(name .. "PetBattleIcon")
        unitFrame.petBattleIcon = petBattleIcon
        petBattleIcon:SetSize(size, size)
        petBattleIcon:SetPoint("TOPLEFT", unitFrame, "BOTTOMRIGHT", offset, -offset)
    end
    if unitFrame.showPowerBarAlt then
        ---@type StatusBar
        local powerBarAlt = CreateFrame("StatusBar", name .. "UnitPowerBarAlt", unitFrame)
        unitFrame.powerBarAlt = powerBarAlt
        powerBarAlt:SetSize(192, 16)
        powerBarAlt:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill")
        ---@type Texture
        local powerBarAltBackground = powerBarAlt:CreateTexture(name .. "UnitPowerBarAltBackground", "BACKGROUND")
        powerBarAltBackground:SetAllPoints()
        powerBarAltBackground:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")
        ---@type FontString
        local valueLabel = powerBarAlt:CreateFontString(name .. "UnitPowerBarAltValueLabel", "ARTWORK", font)
        powerBarAlt.valueLabel = valueLabel
        valueLabel:SetPoint("LEFT", 1, 0)
        ---@type FontString
        local valuePercentLabel = powerBarAlt:CreateFontString(name .. "UnitPowerBarAltValuePercentLabel", "ARTWORK",
                font)
        powerBarAlt.valuePercentLabel = valuePercentLabel
        valuePercentLabel:SetPoint("RIGHT", -1, 0)

        powerBarAlt:SetScript("OnEnter", UnitFrameUnitPowerBarAltOnEnter)
        powerBarAlt:SetScript("OnLeave", UnitFrameUnitPowerBarAltOnLeave)

        unitFrame:RegisterUnitEvent("UNIT_POWER_BAR_SHOW")
        unitFrame:RegisterUnitEvent("UNIT_POWER_BAR_HIDE")
    end
    if unitFrame.buffFrame or unitFrame.debuffFrame then
        unitFrame:RegisterUnitEvent("UNIT_AURA", unit)
    end
end

---@param unitFrame Button
---@return Frame
local function CreateUnitFrameAuraFrame(unitFrame, auraType, orientation, maxCount, countPerLine)
    ---@type Frame
    local frame = CreateFrame("Frame", strconcat(unitFrame:GetName(), auraType, "Frame"), unitFrame)
    frame.type = auraType
    frame.maxCount = maxCount
    frame.orientation = orientation
    frame.countPerLine = countPerLine
    local buttonSize = unitFrame:GetHeight() / 2
    frame.buttonSize = buttonSize
    local rows = ceil(maxCount / countPerLine)
    frame:SetSize(countPerLine * (buttonSize + spacing) - spacing, rows * (buttonSize + spacing) - spacing)
    return frame
end

local function UnitFrameSpellBarOnEvent(self, event, ...)
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

local function GetUnitCastingInfo(bar)
    local unit = bar.unit
    local startTime, endTime, isTradeSkill, castId, _
    if bar.channeling then
        _, _, _, startTime, endTime, isTradeSkill, _, castId = UnitChannelInfo(unit)
    elseif bar.casting then
        _, _, _, startTime, endTime, isTradeSkill, _, _, castId = UnitCastingInfo(unit)
    end
    if startTime and endTime then
        return startTime / 1000, endTime / 1000, isTradeSkill, castId
    end
end

local castingStartTime, castingDelayTime

local function HookUnitFrameSpellBarOnEvent(self, event, ...)
    local unit = ...
    if unit ~= self.unit then
        return
    end
    if event == "UNIT_SPELLCAST_START" then
        castingStartTime = GetUnitCastingInfo(self)
        castingDelayTime = 0
    elseif event == "UNIT_SPELLCAST_DELAYED" then
        local startTime = GetUnitCastingInfo(self)
        if startTime and self.casting then
            castingDelayTime = (castingDelayTime or 0) + (startTime - (castingStartTime or startTime))
        end
    end
end

local function FormatTime(seconds)
    if seconds < 10 then
        return format("%.1f", seconds)
    elseif seconds < SECONDS_PER_MIN then
        return format("%d", seconds)
    end
    return SecondsToClock(seconds)
end

local function HookUnitFrameSpellBarOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.01 then
        return
    end
    self.elapsed = 0

    ---@type FontString
    local timeLabel = self.timeLabel
    ---@type FontString
    local delayTimeLabel = self.delayTimeLabel
    if self.casting then
        timeLabel:SetFormattedText("%s/%s", FormatTime(self.maxValue - self.value), FormatTime(self.maxValue))
    elseif self.channeling then
        timeLabel:SetFormattedText("%s/%s", FormatTime(self.value), FormatTime(self.maxValue))
    end
    if castingDelayTime and castingDelayTime >= 0.1 and self.casting then
        delayTimeLabel:SetFormattedText("+%.2f", castingDelayTime)
    else
        delayTimeLabel:SetText("")
    end
end

---@param self Texture
local function HookSpellBarBorderShieldShow(self)
    SetFrameBorderShown(self:GetParent(), true)
end

---@param self Texture
local function HookSpellBarBorderShieldHide(self)
    SetFrameBorderShown(self:GetParent())
end

---@param bar StatusBar|CastingBarFrameTemplate
local function InitializeUnitFrameSpellBar(bar)
    bar.Border:Hide()
    bar.Flash:SetTexture(nil)
    bar.Spark:SetTexture(nil)
    bar.BorderShield:SetTexture(nil)
    local height = bar:GetHeight()
    bar.Icon:SetSize(height, height)
    bar.Icon:SetPoint("RIGHT", bar, "LEFT")
    bar.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    bar.Icon:Show()
    bar.Text:ClearAllPoints()
    bar.Text:SetPoint("LEFT", 5, 0)
    bar.Text:SetJustifyH("LEFT")
    bar.Text:SetWidth(bar:GetWidth() * 2 / 3)
    bar.Text:SetFontObject(font)

    ---@type FontString
    local timeLabel = bar:CreateFontString(bar:GetName() .. "TimeLabel", "ARTWORK", font)
    bar.timeLabel = timeLabel
    timeLabel:SetPoint("RIGHT")
    ---@type FontString
    local delayTimeLabel = bar:CreateFontString(bar:GetName() .. "DelayTimeLabel", "ARTWORK", font)
    bar.delayTimeLabel = delayTimeLabel
    delayTimeLabel:SetPoint("RIGHT", timeLabel, "LEFT", -1, 0)
    delayTimeLabel:SetTextColor(1, 0, 0)

    CreateFrameBorder(bar, HIGHLIGHT_FONT_COLOR, 2)
    local borderWidth = bar.borderTop:GetWidth()
    bar.borderTop:SetWidth(borderWidth + 26)
    bar.borderBottom:SetWidth(borderWidth + 26)
    bar.borderTop:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT")
    bar.borderBottom:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT")
    bar.borderLeft:SetPoint("RIGHT", bar, "LEFT", -26, 0)

    hooksecurefunc(bar.BorderShield, "Show", HookSpellBarBorderShieldShow)
    hooksecurefunc(bar.BorderShield, "Hide", HookSpellBarBorderShieldHide)

    bar:HookScript("OnEvent", HookUnitFrameSpellBarOnEvent)
    bar:HookScript("OnUpdate", HookUnitFrameSpellBarOnUpdate)
end

---@param unitFrame Button
local function CreateUnitFrameSpellBar(unitFrame, event)
    ---@type StatusBar|CastingBarFrameTemplate
    local bar = CreateFrame("StatusBar", unitFrame:GetName() .. "SpellBar", UIParent, "CastingBarFrameTemplate")
    unitFrame.spellBar = bar
    bar:Hide()
    CastingBarFrame_SetUnit(bar, unitFrame.unit, true, true)
    if event then
        bar.updateEvent = event
        bar:RegisterEvent(event)
    end
    bar:SetScript("OnEvent", UnitFrameSpellBarOnEvent)
end

---@type Button
local petFrame = CreateFrame("Button", "WlkPetFrame", UIParent, "SecureUnitButtonTemplate")
petFrame:SetFrameStrata("HIGH")
petFrame:SetSize(773 - 540 - 21, 42)
petFrame:SetPoint("BOTTOMLEFT", 540 + 21, 100)
petFrame.unit = "pet"
petFrame.unit2 = "player"
petFrame.unitEvents = CopyTable(unitEvents)
petFrame.position = "LEFT"
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
totFrame:SetSize(petFrame:GetSize())
totFrame:SetPoint("BOTTOMRIGHT", -540 - 21, 100)
totFrame.unit = "targetTarget"
totFrame.isTotFrame = true
totFrame.position = "RIGHT"
totFrame:RegisterUnitEvent("UNIT_TARGET", "target")
totFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
InitializeUnitFrame(totFrame)

---@type Button
local playerFrame = CreateFrame("Button", "WlkPlayerFrame", UIParent, "SecureUnitButtonTemplate")
playerFrame:SetSize((27 + spacing) * 9, 54)
playerFrame:SetPoint("BOTTOMLEFT", 540 + 27, 100 + 42 + 27)
playerFrame.unit = "player"
playerFrame.unit2 = "vehicle"
playerFrame.unitEvents = CopyTable(unitEvents)
playerFrame.showIndicators = 1
playerFrame.showStatusIcon = 1
playerFrame.position = "LEFT"
playerFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
playerFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
InitializeUnitFrame(playerFrame)

---@param auraButton AuraButtonTemplate
hooksecurefunc("AuraButton_UpdateDuration", function(auraButton)
    if auraButton.wlkCooldown then
        auraButton.duration:Hide()
    end
end)

hooksecurefunc("CreateFrame", function(_, frameName)
    if frameName and (strmatch(frameName, "^BuffButton%d$") or strmatch(frameName, "^DebuffButton%d$")) then
        ---@type Button|AuraButtonTemplate|BuffButtonTemplate|DebuffButtonTemplate
        local button = _G[frameName]
        button:SetSize(27, 27)
        button.SetAlpha = nop
        if button.Border then
            button.Border:ClearAllPoints()
            button.Border:SetPoint("TOPLEFT", -1, 1)
            button.Border:SetPoint("BOTTOMRIGHT", 1, -1)
        end
        button.count:ClearAllPoints()
        button.count:SetPoint("BOTTOMRIGHT", 3, 0)
        button.count:SetJustifyH("RIGHT")
        button.count:SetFontObject("Game12Font_o1")
        button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        ---@type Cooldown
        local cooldown = CreateFrame("Cooldown", frameName .. "WlkCooldown", button, "CooldownFrameTemplate")
        button.wlkCooldown = cooldown
        cooldown:SetReverse(true)
        cooldown:SetDrawEdge(true)
    end
end)

hooksecurefunc("AuraButton_Update", function(buttonName, index, _, _, _, _, duration, expirationTime)
    local cooldown = _G[buttonName .. index].wlkCooldown
    if cooldown then
        local startTime = expirationTime - duration
        CooldownFrame_Set(cooldown, startTime, duration, duration > 0, true)
    end
end)

hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", function()
    if BuffFrame.BuffButton then
        ---@type Button
        local button
        for i = 1, BUFF_MAX_DISPLAY do
            button = BuffFrame.BuffButton[i]
            if button and button.SetPoint ~= nop then
                button:ClearAllPoints()
                button:SetPoint("BOTTOMRIGHT", playerFrame, "TOPRIGHT", (i - 1) % 15 * -(27 + 3),
                        78 + floor((i - 1) / 15) * (27 + 3))
                button.SetPoint = nop
            end
        end
    end
end)

hooksecurefunc("DebuffButton_UpdateAnchors", function(buttonName, index)
    ---@type Button
    local button = BuffFrame[buttonName][index]
    if button.SetPoint ~= nop then
        button:ClearAllPoints()
        button:SetPoint("BOTTOMRIGHT", playerFrame, "TOPRIGHT", (index - 1) % 8 * -(27 + 3) - 60,
                3 + floor((index - 1) / 8) * (27 + 3))
        button.SetPoint = nop
    end
end)

for i = 1, NUM_TEMP_ENCHANT_FRAMES do
    ---@type Button|AuraButtonTemplate
    local button = _G["TempEnchant" .. i]
    button:SetSize(27, 27)
    button:ClearAllPoints()
    button:SetPoint("BOTTOMRIGHT", playerFrame, "TOPRIGHT", (1 - i) * (27 + 3) - 60, 78 + 60)
    button.Border:Hide()
    button.SetAlpha = nop
    button.duration:ClearAllPoints()
    button.duration:SetPoint("TOPRIGHT", 3, 0)
    button.duration:SetFontObject("Game12Font_o1")
    button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
end

TotemFrame:SetParent(playerFrame)

for i = 1, MAX_TOTEMS do
    ---@type Button|TotemButtonTemplate
    local button = _G["TotemFrameTotem" .. i]
    button:SetSize(29, 29)
    button:ClearAllPoints()
    button:SetPoint("RIGHT", playerFrame, (1 - i) * (29 + 0.5), 0)
    button:SetPoint("TOP", UIParent, "BOTTOM", 0, 433 - 2.5)
    button.duration:SetFontObject(font)
    button.duration:SetPoint("TOP", button, "BOTTOM", 0, -1)
end

---@param button Button
hooksecurefunc("TotemButton_Update", function(button)
    ---@type Cooldown
    local cooldown = _G[button:GetName() .. "IconCooldown"]
    cooldown:Hide()
end)

CastingBarFrame:SetSize(360 - 30, 30)
CastingBarFrame:ClearAllPoints()
CastingBarFrame:SetPoint("BOTTOM", 30 * 0.5, 253)
CastingBarFrame.SetPoint = nop
InitializeUnitFrameSpellBar(CastingBarFrame)
PetCastingBarFrame:SetSize(360 - 30, 30)
PetCastingBarFrame:ClearAllPoints()
PetCastingBarFrame:SetPoint("BOTTOM", 30 * 0.5, 253)
PetCastingBarFrame.SetPoint = nop
InitializeUnitFrameSpellBar(PetCastingBarFrame)

---@type Button
local targetFrame = CreateFrame("Button", "WlkTargetFrame", UIParent, "SecureUnitButtonTemplate")
targetFrame:SetSize(playerFrame:GetSize())
targetFrame:SetPoint("BOTTOMRIGHT", -540 - 27, 100 + 42 + 27)
targetFrame.unit = "target"
targetFrame.totFrame = totFrame
targetFrame.showIndicators = 1
targetFrame.showQuestIcon = 1
targetFrame.showPetBattleIcon = 1
targetFrame.showPowerBarAlt = 1
targetFrame.position = "RIGHT"
targetFrame.debuffFrame = CreateUnitFrameAuraFrame(targetFrame, "Debuff", "toRightTop", 16, 8)
targetFrame.debuffFrame:SetPoint("BOTTOMLEFT", targetFrame, "TOPLEFT", (27 + spacing) * 2, spacing)
targetFrame.buffFrame = CreateUnitFrameAuraFrame(targetFrame, "Buff", "toRightTop", 32, 8)
targetFrame.buffFrame:SetPoint("BOTTOMLEFT", targetFrame, "TOPRIGHT", 27 + 5, -27)
targetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
targetFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
InitializeUnitFrame(targetFrame)
targetFrame.powerBarAlt:SetSize(targetFrame:GetWidth() - 27 * 5, 27)
targetFrame.powerBarAlt:SetPoint("TOPLEFT", targetFrame, "BOTTOMLEFT")
CreateUnitFrameSpellBar(targetFrame, "PLAYER_TARGET_CHANGED")
targetFrame.spellBar:SetSize(targetFrame:GetWidth() + 27 - 26 - 4, 30 - 4)
targetFrame.spellBar:SetPoint("BOTTOMLEFT", targetFrame, "TOPLEFT", 2 + 26, 60 + 3 + 2)
InitializeUnitFrameSpellBar(targetFrame.spellBar)

---@type Button
local focusFrame = CreateFrame("Button", "WlkFocusFrame", UIParent, "SecureUnitButtonTemplate")
focusFrame:SetSize(240 - 24 - 2 * 2, 48)
focusFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMRIGHT", -540 + 2 + 2, 30 + 24 + 2)
focusFrame.unit = "focus"
focusFrame.showSelectionHighlight = 1
focusFrame.showIndicators = 1
focusFrame.showQuestIcon = 1
focusFrame.showPetBattleIcon = 1
focusFrame.showPowerBarAlt = 1
focusFrame.position = "RIGHT"
focusFrame.debuffFrame = CreateUnitFrameAuraFrame(focusFrame, "Debuff", "toRightTop", 9, 9)
focusFrame.debuffFrame:SetPoint("BOTTOMLEFT", focusFrame, "TOPLEFT", -2, 2 + 2)
focusFrame.buffFrame = CreateUnitFrameAuraFrame(focusFrame, "Buff", "toRightTop", 18, 9)
focusFrame.buffFrame:SetPoint("BOTTOMLEFT", focusFrame.debuffFrame, "TOPLEFT", 0, 3)
focusFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
focusFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
InitializeUnitFrame(focusFrame)
focusFrame.powerBarAlt:SetSize(focusFrame.debuffFrame:GetWidth() - 24 * 6, 24)
focusFrame.powerBarAlt:SetPoint("TOPLEFT", focusFrame, "BOTTOMLEFT", -2, -2)
CreateUnitFrameSpellBar(focusFrame, "PLAYER_FOCUS_CHANGED")
focusFrame.spellBar:SetSize(240 - 4 - 26, 30 - 4)
focusFrame.spellBar:SetPoint("TOPLEFT", focusFrame, "BOTTOMLEFT", 26, -2 * 2 - 24)
InitializeUnitFrameSpellBar(focusFrame.spellBar)

for i = 1, MAX_BOSS_FRAMES do
    ---@type Button
    local bossFrame = CreateFrame("Button", strconcat("WlkBoss", i, "Frame"), UIParent, "SecureUnitButtonTemplate")
    bossFrame:SetSize(429 - 4 - 24 - 192, 48)
    bossFrame:SetPoint("BOTTOMRIGHT", -298 - 24 - 2, 316 + 2 + (i - 1) * (48 + 2 * 2 + 24 * 2 + 2 + 3 + 5))
    bossFrame.unit = "boss" .. i
    bossFrame.showSelectionHighlight = 1
    bossFrame.showPowerBarAlt = 1
    bossFrame.position = "RIGHT"
    bossFrame.debuffFrame = CreateUnitFrameAuraFrame(bossFrame, "Debuff", "toRightTop", 16, 16)
    bossFrame.debuffFrame:SetPoint("BOTTOMRIGHT", bossFrame, "TOPRIGHT", 2 + 24, 2 + 2)
    bossFrame.buffFrame = CreateUnitFrameAuraFrame(bossFrame, "Buff", "toRightTop", 16, 16)
    bossFrame.buffFrame:SetPoint("BOTTOMRIGHT", bossFrame.debuffFrame, "TOPRIGHT", 0, 3)
    if i == 1 then
        bossFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    end
    bossFrame:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "boss" .. i)
    bossFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
    InitializeUnitFrame(bossFrame)
    bossFrame.powerBarAlt:SetPoint("BOTTOMRIGHT", bossFrame, "BOTTOMLEFT", -2, 0)
    CreateUnitFrameSpellBar(bossFrame, "INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    bossFrame.spellBar:SetSize(192 - 4 - 26, 30 - 4)
    bossFrame.spellBar:SetPoint("TOPRIGHT", bossFrame, "TOPLEFT", -2 - 2, 0)
    InitializeUnitFrameSpellBar(bossFrame.spellBar)
end

---@param self StatusBar
hooksecurefunc("UnitPowerBarAltStatus_ToggleFrame", function(self)
    if self.enabled and GetCVar("statusText") == "1" then
        self:Show()
        UnitPowerBarAltStatus_UpdateText(self)
    else
        self:Hide()
    end
end)

PlayerPowerBarAltStatusFrame:HookScript("OnEvent", function(self, _, ...)
    local cvar = ...
    if cvar == "STATUS_TEXT_DISPLAY" then
        UnitPowerBarAltStatus_ToggleFrame(self)
    end
end)

--- PlayerPowerBarAlt 的宽度
local WIDTH1 = 256
--- PlayerPowerBarAlt 的高度
local HEIGHT1 = 256
--- OrderHallCommandBar 的高度
local HEIGHT2 = 25
local scale = 0.75
PlayerPowerBarAlt:SetScale(scale)
PlayerPowerBarAlt:SetMovable(true)
PlayerPowerBarAlt:SetUserPlaced(true)
---@type Frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event)
    eventFrame:UnregisterEvent(event)
    PlayerPowerBarAlt:ClearAllPoints()
    PlayerPowerBarAlt:SetPoint("CENTER", UIParent, "TOPRIGHT", (-298 - 429 + WIDTH1 * 0.5 * scale) / scale,
            (-HEIGHT2 - HEIGHT1 * 0.5 * scale) / scale)
    PlayerPowerBarAlt:SetMovable(false)
end)
