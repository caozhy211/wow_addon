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

local function CreateUnitFrame(config)
    local frame = CreateFrame("Button", config.name, UIParent, "SecureUnitButtonTemplate")
    frame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
    frame:SetBackdropColor(0, 0, 0, 0.8)

    frame.unit = config.unit
    frame.otherUnit = config.otherUnit
    frame.fullUpdates = {}

    frame:SetAttribute("unit", config.unit)
    RegisterUnitWatch(frame, false)
    frame:RegisterForClicks("AnyUp")
    frame:SetAttribute("*type1", "target")
    frame:SetAttribute("*type2", "togglemenu")

    frame:SetScript("OnEnter", function(self)
        UnitFrame_OnEnter(self)
    end)

    frame:SetScript("OnLeave", function(self)
        UnitFrame_OnLeave(self)
    end)

    if config.checkRange then
        frame:SetScript("OnUpdate", function(self)
            local spell
            if (UnitCanAssist("player", self.unit)) then
                -- 友方法術：靈魂石
                spell = GetSpellInfo(20707)
            elseif (UnitCanAttack("player", self.unit)) then
                -- 敵方法術：吸取生命
                spell = GetSpellInfo(234153)
            end

            if spell then
                self:SetAlpha(IsSpellInRange(spell, self.unit) == 1 and 1 or 0.55)
            else
                self:SetAlpha(CheckInteractDistance(self.unit, 1) and 1 or 0.55)
            end
        end)
    end

    for event, isUnitEvent in pairs(config.events) do
        if isUnitEvent then
            frame:RegisterUnitEvent(event, config.unit, config.otherUnit)
        else
            frame:RegisterEvent(event)
        end
    end

    frame:SetScript("OnEvent", function(self, event)
        if self.otherUnit then
            if event == "PLAYER_REGEN_ENABLED" then
                self:SetAttribute("unit", self.unit)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            elseif event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_ENTERING_VEHICLE" then
                if UnitHasVehicleUI("player") and UnitHasVehiclePlayerFrameUI("player") then
                    local temp = self.unit
                    self.unit = self.otherUnit
                    self.otherUnit = temp
                    if not InCombatLockdown() then
                        self:SetAttribute("unit", self.unit)
                    else
                        self:RegisterEvent("PLAYER_REGEN_ENABLED")
                    end
                end
            elseif event == "UNIT_EXITED_VEHICLE" or event == "UNIT_EXITING_VEHICLE" then
                self.unit = config.unit
                self.otherUnit = config.otherUnit
                if not InCombatLockdown() then
                    self:SetAttribute("unit", self.unit)
                else
                    self:RegisterEvent("PLAYER_REGEN_ENABLED")
                end
            end
        end

        for i = 1, #self.fullUpdates, 2 do
            local module = self.fullUpdates[i]
            local func = self.fullUpdates[i + 1]
            module[func](module)
        end
    end)

    return frame
end

local function OnEvent(module)
    local frame = module:GetParent()

    for i = 1, #module.events, 3 do
        local e = module.events[i]
        if module.events[i + 1] then
            module:RegisterUnitEvent(e, frame.unit, frame.otherUnit)
        else
            module:RegisterEvent(e)
        end
    end

    module:SetScript("OnEvent", function(self, event, unit)
        if frame.otherUnit and unit and unit ~= frame.unit then
            return
        end

        for i = 1, #self.events, 3 do
            if self.events[i] == event then
                local func = self.events[i + 2]
                self[func](self)
            end
        end
    end)
end

local function AddToFullUpdates(module, func)
    local fullUpdates = module:GetParent().fullUpdates
    tinsert(fullUpdates, module)
    tinsert(fullUpdates, func)
end

local function AddToEvents(module, event, isUnitEvent, func)
    tinsert(module.events, event)
    tinsert(module.events, isUnitEvent)
    tinsert(module.events, func)
end

local function CreatePortrait(frame)
    local portrait = CreateFrame("PlayerModel", nil, frame)
    portrait:SetSize(58, 58)
    if frame.unit == "player" then
        portrait:SetPoint("Left", 1, 1)
    else
        portrait:SetPoint("Right", -1, 1)
    end

    portrait.events = {
        "UNIT_PORTRAIT_UPDATE", true, "UpdateGUID",
        "UNIT_MODEL_CHANGED", true, "Update",
    }

    portrait:SetScript("OnShow", function(self)
        self:SetPortraitZoom(1)
    end)

    portrait:SetScript("OnHide", function(self)
        self.guid = nil
    end)

    function portrait:UpdateGUID()
        local guid = UnitGUID(frame.unit)
        if self.guid ~= guid then
            self:Update()
        end
        self.guid = guid
    end

    function portrait:Update()
        if not UnitIsVisible(frame.unit) or not UnitIsConnected(frame.unit) then
            self:ClearModel()
            self:SetModelScale(5.5)
            self:SetPosition(0, 0, 0)
            self:SetModel("Interface\\Buttons\\talktomequestionmark.m2")
        else
            self:ClearModel()
            self:SetUnit(frame.unit)
            self:SetPortraitZoom(1)
            self:SetPosition(0, 0, 0)
        end
    end

    OnEvent(portrait)
    AddToFullUpdates(portrait, "UpdateGUID")
    return portrait
end

