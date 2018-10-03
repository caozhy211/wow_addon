local addOnName = ...
local auraFilter
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addOn)
    if addOn == addOnName then
        if not AuraFilter then
            AuraFilter = {
                ["blacklist"] = {
                    ["buff"] = {},
                    ["debuff"] = {},
                },
                ["overridelist"] = {
                    ["buff"] = {},
                    ["debuff"] = {},
                },
            }
        end
        auraFilter = AuraFilter
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
------------------------------------------------------------------------------------------------------------------------
-- 友方法術：靈魂石
local friendly = GetSpellInfo(20707)
-- 敵方法術：吸取生命
local hostile = GetSpellInfo(234153)
------------------------------------------------------------------------------------------------------------------------
local function FormatNumber(number)
    if number >= 1e8 then
        return format("%.2f億", number / 1e8)
    elseif number >= 1e6 then
        return format("%d萬", number / 1e4)
    elseif number >= 1e4 then
        return format("%.1f萬", number / 1e4)
    end
    return number
end

local function PositionBar(bar, amount)
    local unit = bar:GetParent().unit
    if amount <= 0 then
        bar:Hide()
        return
    end

    local health = UnitHealth(unit)
    if health <= 0 then
        bar:Hide()
        return
    end

    local maxHealth = UnitHealthMax(unit)
    if maxHealth <= 0 then
        bar:Hide()
        return
    end

    bar:SetMinMaxValues(0, maxHealth)
    bar:SetValue(health + amount)
    bar:Show()
end
------------------------------------------------------------------------------------------------------------------------
local function ResetCamera(portrait)
    portrait:SetPortraitZoom(1)
end

local function ResetGUID(portrait)
    portrait.guid = nil
end

local function UpdatePortrait(portrait)
    local unit = portrait:GetParent().unit
    if not UnitIsVisible(unit) or not UnitIsConnected(unit) then
        portrait:ClearModel()
        portrait:SetModelScale(5.5)
        portrait:SetPosition(0, 0, 0)
        portrait:SetModel("Interface\\Buttons\\talktomequestionmark.m2")
    else
        portrait:ClearModel()
        portrait:SetUnit(unit)
        portrait:SetPortraitZoom(1)
        portrait:SetPosition(0, 0, 0)
    end
end

local function UpdatePortraitGUID(portrait)
    local unit = portrait:GetParent().unit
    local guid = UnitGUID(unit)
    if portrait.guid ~= guid then
        UpdatePortrait(portrait)
    end
    portrait.guid = guid
end
------------------------------------------------------------------------------------------------------------------------
local function UpdatePVPFlag(indicator)
    local unit = indicator:GetParent().unit
    local faction = UnitFactionGroup(unit)
    if UnitIsPVPFreeForAll(unit) then
        indicator.pvp:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
        indicator.pvp:SetTexCoord(0, 1, 0, 1)
        indicator.pvp:Show()
    elseif faction and faction ~= "Neutral" and UnitIsPVP(unit) then
        indicator.pvp:SetTexture(string.format("Interface\\TargetingFrame\\UI-PVP-%s", faction))
        indicator.pvp:SetTexCoord(0, 1, 0, 1)
        indicator.pvp:Show()
    else
        indicator.pvp:Hide()
    end
end

local function UpdateLeader(indicator)
    local unit = indicator:GetParent().unit
    if UnitIsGroupLeader(unit) then
        if HasLFGRestrictions() then
            indicator.leader:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
            indicator.leader:SetTexCoord(0, 0.296875, 0.015625, 0.3125)
        else
            indicator.leader:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
            indicator.leader:SetTexCoord(0, 1, 0, 1)
        end
        indicator.leader:Show()
    elseif UnitIsGroupAssistant(unit) or (UnitInRaid(unit) and IsEveryoneAssistant()) then
        indicator.leader:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
        indicator.leader:SetTexCoord(0, 1, 0, 1)
        indicator.leader:Show()
    else
        indicator.leader:Hide()
    end
end

local function UpdateRaidTarget(indicator)
    local unit = indicator:GetParent().unit
    if UnitExists(unit) and GetRaidTargetIndex(unit) then
        SetRaidTargetIconTexture(indicator.raidTarget, GetRaidTargetIndex(unit))
        indicator.raidTarget:Show()
    else
        indicator.raidTarget:Hide()
    end
end

local function UpdateQuestBoss(indicator)
    local unit = indicator:GetParent().unit
    if UnitIsQuestBoss(unit) then
        indicator.questBoss:Show()
    else
        indicator.questBoss:Hide()
    end
end

local function UpdateStatus(indicator)
    local unit = indicator:GetParent().unit
    if UnitAffectingCombat(unit) then
        indicator.status:SetTexCoord(0.50, 1.0, 0.0, 0.49)
        indicator.status:Show()
    elseif unit == "player" and IsResting() then
        indicator.status:SetTexCoord(0.0, 0.50, 0.0, 0.421875)
        indicator.status:Show()
    else
        indicator.status:Hide()
    end
end
------------------------------------------------------------------------------------------------------------------------
local function UpdateHealthColor(health)
    local unit = health:GetParent().unit
    local color = {}
    if not UnitIsConnected(unit) then
        color.r, color.g, color.b = 0.5, 0.5, 0.5
    elseif unit == "vehicle" then
        color.r, color.g, color.b = 0.23, 0.41, 0.23
    elseif not UnitPlayerControlled(unit) and UnitIsTapDenied(unit) then
        color.r, color.g, color.b = 0.5, 0.5, 0.5
    elseif UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        color = RAID_CLASS_COLORS[class]
    else
        local reaction = UnitReaction(unit, "player")
        if reaction then
            if (reaction > 4) then
                color.r, color.g, color.b = 0, 1, 0
            elseif (reaction == 4) then
                color.r, color.g, color.b = 1, 1, 0
            elseif (reaction < 4) then
                color.r, color.g, color.b = 1, 0, 0
            end
        else
            color.r, color.g, color.b = 1, 0, 0
        end
    end
    health:SetStatusBarColor(color.r, color.g, color.b)
end

local function UpdateHealth(health)
    local unit = health:GetParent().unit
    local currentHealth = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    health:SetMinMaxValues(0, maxHealth)
    health:SetValue(currentHealth)
end
------------------------------------------------------------------------------------------------------------------------
local function UpdatePowerColor(power)
    local unit = power:GetParent().unit
    local color = {}
    local powerID, currentType, altR, altG, altB = UnitPowerType(unit)
    if not UnitIsConnected(unit) then
        color.r, color.g, color.b = 0.5, 0.5, 0.5
    elseif PowerBarColor[currentType] then
        color = PowerBarColor[currentType]
    elseif altR then
        color.r, color.g, color.b = altR, altG, altB
    else
        color = PowerBarColor["MANA"]
    end
    power:SetStatusBarColor(color.r, color.g, color.b)
end

local function UpdatePower(power)
    local unit = power:GetParent().unit
    local currentPower = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    power:SetMinMaxValues(0, maxPower)
    power:SetValue(currentPower)
end
------------------------------------------------------------------------------------------------------------------------
local function UpdateTagGroup(tags)
    local unit = tags:GetParent().unit
    local text = ""
    if UnitInRaid(unit) then
        local name, server = UnitName(unit)
        if server and server ~= "" then
            name = format("%s-%s", name, server)
        end
        for i = 1, GetNumGroupMembers() do
            local raidName, _, group = GetRaidRosterInfo(i)
            if raidName == name then
                text = "(" .. group .. ")"
                break
            end
        end
    end
    tags.group:SetText(text)
end

local function UpdateTagName(tags)
    local unit = tags:GetParent().unit
    tags.name:SetText(UnitName(unit) or "")
end

local function UpdateTagAFK(tags)
    local unit = tags:GetParent().unit
    local text = ""
    if UnitIsAFK(unit) then
        text = "(暫離)"
    elseif UnitIsDND(unit) then
        text = "(勿擾)"
    end
    tags.afk:SetText(text)
end

local function UpdateTagLevel(tags)
    local unit = tags:GetParent().unit
    local text = ""
    local classif = UnitClassification(unit)
    if classif == "worldboss" then
        text = "首領"
    elseif UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
        text = UnitBattlePetLevel(unit)
    else
        local level = UnitLevel(unit)
        text = level > 0 and level or "??"
        if classif == "elite" or classif == "rareelite" then
            text = text .. "+"
        end
    end
    tags.level:SetText(text)
end

local function UpdateTagRace(tags)
    local unit = tags:GetParent().unit
    local text = ""
    if UnitIsPlayer(unit) then
        text = UnitRace(unit)
    else
        text = UnitCreatureFamily(unit) or UnitCreatureType(unit)
    end
    tags.race:SetText(text)
end

local function UpdateTagPercentHealth(tags)
    local unit = tags:GetParent().unit
    local currentHealth = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    local text = maxHealth > 0 and floor(currentHealth / maxHealth * 100 + 0.5) .. "%" or ""
    tags.percentHealth:SetText(text)
end

local function UpdateTagAbsorb(tags)
    local unit = tags:GetParent().unit
    local text = ""
    local absorb = UnitGetTotalAbsorbs(unit)
    if absorb and absorb > 0 then
        text = "+" .. FormatNumber(absorb)
    end
    tags.absorb:SetText(text)
end

local function UpdateTagHealth(tags)
    local unit = tags:GetParent().unit
    local currentHealth = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    local text = maxHealth > 0 and FormatNumber(currentHealth) .. "/" .. FormatNumber(maxHealth) or ""
    tags.health:SetText(text)
end

local function UpdateTagPercentPower(tags)
    local unit = tags:GetParent().unit
    local currentPower = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    local text = maxPower > 0 and floor(currentPower / maxPower * 100 + 0.5) .. "%" or ""
    tags.percentPower:SetText(text)
end

local function UpdateTagPower(tags)
    local unit = tags:GetParent().unit
    local currentPower = UnitPower(unit)
    local maxPower = UnitPowerMax(unit)
    local text = maxPower > 0 and FormatNumber(currentPower) .. "/" .. FormatNumber(maxPower) or ""
    tags.power:SetText(text)
end
------------------------------------------------------------------------------------------------------------------------
local function UpdateHealPrediction(healPrediction)
    local unit = healPrediction:GetParent().unit
    local amount = UnitGetIncomingHeals(unit) or 0
    if amount > 0 then
        amount = amount + (UnitGetTotalHealAbsorbs(unit) or 0)
    end
    PositionBar(healPrediction, amount)
end
------------------------------------------------------------------------------------------------------------------------
local function UpdateHealAbsorb(healAbsorb)
    local unit = healAbsorb:GetParent().unit
    local amount = UnitGetTotalHealAbsorbs(unit) or 0
    PositionBar(healAbsorb, amount)
end
------------------------------------------------------------------------------------------------------------------------
local function UpdateTotalAbsorb(totalAbsorb)
    local unit = totalAbsorb:GetParent().unit
    local amount = UnitGetTotalAbsorbs(unit) or 0
    if amount > 0 then
        amount = amount + (UnitGetIncomingHeals(unit) or 0)
        amount = amount + (UnitGetTotalHealAbsorbs(unit) or 0)
    end
    PositionBar(totalAbsorb, amount)
end
------------------------------------------------------------------------------------------------------------------------
local function UpdateAltPower(altPower)
    local unit = altPower:GetParent().unit
    local _, minPower = UnitAlternatePowerInfo(unit)
    minPower = minPower or 0
    local maxPower = UnitPowerMax(unit, ALTERNATE_POWER_INDEX) or 0
    local currentPower = UnitPower(unit, ALTERNATE_POWER_INDEX) or 0
    altPower:SetMinMaxValues(minPower, maxPower)
    altPower:SetValue(currentPower)

    if maxPower <= 0 then
        return
    end

    if not altPower.text then
        altPower.text = altPower:CreateFontString()
        altPower.text:SetFont(GameFontNormal:GetFont(), 11, "Outline")
        altPower.text:SetPoint("Center")
    end
    local percent = floor(currentPower / maxPower * 100 + 0.5)
    altPower.text:SetText("(" .. percent .. "%) " .. currentPower .. "/" .. maxPower)
end