local function CreateIndicators(frame, config)
    local indicators = CreateFrame("Frame", nil, frame)
    if frame.unit == "player" or frame.unit == "target" then
        indicators:SetSize(60, 60)
        indicators:SetPoint(frame.unit == "player" and "Left" or "Right")
    else
        indicators:SetSize(27, 27)
        if frame.unit == "pet" then
            indicators:SetPoint("Right", frame, "Left")
        elseif frame.unit == "targetTarget" then
            indicators:SetPoint("Left", frame, "Right")
        else
            indicators:SetPoint("Left", frame, "Right", 2, 0)
        end
    end

    indicators.events = {}

    if config.raidTarget then
        indicators.raidTarget = indicators:CreateTexture(nil, "Overlay")
        indicators.raidTarget:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        if frame.unit == "player" or frame.unit == "target" then
            indicators.raidTarget:SetSize(18, 18)
            indicators.raidTarget:SetPoint("BottomLeft")
        else
            indicators.raidTarget:SetAllPoints()
        end
        AddToEvents(indicators, "RAID_TARGET_UPDATE", false, "UpdateRaidTarget")
        AddToFullUpdates(indicators, "UpdateRaidTarget")
    end

    if config.pvp then
        indicators.pvp = indicators:CreateTexture(nil, "Overlay")
        indicators.pvp:SetSize(35, 35)
        indicators.pvp:SetPoint("BottomRight", 15, -13)
        AddToEvents(indicators, "PLAYER_FLAGS_CHANGED", true, "UpdatePVPFlag")
        AddToEvents(indicators, "UNIT_FACTION", true, "UpdatePVPFlag")
        AddToFullUpdates(indicators, "UpdatePVPFlag")
    end

    if config.leader then
        indicators.leader = indicators:CreateTexture(nil, "Overlay")
        indicators.leader:SetSize(16, 16)
        indicators.leader:SetPoint("TopLeft")
        AddToEvents(indicators, "PARTY_LEADER_CHANGED", false, "UpdateLeader")
        AddToEvents(indicators, "GROUP_ROSTER_UPDATE", false, "UpdateLeader")
        AddToFullUpdates(indicators, "UpdateLeader")
    end

    if config.status then
        indicators.status = indicators:CreateTexture(nil, "Overlay")
        indicators.status:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        indicators.status:SetSize(18, 18)
        indicators.status:SetPoint("TopRight")
        AddToEvents(indicators, "PLAYER_REGEN_ENABLED", false, "UpdateStatus")
        AddToEvents(indicators, "PLAYER_REGEN_DISABLED", false, "UpdateStatus")
        AddToEvents(indicators, "PLAYER_UPDATE_RESTING", false, "UpdateStatus")
        AddToEvents(indicators, "UPDATE_FACTION", false, "UpdateStatus")
        AddToFullUpdates(indicators, "UpdateStatus")
    end

    if config.questBoss then
        indicators.questBoss = indicators:CreateTexture(nil, "Overlay")
        indicators.questBoss:SetTexture("Interface\\TargetingFrame\\PortraitQuestBadge")
        indicators.questBoss:SetSize(20, 20)
        indicators.questBoss:SetPoint("TopRight")
        AddToEvents(indicators, "UNIT_CLASSIFICATION_CHANGED", true, "UpdateQuestBoss")
        AddToFullUpdates(indicators, "UpdateQuestBoss")
    end

    function indicators:UpdateRaidTarget()
        if UnitExists(frame.unit) and GetRaidTargetIndex(frame.unit) then
            SetRaidTargetIconTexture(self.raidTarget, GetRaidTargetIndex(frame.unit))
            self.raidTarget:Show()
        else
            self.raidTarget:Hide()
        end
    end

    function indicators:UpdatePVPFlag()
        local faction = UnitFactionGroup(frame.unit)
        if UnitIsPVPFreeForAll(frame.unit) then
            self.pvp:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
            self.pvp:SetTexCoord(0, 1, 0, 1)
            self.pvp:Show()
        elseif faction and faction ~= "Neutral" and UnitIsPVP(frame.unit) then
            self.pvp:SetTexture(string.format("Interface\\TargetingFrame\\UI-PVP-%s", faction))
            self.pvp:SetTexCoord(0, 1, 0, 1)
            self.pvp:Show()
        else
            self.pvp:Hide()
        end
    end

    function indicators:UpdateLeader()
        if UnitIsGroupLeader(frame.unit) then
            if HasLFGRestrictions() then
                self.leader:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
                self.leader:SetTexCoord(0, 0.296875, 0.015625, 0.3125)
            else
                self.leader:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
                self.leader:SetTexCoord(0, 1, 0, 1)
            end

            self.leader:Show()
        elseif UnitIsGroupAssistant(frame.unit) or (UnitInRaid(frame.unit) and IsEveryoneAssistant()) then
            self.leader:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
            self.leader:SetTexCoord(0, 1, 0, 1)
            self.leader:Show()
        else
            self.leader:Hide()
        end
    end

    function indicators:UpdateStatus()
        if UnitAffectingCombat(frame.unit) then
            self.status:SetTexCoord(0.50, 1.0, 0.0, 0.49)
            self.status:Show()
        elseif IsResting() then
            self.status:SetTexCoord(0.0, 0.50, 0.0, 0.421875)
            self.status:Show()
        else
            self.status:Hide()
        end
    end

    function indicators:UpdateQuestBoss()
        if UnitIsQuestBoss(frame.unit) then
            self.questBoss:Show()
        else
            self.questBoss:Hide()
        end
    end

    OnEvent(indicators)
    return indicators
end

local function CreateHealth(frame)
    local health = CreateFrame("StatusBar", nil, frame)
    health:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
    health:SetSize(frame.portrait and frame:GetWidth() - 60 or frame:GetWidth(), frame:GetHeight() * 2 / 3)
    if frame.unit == "player" then
        health:SetPoint("TopRight")
    elseif frame.unit == "target" then
        health:SetPoint("TopLeft")
    else
        health:SetPoint("Top")
    end

    health.bg = health:CreateTexture(nil, "Background")
    health.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Bg")
    health.bg:SetTexCoord(0, 1, 0, 0.53125)
    health.bg:SetAllPoints()

    health.events = {
        "UNIT_HEALTH", true, "Update",
        "UNIT_MAXHEALTH", true, "Update",
        "UNIT_CONNECTION", true, "UpdateColor",
        "UNIT_FACTION", true, "Update",
        "UNIT_HEALTH_FREQUENT", true, "Update",
        "UNIT_TARGETABLE_CHANGED", true, "Update",
    }
    if frame.unit == "pet" then
        AddToEvents(health, "UNIT_POWER_UPDATE", true, "UpdateColor")
    end

    function health:Update()
        self:SetMinMaxValues(0, UnitHealthMax(frame.unit))
        self:SetValue(UnitHealth(frame.unit))
    end

    function health:UpdateColor()
        local r, g, b = 1, 0, 0
        if not UnitIsConnected(frame.unit) then
            r, g, b = 0.5, 0.5, 0.5
        elseif frame.unit == "vehicle" then
            r, g, b = 0.23, 0.41, 0.23
        elseif not UnitPlayerControlled(frame.unit) and UnitIsTapDenied(frame.unit) then
            r, g, b = 0.5, 0.5, 0.5
        elseif UnitIsPlayer(frame.unit) then
            local _, class = UnitClass(frame.unit)
            r, g, b = GetClassColor(class)
        else
            local reaction = UnitReaction(frame.unit, "player")
            if reaction then
                if (reaction > 4) then
                    r, g, b = 0, 1, 0
                elseif (reaction == 4) then
                    r, g, b = 1, 1, 0
                else
                    r, g, b = 1, 0, 0
                end
            end
        end
        self:SetStatusBarColor(r, g, b)
    end

    OnEvent(health)
    AddToFullUpdates(health, "Update")
    AddToFullUpdates(health, "UpdateColor")
    return health
end

local function CreatePower(frame)
    local power = CreateFrame("StatusBar", nil, frame)
    power:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill")
    power:SetSize(frame.health:GetWidth(), frame:GetHeight() - frame.health:GetHeight())
    power:SetPoint("Top", frame.health, "Bottom")

    power.bg = power:CreateTexture(nil, "Background")
    power.bg:SetTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Background")
    power.bg:SetAllPoints()

    power.events = {
        "UNIT_POWER_FREQUENT", true, "Update",
        "UNIT_MAXPOWER", true, "Update",
        "UNIT_CONNECTION", true, "UpdateColor",
        "UNIT_POWER_BAR_SHOW", true, "Update",
        "UNIT_POWER_BAR_HIDE", true, "Update",
        "UNIT_DISPLAYPOWER", true, "UpdateColor",
        "UNIT_MANA", true, "Update",
    }
    if frame.unit == "player" then
        AddToEvents(power, "PLAYER_UNGHOST", false, "Update")
    end

    function power:Update()
        self:SetMinMaxValues(0, UnitPowerMax(frame.unit))
        self:SetValue(UnitPower(frame.unit))
    end

    function power:UpdateColor()
        local color = {}
        local powerID, currentType, altR, altG, altB = UnitPowerType(frame.unit)
        if not UnitIsConnected(frame.unit) then
            color.r, color.g, color.b = 0.5, 0.5, 0.5
        elseif PowerBarColor[currentType] then
            color = PowerBarColor[currentType]
        elseif altR then
            color.r, color.g, color.b = altR, altG, altB
        else
            color = PowerBarColor["MANA"]
        end
        self:SetStatusBarColor(color.r, color.g, color.b)
    end

    OnEvent(power)
    AddToFullUpdates(power, "Update")
    AddToFullUpdates(power, "UpdateColor")
    return power
end

local function CreateTextFont(frame)
    local fontString = frame:CreateFontString()
    fontString:SetFont(GameFontNormal:GetFont(), 11, "Outline")
    return fontString
end

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