local function UpdateAltPowerVisibility(altPower)
    local unit = altPower:GetParent().unit
    local barType, minPower, _, _, _, hideFromOthers, showOnRaid = UnitAlternatePowerInfo(unit)
    local visible = false

    if barType and (not hideFromOthers or (showOnRaid and (UnitInRaid(unit) or UnitInParty(unit)))) then
        visible = true
    end

    if visible then
        altPower:Show()
        altPower:RegisterUnitEvent("UNIT_POWER_FREQUENT", unit)
        altPower:RegisterUnitEvent("UNIT_MAXPOWER", unit)
        altPower:RegisterUnitEvent("UNIT_DISPLAYPOWER", unit)
    else
        altPower:Hide()
        altPower:UnregisterEvent("UNIT_POWER_FREQUENT")
        altPower:UnregisterEvent("UNIT_MAXPOWER")
        altPower:UnregisterEvent("UNIT_DISPLAYPOWER")
    end

    if not visible then
        return
    end

    altPower:SetStatusBarColor(0.7, 0.7, 0.6)
    UpdateAltPower(altPower)
end
------------------------------------------------------------------------------------------------------------------------
local function SetAuraButton(parent, frame, type, index, filter, name, texture, count, duration, endTime, caster, spellID)
    spellID = tostring(spellID)
    -- 通過黑名單過濾光環
    if frame.blacklist and (auraFilter.blacklist[type][name] or auraFilter.blacklist[type][spellID]) then
        return
    end

    -- 通過覆蓋名單和施放者過濾光環
    local CasterIsPlayer = caster == "player" or caster == "vehicle" or caster == "pet"
    if not (frame.overridelist and (auraFilter.overridelist[type][name] or auraFilter.overridelist[type][spellID])) and frame.onlyPlayerCast and not CasterIsPlayer then
        return
    end

    frame.totalAuras = frame.totalAuras + 1
    if frame.buttons[frame.totalAuras] then
        local button = frame.buttons[frame.totalAuras]
        button.cooldown:SetCooldown(endTime - duration, duration)
        button.unit = parent:GetParent().unit
        button.auraID = index
        button.filter = filter
        button.icon:SetTexture(texture)
        button.stack:SetText(count > 1 and count or "")
        button:Show()
    end
end

local function CheckAura(parent, frame, type, filter)
    local unit = parent:GetParent().unit

    local index = 0
    while true do
        index = index + 1
        local name, texture, count, auraType, duration, endTime, caster, isRemovable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff = UnitAura(unit, index, filter)
        if not name then
            break
        end
        SetAuraButton(parent, frame, type, index, filter, name, texture, count, duration, endTime, caster, spellID)
        if frame.totalAuras >= frame.maxAuras then
            break
        end
    end

    for i = frame.totalAuras + 1, #(frame.buttons) do
        frame.buttons[i]:Hide()
    end
end

local function UpdateAura(auras)
    if auras.buffs then
        auras.buffs.totalAuras = 0
        CheckAura(auras, auras.buffs, "buff", "HELPFUL")
    end

    if auras.debuffs then
        auras.debuffs.totalAuras = 0
        CheckAura(auras, auras.debuffs, "debuff", "HARMFUL")
    end
end

local function CreateAuraButtons(parent, size, spacing, direction, numPerLine)
    local buttons = {}
    for i = 1, parent.maxAuras do
        local button = CreateFrame("Button", nil, parent)
        buttons[i] = button

        button.cooldown = CreateFrame("Cooldown", parent:GetName() .. "Button" .. i .. "Cooldown", button, "CooldownFrameTemplate")
        button.cooldown:SetAllPoints(button)
        button.cooldown:SetReverse(true)
        button.cooldown:SetDrawEdge(false)
        button.cooldown:SetDrawSwipe(true)
        button.cooldown:SetSwipeColor(0, 0, 0, 0.8)

        button.stack = button:CreateFontString()
        button.stack:SetFont(GameFontNormal:GetFont(), 12, "Outline")
        button.stack:SetPoint("BottomRight")

        button.icon = button:CreateTexture()
        button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        button.icon:SetAllPoints(button)

        button:SetSize(size, size)
        if direction == "right" then
            if i == 1 then
                button:SetPoint("BottomLeft", parent)
            elseif i % numPerLine == 1 then
                button:SetPoint("Bottom", buttons[i - numPerLine], "Top", 0, 1)
            else
                button:SetPoint("Left", buttons[i - 1], "Right", spacing, 0)
            end
        else
            if i == 1 then
                button:SetPoint("BottomRight", parent)
            elseif i % numPerLine == 1 then
                button:SetPoint("Bottom", buttons[i - numPerLine], "Top", 0, 1)
            else
                button:SetPoint("Right", buttons[i - 1], "Left", -spacing, 0)
            end
        end
        button:Hide()

        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 30, -12)
            GameTooltip:SetUnitAura(self.unit, self.auraID, self.filter)
            self:SetScript("OnUpdate", function(self)
                GameTooltip:SetUnitAura(self.unit, self.auraID, self.filter)
            end)
        end)
        button:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            self:SetScript("OnUpdate", nil)
        end)

        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", function(self, mouse)
            if mouse == "LeftButton" then
                local auraName = UnitAura(self.unit, self.auraID, self.filter)
                local type = self.filter == "HELPFUL" and "buff" or "debuff"
                auraFilter.blacklist[type][auraName] = true
                UpdateAura(parent:GetParent())
            else
                if InCombatLockdown() or (not UnitIsUnit(self.unit, "player") and not UnitIsUnit(self.unit, "vehicle")) then
                    return
                end

                CancelUnitBuff(self.unit, self.auraID, self.filter)
            end
        end)
    end
    return buttons
end
------------------------------------------------------------------------------------------------------------------------
local function UpdateComboPoint(comboPoints)
    local parent = comboPoints:GetParent()
    local unit = parent.unit
    local maxPoints = UnitPowerMax(unit, Enum.PowerType.ComboPoints)
    if maxPoints > 0 then
        if #(comboPoints.points) ~= maxPoints then
            for i = 1, maxPoints do
                local point = comboPoints:CreateTexture()
                point:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                local color = PowerBarColor["COMBO_POINTS"]
                point:SetColorTexture(color.r, color.g, color.b, 1)
                local width = (comboPoints:GetWidth() - (maxPoints - 1) * 5) / maxPoints
                point:SetSize(width, comboPoints:GetHeight())
                point:SetPoint("Left", comboPoints, (width + 5) * (i - 1), 0)
                comboPoints.points[i] = point
            end
        end

        local currentPoints
        if unit == "vehicle" then
            currentPoints = GetComboPoints(unit)
            if currentPoints == 0 then
                currentPoints = GetComboPoints(unit, "vehicle")
            end
        else
            currentPoints = UnitPower(unit, Enum.PowerType.ComboPoints)
        end

        if currentPoints > 0 then
            for i = 1, #(comboPoints.points) do
                comboPoints.points[i]:SetAlpha(i > currentPoints and 0.15 or 1)
            end

            comboPoints:Show()
        else
            comboPoints:Hide()
        end
    else
        comboPoints:Hide()
        table.wipe(comboPoints.points)
    end
end
------------------------------------------------------------------------------------------------------------------------
local function CheckRange(frame)
    local unit = frame.unit
    local spell
    if (UnitCanAssist("player", unit)) then
        spell = friendly
    elseif (UnitCanAttack("player", unit)) then
        spell = hostile
    end

    if spell then
        frame:SetAlpha(IsSpellInRange(spell, unit) == 1 and 1 or 0.55)
    else
        frame:SetAlpha(CheckInteractDistance(unit, 1) and 1 or 0.55)
    end
end
------------------------------------------------------------------------------------------------------------------------
local function UpdateHighlight(frame)
    local unit = frame.unit
    if UnitIsUnit(unit, "target") then
        if not frame.highlightTop then
            frame.highlightTop = frame:CreateTexture()
            frame.highlightTop:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
            frame.highlightTop:SetColorTexture(1, 1, 0)
            frame.highlightTop:SetSize(frame:GetWidth(), 2)
            frame.highlightTop:SetPoint("Bottom", frame, "Top")

            frame.highlightBottom = frame:CreateTexture()
            frame.highlightBottom:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
            frame.highlightBottom:SetColorTexture(1, 1, 0)
            frame.highlightBottom:SetSize(frame:GetWidth(), 2)
            frame.highlightBottom:SetPoint("Top", frame, "Bottom")

            frame.highlightLeft = frame:CreateTexture()
            frame.highlightLeft:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
            frame.highlightLeft:SetColorTexture(1, 1, 0)
            frame.highlightLeft:SetSize(2, frame:GetHeight() + 4)
            frame.highlightLeft:SetPoint("Right", frame, "Left")

            frame.highlightRight = frame:CreateTexture()
            frame.highlightRight:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
            frame.highlightRight:SetColorTexture(1, 1, 0)
            frame.highlightRight:SetSize(2, frame:GetHeight() + 4)
            frame.highlightRight:SetPoint("Left", frame, "Right")
        end

        frame.highlightTop:Show()
        frame.highlightBottom:Show()
        frame.highlightLeft:Show()
        frame.highlightRight:Show()
    elseif frame.highlightTop then
        frame.highlightTop:Hide()
        frame.highlightBottom:Hide()
        frame.highlightLeft:Hide()
        frame.highlightRight:Hide()
    end
end
------------------------------------------------------------------------------------------------------------------------
local target = CreateFrame("Button", "UnitTargetFrame", UIParent, "SecureUnitButtonTemplate")
target:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
target:SetBackdropColor(0, 0, 0, 0.8)
target:SetSize(300, 60)
target:SetPoint("Bottom", 270, 185)

target:SetAttribute("unit", "target")
RegisterUnitWatch(target, false)

target:RegisterForClicks("AnyUp")
target:SetAttribute("*type2", "togglemenu")

target.unit = "target"
target:SetScript("OnEnter", function(self)
    UnitFrame_OnEnter(self)
end)
target:SetScript("OnLeave", function(self)
    UnitFrame_OnLeave(self)
end)

target:RegisterEvent("PLAYER_TARGET_CHANGED")
target:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "target")
target:SetScript("OnEvent", function(self)
    UpdatePortraitGUID(self.portrait)
    UpdatePVPFlag(self.indicator)
    UpdateLeader(self.indicator)
    UpdateRaidTarget(self.indicator)
    UpdateQuestBoss(self.indicator)
    UpdateHealth(self.health)
    UpdateHealthColor(self.health)
    UpdatePower(self.power)
    UpdatePowerColor(self.power)
    UpdateTagGroup(self.tags)
    UpdateTagName(self.tags)
    UpdateTagAFK(self.tags)
    UpdateTagLevel(self.tags)
    UpdateTagRace(self.tags)
    UpdateTagPercentHealth(self.tags)
    UpdateTagHealth(self.tags)
    UpdateTagAbsorb(self.tags)
    UpdateTagPercentPower(self.tags)
    UpdateTagPower(self.tags)
    UpdateHealPrediction(self.healPrediction)
    UpdateHealAbsorb(self.healAbsorb)
    UpdateTotalAbsorb(self.totalAbsorb)
    UpdateAltPowerVisibility(self.altPower)
    UpdateAura(self.auras)
end)

target:SetScript("OnUpdate", CheckRange)
------------------------------------------------------------------------------------------------------------------------
target.portrait = CreateFrame("PlayerModel", nil, target)
target.portrait:SetSize(58, 58)
target.portrait:SetPoint("Right", -1, 1)

target.portrait:SetScript("OnShow", ResetCamera)
target.portrait:SetScript("OnHide", ResetGUID)