local function CreateTags(frame, config)
    local tags = CreateFrame("Frame", nil, frame)
    tags:SetAllPoints()

    tags.events = {}

    if config.percentHealth then
        tags.percentHealth = CreateTextFont(tags)
        if frame.unit == "player" then
            tags.percentHealth:SetPoint("Right", frame.health, "BottomRight", 0, 9)
        elseif frame.unit == "target" then
            tags.percentHealth:SetPoint("Left", frame.health, "BottomLeft", 0, 9)
        else
            tags.percentHealth:SetPoint(frame.unit == "pet" and "Right" or "Left", frame.health)
        end
        AddToEvents(tags, "UNIT_HEALTH", true, "UpdatePercentHealth")
        AddToEvents(tags, "UNIT_HEALTH_FREQUENT", true, "UpdatePercentHealth")
        AddToEvents(tags, "UNIT_MAXHEALTH", true, "UpdatePercentHealth")
        AddToFullUpdates(tags, "UpdatePercentHealth")
    end

    if config.health then
        tags.health = CreateTextFont(tags)
        if frame.unit == "player" then
            tags.health:SetPoint("Left", frame.health, "BottomLeft", 0, 9)
        elseif frame.unit == "target" then
            tags.health:SetPoint("Right", frame.health, "BottomRight", 0, 9)
        else
            tags.health:SetPoint(frame.unit == "pet" and "Left" or "Right", frame.health)
        end
        AddToEvents(tags, "UNIT_HEALTH", true, "UpdateHealth")
        AddToEvents(tags, "UNIT_HEALTH_FREQUENT", true, "UpdateHealth")
        AddToEvents(tags, "UNIT_MAXHEALTH", true, "UpdateHealth")
        AddToFullUpdates(tags, "UpdateHealth")
    end

    if config.absorb then
        tags.absorb = CreateTextFont(tags)
        if frame.unit == "player" or frame.unit == "pet" then
            tags.absorb:SetPoint("Left", tags.health, "Right")
        elseif frame.unit == "target" then
            tags.absorb:SetPoint("Right", frame.health, "BottomRight", 0, 9)
            tags.health:SetPoint("Right", tags.absorb, "Left")
        else
            tags.absorb:SetPoint("Right", frame.health)
            tags.health:SetPoint("Right", tags.absorb, "Left")
        end
        AddToEvents(tags, "UNIT_ABSORB_AMOUNT_CHANGED", true, "UpdateAbsorb")
        AddToFullUpdates(tags, "UpdateAbsorb")
    end

    if config.percentPower then
        tags.percentPower = CreateTextFont(tags)
        if frame.unit == "player" or frame.unit == "pet" then
            tags.percentPower:SetPoint("Right", frame.power)
        else
            tags.percentPower:SetPoint("Left", frame.power)
        end
        AddToEvents(tags, "UNIT_POWER_FREQUENT", true, "UpdatePercentPower")
        AddToEvents(tags, "UNIT_MAXPOWER", true, "UpdatePercentPower")
        AddToFullUpdates(tags, "UpdatePercentPower")
    end

    if config.name then
        tags.name = CreateTextFont(tags)
        if frame.unit == "player" then
            tags.name:SetPoint("Right", frame.health, "TopRight", 0, -9)
        elseif frame.unit == "target" then
            tags.name:SetPoint("Left", frame.health, "TopLeft", 0, -9)
        else
            tags.name:SetPoint(frame.unit == "pet" and "Left" or "Right", frame.power)
        end
        AddToEvents(tags, "UNIT_NAME_UPDATE", true, "UpdateName")
        AddToFullUpdates(tags, "UpdateName")
    end

    if config.power then
        tags.power = CreateTextFont(tags)
        tags.power:SetPoint(frame.unit == "player" and "Left" or "Right", frame.power)
        AddToEvents(tags, "UNIT_POWER_FREQUENT", true, "UpdatePower")
        AddToEvents(tags, "UNIT_MAXPOWER", true, "UpdatePower")
        AddToFullUpdates(tags, "UpdatePower")
    end

    if config.group then
        tags.group = CreateTextFont(tags)
        if frame.unit == "player" then
            tags.group:SetPoint("Right", tags.name, "Left")
        else
            tags.group:SetPoint("Left", tags.name, "Right")
        end
        AddToEvents(tags, "GROUP_ROSTER_UPDATE", false, "UpdateGroup")
        AddToFullUpdates(tags, "UpdateGroup")
    end

    if config.afk then
        tags.afk = CreateTextFont(tags)
        if frame.unit == "player" then
            tags.afk:SetPoint("Right", tags.group, "Left")
        else
            tags.afk:SetPoint("Left", tags.group, "Right")
        end
        AddToEvents(tags, "PLAYER_FLAGS_CHANGED", true, "UpdateAFK")
        AddToFullUpdates(tags, "UpdateAFK")
    end

    if config.race then
        tags.race = CreateTextFont(tags)
        if frame.unit == "player" then
            tags.race:SetPoint("Left", frame.health, "TopLeft", 0, -9)
        else
            tags.race:SetPoint("Right", frame.health, "TopRight", 0, -9)
        end
        AddToEvents(tags, "UNIT_CLASSIFICATION_CHANGED", true, "UpdateRace")
        AddToFullUpdates(tags, "UpdateRace")
    end

    if config.level then
        tags.level = CreateTextFont(tags)
        if frame.unit == "player" then
            tags.level:SetPoint("Left", tags.race, "Right")
        else
            tags.level:SetPoint("Right", tags.race, "Left")
        end
        AddToEvents(tags, "UNIT_LEVEL", true, "UpdateLevel")
        AddToEvents(tags, "PLAYER_LEVEL_UP", false, "UpdateLevel")
        AddToEvents(tags, "UNIT_CLASSIFICATION_CHANGED", true, "UpdateLevel")
        AddToFullUpdates(tags, "UpdateLevel")
    end

    function tags:UpdatePercentHealth()
        local currentHealth = UnitHealth(frame.unit)
        local maxHealth = UnitHealthMax(frame.unit)
        local text = maxHealth > 0 and floor(currentHealth / maxHealth * 100 + 0.5) .. "%" or ""
        self.percentHealth:SetText(text)
    end

    function tags:UpdateHealth()
        local currentHealth = UnitHealth(frame.unit)
        local maxHealth = UnitHealthMax(frame.unit)
        local text = maxHealth > 0 and FormatNumber(currentHealth) .. "/" .. FormatNumber(maxHealth) or ""
        self.health:SetText(text)
    end

    function tags:UpdateAbsorb()
        local text = ""
        local absorb = UnitGetTotalAbsorbs(frame.unit)
        if absorb and absorb > 0 then
            text = "+" .. FormatNumber(absorb)
        end
        tags.absorb:SetText(text)
    end

    function tags:UpdatePercentPower()
        local currentPower = UnitPower(frame.unit)
        local maxPower = UnitPowerMax(frame.unit)
        local text = maxPower > 0 and floor(currentPower / maxPower * 100 + 0.5) .. "%" or ""
        self.percentPower:SetText(text)
    end

    function tags:UpdateName()
        self.name:SetText(UnitName(frame.unit) or "")
    end

    function tags:UpdatePower()
        local currentPower = UnitPower(frame.unit)
        local maxPower = UnitPowerMax(frame.unit)
        local text = maxPower > 0 and FormatNumber(currentPower) .. "/" .. FormatNumber(maxPower) or ""
        self.power:SetText(text)
    end

    function tags:UpdateGroup()
        local text = ""
        if UnitInRaid(frame.unit) then
            local name, server = UnitName(frame.unit)
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
        self.group:SetText(text)
    end

    function tags:UpdateAFK()
        self.afk:SetText(UnitIsAFK(frame.unit) and "(暫離)" or UnitIsDND(frame.unit) and "(勿擾)" or "")
    end

    function tags:UpdateRace()
        local text
        if UnitIsPlayer(frame.unit) then
            text = UnitRace(frame.unit)
        else
            text = UnitCreatureFamily(frame.unit) or UnitCreatureType(frame.unit)
        end
        self.race:SetText(text)
    end

    function tags:UpdateLevel()
        local text
        local classif = UnitClassification(frame.unit)
        if classif == "worldboss" then
            text = "首領"
        elseif UnitIsWildBattlePet(frame.unit) or UnitIsBattlePetCompanion(frame.unit) then
            text = UnitBattlePetLevel(frame.unit)
        else
            local level = UnitLevel(frame.unit)
            text = level > 0 and level or "??"
            if classif == "elite" or classif == "rareelite" then
                text = text .. "+"
            end
        end
        self.level:SetText(text)
    end

    OnEvent(tags)
    return tags
end