target.portrait:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "target")
target.portrait:RegisterUnitEvent("UNIT_MODEL_CHANGED", "target")
target.portrait:SetScript("OnEvent", function(self, event)
    if event == "UNIT_MODEL_CHANGED" then
        UpdatePortrait(self)
    end
    if event == "UNIT_PORTRAIT_UPDATE" then
        UpdatePortraitGUID(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
target.indicator = CreateFrame("Frame", nil, target)
target.indicator:SetSize(target.portrait:GetSize())
target.indicator:SetAllPoints(target.portrait)

target.indicator.pvp = target.indicator:CreateTexture(nil, "Overlay")
target.indicator.pvp:SetPoint("TopRight", 15, 0)
target.indicator.pvp:SetSize(35, 35)
target.indicator.leader = target.indicator:CreateTexture(nil, "Overlay")
target.indicator.leader:SetPoint("TopLeft")
target.indicator.leader:SetSize(16, 16)
target.indicator.raidTarget = target.indicator:CreateTexture(nil, "Overlay")
target.indicator.raidTarget:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
target.indicator.raidTarget:SetPoint("BottomLeft")
target.indicator.raidTarget:SetSize(18, 18)
target.indicator.questBoss = target.indicator:CreateTexture(nil, "Overlay")
target.indicator.questBoss:SetTexture("Interface\\TargetingFrame\\PortraitQuestBadge")
target.indicator.questBoss:SetPoint("BottomRight", 5, 0)
target.indicator.questBoss:SetSize(20, 20)

target.indicator:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", "target")
target.indicator:RegisterUnitEvent("UNIT_FACTION", "target")
target.indicator:RegisterEvent("PARTY_LEADER_CHANGED")
target.indicator:RegisterEvent("GROUP_ROSTER_UPDATE")
target.indicator:RegisterEvent("RAID_TARGET_UPDATE")
target.indicator:RegisterUnitEvent("UNIT_CLASSIFICATION_CHANGED", "target")
target.indicator:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_FLAGS_CHANGED" or event == "UNIT_FACTION" then
        UpdatePVPFlag(self)
    end
    if event == "PARTY_LEADER_CHANGED" or event == "GROUP_ROSTER_UPDATE" then
        UpdateLeader(self)
    end
    if event == "RAID_TARGET_UPDATE" then
        UpdateRaidTarget(self)
    end
    if event == "UNIT_CLASSIFICATION_CHANGED" then
        UpdateQuestBoss(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
target.health = CreateFrame("StatusBar", nil, target)
target.health:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
target.health:SetSize(240, 40)
target.health:SetPoint("TopLeft")

target.health.bg = target.health:CreateTexture(nil, "Background")
target.health.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Bg")
target.health.bg:SetTexCoord(0, 1, 0, 0.53125)
target.health.bg:SetAllPoints(target.health)

target.health:RegisterUnitEvent("UNIT_HEALTH", "target")
target.health:RegisterUnitEvent("UNIT_MAXHEALTH", "target")
target.health:RegisterUnitEvent("UNIT_CONNECTION", "target")
target.health:RegisterUnitEvent("UNIT_FACTION", "target")
target.health:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "target")
target.health:SetScript("OnEvent", function(self, event)
    if event == "UNIT_FACTION" or event == "UNIT_CONNECTION" then
        UpdateHealthColor(self)
    end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        UpdateHealth(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
target.power = CreateFrame("StatusBar", nil, target)
target.power:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill")
target.power:SetSize(240, 20)
target.power:SetPoint("Top", target.health, "Bottom")

target.power.bg = target.power:CreateTexture(nil, "Background")
target.power.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Background")
target.power.bg:SetAllPoints(target.power)

target.power:RegisterUnitEvent("UNIT_POWER_FREQUENT", "target")
target.power:RegisterUnitEvent("UNIT_MAXPOWER", "target")
target.power:RegisterUnitEvent("UNIT_CONNECTION", "target")
target.power:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "target")
target.power:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "target")
target.power:RegisterUnitEvent("UNIT_DISPLAYPOWER", "target")
target.power:RegisterUnitEvent("UNIT_MANA", "target")
target.power:SetScript("OnEvent", function(self, event)
    if event == "UNIT_DISPLAYPOWER" or event == "UNIT_CONNECTION" then
        UpdatePowerColor(self)
    end
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" or event == "UNIT_POWER_BAR_SHOW" or event ==
            "UNIT_POWER_BAR_HIDE" or event == "UNIT_MANA" then
        UpdatePower(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
target.tags = CreateFrame("Frame", nil, target)
target.tags:SetSize(240, 60)
target.tags:SetPoint("Left")

target.tags.name = target.tags:CreateFontString()
target.tags.name:SetFont(GameFontNormal:GetFont(), 11, "Outline")
target.tags.name:SetPoint("Left", target.health, "TopLeft", 0, -9)
target.tags.group = target.tags:CreateFontString()
target.tags.group:SetFont(GameFontNormal:GetFont(), 11, "Outline")
target.tags.group:SetPoint("Left", target.tags.name, "Right")
target.tags.afk = target.tags:CreateFontString()
target.tags.afk:SetFont(GameFontNormal:GetFont(), 11, "Outline")
target.tags.afk:SetPoint("Left", target.tags.group, "Right")
target.tags.race = target.tags:CreateFontString()
target.tags.race:SetFont(GameFontNormal:GetFont(), 11, "Outline")
target.tags.race:SetPoint("Right", target.health, "TopRight", 0, -9)
target.tags.level = target.tags:CreateFontString()
target.tags.level:SetFont(GameFontNormal:GetFont(), 11, "Outline")
target.tags.level:SetPoint("Right", target.tags.race, "Left")
target.tags.percentHealth = target.tags:CreateFontString()
target.tags.percentHealth:SetFont(GameFontNormal:GetFont(), 11, "Outline")
target.tags.percentHealth:SetPoint("Left", target.health, "BottomLeft", 0, 9)
target.tags.absorb = target.tags:CreateFontString()
target.tags.absorb:SetFont(GameFontNormal:GetFont(), 11, "Outline")
target.tags.absorb:SetPoint("Right", target.health, "BottomRight", 0, 9)
target.tags.health = target.tags:CreateFontString()
target.tags.health:SetFont(GameFontNormal:GetFont(), 11, "Outline")
target.tags.health:SetPoint("Right", target.tags.absorb, "Left")
target.tags.percentPower = target.tags:CreateFontString()
target.tags.percentPower:SetFont(GameFontNormal:GetFont(), 11, "Outline")
target.tags.percentPower:SetPoint("Left", target.power)
target.tags.power = target.tags:CreateFontString()
target.tags.power:SetFont(GameFontNormal:GetFont(), 11, "Outline")
target.tags.power:SetPoint("Right", target.power)

target.tags:RegisterEvent("GROUP_ROSTER_UPDATE")
target.tags:RegisterUnitEvent("UNIT_NAME_UPDATE", "target")
target.tags:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", "target")
target.tags:RegisterUnitEvent("UNIT_LEVEL", "target")
target.tags:RegisterEvent("PLAYER_LEVEL_UP")
target.tags:RegisterUnitEvent("UNIT_CLASSIFICATION_CHANGED", "target")
target.tags:RegisterUnitEvent("UNIT_HEALTH", "target")
target.tags:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "target")
target.tags:RegisterUnitEvent("UNIT_MAXHEALTH", "target")
target.tags:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "target")
target.tags:RegisterUnitEvent("UNIT_POWER_FREQUENT", "target")
target.tags:RegisterUnitEvent("UNIT_MAXPOWER", "target")
target.tags:SetScript("OnEvent", function(self, event)
    if event == "GROUP_ROSTER_UPDATE" then
        UpdateTagGroup(self)
    end
    if event == "UNIT_NAME_UPDATE" then
        UpdateTagName(self)
    end
    if event == "PLAYER_FLAGS_CHANGED" then
        UpdateTagAFK(self)
    end
    if event == "UNIT_LEVEL" or event == "PLAYER_LEVEL_UP" or event == "UNIT_CLASSIFICATION_CHANGED" then
        UpdateTagLevel(self)
    end
    if event == "UNIT_CLASSIFICATION_CHANGED" then
        UpdateTagRace(self)
    end
    if event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" or event == "UNIT_MAXHEALTH" then
        UpdateTagPercentHealth(self)
        UpdateTagHealth(self)
    end
    if event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        UpdateTagAbsorb(self)
    end
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" then
        UpdateTagPercentPower(self)
        UpdateTagPower(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
target.healPrediction = CreateFrame("StatusBar", nil, target)
target.healPrediction:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill", "Border")
target.healPrediction:SetStatusBarColor(0.0, 0.659, 0.608)
target.healPrediction:SetSize(target.health:GetSize())
target.healPrediction:SetAllPoints(target.health)
target.healPrediction:Hide()

target.healPrediction:RegisterUnitEvent("UNIT_MAXHEALTH", "target")
target.healPrediction:RegisterUnitEvent("UNIT_HEALTH", "target")
target.healPrediction:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "target")
target.healPrediction:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "target")
target.healPrediction:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "target")
target.healPrediction:SetScript("OnEvent", function(self)
    UpdateHealPrediction(self)
end)
------------------------------------------------------------------------------------------------------------------------
target.healAbsorb = CreateFrame("StatusBar", nil, target)
target.healAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Absorb-Fill", "Border")
target.healAbsorb:SetSize(target.health:GetSize())
target.healAbsorb:SetAllPoints(target.health)
target.healAbsorb:Hide()

target.healPrediction:RegisterUnitEvent("UNIT_MAXHEALTH", "target")
target.healPrediction:RegisterUnitEvent("UNIT_HEALTH", "target")
target.healPrediction:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "target")
target.healPrediction:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "target")
target.healAbsorb:SetScript("OnEvent", function(self)
    UpdateHealAbsorb(self)
end)
------------------------------------------------------------------------------------------------------------------------
target.totalAbsorb = CreateFrame("StatusBar", nil, target)
target.totalAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill", "Border")
target.totalAbsorb:SetSize(target.health:GetSize())
target.totalAbsorb:SetAllPoints(target.health)
target.totalAbsorb:Hide()

target.totalAbsorb:RegisterUnitEvent("UNIT_MAXHEALTH", "target")
target.totalAbsorb:RegisterUnitEvent("UNIT_HEALTH", "target")
target.totalAbsorb:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "target")
target.totalAbsorb:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "target")
target.totalAbsorb:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "target")
target.totalAbsorb:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "target")
target.totalAbsorb:SetScript("OnEvent", function(self)
    UpdateTotalAbsorb(self)
end)
------------------------------------------------------------------------------------------------------------------------
target.altPower = CreateFrame("StatusBar", nil, target)
target.altPower:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill")
target.altPower:SetSize(240, 12)
target.altPower:SetPoint("BottomLeft", target)

target.altPower:SetScript("OnShow", function(self)
    local parent = self:GetParent()
    parent.health:SetHeight(32)
    parent.power:SetHeight(16)
end)
target.altPower:SetScript("OnHide", function(self)
    local parent = self:GetParent()
    parent.health:SetHeight(40)
    parent.power:SetHeight(20)
end)

target.altPower:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "target")
target.altPower:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "target")
target.altPower:RegisterEvent("PLAYER_ENTERING_WORLD")
target.altPower:SetScript("OnEvent", function(self, event)
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        UpdateAltPower(self)
    end
    if event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" or event == "PLAYER_ENTERING_WORLD" then
        UpdateAltPowerVisibility(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
target.auras = CreateFrame("Frame", nil, target)

target.auras.debuffs = CreateFrame("Frame", "MyUnitTargetDebuff", target.auras)
target.auras.debuffs:SetSize(300, 34)
target.auras.debuffs:SetPoint("Bottom", target, "Top", 0, 1)

target.auras.debuffs.maxAuras = 8
target.auras.debuffs.onlyPlayerCast = true
target.auras.debuffs.blacklist = true
target.auras.debuffs.overridelist = true

target.auras.debuffs.buttons = CreateAuraButtons(target.auras.debuffs, 34, 4, "right", 8)
------------------------------------------------------------------------------------------------------------------------
target.auras.buffs = CreateFrame("Frame", "MyUnitTargetBuff", target.auras)
target.auras.buffs:SetSize(300, 34)
target.auras.buffs:SetPoint("Top", target, "Bottom", 0, -1)

target.auras.buffs.maxAuras = 8

target.auras.buffs.buttons = CreateAuraButtons(target.auras.buffs, 34, 4, "right", 8)

target.auras:RegisterEvent("PLAYER_ENTERING_WORLD")
target.auras:RegisterUnitEvent("UNIT_AURA", "target")
target.auras:SetScript("OnEvent", function(self)
    UpdateAura(self)
end)
------------------------------------------------------------------------------------------------------------------------
local player = CreateFrame("Button", "UnitPlayerFrame", UIParent, "SecureUnitButtonTemplate")
player:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
player:SetBackdropColor(0, 0, 0, 0.8)
player:SetSize(300, 60)
player:SetPoint("Bottom", -270, 185)

player:SetAttribute("unit", "player")
RegisterUnitWatch(player, false)

player:RegisterForClicks("AnyUp")
player:SetAttribute("*type1", "target")
player:SetAttribute("*type2", "togglemenu")

player.unit = "player"
player:SetScript("OnEnter", function(self)
    UnitFrame_OnEnter(self)
end)
player:SetScript("OnLeave", function(self)
    UnitFrame_OnLeave(self)
end)

player:RegisterEvent("PLAYER_LOGIN")
player:RegisterEvent("PLAYER_ALIVE")
player:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
player:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
player:SetScript("OnEvent", function(self, event)
    if event == "UNIT_ENTERED_VEHICLE" then
        if UnitHasVehicleUI("player") and UnitHasVehiclePlayerFrameUI("player") then
            self.unit = "vehicle"
        end
    elseif event == "UNIT_EXITING_VEHICLE" then
        self.unit = "player"
    end
    UpdatePortraitGUID(self.portrait)
    UpdatePVPFlag(self.indicator)
    UpdateLeader(self.indicator)
    UpdateRaidTarget(self.indicator)
    UpdateStatus(self.indicator)
    UpdateHealth(self.health)
    UpdateHealthColor(self.health)
    UpdatePower(self.power)
    UpdatePowerColor(self.power)
    UpdateTagGroup(self.tags)
    UpdateTagName(self.tags)
    UpdateTagAFK(self.tags)
    UpdateTagLevel(self.tags)
    UpdateTagRace(self.tags)
    UpdateTagPercentHealth(self.tags)
    UpdateTagAbsorb(self.tags)
    UpdateTagHealth(self.tags)
    UpdateTagPercentPower(self.tags)
    UpdateTagPower(self.tags)
    UpdateHealPrediction(self.healPrediction)
    UpdateHealAbsorb(self.healAbsorb)
    UpdateTotalAbsorb(self.totalAbsorb)
    UpdateAura(self.auras)
    UpdateComboPoint(self.comboPoints)
end)
------------------------------------------------------------------------------------------------------------------------
player.portrait = CreateFrame("PlayerModel", nil, player)
player.portrait:SetSize(58, 58)
player.portrait:SetPoint("Left", 1, 1)

player.portrait:SetScript("OnShow", ResetCamera)
player.portrait:SetScript("OnHide", ResetGUID)

player.portrait:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player", "vehicle")
player.portrait:RegisterUnitEvent("UNIT_MODEL_CHANGED", "player", "vehicle")
player.portrait:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    if event == "UNIT_MODEL_CHANGED" then
        UpdatePortrait(self)
    end
    if event == "UNIT_PORTRAIT_UPDATE" then
        UpdatePortraitGUID(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
player.indicator = CreateFrame("Frame", nil, player)
player.indicator:SetSize(player.portrait:GetSize())
player.indicator:SetAllPoints(player.portrait)

player.indicator.pvp = player.indicator:CreateTexture(nil, "Overlay")
player.indicator.pvp:SetPoint("TopRight", 15, 0)
player.indicator.pvp:SetSize(35, 35)
player.indicator.leader = player.indicator:CreateTexture(nil, "Overlay")
player.indicator.leader:SetPoint("TopLeft")
player.indicator.leader:SetSize(16, 16)
player.indicator.status = player.indicator:CreateTexture(nil, "Overlay")
player.indicator.status:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
player.indicator.status:SetPoint("BottomLeft")
player.indicator.status:SetSize(20, 20)
player.indicator.raidTarget = player.indicator:CreateTexture(nil, "Overlay")
player.indicator.raidTarget:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
player.indicator.raidTarget:SetPoint("BottomRight")
player.indicator.raidTarget:SetSize(18, 18)

player.indicator:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", "player")
player.indicator:RegisterEvent("PARTY_LEADER_CHANGED")
player.indicator:RegisterEvent("GROUP_ROSTER_UPDATE")
player.indicator:RegisterEvent("RAID_TARGET_UPDATE")
player.indicator:RegisterEvent("PLAYER_REGEN_ENABLED")
player.indicator:RegisterEvent("PLAYER_REGEN_DISABLED")
player.indicator:RegisterEvent("PLAYER_UPDATE_RESTING")
player.indicator:RegisterEvent("UPDATE_FACTION")
player.indicator:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_FLAGS_CHANGED" or event == "UNIT_FACTION" then
        UpdatePVPFlag(self)
    end
    if event == "PARTY_LEADER_CHANGED" or event == "GROUP_ROSTER_UPDATE" then
        UpdateLeader(self)
    end
    if event == "RAID_TARGET_UPDATE" then
        UpdateRaidTarget(self)
    end
    if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_UPDATE_RESTING" then
        UpdateStatus(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
player.health = CreateFrame("StatusBar", nil, player)
player.health:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
player.health:SetSize(240, 40)
player.health:SetPoint("TopRight")

player.health.bg = player.health:CreateTexture(nil, "Background")
player.health.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Bg")
player.health.bg:SetTexCoord(0, 1, 0, 0.53125)
player.health.bg:SetAllPoints(player.health)

player.health:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "player", "vehicle")
player.health:RegisterUnitEvent("UNIT_HEALTH", "player", "vehicle")
player.health:RegisterUnitEvent("UNIT_MAXHEALTH", "player", "vehicle")
player.health:RegisterUnitEvent("UNIT_CONNECTION", "player", "vehicle")
player.health:RegisterUnitEvent("UNIT_FACTION", "player", "vehicle")
player.health:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "player", "vehicle")
player.health:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    if event == "UNIT_FACTION" or event == "UNIT_CONNECTION" or event == "UNIT_TARGETABLE_CHANGED" then
        UpdateHealthColor(self)
    end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        UpdateHealth(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
player.power = CreateFrame("StatusBar", nil, player)
player.power:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill")
player.power:SetSize(240, 20)
player.power:SetPoint("Top", player.health, "Bottom")

player.power.bg = player.power:CreateTexture(nil, "Background")
player.power.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Background")
player.power.bg:SetAllPoints(player.power)

player.power:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player", "vehicle")
player.power:RegisterUnitEvent("UNIT_MAXPOWER", "player", "vehicle")
player.power:RegisterUnitEvent("UNIT_CONNECTION", "player", "vehicle")
player.power:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "player", "vehicle")
player.power:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "player", "vehicle")
player.power:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player", "vehicle")
player.power:RegisterUnitEvent("UNIT_MANA", "player", "vehicle")
player.power:RegisterEvent("PLAYER_UNGHOST")
player.power:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    if event == "UNIT_DISPLAYPOWER" or event == "UNIT_CONNECTION" then
        UpdatePowerColor(self)
    end
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" or event == "UNIT_POWER_BAR_SHOW" or event ==
            "UNIT_POWER_BAR_HIDE" or event == "UNIT_MANA" or event == "PLAYER_UNGHOST" then
        UpdatePower(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
player.tags = CreateFrame("Frame", nil, player)
player.tags:SetSize(240, 60)
player.tags:SetPoint("Right")

player.tags.name = player.tags:CreateFontString()
player.tags.name:SetFont(GameFontNormal:GetFont(), 11, "Outline")
player.tags.name:SetPoint("Right", player.health, "TopRight", 0, -9)
player.tags.group = player.tags:CreateFontString()
player.tags.group:SetFont(GameFontNormal:GetFont(), 11, "Outline")
player.tags.group:SetPoint("Right", player.tags.name, "Left")
player.tags.afk = player.tags:CreateFontString()
player.tags.afk:SetFont(GameFontNormal:GetFont(), 11, "Outline")
player.tags.afk:SetPoint("Right", player.tags.group, "Left")
player.tags.race = player.tags:CreateFontString()
player.tags.race:SetFont(GameFontNormal:GetFont(), 11, "Outline")
player.tags.race:SetPoint("Left", player.health, "TopLeft", 0, -9)
player.tags.level = player.tags:CreateFontString()
player.tags.level:SetFont(GameFontNormal:GetFont(), 11, "Outline")
player.tags.level:SetPoint("Left", player.tags.race, "Right")
player.tags.percentHealth = player.tags:CreateFontString()
player.tags.percentHealth:SetFont(GameFontNormal:GetFont(), 11, "Outline")
player.tags.percentHealth:SetPoint("Right", player.health, "BottomRight", 0, 9)
player.tags.health = player.tags:CreateFontString()
player.tags.health:SetFont(GameFontNormal:GetFont(), 11, "Outline")
player.tags.health:SetPoint("Left", player.health, "BottomLeft", 0, 9)
player.tags.absorb = player.tags:CreateFontString()
player.tags.absorb:SetFont(GameFontNormal:GetFont(), 11, "Outline")
player.tags.absorb:SetPoint("Left", player.tags.health, "Right")
player.tags.percentPower = player.tags:CreateFontString()
player.tags.percentPower:SetFont(GameFontNormal:GetFont(), 11, "Outline")
player.tags.percentPower:SetPoint("Right", player.power)
player.tags.power = player.tags:CreateFontString()
player.tags.power:SetFont(GameFontNormal:GetFont(), 11, "Outline")
player.tags.power:SetPoint("Left", player.power)

player.tags:RegisterEvent("GROUP_ROSTER_UPDATE")
player.tags:RegisterEvent("PLAYER_LEVEL_UP")
player.tags:RegisterUnitEvent("UNIT_NAME_UPDATE", "player", "vehicle")
player.tags:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", "player", "vehicle")
player.tags:RegisterUnitEvent("UNIT_LEVEL", "player", "vehicle")
player.tags:RegisterUnitEvent("UNIT_CLASSIFICATION_CHANGED", "player", "vehicle")
player.tags:RegisterUnitEvent("UNIT_HEALTH", "player", "vehicle")
player.tags:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "player", "vehicle")
player.tags:RegisterUnitEvent("UNIT_MAXHEALTH", "player", "vehicle")
player.tags:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "player", "vehicle")
player.tags:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player", "vehicle")
player.tags:RegisterUnitEvent("UNIT_MAXPOWER", "player", "vehicle")
player.tags:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    if event == "GROUP_ROSTER_UPDATE" then
        UpdateTagGroup(self)
    end
    if event == "UNIT_NAME_UPDATE" then
        UpdateTagName(self)
    end
    if event == "PLAYER_FLAGS_CHANGED" then
        UpdateTagAFK(self)
    end
    if event == "UNIT_LEVEL" or event == "UNIT_CLASSIFICATION_CHANGED" or "PLAYER_LEVEL_UP" then
        UpdateTagLevel(self)
    end
    if event == "UNIT_CLASSIFICATION_CHANGED" then
        UpdateTagRace(self)
    end
    if event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" or event == "UNIT_MAXHEALTH" then
        UpdateTagPercentHealth(self)
        UpdateTagHealth(self)
    end
    if event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        UpdateTagAbsorb(self)
    end
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" then
        UpdateTagPercentPower(self)
        UpdateTagPower(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
player.healPrediction = CreateFrame("StatusBar", nil, player)
player.healPrediction:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill", "Border")
player.healPrediction:SetStatusBarColor(0.0, 0.659, 0.608)
player.healPrediction:SetSize(player.health:GetSize())
player.healPrediction:SetAllPoints(player.health)
player.healPrediction:Hide()

player.healPrediction:RegisterUnitEvent("UNIT_MAXHEALTH", "player", "vehicle")
player.healPrediction:RegisterUnitEvent("UNIT_HEALTH", "player", "vehicle")
player.healPrediction:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "player", "vehicle")
player.healPrediction:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "player", "vehicle")
player.healPrediction:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "player", "vehicle")
player.healPrediction:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    UpdateHealPrediction(self)
end)
------------------------------------------------------------------------------------------------------------------------
player.healAbsorb = CreateFrame("StatusBar", nil, player)
player.healAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Absorb-Fill", "Border")
player.healAbsorb:SetSize(player.health:GetSize())
player.healAbsorb:SetAllPoints(player.health)
player.healAbsorb:Hide()