local function SetBarValue(bar, amount)
    local frame = bar:GetParent()

    if amount <= 0 then
        bar:Hide()
        return
    end

    local health = UnitHealth(frame.unit)
    if health <= 0 then
        bar:Hide()
        return
    end

    local maxHealth = UnitHealthMax(frame.unit)
    if maxHealth <= 0 then
        bar:Hide()
        return
    end

    bar:SetMinMaxValues(0, maxHealth)
    bar:SetValue(health + amount)
    bar:Show()
end

local function CreateHealAbsorb(frame)
    local healAbsorb = CreateFrame("StatusBar", nil, frame)
    healAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Absorb-Fill", "Border")
    healAbsorb:SetAllPoints(frame.health)

    healAbsorb.events = {
        "UNIT_HEALTH", true, "Update",
        "UNIT_HEALTH_FREQUENT", true, "Update",
        "UNIT_MAXHEALTH", true, "Update",
        "UNIT_HEAL_ABSORB_AMOUNT_CHANGED", true, "Update",
    }

    function healAbsorb:Update()
        SetBarValue(self, UnitGetTotalHealAbsorbs(frame.unit) or 0)
    end

    OnEvent(healAbsorb)
    AddToFullUpdates(healAbsorb, "Update")
    return healAbsorb
end

local function CreateHealPrediction(frame)
    local healPrediction = CreateFrame("StatusBar", nil, frame)
    healPrediction:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill", "Border")
    healPrediction:SetStatusBarColor(0.0, 0.659, 0.608)
    healPrediction:SetAllPoints(frame.health)

    healPrediction.events = {
        "UNIT_HEALTH", true, "Update",
        "UNIT_HEALTH_FREQUENT", true, "Update",
        "UNIT_MAXHEALTH", true, "Update",
        "UNIT_HEAL_ABSORB_AMOUNT_CHANGED", true, "Update",
        "UNIT_HEAL_PREDICTION", true, "Update",
    }

    function healPrediction:Update()
        local amount = UnitGetIncomingHeals(frame.unit) or 0
        if amount > 0 then
            amount = amount + (UnitGetTotalHealAbsorbs(frame.unit) or 0)
        end
        SetBarValue(self, amount)
    end

    OnEvent(healPrediction)
    AddToFullUpdates(healPrediction, "Update")
    return healPrediction
end

local function CreateTotalAbsorb(frame)
    local totalAbsorb = CreateFrame("StatusBar", nil, frame)
    totalAbsorb:SetStatusBarTexture("Interface\\RaidFrame\\Shield-Fill", "Border")
    totalAbsorb:SetAllPoints(frame.health)

    totalAbsorb.events = {
        "UNIT_HEALTH", true, "Update",
        "UNIT_HEALTH_FREQUENT", true, "Update",
        "UNIT_MAXHEALTH", true, "Update",
        "UNIT_HEAL_ABSORB_AMOUNT_CHANGED", true, "Update",
        "UNIT_HEAL_ABSORB_AMOUNT_CHANGED", true, "Update",
        "UNIT_ABSORB_AMOUNT_CHANGED", true, "Update",
    }

    function totalAbsorb:Update()
        local amount = UnitGetTotalAbsorbs(frame.unit) or 0
        if amount > 0 then
            amount = amount + (UnitGetIncomingHeals(frame.unit) or 0)
            amount = amount + (UnitGetTotalHealAbsorbs(frame.unit) or 0)
        end
        SetBarValue(self, amount)
    end

    OnEvent(totalAbsorb)
    AddToFullUpdates(totalAbsorb, "Update")
    return totalAbsorb
end

local function CreateComboPoints(frame)
    local comboPoints = CreateFrame("Frame", nil, frame)
    comboPoints:SetSize(frame.health:GetWidth(), 10)
    comboPoints:SetPoint("BottomRight")

    comboPoints.points = {}
    comboPoints.events = {
        "UNIT_POWER_UPDATE", true, "Update",
        "UNIT_POWER_FREQUENT", true, "Update",
        "UNIT_MAXPOWER", true, "Update",
    }

    comboPoints:SetScript("OnShow", function(self)
        frame.power:SetHeight(frame:GetHeight() / 3 - 4)
        frame.health:SetHeight(frame:GetHeight() - frame.power:GetHeight() - self:GetHeight())
    end)

    comboPoints:SetScript("OnHide", function()
        frame.power:SetHeight(frame:GetHeight() / 3)
        frame.health:SetHeight(frame:GetHeight() * 2 / 3)
    end)

    function comboPoints:Update()
        local maxPoints = UnitPowerMax(frame.unit, Enum.PowerType.ComboPoints)
        if maxPoints > 0 then
            if #(self.points) ~= maxPoints then
                for i = 1, maxPoints do
                    local point = self:CreateTexture()
                    point:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
                    local color = PowerBarColor["COMBO_POINTS"]
                    point:SetColorTexture(color.r, color.g, color.b, 1)
                    local width = (self:GetWidth() - (maxPoints - 1) * 5) / maxPoints
                    point:SetSize(width, self:GetHeight())
                    point:SetPoint("Left", self, (width + 5) * (i - 1), 0)
                    self.points[i] = point
                end
            end

            local currentPoints
            if frame.unit == "vehicle" then
                currentPoints = GetComboPoints(frame.unit)
                if currentPoints == 0 then
                    currentPoints = GetComboPoints(frame.unit, "vehicle")
                end
            else
                currentPoints = UnitPower(frame.unit, Enum.PowerType.ComboPoints)
            end

            if currentPoints > 0 then
                for i = 1, #(self.points) do
                    self.points[i]:SetAlpha(i > currentPoints and 0.15 or 1)
                end

                self:Show()
            else
                self:Hide()
            end
        else
            self:Hide()
            table.wipe(self.points)
        end
    end

    OnEvent(comboPoints)
    AddToFullUpdates(comboPoints, "Update")
    return comboPoints
end