player.healAbsorb:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
player.healAbsorb:RegisterUnitEvent("UNIT_HEALTH", "player")
player.healAbsorb:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "player")
player.healAbsorb:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "player", "vehicle")
player.healAbsorb:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    UpdateHealAbsorb(self)
end)
------------------------------------------------------------------------------------------------------------------------
player.totalAbsorb = CreateFrame("StatusBar", nil, player)
player.totalAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill", "Border")
player.totalAbsorb:SetSize(player.health:GetSize())
player.totalAbsorb:SetAllPoints(player.health)
player.totalAbsorb:Hide()

player.totalAbsorb:RegisterUnitEvent("UNIT_MAXHEALTH", "player", "vehicle")
player.totalAbsorb:RegisterUnitEvent("UNIT_HEALTH", "player", "vehicle")
player.totalAbsorb:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "player", "vehicle")
player.totalAbsorb:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "player", "vehicle")
player.totalAbsorb:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "player", "vehicle")
player.totalAbsorb:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "player", "vehicle")
player.totalAbsorb:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    UpdateTotalAbsorb(self)
end)
------------------------------------------------------------------------------------------------------------------------
player.comboPoints = CreateFrame("Frame", nil, player)
player.comboPoints:SetSize(240, 12)
player.comboPoints:SetPoint("BottomRight", player)

player.comboPoints.points = {}

player.comboPoints:SetScript("OnShow", function(self)
    local parent = self:GetParent()
    parent.health:SetHeight(32)
    parent.power:SetHeight(16)
end)
player.comboPoints:SetScript("OnHide", function(self)
    local parent = self:GetParent()
    parent.health:SetHeight(40)
    parent.power:SetHeight(20)
end)

player.comboPoints:RegisterUnitEvent("UNIT_POWER_UPDATE", "player", "vehicle")
player.comboPoints:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player", "vehicle")
player.comboPoints:RegisterUnitEvent("UNIT_MAXPOWER", "player", "vehicle")
player.comboPoints:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    UpdateComboPoint(self)
end)
------------------------------------------------------------------------------------------------------------------------
player.auras = CreateFrame("Frame", nil, player)

player.auras.debuffs = CreateFrame("Frame", "MyUnitPlayerDebuff", player.auras)
player.auras.debuffs:SetSize(300, 34)
player.auras.debuffs:SetPoint("Top", player, "Bottom", 0, -1)

player.auras.debuffs.maxAuras = 8

player.auras.debuffs.buttons = CreateAuraButtons(player.auras.debuffs, 34, 4, "left", 8)
------------------------------------------------------------------------------------------------------------------------
player.auras.buffs = CreateFrame("Frame", "MyUnitPlayerBuff", player.auras)
player.auras.buffs:SetSize(300, 69)
player.auras.buffs:SetPoint("Bottom", player, "Top", 0, 1)

player.auras.buffs.maxAuras = 16
player.auras.buffs.onlyPlayerCast = true
player.auras.buffs.blacklist = true
player.auras.buffs.overridelist = true

player.auras.buffs.buttons = CreateAuraButtons(player.auras.buffs, 34, 4, "left", 8)

player.auras:RegisterEvent("PLAYER_ENTERING_WORLD")
player.auras:RegisterUnitEvent("UNIT_AURA", "player", "vehicle")
player.auras:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    UpdateAura(self)
end)
------------------------------------------------------------------------------------------------------------------------
local focus = CreateFrame("Button", "UnitFocusFrame", UIParent, "SecureUnitButtonTemplate")
focus:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
focus:SetBackdropColor(0, 0, 0, 0.8)
focus:SetSize(195, 48)
focus:SetPoint("TopLeft", target, "TopRight", 5, 5)

focus:SetAttribute("unit", "focus")
RegisterUnitWatch(focus, false)

focus:RegisterForClicks("AnyUp")
focus:SetAttribute("*type1", "target")
focus:SetAttribute("*type2", "togglemenu")

focus.unit = "focus"
focus:SetScript("OnEnter", function(self)
    UnitFrame_OnEnter(self)
end)
focus:SetScript("OnLeave", function(self)
    UnitFrame_OnLeave(self)
end)

focus:RegisterEvent("PLAYER_FOCUS_CHANGED")
focus:RegisterEvent("PLAYER_TARGET_CHANGED")
focus:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "focus")
focus:SetScript("OnEvent", function(self, event)
    UpdateHighlight(self)
    if event ~= "PLAYER_TARGET_CHANGED" then
        UpdateRaidTarget(self.indicator)
        UpdateHealth(self.health)
        UpdateHealthColor(self.health)
        UpdatePower(self.power)
        UpdatePowerColor(self.power)
        UpdateTagName(self.tags)
        UpdateTagPercentHealth(self.tags)
        UpdateTagHealth(self.tags)
        UpdateTagAbsorb(self.tags)
        UpdateTagPercentPower(self.tags)
        UpdateHealPrediction(self.healPrediction)
        UpdateHealAbsorb(self.healAbsorb)
        UpdateTotalAbsorb(self.totalAbsorb)
        UpdateAltPowerVisibility(self.altPower)
        UpdateAura(self.auras)
    end
end)

focus:SetScript("OnUpdate", CheckRange)
------------------------------------------------------------------------------------------------------------------------
focus.indicator = CreateFrame("Frame", nil, focus)
focus.indicator:SetSize(27, 27)
focus.indicator:SetPoint("Left", focus, "Right", 2, 0)

focus.indicator.raidTarget = focus.indicator:CreateTexture(nil, "Overlay")
focus.indicator.raidTarget:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
focus.indicator.raidTarget:SetPoint("Center")
focus.indicator.raidTarget:SetSize(27, 27)

focus.indicator:RegisterEvent("RAID_TARGET_UPDATE")
focus.indicator:SetScript("OnEvent", function(self)
    UpdateRaidTarget(self)
end)
------------------------------------------------------------------------------------------------------------------------
focus.health = CreateFrame("StatusBar", nil, focus)
focus.health:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
focus.health:SetSize(focus:GetWidth(), 32)
focus.health:SetPoint("Top")

focus.health.bg = focus.health:CreateTexture(nil, "Background")
focus.health.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Bg")
focus.health.bg:SetTexCoord(0, 1, 0, 0.53125)
focus.health.bg:SetAllPoints(focus.health)

focus.health:RegisterUnitEvent("UNIT_HEALTH", "focus")
focus.health:RegisterUnitEvent("UNIT_MAXHEALTH", "focus")
focus.health:RegisterUnitEvent("UNIT_CONNECTION", "focus")
focus.health:RegisterUnitEvent("UNIT_FACTION", "focus")
focus.health:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "focus")
focus.health:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "focus")
focus.health:SetScript("OnEvent", function(self, event)
    if event == "UNIT_FACTION" or event == "UNIT_CONNECTION" or event == "UNIT_TARGETABLE_CHANGED" then
        UpdateHealthColor(self)
    end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        UpdateHealth(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
focus.power = CreateFrame("StatusBar", nil, focus)
focus.power:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill")
focus.power:SetSize(focus:GetWidth(), 16)
focus.power:SetPoint("Top", focus.health, "Bottom")

focus.power.bg = focus.power:CreateTexture(nil, "Background")
focus.power.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Background")
focus.power.bg:SetAllPoints(focus.power)

focus.power:RegisterUnitEvent("UNIT_POWER_FREQUENT", "focus")
focus.power:RegisterUnitEvent("UNIT_MAXPOWER", "focus")
focus.power:RegisterUnitEvent("UNIT_CONNECTION", "focus")
focus.power:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "focus")
focus.power:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "focus")
focus.power:RegisterUnitEvent("UNIT_DISPLAYPOWER", "focus")
focus.power:RegisterUnitEvent("UNIT_MANA", "focus")
focus.power:SetScript("OnEvent", function(self, event)
    if event == "UNIT_DISPLAYPOWER" or event == "UNIT_CONNECTION" then
        UpdatePowerColor(self)
    end
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" or event == "UNIT_POWER_BAR_SHOW" or event ==
            "UNIT_POWER_BAR_HIDE" or event == "UNIT_MANA" then
        UpdatePower(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
focus.tags = CreateFrame("Frame", nil, focus)
focus.tags:SetSize(focus:GetSize())
focus.tags:SetPoint("Center")

focus.tags.percentHealth = focus.tags:CreateFontString()
focus.tags.percentHealth:SetFont(GameFontNormal:GetFont(), 11, "Outline")
focus.tags.percentHealth:SetPoint("Left", focus.health)
focus.tags.absorb = focus.tags:CreateFontString()
focus.tags.absorb:SetFont(GameFontNormal:GetFont(), 11, "Outline")
focus.tags.absorb:SetPoint("Right", focus.health)
focus.tags.health = focus.tags:CreateFontString()
focus.tags.health:SetFont(GameFontNormal:GetFont(), 11, "Outline")
focus.tags.health:SetPoint("Right", focus.tags.absorb, "Left")
focus.tags.percentPower = focus.tags:CreateFontString()
focus.tags.percentPower:SetFont(GameFontNormal:GetFont(), 11, "Outline")
focus.tags.percentPower:SetPoint("Left", focus.power)
focus.tags.name = focus.tags:CreateFontString()
focus.tags.name:SetFont(GameFontNormal:GetFont(), 11, "Outline")
focus.tags.name:SetPoint("Right", focus.power)

focus.tags:RegisterUnitEvent("UNIT_NAME_UPDATE", "focus")
focus.tags:RegisterUnitEvent("UNIT_HEALTH", "focus")
focus.tags:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "focus")
focus.tags:RegisterUnitEvent("UNIT_MAXHEALTH", "focus")
focus.tags:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "focus")
focus.tags:RegisterUnitEvent("UNIT_POWER_FREQUENT", "focus")
focus.tags:RegisterUnitEvent("UNIT_MAXPOWER", "focus")
focus.tags:SetScript("OnEvent", function(self, event)
    if event == "UNIT_NAME_UPDATE" then
        UpdateTagName(self)
    end
    if event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" or event == "UNIT_MAXHEALTH" then
        UpdateTagPercentHealth(self)
        UpdateTagHealth(self)
    end
    if event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        UpdateTagAbsorb(self)
    end
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" then
        UpdateTagPercentPower(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
focus.healPrediction = CreateFrame("StatusBar", nil, focus)
focus.healPrediction:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill", "Border")
focus.healPrediction:SetStatusBarColor(0.0, 0.659, 0.608)
focus.healPrediction:SetSize(focus.health:GetSize())
focus.healPrediction:SetAllPoints(focus.health)
focus.healPrediction:Hide()

focus.healPrediction:RegisterUnitEvent("UNIT_MAXHEALTH", "focus")
focus.healPrediction:RegisterUnitEvent("UNIT_HEALTH", "focus")
focus.healPrediction:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "focus")
focus.healPrediction:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "focus")
focus.healPrediction:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "focus")
focus.healPrediction:SetScript("OnEvent", function(self)
    UpdateHealPrediction(self)
end)
------------------------------------------------------------------------------------------------------------------------
focus.healAbsorb = CreateFrame("StatusBar", nil, focus)
focus.healAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Absorb-Fill", "Border")
focus.healAbsorb:SetSize(focus.health:GetSize())
focus.healAbsorb:SetAllPoints(focus.health)
focus.healAbsorb:Hide()

focus.healPrediction:RegisterUnitEvent("UNIT_MAXHEALTH", "focus")
focus.healPrediction:RegisterUnitEvent("UNIT_HEALTH", "focus")
focus.healPrediction:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "focus")
focus.healPrediction:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "focus")
focus.healAbsorb:SetScript("OnEvent", function(self)
    UpdateHealAbsorb(self)
end)
------------------------------------------------------------------------------------------------------------------------
focus.totalAbsorb = CreateFrame("StatusBar", nil, focus)
focus.totalAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill", "Border")
focus.totalAbsorb:SetSize(focus.health:GetSize())
focus.totalAbsorb:SetAllPoints(focus.health)
focus.totalAbsorb:Hide()

focus.totalAbsorb:RegisterUnitEvent("UNIT_MAXHEALTH", "focus")
focus.totalAbsorb:RegisterUnitEvent("UNIT_HEALTH", "focus")
focus.totalAbsorb:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "focus")
focus.totalAbsorb:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "focus")
focus.totalAbsorb:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "focus")
focus.totalAbsorb:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "focus")
focus.totalAbsorb:SetScript("OnEvent", function(self)
    UpdateTotalAbsorb(self)
end)
------------------------------------------------------------------------------------------------------------------------
focus.altPower = CreateFrame("StatusBar", nil, focus)
focus.altPower:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill")
focus.altPower:SetSize(focus:GetWidth(), 12)
focus.altPower:SetPoint("Bottom", focus)