local function CreateAltPower(frame)
    local altPower = CreateFrame("StatusBar", nil, frame)
    altPower:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Resource-Fill")
    altPower:SetSize(frame.health:GetWidth(), 10)
    altPower:SetPoint("Bottom")

    altPower.events = {
        "UNIT_POWER_BAR_SHOW", true, "UpdateVisibility",
        "UNIT_POWER_BAR_HIDE", true, "UpdateVisibility",
        "PLAYER_ENTERING_WORLD", false, "UpdateVisibility",
    }

    altPower:SetScript("OnShow", function(self)
        local height = frame.power:GetHeight()
        height = height - 4 > 11 and height - 4 or 11
        frame.power:SetHeight(height)
        frame.health:SetHeight(frame:GetHeight() - height - self:GetHeight())
    end)

    altPower:SetScript("OnHide", function(self)
        frame.power:SetHeight(frame:GetHeight() / 3)
        frame.health:SetHeight(frame:GetHeight() * 2 / 3)
    end)

    function altPower:UpdateVisibility()
        local barType, minPower, _, _, _, hideFromOthers, showOnRaid = UnitAlternatePowerInfo(frame.unit)
        local visible = false
        if barType and (not hideFromOthers or (showOnRaid and (UnitInRaid(frame.unit) or UnitInParty(frame.unit)))) then
            visible = true
        end
        if visible then
            self:Show()
            AddToEvents(self, "UNIT_POWER_FREQUENT", true, "Update")
            AddToEvents(self, "UNIT_MAXPOWER", true, "Update")
            AddToEvents(self, "UNIT_DISPLAYPOWER", true, "Update")
        else
            self:Hide()
            self:UnregisterEvent("UNIT_POWER_FREQUENT")
            self:UnregisterEvent("UNIT_MAXPOWER")
            self:UnregisterEvent("UNIT_DISPLAYPOWER")
        end
        if not visible then
            return
        end
        self:SetStatusBarColor(0.7, 0.7, 0.6)
        self:Update()
    end

    function altPower:Update()
        local _, minPower = UnitAlternatePowerInfo(frame.unit)
        minPower = minPower or 0
        local maxPower = UnitPowerMax(frame.unit, ALTERNATE_POWER_INDEX) or 0
        local currentPower = UnitPower(frame.unit, ALTERNATE_POWER_INDEX) or 0
        self:SetMinMaxValues(minPower, maxPower)
        self:SetValue(currentPower)

        if maxPower <= 0 then
            return
        end

        if not self.text then
            self.text = CreateTextFont(self)
            self.text:SetPoint("Center")
        end
        local percent = floor(currentPower / maxPower * 100 + 0.5)
        self.text:SetText("(" .. percent .. "%) " .. currentPower .. "/" .. maxPower)
    end

    OnEvent(altPower)
    AddToFullUpdates(altPower, "UpdateVisibility")
    return altPower
end

local function CreateAuraButtons(frame, size, spacing, direction, numPerLine)
    local buttons = {}
    for i = 1, frame.maxAuras do
        local button = CreateFrame("Button", nil, frame)
        buttons[i] = button

        button.cooldown = CreateFrame("Cooldown", frame:GetName() .. i .. "CD", button, "CooldownFrameTemplate")
        button.cooldown:SetAllPoints(button)
        button.cooldown:SetReverse(true)
        button.cooldown:SetDrawEdge(false)
        button.cooldown:SetDrawSwipe(true)
        button.cooldown:SetSwipeColor(0, 0, 0, 0.8)

        button.stack = CreateTextFont(button)
        button.stack:SetPoint("BottomRight")

        button.icon = button:CreateTexture()
        button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        button.icon:SetAllPoints(button)

        button:SetSize(size, size)
        if direction == "right" then
            if i == 1 then
                button:SetPoint("BottomLeft", frame)
            elseif i % numPerLine == 1 then
                button:SetPoint("Bottom", buttons[i - numPerLine], "Top", 0, 1)
            else
                button:SetPoint("Left", buttons[i - 1], "Right", spacing, 0)
            end
        else
            if i == 1 then
                button:SetPoint("BottomRight", frame)
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
                frame:GetParent():Update()
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

local function CreateAuraFrame(auras, config)
    local name = config.name
    local size = config.size
    local spacing = config.spacing
    local numPerLine = config.numPerLine
    local numLine = ceil(config.maxAuras / numPerLine)
    local width = numPerLine * size + spacing * (numPerLine - 1)
    local height = numLine * size + numLine - 1
    local frame = CreateFrame("Frame", name, auras)
    frame:SetSize(width, height)
    frame.maxAuras = config.maxAuras
    frame.onlyPlayerCast = config.onlyPlayerCast
    frame.blacklist = config.blacklist
    frame.overridelist = config.overridelist
    local direction = config.direction
    frame.buttons = CreateAuraButtons(frame, size, spacing, direction, numPerLine)
    return frame
end