focus.altPower:SetScript("OnShow", function(self)
    local parent = self:GetParent()
    parent.health:SetHeight(24)
    parent.power:SetHeight(12)
end)
focus.altPower:SetScript("OnHide", function(self)
    local parent = self:GetParent()
    parent.health:SetHeight(32)
    parent.power:SetHeight(16)
end)

focus.altPower:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "focus")
focus.altPower:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "focus")
focus.altPower:RegisterEvent("PLAYER_ENTERING_WORLD")
focus.altPower:SetScript("OnEvent", function(self, event)
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        UpdateAltPower(self)
    end
    if event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" or event == "PLAYER_ENTERING_WORLD" then
        UpdateAltPowerVisibility(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
focus.auras = CreateFrame("Frame", nil, focus)

focus.auras.debuffs = CreateFrame("Frame", "MyUnitFocusDebuff", focus.auras)
focus.auras.debuffs:SetSize(focus:GetWidth(), 27)
focus.auras.debuffs:SetPoint("Bottom", focus, "Top", 0, 3)

focus.auras.debuffs.maxAuras = 8
focus.auras.debuffs.onlyPlayerCast = true
focus.auras.debuffs.blacklist = true
focus.auras.debuffs.overridelist = true

focus.auras.debuffs.buttons = CreateAuraButtons(focus.auras.debuffs, 27, 1, "right", 8)
------------------------------------------------------------------------------------------------------------------------
focus.auras.buffs = CreateFrame("Frame", "MyUnitFocusBuff", focus.auras)
focus.auras.buffs:SetSize(focus:GetWidth(), 27)
focus.auras.buffs:SetPoint("Top", focus, "Bottom", 0, -3)

focus.auras.buffs.maxAuras = 8

focus.auras.buffs.buttons = CreateAuraButtons(focus.auras.buffs, 27, 1, "right", 8)

focus.auras:RegisterEvent("PLAYER_ENTERING_WORLD")
focus.auras:RegisterUnitEvent("UNIT_AURA", "focus")
focus.auras:SetScript("OnEvent", function(self)
    UpdateAura(self)
end)
------------------------------------------------------------------------------------------------------------------------
local pet = CreateFrame("Button", "UnitPetFrame", UIParent, "SecureUnitButtonTemplate")
pet:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
pet:SetBackdropColor(0, 0, 0, 0.8)
pet:SetSize(200, 36)
pet:SetPoint("BottomLeft", 567, 110)

pet:SetAttribute("unit", "pet")
RegisterUnitWatch(pet, false)

pet:RegisterForClicks("AnyUp")
pet:SetAttribute("*type1", "target")
pet:SetAttribute("*type2", "togglemenu")

pet.unit = "pet"
pet:SetScript("OnEnter", function(self)
    UnitFrame_OnEnter(self)
end)
pet:SetScript("OnLeave", function(self)
    UnitFrame_OnLeave(self)
end)

pet:RegisterEvent("UNIT_PET")
pet:RegisterUnitEvent("UNIT_ENTERING_VEHICLE", "player")
pet:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
pet:SetScript("OnEvent", function(self, event)
    if event == "UNIT_ENTERING_VEHICLE" then
        if UnitHasVehicleUI("player") and UnitHasVehiclePlayerFrameUI("player") then
            self.unit = "player"
        end
    elseif event == "UNIT_EXITED_VEHICLE" then
        self.unit = "pet"
    end
    UpdateRaidTarget(self.indicator)
    UpdateHealth(self.health)
    UpdateHealthColor(self.health)
    UpdatePower(self.power)
    UpdatePowerColor(self.power)
    UpdateTagName(self.tags)
    UpdateTagPercentHealth(self.tags)
    UpdateTagHealth(self.tags)
    UpdateTagAbsorb(self.tags)
    UpdateTagPercentPower(self.tags)
    UpdateHealPrediction(self.healPrediction)
    UpdateHealAbsorb(self.healAbsorb)
    UpdateTotalAbsorb(self.totalAbsorb)
end)

pet:SetScript("OnUpdate", CheckRange)
------------------------------------------------------------------------------------------------------------------------
pet.indicator = CreateFrame("Frame", nil, pet)
pet.indicator:SetSize(27, 27)
pet.indicator:SetPoint("Right", pet, "Left")

pet.indicator.raidTarget = pet.indicator:CreateTexture(nil, "Overlay")
pet.indicator.raidTarget:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
pet.indicator.raidTarget:SetPoint("Center")
pet.indicator.raidTarget:SetSize(27, 27)

pet.indicator:RegisterEvent("RAID_TARGET_UPDATE")
pet.indicator:SetScript("OnEvent", function(self)
    UpdateRaidTarget(self)
end)
------------------------------------------------------------------------------------------------------------------------
pet.health = CreateFrame("StatusBar", nil, pet)
pet.health:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
pet.health:SetSize(pet:GetWidth(), 24)
pet.health:SetPoint("Top")

pet.health.bg = pet.health:CreateTexture(nil, "Background")
pet.health.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Bg")
pet.health.bg:SetTexCoord(0, 1, 0, 0.53125)
pet.health.bg:SetAllPoints(pet.health)

pet.health:RegisterUnitEvent("UNIT_HEALTH", "pet", "player")
pet.health:RegisterUnitEvent("UNIT_MAXHEALTH", "pet", "player")
pet.health:RegisterUnitEvent("UNIT_CONNECTION", "pet", "player")
pet.health:RegisterUnitEvent("UNIT_FACTION", "pet", "player")
pet.health:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "pet", "player")
pet.health:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "pet", "player")
pet.health:RegisterUnitEvent("UNIT_POWER_UPDATE", "pet")
pet.health:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    if event == "UNIT_FACTION" or event == "UNIT_CONNECTION" or event == "UNIT_TARGETABLE_CHANGED" or event == "UNIT_POWER_UPDATE" then
        UpdateHealthColor(self)
    end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        UpdateHealth(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
pet.power = CreateFrame("StatusBar", nil, pet)
pet.power:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill")
pet.power:SetSize(pet:GetWidth(), 12)
pet.power:SetPoint("Top", pet.health, "Bottom")

pet.power.bg = pet.power:CreateTexture(nil, "Background")
pet.power.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Background")
pet.power.bg:SetAllPoints(pet.power)

pet.power:RegisterUnitEvent("UNIT_POWER_FREQUENT", "pet", "player")
pet.power:RegisterUnitEvent("UNIT_MAXPOWER", "pet", "player")
pet.power:RegisterUnitEvent("UNIT_CONNECTION", "pet", "player")
pet.power:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "pet", "player")
pet.power:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "pet", "player")
pet.power:RegisterUnitEvent("UNIT_DISPLAYPOWER", "pet", "player")
pet.power:RegisterUnitEvent("UNIT_MANA", "pet", "player")
pet.power:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    if event == "UNIT_DISPLAYPOWER" or event == "UNIT_CONNECTION" then
        UpdatePowerColor(self)
    end
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" or event == "UNIT_POWER_BAR_SHOW" or event ==
            "UNIT_POWER_BAR_HIDE" or event == "UNIT_MANA" then
        UpdatePower(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
pet.tags = CreateFrame("Frame", nil, pet)
pet.tags:SetSize(pet:GetSize())
pet.tags:SetPoint("Center")

pet.tags.percentHealth = pet.tags:CreateFontString()
pet.tags.percentHealth:SetFont(GameFontNormal:GetFont(), 11, "Outline")
pet.tags.percentHealth:SetPoint("Right", pet.health)
pet.tags.health = pet.tags:CreateFontString()
pet.tags.health:SetFont(GameFontNormal:GetFont(), 11, "Outline")
pet.tags.health:SetPoint("Left", pet.health)
pet.tags.absorb = pet.tags:CreateFontString()
pet.tags.absorb:SetFont(GameFontNormal:GetFont(), 11, "Outline")
pet.tags.absorb:SetPoint("Left", pet.tags.health, "Right")
pet.tags.percentPower = pet.tags:CreateFontString()
pet.tags.percentPower:SetFont(GameFontNormal:GetFont(), 11, "Outline")
pet.tags.percentPower:SetPoint("Right", pet.power)
pet.tags.name = pet.tags:CreateFontString()
pet.tags.name:SetFont(GameFontNormal:GetFont(), 11, "Outline")
pet.tags.name:SetPoint("Left", pet.power)

pet.tags:RegisterUnitEvent("UNIT_NAME_UPDATE", "pet", "player")
pet.tags:RegisterUnitEvent("UNIT_HEALTH", "pet", "player")
pet.tags:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "pet", "player")
pet.tags:RegisterUnitEvent("UNIT_MAXHEALTH", "pet", "player")
pet.tags:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "pet", "player")
pet.tags:RegisterUnitEvent("UNIT_POWER_FREQUENT", "pet", "player")
pet.tags:RegisterUnitEvent("UNIT_MAXPOWER", "pet", "player")
pet.tags:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    if event == "UNIT_NAME_UPDATE" then
        UpdateTagName(self)
    end
    if event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" or event == "UNIT_MAXHEALTH" then
        UpdateTagPercentHealth(self)
        UpdateTagHealth(self)
    end
    if event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        UpdateTagAbsorb(self)
    end
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" then
        UpdateTagPercentPower(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
pet.healPrediction = CreateFrame("StatusBar", nil, pet)
pet.healPrediction:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill", "Border")
pet.healPrediction:SetStatusBarColor(0.0, 0.659, 0.608)
pet.healPrediction:SetSize(pet.health:GetSize())
pet.healPrediction:SetAllPoints(pet.health)
pet.healPrediction:Hide()

pet.healPrediction:RegisterUnitEvent("UNIT_MAXHEALTH", "pet", "player")
pet.healPrediction:RegisterUnitEvent("UNIT_HEALTH", "pet", "player")
pet.healPrediction:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "pet", "player")
pet.healPrediction:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "pet", "player")
pet.healPrediction:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "pet", "player")
pet.healPrediction:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    UpdateHealPrediction(self)
end)
------------------------------------------------------------------------------------------------------------------------
pet.healAbsorb = CreateFrame("StatusBar", nil, pet)
pet.healAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Absorb-Fill", "Border")
pet.healAbsorb:SetSize(pet.health:GetSize())
pet.healAbsorb:SetAllPoints(pet.health)
pet.healAbsorb:Hide()

pet.healPrediction:RegisterUnitEvent("UNIT_MAXHEALTH", "pet", "player")
pet.healPrediction:RegisterUnitEvent("UNIT_HEALTH", "pet", "player")
pet.healPrediction:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "pet", "player")
pet.healPrediction:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "pet", "player")
pet.healAbsorb:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    UpdateHealAbsorb(self)
end)
------------------------------------------------------------------------------------------------------------------------
pet.totalAbsorb = CreateFrame("StatusBar", nil, pet)
pet.totalAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill", "Border")
pet.totalAbsorb:SetSize(pet.health:GetSize())
pet.totalAbsorb:SetAllPoints(pet.health)
pet.totalAbsorb:Hide()

pet.totalAbsorb:RegisterUnitEvent("UNIT_MAXHEALTH", "pet", "player")
pet.totalAbsorb:RegisterUnitEvent("UNIT_HEALTH", "pet", "player")
pet.totalAbsorb:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "pet", "player")
pet.totalAbsorb:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "pet", "player")
pet.totalAbsorb:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "pet", "player")
pet.totalAbsorb:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "pet", "player")
pet.totalAbsorb:SetScript("OnEvent", function(self, event, unit)
    if unit and unit ~= self:GetParent().unit then
        return
    end
    UpdateTotalAbsorb(self)
end)
------------------------------------------------------------------------------------------------------------------------
local targetTarget = CreateFrame("Button", "UnitTargetTargetFrame", UIParent, "SecureUnitButtonTemplate")
targetTarget:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
targetTarget:SetBackdropColor(0, 0, 0, 0.8)
targetTarget:SetSize(200, 36)
targetTarget:SetPoint("BottomRight", -567, 110)

targetTarget:SetAttribute("unit", "targetTarget")
RegisterUnitWatch(targetTarget, false)

targetTarget:RegisterForClicks("AnyUp")
targetTarget:SetAttribute("*type1", "target")
targetTarget:SetAttribute("*type2", "togglemenu")

targetTarget.unit = "targetTarget"
targetTarget:SetScript("OnEnter", function(self)
    UnitFrame_OnEnter(self)
end)
targetTarget:SetScript("OnLeave", function(self)
    UnitFrame_OnLeave(self)
end)

targetTarget:RegisterEvent("PLAYER_TARGET_CHANGED")
targetTarget:RegisterEvent("UNIT_TARGET")
targetTarget:SetScript("OnEvent", function(self)
    UpdateRaidTarget(self.indicator)
    UpdateHealth(self.health)
    UpdateHealthColor(self.health)
    UpdatePower(self.power)
    UpdatePowerColor(self.power)
    UpdateTagName(self.tags)
    UpdateTagPercentHealth(self.tags)
    UpdateTagHealth(self.tags)
    UpdateTagAbsorb(self.tags)
    UpdateTagPercentPower(self.tags)
    UpdateHealPrediction(self.healPrediction)
    UpdateHealAbsorb(self.healAbsorb)
    UpdateTotalAbsorb(self.totalAbsorb)
end)

targetTarget:SetScript("OnUpdate", CheckRange)
------------------------------------------------------------------------------------------------------------------------
targetTarget.indicator = CreateFrame("Frame", nil, targetTarget)
targetTarget.indicator:SetSize(27, 27)
targetTarget.indicator:SetPoint("Left", targetTarget, "Right")

targetTarget.indicator.raidTarget = targetTarget.indicator:CreateTexture(nil, "Overlay")
targetTarget.indicator.raidTarget:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
targetTarget.indicator.raidTarget:SetPoint("Center")
targetTarget.indicator.raidTarget:SetSize(27, 27)

targetTarget.indicator:RegisterEvent("RAID_TARGET_UPDATE")
targetTarget.indicator:SetScript("OnEvent", function(self)
    UpdateRaidTarget(self)
end)
------------------------------------------------------------------------------------------------------------------------
targetTarget.health = CreateFrame("StatusBar", nil, targetTarget)
targetTarget.health:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
targetTarget.health:SetSize(targetTarget:GetWidth(), 24)
targetTarget.health:SetPoint("Top")

targetTarget.health.bg = targetTarget.health:CreateTexture(nil, "Background")
targetTarget.health.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Bg")
targetTarget.health.bg:SetTexCoord(0, 1, 0, 0.53125)
targetTarget.health.bg:SetAllPoints(targetTarget.health)

targetTarget.health:RegisterUnitEvent("UNIT_HEALTH", "targetTarget")
targetTarget.health:RegisterUnitEvent("UNIT_MAXHEALTH", "targetTarget")
targetTarget.health:RegisterUnitEvent("UNIT_CONNECTION", "targetTarget")
targetTarget.health:RegisterUnitEvent("UNIT_FACTION", "targetTarget")
targetTarget.health:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "targetTarget")
targetTarget.health:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "targetTarget")
targetTarget.health:SetScript("OnEvent", function(self, event)
    if event == "UNIT_FACTION" or event == "UNIT_CONNECTION" or event == "UNIT_TARGETABLE_CHANGED" then
        UpdateHealthColor(self)
    end
    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        UpdateHealth(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
targetTarget.power = CreateFrame("StatusBar", nil, targetTarget)
targetTarget.power:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill")
targetTarget.power:SetSize(targetTarget:GetWidth(), 12)
targetTarget.power:SetPoint("Top", targetTarget.health, "Bottom")

targetTarget.power.bg = targetTarget.power:CreateTexture(nil, "Background")
targetTarget.power.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Background")
targetTarget.power.bg:SetAllPoints(targetTarget.power)

targetTarget.power:RegisterUnitEvent("UNIT_POWER_FREQUENT", "targetTarget")
targetTarget.power:RegisterUnitEvent("UNIT_MAXPOWER", "targetTarget")
targetTarget.power:RegisterUnitEvent("UNIT_CONNECTION", "targetTarget")
targetTarget.power:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "targetTarget")
targetTarget.power:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "targetTarget")
targetTarget.power:RegisterUnitEvent("UNIT_DISPLAYPOWER", "targetTarget")
targetTarget.power:RegisterUnitEvent("UNIT_MANA", "targetTarget")
targetTarget.power:SetScript("OnEvent", function(self, event)
    if event == "UNIT_DISPLAYPOWER" or event == "UNIT_CONNECTION" then
        UpdatePowerColor(self)
    end
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" or event == "UNIT_POWER_BAR_SHOW" or event ==
            "UNIT_POWER_BAR_HIDE" or event == "UNIT_MANA" then
        UpdatePower(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
targetTarget.tags = CreateFrame("Frame", nil, targetTarget)
targetTarget.tags:SetSize(targetTarget:GetSize())
targetTarget.tags:SetPoint("Center")

targetTarget.tags.percentHealth = targetTarget.tags:CreateFontString()
targetTarget.tags.percentHealth:SetFont(GameFontNormal:GetFont(), 11, "Outline")
targetTarget.tags.percentHealth:SetPoint("Left", targetTarget.health)
targetTarget.tags.absorb = targetTarget.tags:CreateFontString()
targetTarget.tags.absorb:SetFont(GameFontNormal:GetFont(), 11, "Outline")
targetTarget.tags.absorb:SetPoint("Right", targetTarget.health)
targetTarget.tags.health = targetTarget.tags:CreateFontString()
targetTarget.tags.health:SetFont(GameFontNormal:GetFont(), 11, "Outline")
targetTarget.tags.health:SetPoint("Right", targetTarget.tags.absorb, "Left")
targetTarget.tags.percentPower = targetTarget.tags:CreateFontString()
targetTarget.tags.percentPower:SetFont(GameFontNormal:GetFont(), 11, "Outline")
targetTarget.tags.percentPower:SetPoint("Left", targetTarget.power)
targetTarget.tags.name = targetTarget.tags:CreateFontString()
targetTarget.tags.name:SetFont(GameFontNormal:GetFont(), 11, "Outline")
targetTarget.tags.name:SetPoint("Right", targetTarget.power)

targetTarget.tags:RegisterUnitEvent("UNIT_NAME_UPDATE", "targetTarget")
targetTarget.tags:RegisterUnitEvent("UNIT_HEALTH", "targetTarget")
targetTarget.tags:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "targetTarget")
targetTarget.tags:RegisterUnitEvent("UNIT_MAXHEALTH", "targetTarget")
targetTarget.tags:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "targetTarget")
targetTarget.tags:RegisterUnitEvent("UNIT_POWER_FREQUENT", "targetTarget")
targetTarget.tags:RegisterUnitEvent("UNIT_MAXPOWER", "targetTarget")
targetTarget.tags:SetScript("OnEvent", function(self, event)
    if event == "UNIT_NAME_UPDATE" then
        UpdateTagName(self)
    end
    if event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" or event == "UNIT_MAXHEALTH" then
        UpdateTagPercentHealth(self)
        UpdateTagHealth(self)
    end
    if event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        UpdateTagAbsorb(self)
    end
    if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" then
        UpdateTagPercentPower(self)
    end
end)
------------------------------------------------------------------------------------------------------------------------
targetTarget.healPrediction = CreateFrame("StatusBar", nil, targetTarget)
targetTarget.healPrediction:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill", "Border")
targetTarget.healPrediction:SetStatusBarColor(0.0, 0.659, 0.608)
targetTarget.healPrediction:SetSize(targetTarget.health:GetSize())
targetTarget.healPrediction:SetAllPoints(targetTarget.health)
targetTarget.healPrediction:Hide()

targetTarget.healPrediction:RegisterUnitEvent("UNIT_MAXHEALTH", "targetTarget")
targetTarget.healPrediction:RegisterUnitEvent("UNIT_HEALTH", "targetTarget")
targetTarget.healPrediction:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "targetTarget")
targetTarget.healPrediction:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "targetTarget")
targetTarget.healPrediction:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "targetTarget")
targetTarget.healPrediction:SetScript("OnEvent", function(self)
    UpdateHealPrediction(self)
end)
------------------------------------------------------------------------------------------------------------------------
targetTarget.healAbsorb = CreateFrame("StatusBar", nil, targetTarget)
targetTarget.healAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Absorb-Fill", "Border")
targetTarget.healAbsorb:SetSize(targetTarget.health:GetSize())
targetTarget.healAbsorb:SetAllPoints(targetTarget.health)
targetTarget.healAbsorb:Hide()

targetTarget.healPrediction:RegisterUnitEvent("UNIT_MAXHEALTH", "targetTarget")
targetTarget.healPrediction:RegisterUnitEvent("UNIT_HEALTH", "targetTarget")
targetTarget.healPrediction:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "targetTarget")
targetTarget.healPrediction:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "targetTarget")
targetTarget.healAbsorb:SetScript("OnEvent", function(self)
    UpdateHealAbsorb(self)
end)
------------------------------------------------------------------------------------------------------------------------
targetTarget.totalAbsorb = CreateFrame("StatusBar", nil, targetTarget)
targetTarget.totalAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill", "Border")
targetTarget.totalAbsorb:SetSize(targetTarget.health:GetSize())
targetTarget.totalAbsorb:SetAllPoints(targetTarget.health)
targetTarget.totalAbsorb:Hide()

targetTarget.totalAbsorb:RegisterUnitEvent("UNIT_MAXHEALTH", "targetTarget")
targetTarget.totalAbsorb:RegisterUnitEvent("UNIT_HEALTH", "targetTarget")
targetTarget.totalAbsorb:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "targetTarget")
targetTarget.totalAbsorb:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "targetTarget")
targetTarget.totalAbsorb:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "targetTarget")
targetTarget.totalAbsorb:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "targetTarget")
targetTarget.totalAbsorb:SetScript("OnEvent", function(self)
    UpdateTotalAbsorb(self)
end)
------------------------------------------------------------------------------------------------------------------------
local boss = CreateFrame("Frame", "UnitBossFrame", UIParent)
boss:SetSize(259, 465)
boss:SetPoint("BottomLeft", target.auras.debuffs, "TopRight", -30, 5)