local function CreateAuras(frame, config)
    local auras = CreateFrame("Frame", nil, frame)

    auras.events = {
        "PLAYER_ENTERING_WORLD", false, "Update",
        "UNIT_AURA", true, "Update",
    }

    if config.debuff then
        auras.debuffs = CreateAuraFrame(auras, config.debuff)
        if frame.unit == "player" then
            auras.debuffs:SetPoint("Top", frame, "Bottom", 0, -1)
        elseif frame.unit == "target" then
            auras.debuffs:SetPoint("Bottom", frame, "Top", 0, 1)
        else
            auras.debuffs:SetPoint("BottomLeft", frame, "TopLeft", 0, 3)
        end
    end

    if config.buff then
        auras.buffs = CreateAuraFrame(auras, config.buff)
        if frame.unit == "player" then
            auras.buffs:SetPoint("Bottom", frame, "Top", 0, 1)
        elseif frame.unit == "target" then
            auras.buffs:SetPoint("Top", frame, "Bottom", 0, -1)
        else
            auras.buffs:SetPoint("TopLeft", frame, "BottomLeft", 0, -3)
        end
    end

    function auras:Update()
        if self.debuffs then
            self.debuffs.totalAuras = 0
            self:Scan(self.debuffs, "debuff", "HARMFUL")
        end

        if self.buffs then
            self.buffs.totalAuras = 0
            self:Scan(self.buffs, "buff", "HELPFUL")
        end
    end

    function auras:Scan(auraFrame, type, filter)
        local index = 0
        while true do
            index = index + 1
            local name, texture, count, auraType, duration, endTime, caster, isRemovable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff = UnitAura(frame.unit, index, filter)
            if not name then
                break
            end
            self:RenderAura(auraFrame, type, index, filter, name, texture, count, duration, endTime, caster, spellID)
            if auraFrame.totalAuras >= auraFrame.maxAuras then
                break
            end
        end

        for i = auraFrame.totalAuras + 1, #(auraFrame.buttons) do
            auraFrame.buttons[i]:Hide()
        end
    end

    function auras:RenderAura(auraFrame, type, index, filter, name, texture, count, duration, endTime, caster, spellID)
        spellID = tostring(spellID)
        -- 通過黑名單過濾光環
        if auraFrame.blacklist and (auraFilter.blacklist[type][name] or auraFilter.blacklist[type][spellID]) then
            return
        end

        -- 通過覆蓋名單和施放者過濾光環
        local CasterIsPlayer = caster == "player" or caster == "vehicle" or caster == "pet"
        if not (auraFrame.overridelist and (auraFilter.overridelist[type][name] or auraFilter.overridelist[type][spellID])) and auraFrame.onlyPlayerCast and not CasterIsPlayer then
            return
        end

        auraFrame.totalAuras = auraFrame.totalAuras + 1
        if auraFrame.buttons[auraFrame.totalAuras] then
            local button = auraFrame.buttons[auraFrame.totalAuras]
            button.cooldown:SetCooldown(endTime - duration, duration)
            button.unit = frame.unit
            button.auraID = index
            button.filter = filter
            button.icon:SetTexture(texture)
            button.stack:SetText(count > 1 and count or "")
            button:Show()
        end
    end

    OnEvent(auras)
    AddToFullUpdates(auras, "Update")
    return auras
end

local function CreateHighlight(frame)
    local highlight = CreateFrame("Frame", nil, frame)

    highlight.events = {
        "PLAYER_TARGET_CHANGED", false, "Update",
    }

    function highlight:Update()
        if UnitIsUnit(frame.unit, "target") then
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

    OnEvent(highlight)
    AddToFullUpdates(highlight, "Update")
    return highlight
end

local function CreateModules(frame, config)
    if config.portrait then
        frame.portrait = CreatePortrait(frame)
    end
    if config.indicators then
        frame.indicators = CreateIndicators(frame, config.indicators)
    end
    if config.health then
        frame.health = CreateHealth(frame)
    end
    if config.power then
        frame.power = CreatePower(frame)
    end
    if config.tags then
        frame.tags = CreateTags(frame, config.tags)
    end
    if config.healAbsorb then
        frame.healAbsorb = CreateHealAbsorb(frame)
    end
    if config.healPrediction then
        frame.healPrediction = CreateHealPrediction(frame)
    end
    if config.totalAbsorb then
        frame.totalAbsorb = CreateTotalAbsorb(frame)
    end
    if config.comboPoints then
        frame.comboPoints = CreateComboPoints(frame)
    end
    if config.altPower then
        frame.altPower = CreateAltPower(frame)
    end
    if config.auras then
        frame.auras = CreateAuras(frame, config.auras)
    end
    if config.highlight then
        frame.highlight = CreateHighlight(frame)
    end
end

local playerConfig = {
    name = "MyUnitPlayer",
    unit = "player",
    otherUnit = "vehicle",
    events = {
        ["PLAYER_LOGIN"] = false,
        ["PLAYER_ALIVE"] = false,
        ["UNIT_ENTERED_VEHICLE"] = true,
        ["UNIT_EXITING_VEHICLE"] = true,
    },
    modules = {
        ["portrait"] = true,
        ["indicators"] = {
            ["raidTarget"] = true,
            ["pvp"] = true,
            ["leader"] = true,
            ["status"] = true,
        },
        ["health"] = true,
        ["power"] = true,
        ["tags"] = {
            ["health"] = true,
            ["percentHealth"] = true,
            ["absorb"] = true,
            ["power"] = true,
            ["percentPower"] = true,
            ["name"] = true,
            ["group"] = true,
            ["afk"] = true,
            ["race"] = true,
            ["level"] = true,
        },
        ["healAbsorb"] = true,
        ["healPrediction"] = true,
        ["totalAbsorb"] = true,
        ["comboPoints"] = true,
        ["auras"] = {
            debuff = {
                name = "MyUnitPlayerDebuff",
                size = 34,
                spacing = 4,
                numPerLine = 8,
                direction = "left",
                maxAuras = 8,
            },
            buff = {
                name = "MyUnitPlayerBuff",
                size = 34,
                spacing = 4,
                numPerLine = 8,
                direction = "left",
                maxAuras = 8,
                onlyPlayerCast = true,
                blacklist = true,
                overridelist = true,
            },
        },
    },
}
local player = CreateUnitFrame(playerConfig)
player:SetSize(300, 60)
player:SetPoint("Bottom", -270, 185)
CreateModules(player, playerConfig.modules)

local petConfig = {
    name = "MyUnitPet",
    unit = "pet",
    otherUnit = "player",
    checkRange = true,
    events = {
        ["UNIT_PET"] = false,
        ["UNIT_ENTERING_VEHICLE"] = true,
        ["UNIT_EXITED_VEHICLE"] = true,
    },
    modules = {
        ["indicators"] = {
            ["raidTarget"] = true,
        },
        ["health"] = true,
        ["power"] = true,
        ["tags"] = {
            ["health"] = true,
            ["percentHealth"] = true,
            ["absorb"] = true,
            ["percentPower"] = true,
            ["name"] = true,
        },
        ["healAbsorb"] = true,
        ["healPrediction"] = true,
        ["totalAbsorb"] = true,
    },
}
local pet = CreateUnitFrame(petConfig)
pet:SetSize(200, 36)
pet:SetPoint("BottomLeft", 567, 110)
CreateModules(pet, petConfig.modules)