local bosses = {}
for i = 1, 5 do
    bosses[i] = CreateFrame("Button", "UnitBoss" .. i .. "Frame", boss, "SecureUnitButtonTemplate")
    bosses[i]:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
    bosses[i]:SetBackdropColor(0, 0, 0, 0.8)
    bosses[i]:SetSize(228, 32)
    if i == 1 then
        bosses[i]:SetPoint("BottomLeft", 2, 23)
    else
        bosses[i]:SetPoint("Bottom", bosses[i - 1], "Top", 0, 62)
    end

    bosses[i]:SetAttribute("unit", "boss" .. i)
    RegisterUnitWatch(bosses[i], false)

    bosses[i]:RegisterForClicks("AnyUp")
    bosses[i]:SetAttribute("*type1", "target")
    bosses[i]:SetAttribute("*type2", "togglemenu")

    bosses[i].unit = "boss" .. i
    bosses[i]:SetScript("OnEnter", function(self)
        UnitFrame_OnEnter(self)
    end)
    bosses[i]:SetScript("OnLeave", function(self)
        UnitFrame_OnLeave(self)
    end)

    bosses[i]:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
    bosses[i]:RegisterEvent("PLAYER_TARGET_CHANGED")
    bosses[i]:RegisterEvent("PLAYER_LOGIN")
    bosses[i]:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "boss" .. i)
    bosses[i]:RegisterUnitEvent("UNIT_NAME_UPDATE", "boss" .. i)
    bosses[i]:SetScript("OnEvent", function(self, event)
        UpdateHighlight(self)
        if event ~= "PLAYER_TARGET_CHANGED" then
            UpdateRaidTarget(self.indicator)
            UpdateHealth(self.health)
            UpdateHealthColor(self.health)
            UpdatePower(self.power)
            UpdatePowerColor(self.power)
            UpdateTagName(self.tags)
            UpdateTagPercentHealth(self.tags)
            UpdateTagHealth(self.tags)
            UpdateTagAbsorb(self.tags)
            UpdateTagPercentPower(self.tags)
            UpdateHealPrediction(self.healPrediction)
            UpdateHealAbsorb(self.healAbsorb)
            UpdateTotalAbsorb(self.totalAbsorb)
            UpdateAltPowerVisibility(self.altPower)
            UpdateAura(self.auras)
        end
    end)

    bosses[i]:SetScript("OnUpdate", CheckRange)
    --------------------------------------------------------------------------------------------------------------------
    bosses[i].indicator = CreateFrame("Frame", nil, bosses[i])
    bosses[i].indicator:SetSize(27, 27)
    bosses[i].indicator:SetPoint("Left", bosses[i], "Right", 2, 0)

    bosses[i].indicator.raidTarget = bosses[i].indicator:CreateTexture(nil, "Overlay")
    bosses[i].indicator.raidTarget:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    bosses[i].indicator.raidTarget:SetPoint("Center")
    bosses[i].indicator.raidTarget:SetSize(27, 27)

    bosses[i].indicator:RegisterEvent("RAID_TARGET_UPDATE")
    bosses[i].indicator:SetScript("OnEvent", function(self)
        UpdateRaidTarget(self)
    end)
    --------------------------------------------------------------------------------------------------------------------
    bosses[i].health = CreateFrame("StatusBar", nil, bosses[i])
    bosses[i].health:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
    bosses[i].health:SetSize(bosses[i]:GetWidth(), 20)
    bosses[i].health:SetPoint("Top")

    bosses[i].health.bg = bosses[i].health:CreateTexture(nil, "Background")
    bosses[i].health.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Bg")
    bosses[i].health.bg:SetTexCoord(0, 1, 0, 0.53125)
    bosses[i].health.bg:SetAllPoints(bosses[i].health)

    bosses[i].health:RegisterUnitEvent("UNIT_HEALTH", "boss" .. i)
    bosses[i].health:RegisterUnitEvent("UNIT_MAXHEALTH", "boss" .. i)
    bosses[i].health:RegisterUnitEvent("UNIT_CONNECTION", "boss" .. i)
    bosses[i].health:RegisterUnitEvent("UNIT_FACTION", "boss" .. i)
    bosses[i].health:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "boss" .. i)
    bosses[i].health:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "boss" .. i)
    bosses[i].health:SetScript("OnEvent", function(self, event)
        if event == "UNIT_FACTION" or event == "UNIT_CONNECTION" or event == "UNIT_TARGETABLE_CHANGED" then
            UpdateHealthColor(self)
        end
        if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_HEALTH_FREQUENT" then
            UpdateHealth(self)
        end
    end)
    --------------------------------------------------------------------------------------------------------------------
    bosses[i].power = CreateFrame("StatusBar", nil, bosses[i])
    bosses[i].power:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill")
    bosses[i].power:SetSize(bosses[i]:GetWidth(), 12)
    bosses[i].power:SetPoint("Top", bosses[i].health, "Bottom")

    bosses[i].power.bg = bosses[i].power:CreateTexture(nil, "Background")
    bosses[i].power.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Background")
    bosses[i].power.bg:SetAllPoints(bosses[i].power)

    bosses[i].power:RegisterUnitEvent("UNIT_POWER_FREQUENT", "boss" .. i)
    bosses[i].power:RegisterUnitEvent("UNIT_MAXPOWER", "boss" .. i)
    bosses[i].power:RegisterUnitEvent("UNIT_CONNECTION", "boss" .. i)
    bosses[i].power:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "boss" .. i)
    bosses[i].power:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "boss" .. i)
    bosses[i].power:RegisterUnitEvent("UNIT_DISPLAYPOWER", "boss" .. i)
    bosses[i].power:RegisterUnitEvent("UNIT_MANA", "boss" .. i)
    bosses[i].power:SetScript("OnEvent", function(self, event)
        if event == "UNIT_DISPLAYPOWER" or event == "UNIT_CONNECTION" then
            UpdatePowerColor(self)
        end
        if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" or event == "UNIT_POWER_BAR_SHOW" or event ==
                "UNIT_POWER_BAR_HIDE" or event == "UNIT_MANA" then
            UpdatePower(self)
        end
    end)
    --------------------------------------------------------------------------------------------------------------------
    bosses[i].tags = CreateFrame("Frame", nil, bosses[i])
    bosses[i].tags:SetSize(bosses[i]:GetSize())
    bosses[i].tags:SetPoint("Center")

    bosses[i].tags.percentHealth = bosses[i].tags:CreateFontString()
    bosses[i].tags.percentHealth:SetFont(GameFontNormal:GetFont(), 11, "Outline")
    bosses[i].tags.percentHealth:SetPoint("Left", bosses[i].health)
    bosses[i].tags.absorb = bosses[i].tags:CreateFontString()
    bosses[i].tags.absorb:SetFont(GameFontNormal:GetFont(), 11, "Outline")
    bosses[i].tags.absorb:SetPoint("Right", bosses[i].health)
    bosses[i].tags.health = bosses[i].tags:CreateFontString()
    bosses[i].tags.health:SetFont(GameFontNormal:GetFont(), 11, "Outline")
    bosses[i].tags.health:SetPoint("Right", bosses[i].tags.absorb, "Left")
    bosses[i].tags.percentPower = bosses[i].tags:CreateFontString()
    bosses[i].tags.percentPower:SetFont(GameFontNormal:GetFont(), 11, "Outline")
    bosses[i].tags.percentPower:SetPoint("Left", bosses[i].power)
    bosses[i].tags.name = bosses[i].tags:CreateFontString()
    bosses[i].tags.name:SetFont(GameFontNormal:GetFont(), 11, "Outline")
    bosses[i].tags.name:SetPoint("Right", bosses[i].power)

    bosses[i].tags:RegisterUnitEvent("UNIT_NAME_UPDATE", "boss" .. i)
    bosses[i].tags:RegisterUnitEvent("UNIT_HEALTH", "boss" .. i)
    bosses[i].tags:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "boss" .. i)
    bosses[i].tags:RegisterUnitEvent("UNIT_MAXHEALTH", "boss" .. i)
    bosses[i].tags:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "boss" .. i)
    bosses[i].tags:RegisterUnitEvent("UNIT_POWER_FREQUENT", "boss" .. i)
    bosses[i].tags:RegisterUnitEvent("UNIT_MAXPOWER", "boss" .. i)
    bosses[i].tags:SetScript("OnEvent", function(self, event)
        if event == "UNIT_NAME_UPDATE" then
            UpdateTagName(self)
        end
        if event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" or event == "UNIT_MAXHEALTH" then
            UpdateTagPercentHealth(self)
            UpdateTagHealth(self)
        end
        if event == "UNIT_ABSORB_AMOUNT_CHANGED" then
            UpdateTagAbsorb(self)
        end
        if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" then
            UpdateTagPercentPower(self)
        end
    end)
    --------------------------------------------------------------------------------------------------------------------
    bosses[i].healPrediction = CreateFrame("StatusBar", nil, bosses[i])
    bosses[i].healPrediction:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill", "Border")
    bosses[i].healPrediction:SetStatusBarColor(0.0, 0.659, 0.608)
    bosses[i].healPrediction:SetSize(bosses[i].health:GetSize())
    bosses[i].healPrediction:SetAllPoints(bosses[i].health)
    bosses[i].healPrediction:Hide()

    bosses[i].healPrediction:RegisterUnitEvent("UNIT_MAXHEALTH", "boss" .. i)
    bosses[i].healPrediction:RegisterUnitEvent("UNIT_HEALTH", "boss" .. i)
    bosses[i].healPrediction:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "boss" .. i)
    bosses[i].healPrediction:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "boss" .. i)
    bosses[i].healPrediction:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "boss" .. i)
    bosses[i].healPrediction:SetScript("OnEvent", function(self)
        UpdateHealPrediction(self)
    end)
    --------------------------------------------------------------------------------------------------------------------
    bosses[i].healAbsorb = CreateFrame("StatusBar", nil, bosses[i])
    bosses[i].healAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Absorb-Fill", "Border")
    bosses[i].healAbsorb:SetSize(bosses[i].health:GetSize())
    bosses[i].healAbsorb:SetAllPoints(bosses[i].health)
    bosses[i].healAbsorb:Hide()

    bosses[i].healPrediction:RegisterUnitEvent("UNIT_MAXHEALTH", "boss" .. i)
    bosses[i].healPrediction:RegisterUnitEvent("UNIT_HEALTH", "boss" .. i)
    bosses[i].healPrediction:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "boss" .. i)
    bosses[i].healPrediction:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "boss" .. i)
    bosses[i].healAbsorb:SetScript("OnEvent", function(self)
        UpdateHealAbsorb(self)
    end)
    --------------------------------------------------------------------------------------------------------------------
    bosses[i].totalAbsorb = CreateFrame("StatusBar", nil, bosses[i])
    bosses[i].totalAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill", "Border")
    bosses[i].totalAbsorb:SetSize(bosses[i].health:GetSize())
    bosses[i].totalAbsorb:SetAllPoints(bosses[i].health)
    bosses[i].totalAbsorb:Hide()

    bosses[i].totalAbsorb:RegisterUnitEvent("UNIT_MAXHEALTH", "boss" .. i)
    bosses[i].totalAbsorb:RegisterUnitEvent("UNIT_HEALTH", "boss" .. i)
    bosses[i].totalAbsorb:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "boss" .. i)
    bosses[i].totalAbsorb:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "boss" .. i)
    bosses[i].totalAbsorb:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "boss" .. i)
    bosses[i].totalAbsorb:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "boss" .. i)
    bosses[i].totalAbsorb:SetScript("OnEvent", function(self)
        UpdateTotalAbsorb(self)
    end)
    --------------------------------------------------------------------------------------------------------------------
    bosses[i].altPower = CreateFrame("StatusBar", nil, bosses[i])
    bosses[i].altPower:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill")
    bosses[i].altPower:SetSize(bosses[i]:GetWidth(), 10)
    bosses[i].altPower:SetPoint("Bottom", bosses[i])

    bosses[i].altPower:SetScript("OnShow", function(self)
        local parent = self:GetParent()
        parent.health:SetHeight(12)
        parent.power:SetHeight(10)
    end)
    bosses[i].altPower:SetScript("OnHide", function(self)
        local parent = self:GetParent()
        parent.health:SetHeight(20)
        parent.power:SetHeight(12)
    end)

    bosses[i].altPower:RegisterUnitEvent("UNIT_POWER_BAR_SHOW", "boss" .. i)
    bosses[i].altPower:RegisterUnitEvent("UNIT_POWER_BAR_HIDE", "boss" .. i)
    bosses[i].altPower:RegisterEvent("PLAYER_ENTERING_WORLD")
    bosses[i].altPower:SetScript("OnEvent", function(self, event)
        if event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
            UpdateAltPower(self)
        end
        if event == "UNIT_POWER_BAR_SHOW" or event == "UNIT_POWER_BAR_HIDE" or event == "PLAYER_ENTERING_WORLD" then
            UpdateAltPowerVisibility(self)
        end
    end)
    --------------------------------------------------------------------------------------------------------------------
    bosses[i].auras = CreateFrame("Frame", nil, bosses[i])

    bosses[i].auras.debuffs = CreateFrame("Frame", "MyUnitBoss" .. i .. "Debuff", bosses[i].auras)
    bosses[i].auras.debuffs:SetSize(bosses[i]:GetWidth(), 31)
    bosses[i].auras.debuffs:SetPoint("Bottom", bosses[i], "Top", 0, 3)

    bosses[i].auras.debuffs.maxAuras = 8
    bosses[i].auras.debuffs.onlyPlayerCast = true
    bosses[i].auras.debuffs.blacklist = true
    bosses[i].auras.debuffs.overridelist = true

    bosses[i].auras.debuffs.buttons = CreateAuraButtons(bosses[i].auras.debuffs, 31, 1, "right", 8)

    bosses[i].auras:RegisterEvent("PLAYER_ENTERING_WORLD")
    bosses[i].auras:RegisterUnitEvent("UNIT_AURA", "boss" .. i)
    bosses[i].auras:SetScript("OnEvent", function(self)
        UpdateAura(self)
    end)
end