local targetConfig = {
    name = "MyUnitTarget",
    unit = "target",
    checkRange = true,
    events = {
        ["PLAYER_TARGET_CHANGED"] = false,
        ["UNIT_TARGETABLE_CHANGED"] = true,
    },
    modules = {
        ["portrait"] = true,
        ["indicators"] = {
            ["raidTarget"] = true,
            ["pvp"] = true,
            ["leader"] = true,
            ["questBoss"] = true,
        },
        ["health"] = true,
        ["power"] = true,
        ["tags"] = {
            ["health"] = true,
            ["percentHealth"] = true,
            ["absorb"] = true,
            ["power"] = true,
            ["percentPower"] = true,
            ["name"] = true,
            ["group"] = true,
            ["afk"] = true,
            ["race"] = true,
            ["level"] = true,
        },
        ["healAbsorb"] = true,
        ["healPrediction"] = true,
        ["totalAbsorb"] = true,
        ["altPower"] = true,
        ["auras"] = {
            debuff = {
                name = "MyUnitTargetDebuff",
                size = 34,
                spacing = 4,
                numPerLine = 8,
                direction = "right",
                maxAuras = 8,
                onlyPlayerCast = true,
                blacklist = true,
                overridelist = true,
            },
            buff = {
                name = "MyUnitTargetBuff",
                size = 34,
                spacing = 4,
                numPerLine = 8,
                direction = "right",
                maxAuras = 8,
            },
        },
    },
}
local target = CreateUnitFrame(targetConfig)
target:SetSize(300, 60)
target:SetPoint("Bottom", 270, 185)
CreateModules(target, targetConfig.modules)

local targetTargetConfig = {
    name = "MyUnitTargetTarget",
    unit = "targetTarget",
    checkRange = true,
    events = {
        ["PLAYER_TARGET_CHANGED"] = false,
        ["UNIT_TARGET"] = false,
    },
    modules = {
        ["indicators"] = {
            ["raidTarget"] = true,
        },
        ["health"] = true,
        ["power"] = true,
        ["tags"] = {
            ["health"] = true,
            ["percentHealth"] = true,
            ["absorb"] = true,
            ["percentPower"] = true,
            ["name"] = true,
        },
        ["healAbsorb"] = true,
        ["healPrediction"] = true,
        ["totalAbsorb"] = true,
    },
}
local targetTarget = CreateUnitFrame(targetTargetConfig)
targetTarget:SetSize(200, 36)
targetTarget:SetPoint("BottomRight", -567, 110)
CreateModules(targetTarget, targetTargetConfig.modules)

local focusConfig = {
    name = "MyUnitFocus",
    unit = "focus",
    checkRange = true,
    events = {
        ["PLAYER_FOCUS_CHANGED"] = false,
        ["UNIT_TARGETABLE_CHANGED"] = true,
    },
    modules = {
        ["indicators"] = {
            ["raidTarget"] = true,
        },
        ["health"] = true,
        ["power"] = true,
        ["tags"] = {
            ["health"] = true,
            ["percentHealth"] = true,
            ["absorb"] = true,
            ["percentPower"] = true,
            ["name"] = true,
        },
        ["healAbsorb"] = true,
        ["healPrediction"] = true,
        ["totalAbsorb"] = true,
        ["altPower"] = true,
        ["auras"] = {
            debuff = {
                name = "MyUnitFocusDebuff",
                size = 27,
                spacing = 1,
                numPerLine = 8,
                direction = "right",
                maxAuras = 8,
                onlyPlayerCast = true,
                blacklist = true,
                overridelist = true,
            },
            buff = {
                name = "MyUnitFocusBuff",
                size = 27,
                spacing = 1,
                numPerLine = 8,
                direction = "right",
                maxAuras = 8,
            }
        },
        ["highlight"] = true,
    },
}
local focus = CreateUnitFrame(focusConfig)
focus:SetSize(195, 48)
focus:SetPoint("BottomLeft", 1385, 202)
CreateModules(focus, focusConfig.modules)

local boss = CreateFrame("Frame", "MyUnitBossFrame", UIParent)
boss:SetSize(259, 465)
boss:SetPoint("BottomLeft", 1350, 285)
local bossConfig = {
    checkRange = true,
    events = {
        ["INSTANCE_ENCOUNTER_ENGAGE_UNIT"] = false,
        ["PLAYER_LOGIN"] = false,
        ["UNIT_TARGETABLE_CHANGED"] = true,
        ["UNIT_NAME_UPDATE"] = true,
    },
    modules = {
        ["indicators"] = {
            ["raidTarget"] = true,
        },
        ["health"] = true,
        ["power"] = true,
        ["tags"] = {
            ["health"] = true,
            ["percentHealth"] = true,
            ["absorb"] = true,
            ["percentPower"] = true,
            ["name"] = true,
        },
        ["healAbsorb"] = true,
        ["healPrediction"] = true,
        ["totalAbsorb"] = true,
        ["altPower"] = true,
        ["auras"] = {
            debuff = {
                size = 31,
                spacing = 1,
                numPerLine = 8,
                direction = "right",
                maxAuras = 8,
                onlyPlayerCast = true,
                blacklist = true,
                overridelist = true,
            },
        },
        ["highlight"] = true,
    },
}
local bosses = {}
for i = 1, 5 do
    bossConfig.name = "MyUnitBoss" .. i
    bossConfig.unit = "boss" .. i
    bosses[i] = CreateUnitFrame(bossConfig)
    bosses[i]:SetSize(228, 33)
    if i == 1 then
        bosses[i]:SetPoint("BottomLeft", boss, 2, 23)
    else
        bosses[i]:SetPoint("Bottom", bosses[i - 1], "Top", 0, 61)
    end
    bossConfig.modules.auras.debuff.name = "MyUnitBoss" .. i .. "Debuff"
    CreateModules(bosses[i], bossConfig.modules)
end