local addonName = ...
local font = GameFontNormal:GetFont()
local combatEvents = {
    DAMAGE_SHIELD = "SpellDamage",
    SPELL_DAMAGE = "SpellDamage",
    SPELL_PERIODIC_DAMAGE = "SpellDamage",
    SPELL_BUILDING_DAMAGE = "SpellDamage",
    RANGE_DAMAGE = "SpellDamage",
    SPELL_ABSORBED = "SpellAbsorbed",
    SWING_DAMAGE = "SwingDamage",
    SWING_MISSED = "SwingMissed",
    SPELL_MISSED = "SpellMissed",
    SPELL_PERIODIC_MISSED = "SpellMissed",
    RANGE_MISSED = "SpellMissed",
    SPELL_BUILDING_MISSED = "SpellMissed",
}
local maxNumSets = 10
local playerModule = { name = "傷害法術列表" }
local damageModule = { name = "傷害", showSpots = true }
local spellModule = { name = "傷害法術細節" }
local targetModule = { name = "受到傷害的怪物" }
local current, total, last, sets
local pets, players = {}, {}
local updateFlag = true
local encounterName, encounterTime
local petFlags = bit.bor(COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_GUARDIAN)
local raidFlags = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)
local dmg = {}
local meter, tooltip
local listener = CreateFrame("Frame")

local function FormatNumber(number)
    if number >= 1e8 then
        return ("%02.2f億"):format(number / 1e8)
    end
    if number >= 1e4 then
        return ("%02.2f萬"):format(number / 1e4)
    end
    return floor(number)
end

local function FormatTime(set)
    if not set then
        return ""
    end

    local startTime = set.startTime
    local endTime = set.endTime or time()
    local duration = SecondsToTime(endTime - startTime, false, false, 2)
    local text = UIParent:CreateFontString()
    text:SetFontObject(GameFontNormal)
    text:SetText(duration)
    duration = "(" .. text:GetText() .. ")"
    return date("%H:%M", startTime) .. " " .. duration
end

local function GetGroupTypeAndCount()
    local type
    local count = GetNumGroupMembers()
    if IsInRaid() then
        type = "raid"
    elseif IsInGroup() then
        type = "party"
        count = count - 1
    end
    return type, count
end

local function CheckGroup()
    local type, count = GetGroupTypeAndCount()
    if count > 0 then
        for i = 1, count do
            local unit = format("%s%d", type, i)
            local playerGUID = UnitGUID(unit)
            if playerGUID then
                players[playerGUID] = true
                local unitPet = unit .. "pet"
                local petGUID = UnitGUID(unitPet)
                if petGUID and not pets[petGUID] then
                    local name, server = UnitName(unit)
                    if server and server ~= "" then
                        name = name .. "-" .. server
                    end
                    pets[petGUID] = { id = playerGUID, name = name }
                end
            end
        end
    end

    local playerGUID = UnitGUID("player")
    if playerGUID then
        players[playerGUID] = true
        local petGUID = UnitGUID("playerpet")
        if petGUID and not pets[petGUID] then
            local name = UnitName("player")
            pets[petGUID] = { id = playerGUID, name = name }
        end
    end
end

local function SetPlayerActiveTimes(set)
    for i = 1, #set.players do
        local player = set.players[i]
        if player.last then
            player.time = player.time + (player.last - player.first)
        end
    end
end

local function GetRaidDPS(set)
    if set.time > 0 then
        return set.damage / max(1, set.time)
    else
        local endTime = set.endTime
        if not endTime then
            endTime = time()
        end
        return set.damage / max(1, endTime - set.startTime)
    end
end

local function CreateSet(name)
    return { players = {}, name = name, startTime = time(), ["time"] = 0, damage = 0, }
end

local function UpdateDisplay(force)
    if force then
        updateFlag = true
    end

    if updateFlag or meter.changed or current then
        meter.changed = false

        if meter.selectedModule then
            local set = meter:GetSelectedSet()
            if set then
                meter.selectedModule:Update(meter, set)
            end

            meter:Display()
        elseif meter.selectedSet then
            local set = meter:GetSelectedSet()
            local data = meter.dataSet[1] or {}
            meter.dataSet[1] = data
            data.id = damageModule.name
            data.label = damageModule.name
            data.value = 1
            if set then
                data.valueText = FormatNumber(set.damage) .. " (" .. FormatNumber(GetRaidDPS(set)) .. ")"
            end
            meter.isSummary = true
            data.icon = "Interface\\Icons\\Inv_throwingaxe_01"

            meter:Display()
        else
            local index = 1
            local data = meter.dataSet[index] or {}
            meter.dataSet[index] = data

            data.id = "total"
            data.label = "總體的"
            data.value = 1
            data.valueText = ""
            data.icon = "Interface\\Icons\\icon_petfamily_critter"

            index = index + 1
            data = meter.dataSet[index] or {}
            meter.dataSet[index] = data

            data.id = "current"
            data.label = "目前的"
            data.value = 1
            data.valueText = ""
            data.icon = "Interface\\Icons\\icon_petfamily_critter"

            for i = 1, #sets do
                index = index + 1
                data = meter.dataSet[index] or {}
                meter.dataSet[index] = data

                data.id = tostring(sets[i].startTime)
                data.label = sets[i].name
                data.value = 1
                data.valueText = FormatTime(sets[i])
                data.icon = "Interface\\Icons\\icon_petfamily_critter"
            end

            meter:Display()
        end
    end

    updateFlag = false
end

local function EndSegment()
    if not current then
        return
    end

    if current.mobName ~= nil and time() - current.startTime >= 5 then
        if not current.endTime then
            current.endTime = time()
        end
        current.time = current.endTime - current.startTime
        SetPlayerActiveTimes(current)

        local name = current.mobName
        local count = 0
        for i = 1, #sets do
            if sets[i].name == name and count == 0 then
                count = 1
            else
                local n, c = strmatch(sets[i].name, "^(.-)%s*%((%d+)%)$")
                if n == name then
                    count = max(count, tonumber(c) or 0)
                end
            end
        end
        if count > 0 then
            name = name .. "(" .. (count + 1) .. ")"
        end
        current.name = name

        tinsert(sets, 1, current)
    end

    last = current

    total.time = total.time + current.time
    SetPlayerActiveTimes(total)
    for i = 1, #total.players do
        total.players[i].first = nil
        total.players[i].last = nil
    end
    current = nil

    local numSets = 0
    for i = 1, #sets do
        if not sets[i].keep then
            numSets = numSets + 1
        end
    end
    for i = #sets, 1, -1 do
        if numSets > maxNumSets and not sets[i].keep then
            tremove(sets, i)
            numSets = numSets - 1
        end
    end

    meter:Wipe()
    UpdateDisplay(true)
    meter:SetScript("OnUpdate", nil)
end

local function IsRaidInCombat()
    local type, count = GetGroupTypeAndCount()
    if count > 0 then
        for i = 1, count do
            if UnitExists(type .. i) and UnitAffectingCombat(type .. i) then
                return true
            end
        end
    elseif UnitAffectingCombat("player") then
        return true
    end
end

local function IsCombatEnd()
    if current and not InCombatLockdown() and not IsRaidInCombat() then
        EndSegment()
    end
end

local function StartCombat()
    meter:Wipe()

    if not current then
        current = CreateSet("current")
    end

    if encounterName and GetTime() < (encounterTime or 0) + 15 then
        current.mobName = encounterName
        encounterName = nil
        encounterTime = nil
    end

    if not total then
        total = CreateSet("total")
        MyDamageMeter.total = total
    end

    UpdateDisplay(true)

    meter:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 1 then
            return
        end
        self.elapsed = 0

        UpdateDisplay()
        IsCombatEnd()
    end)
end

local function IsCombatEvent(eventType)
    for event, func in pairs(combatEvents) do
        if event == eventType then
            return func
        end
    end
end

local function OnCombatEvent(timestamp, eventType, _, srcGUID, srcName, srcFlags, _, dstGUID, dstName, dstFlags, _, ...)
    local srcFilter, dstFilter

    if current and IsCombatEvent(eventType) then
        local func = IsCombatEvent(eventType)
        srcFilter = bit.band(srcFlags, raidFlags) ~= 0 or (bit.band(srcFlags, petFlags) ~= 0 and pets[srcGUID]) or players[srcGUID]
        dstFilter = bit.band(dstFlags, raidFlags) ~= 0 or (bit.band(dstFlags, petFlags) ~= 0 and pets[dstGUID]) or players[dstGUID]
        if srcFilter and not dstFilter then
            listener[func](listener, timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
        end
    end

    if current and srcFilter and bit.band(dstFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) == 0 and not current.mobName then
        current.mobName = dstName
    end

    if eventType == "SPELL_SUMMON" and ((bit.band(srcFlags, raidFlags) ~= 0) or ((bit.band(srcFlags, petFlags)) ~= 0) or ((bit.band(dstFlags, petFlags) ~= 0) and pets[dstGUID])) then
        pets[dstGUID] = { id = srcGUID, name = srcName }
        if pets[srcGUID] then
            pets[dstGUID].id = pets[srcGUID].id
            pets[dstGUID].name = pets[srcGUID].name
        end
    end
end

listener:RegisterEvent("ADDON_LOADED")
listener:RegisterEvent("PLAYER_ENTERING_WORLD")
listener:RegisterEvent("GROUP_ROSTER_UPDATE")
listener:RegisterEvent("UNIT_PET")
listener:RegisterEvent("PLAYER_REGEN_DISABLED")
listener:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
listener:RegisterEvent("ENCOUNTER_START")
listener:RegisterEvent("ENCOUNTER_END")
listener:RegisterEvent("PLAYER_LOGIN")
listener:RegisterEvent("PLAYER_LOGOUT")

listener:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if ... == addonName then
            if not MyDamageMeter then
                MyDamageMeter = {
                    ["sets"] = {},
                }
            end
            sets = MyDamageMeter.sets
            self:UnregisterEvent(event)
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        OnCombatEvent(CombatLogGetCurrentEventInfo())
    elseif event == "PLAYER_REGEN_DISABLED" then
        StartCombat()
    elseif event == "ENCOUNTER_START" then
        if current then
            current.mobName = encounterName
        else
            encounterName = encounterName
            encounterTime = GetTime()
        end
    elseif event == "ENCOUNTER_END" then
        if current and not current.mobName then
            current.mobName = encounterName
        end
    elseif event == "PLAYER_LOGIN" then
        total = MyDamageMeter.total
        damageModule.next1 = playerModule
        damageModule.next2 = targetModule
        playerModule.previous = damageModule
        playerModule.next1 = spellModule
        spellModule.previous = playerModule
        targetModule.previous = damageModule
    elseif event == "PLAYER_LOGOUT" then
        total.playerIndex = nil
        for i = 1, #sets do
            sets[i].playerIndex = nil
        end
    else
        CheckGroup()
    end
end)

local function PlayerActiveTime(set, player)
    local maxTime = 0

    if player.time > 0 then
        maxTime = player.time
    end

    if not set.endTime and player.first then
        maxTime = maxTime + player.last - player.first
    end
    return maxTime
end

local function GetDPS(set, player)
    local totalTime = PlayerActiveTime(set, player)
    return player.damage / max(1, totalTime)
end

function damageModule:Update(window, set)
    local maxValue = 0
    local index = 1
    for i = 1, #set.players do
        local player = set.players[i]
        if player.damage > 0 then
            local dataSet = window.dataSet
            local dps = GetDPS(set, player)
            local data = dataSet[index] or {}
            dataSet[index] = data

            data.label = player.name
            data.valueText = FormatNumber(player.damage) .. " (" .. FormatNumber(dps) .. ", " .. format("%.1f%%", player.damage / set.damage * 100) .. ")"
            data.value = player.damage
            data.id = player.id
            data.class = player.class
            if player.damage > maxValue then
                maxValue = player.damage
            end
            index = index + 1
        end
    end
    window.barMaxValue = maxValue
end

local function FindPlayer(set, playerID)
    if set then
        set.playerIndex = set.playerIndex or {}
        local player = set.playerIndex[playerID]
        if player then
            return player
        end
        for i = 1, #set.players do
            if set.players[i].id == playerID then
                set.playerIndex[playerID] = set.players[i]
                return set.players[i]
            end
        end
    end
end

function damageModule:PostTooltip(window, id, _)
    local set = window:GetSelectedSet()
    local player = FindPlayer(set, id)
    if player then
        local activeTime = PlayerActiveTime(set, player)
        local totalTime = set.time
        GameTooltip:AddDoubleLine("活躍度", format("%.1f%%", activeTime / max(1, totalTime) * 100), 1, 1, 1)
    end
end

function playerModule:Update(window, set)
    local player = FindPlayer(set, self.playerID)
    local maxValue = 0
    if player then
        local index = 1
        for spellName, spell in pairs(player.spells) do
            local dataSet = window.dataSet
            local data = dataSet[index] or {}
            dataSet[index] = data
            data.label = spellName
            data.id = spellName
            local _, _, icon = GetSpellInfo(spell.id)
            data.icon = icon
            data.spellID = spell.id
            data.value = spell.damage
            if spell.school then
                data.spellSchool = spell.school
            end
            data.valueText = FormatNumber(spell.damage) .. " " .. format("(%.1f%%)", spell.damage / player.damage * 100)
            if spell.damage > maxValue then
                maxValue = spell.damage
            end
            index = index + 1
        end
    end
    window.barMaxValue = maxValue
end

function playerModule:Enter(window, id, _)
    local player = FindPlayer(window:GetSelectedSet(), id)
    if player then
        self.playerID = id
        self.title = player.name .. "的傷害"
    end
end

function playerModule:Tooltip(window, _, label)
    local player = FindPlayer(window:GetSelectedSet(), playerModule.playerID)
    if player then
        local spell = player.spells[label]
        if spell then
            GameTooltip:AddLine(player.name .. " - " .. label, 1, 1, 1)
            if spell.school then
                local color = CombatLog_Color_ColorArrayBySchool(spell.school)
                if color then
                    GameTooltip:AddLine(GetSchoolString(spell.school), color.r, color.g, color.b)
                end
            end
            if spell.min and spell.max then
                GameTooltip:AddDoubleLine("最小值:", FormatNumber(spell.min), 1, 1, 1)
                GameTooltip:AddDoubleLine("最大值:", FormatNumber(spell.max), 1, 1, 1)
            end
            GameTooltip:AddDoubleLine("平均值:", FormatNumber(spell.damage / spell.totalHits), 1, 1, 1)
        end
    end
end

local function AddDetailBar(window, label, value)
    local index = spellModule.index + 1
    spellModule.index = index
    local dataSet = window.dataSet
    local data = dataSet[index] or {}
    dataSet[index] = data

    data.label = label
    data.value = value
    data.id = label
    data.valueText = value .. " " .. format("(%.1f%%)", value / spellModule.totalHits * 100)
    window.barMaxValue = max(window.barMaxValue, value)
end

function spellModule:Update(window, set)
    local player = FindPlayer(set, playerModule.playerID)
    if player then
        local spell = player.spells[self.spellName]
        if spell then
            self.totalHits = spell.totalHits
            self.index = 0
            window.barMaxValue = 0

            if spell.hit and spell.hit > 0 then
                AddDetailBar(window, "命中", spell.hit)
            end
            if spell.critical and spell.critical > 0 then
                AddDetailBar(window, "致命一擊", spell.critical)
            end
            if spell.glancing and spell.glancing > 0 then
                AddDetailBar(window, "偏斜", spell.glancing)
            end
            if spell.crushing and spell.crushing > 0 then
                AddDetailBar(window, "碾壓", spell.crushing)
            end
            if spell.ABSORB and spell.ABSORB > 0 then
                AddDetailBar(window, "吸收", spell.ABSORB)
            end
            if spell.BLOCK and spell.BLOCK > 0 then
                AddDetailBar(window, "格擋", spell.BLOCK)
            end
            if spell.DEFLECT and spell.DEFLECT > 0 then
                AddDetailBar(window, "偏斜", spell.DEFLECT)
            end
            if spell.DODGE and spell.DODGE > 0 then
                AddDetailBar(window, "閃躲", spell.DODGE)
            end
            if spell.EVADE and spell.EVADE > 0 then
                AddDetailBar(window, "閃避", spell.EVADE)
            end
            if spell.IMMUNE and spell.IMMUNE > 0 then
                AddDetailBar(window, "免疫", spell.IMMUNE)
            end
            if spell.MISS and spell.MISS > 0 then
                AddDetailBar(window, "未擊中", spell.MISS)
            end
            if spell.PARRY and spell.PARRY > 0 then
                AddDetailBar(window, "招架", spell.PARRY)
            end
            if spell.REFLECT and spell.REFLECT > 0 then
                AddDetailBar(window, "反射", spell.REFLECT)
            end
            if spell.RESIST and spell.RESIST > 0 then
                AddDetailBar(window, "抵抗", spell.RESIST)
            end
        end
    end
end

function spellModule:Enter(window, _, label)
    local player = FindPlayer(window:GetSelectedSet(), playerModule.playerID)
    if player then
        self.spellName = label
        self.playerID = playerModule.playerID
        self.title = player.name .. "的" .. label
    end
end

function spellModule:Tooltip(window, _, label)
    local player = FindPlayer(window:GetSelectedSet(), spellModule.playerID)
    if player then
        local spell = player.spells[spellModule.spellName]
        if spell then
            GameTooltip:AddLine(player.name .. " - " .. spellModule.spellName, 1, 1, 1)
            if label == "致命一擊" and spell.criticalAmount then
                GameTooltip:AddDoubleLine("最小", FormatNumber(spell.criticalMin), 1, 1, 1)
                GameTooltip:AddDoubleLine("最大", FormatNumber(spell.criticalMax), 1, 1, 1)
                GameTooltip:AddDoubleLine("平均", FormatNumber(spell.criticalAmount / spell.critical), 1, 1, 1)
            end
            if label == "命中" and spell.hitAmount then
                GameTooltip:AddDoubleLine("最小", FormatNumber(spell.hitMin), 1, 1, 1)
                GameTooltip:AddDoubleLine("最大", FormatNumber(spell.hitMax), 1, 1, 1)
                GameTooltip:AddDoubleLine("平均", FormatNumber(spell.hitAmount / spell.hit), 1, 1, 1)
            end
        end
    end
end

function targetModule:Update(window, set)
    local player = FindPlayer(set, self.playerID)
    local maxValue = 0
    if player then
        local dataSet = window.dataSet
        local index = 1
        for target, amount in pairs(player.targets) do
            local data = dataSet[index] or {}
            dataSet[index] = data
            data.label = target
            data.id = target
            data.value = amount
            data.valueText = FormatNumber(amount) .. " " .. format("(%.1f%%)", amount / player.damage * 100)
            if amount > maxValue then
                maxValue = amount
            end
            index = index + 1
        end
    end
    window.barMaxValue = maxValue
end

function targetModule:Enter(window, id, _)
    local player = FindPlayer(window:GetSelectedSet(), id)
    self.playerID = id
    self.title = (player and player.name or "Unknown") .. "的受到傷害的怪物"
end

local function GetPlayer(set, playerID, playerName)
    local player = FindPlayer(set, playerID)

    if not player then
        if not playerName then
            return
        end

        local _, playerClass = UnitClass(playerName)
        player = {
            id = playerID,
            class = playerClass,
            name = playerName,
            first = time(),
            ["time"] = 0,
            damage = 0,
            spells = {},
            targets = {},
        }

        local name, realm = strsplit("-", playerName, 2)
        player.name = name or playerName

        set.players[#set.players + 1] = player
    end

    if player.name == UNKNOWN and playerName ~= UNKNOWN then
        local name, realm = strsplit("-", playerName, 2)
        player.name = name or playerName
        local _, playerClass = UnitClass(playerName)
        player.class = playerClass
    end

    if not player.first then
        player.first = time()
    end

    player.last = time()
    updateFlag = true
    return player
end

local function LogDamage(set, dmg)
    local player = GetPlayer(set, dmg.playerID, dmg.playerName)
    if player then
        local amount = dmg.amount
        set.damage = set.damage + amount
        player.damage = player.damage + amount

        if not player.spells[dmg.spellName] then
            player.spells[dmg.spellName] = { id = dmg.spellID, totalHits = 0, damage = 0, school = dmg.school }
        end
        local spell = player.spells[dmg.spellName]
        spell.damage = spell.damage + amount
        spell.totalHits = spell.totalHits + 1
        if spell.max == nil or amount > spell.max then
            spell.max = amount
        end
        if (spell.min == nil or amount < spell.min) and not dmg.missed then
            spell.min = amount
        end

        if dmg.critical then
            spell.critical = (spell.critical or 0) + 1
            spell.criticalAmount = (spell.criticalAmount or 0) + amount
            if not spell.criticalMax or amount > spell.criticalMax then
                spell.criticalMax = amount
            end
            if not spell.criticalMin or amount < spell.criticalMin then
                spell.criticalMin = amount
            end
        elseif dmg.missed ~= nil then
            spell[dmg.missed] = (spell[dmg.missed] or 0) + 1
        elseif dmg.glancing then
            spell.glancing = (spell.glancing or 0) + 1
        elseif dmg.crushing then
            spell.crushing = (spell.crushing or 0) + 1
        else
            spell.hit = (spell.hit or 0) + 1
            spell.hitAmount = (spell.hitAmount or 0) + amount
            if not spell.hitMax or amount > spell.hitMax then
                spell.hitMax = amount
            end
            if not spell.hitMin or amount < spell.hitMin then
                spell.hitMin = amount
            end
        end

        if set == current and dmg.dstName and amount > 0 then
            if not player.targets[dmg.dstName] then
                player.targets[dmg.dstName] = 0
            end

            player.targets[dmg.dstName] = player.targets[dmg.dstName] + amount
        end
    end
end

local function FixPets(dmg)
    if dmg and dmg.playerName then
        local pet = pets[dmg.playerID]
        if pet then
            if dmg.spellName then
                dmg.spellName = dmg.playerName .. ": " .. dmg.spellName
            end
            dmg.playerName = pet.name
            dmg.playerID = pet.id
        else
            if dmg.playerFlags and bit.band(dmg.playerFlags, COMBATLOG_OBJECT_TYPE_GUARDIAN) ~= 0 then
                if bit.band(dmg.playerFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 then
                    if dmg.spellName then
                        dmg.spellName = dmg.playerName .. ": " .. dmg.spellName
                    end
                    dmg.playerName = UnitName("player")
                    dmg.playerID = UnitGUID("player")
                else
                    dmg.playerID = dmg.playerName
                end
            end
        end
    end
end

function listener:SpellDamage(_, _, srcGUID, srcName, srcFlags, dstGUID, dstName, _, spellID, spellName, spellSchool, sAmount, sOverkill, _, sResisted, sBlocked, sAbsorbed, sCritical, sGlancing, sCrushing, sOffhand)
    if srcGUID ~= dstGUID then
        if strmatch(dstGUID, "^Creature%-0%-%d+%-%d+%-%d+%-76933%-%w+$") or strmatch(dstGUID, "^Creature%-0%-%d+%-%d+%-%d+%-103679%-%w+$") then
            return
        end

        dmg.playerID = srcGUID
        dmg.playerFlags = srcFlags
        dmg.dstName = dstName
        dmg.playerName = srcName
        dmg.spellID = spellID
        dmg.spellName = spellName
        dmg.amount = sAmount
        dmg.overkill = sOverkill
        dmg.resisted = sResisted
        dmg.blocked = sBlocked
        dmg.absorbed = sAbsorbed
        dmg.critical = sCritical
        dmg.glancing = sGlancing
        dmg.crushing = sCrushing
        dmg.offhand = sOffhand
        dmg.missed = nil
        dmg.school = spellSchool

        FixPets(dmg)
        LogDamage(current, dmg)
        LogDamage(total, dmg)
    end
end

function listener:SwingDamage(_, _, srcGUID, srcName, srcFlags, dstGUID, dstName, _, sAmount, sOverkill, _, sResisted, sBlocked, sAbsorbed, sCritical, sGlancing, sCrushing, sOffhand)
    if srcGUID ~= dstGUID then
        dmg.playerID = srcGUID
        dmg.playerFlags = srcFlags
        dmg.dstName = dstName
        dmg.playerName = srcName
        dmg.spellID = 6603
        dmg.spellName = "近戰攻擊"
        dmg.amount = sAmount
        dmg.overkill = sOverkill
        dmg.resisted = sResisted
        dmg.blocked = sBlocked
        dmg.absorbed = sAbsorbed
        dmg.critical = sCritical
        dmg.glancing = sGlancing
        dmg.crushing = sCrushing
        dmg.offhand = sOffhand
        dmg.missed = nil
        dmg.school = 0x01

        FixPets(dmg)
        LogDamage(current, dmg)
        LogDamage(total, dmg)
    end
end

function listener:SpellAbsorbed(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
    local chk = ...
    local spellID, spellName, spellSchool, aGUID, aName, aFlags, aRaidFlags, aspellID, aspellName, aspellSchool, aAmount

    if type(chk) == "number" then
        spellID, spellName, spellSchool, aGUID, aName, aFlags, aRaidFlags, aspellID, aspellName, aspellSchool, aAmount = ...

        if aspellID == 184553 then
            return
        end

        if aAmount then
            self:SpellDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID, spellName, spellSchool, aAmount)
        end
    else
        aGUID, aName, aFlags, aRaidFlags, aspellID, aspellName, aspellSchool, aAmount = ...

        if aspellID == 184553 then
            return
        end

        if aAmount then
            self:SwingDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, aAmount)
        end
    end
end

function listener:SwingMissed(_, _, srcGUID, srcName, srcFlags, dstGUID, dstName, _, missed)
    if srcGUID ~= dstGUID then
        dmg.playerID = srcGUID
        dmg.playerFlags = srcFlags
        dmg.dstName = dstName
        dmg.playerName = srcName
        dmg.spellID = 6603
        dmg.spellName = "近戰攻擊"
        dmg.amount = 0
        dmg.overkill = 0
        dmg.resisted = nil
        dmg.blocked = nil
        dmg.absorbed = nil
        dmg.critical = nil
        dmg.glancing = nil
        dmg.crushing = nil
        dmg.offhand = nil
        dmg.missed = missed

        FixPets(dmg)
        LogDamage(current, dmg)
        LogDamage(total, dmg)
    end
end

function listener:SpellMissed(_, _, srcGUID, srcName, srcFlags, dstGUID, dstName, _, spellID, spellName, _, missType)
    if srcGUID ~= dstGUID then
        dmg.playerID = srcGUID
        dmg.playerFlags = srcFlags
        dmg.dstName = dstName
        dmg.playerName = srcName
        dmg.spellID = spellID
        dmg.spellName = spellName
        dmg.amount = 0
        dmg.overkill = 0
        dmg.resisted = nil
        dmg.blocked = nil
        dmg.absorbed = nil
        dmg.critical = nil
        dmg.glancing = nil
        dmg.crushing = nil
        dmg.offhand = nil
        dmg.missed = missType

        FixPets(dmg)
        LogDamage(current, dmg)
        LogDamage(total, dmg)
    end
end

local function CreateTitle(window)
    local title = window:CreateTexture()
    title:SetSize(window:GetWidth(), 20)
    title:SetPoint("Top")
    title:SetColorTexture(0.3, 0.3, 0.3)

    title.text = window:CreateFontString()
    title.text:SetFont(font, 13, "Outline")
    title.text:SetPoint("Left", title, 6, 0)

    return title
end

local function CreateButton(window, config)
    local button = CreateFrame("Button", config.name, window)
    button:SetSize(12, 12)
    button:SetNormalTexture(config.texture)
    button:SetHighlightTexture(config.texture, 1)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    return button
end

local function CreateButtonGroup(window)
    local group = {}
    local config = {
        name = "DamageMeterConfigButton",
        texture = "Interface\\Buttons\\UI-OptionsButton",
    }
    group.config = CreateButton(window, config)
    group.config:SetPoint("Right", window.title, -6, 0)
    group.config:SetScript("OnClick", function()
        window:OpenConfigMenu()
    end)

    config = {
        name = "DamageMeterResetButton",
        texture = "Interface\\Buttons\\UI-StopButton",
    }
    group.reset = CreateButton(window, config)
    group.reset:SetPoint("Right", group.config, "Left", -3, 0)
    group.reset:SetScript("OnClick", function()
        window:Reset()
    end)

    config = {
        name = "DamageMeterResetButton",
        texture = "Interface\\Buttons\\UI-GuildButton-PublicNote-Up",
    }
    group.segment = CreateButton(window, config)
    group.segment:SetPoint("Right", group.reset, "Left", -3, 0)
    group.segment:SetScript("OnClick", function()
        window:OpenSegmentMenu()
    end)

    return group
end

local function SortDataByValue(a, b)
    if not a or a.value == nil then
        return false
    elseif not b or b.value == nil then
        return true
    else
        return a.value > b.value
    end
end

local function AddSubviewToTooltip(window, module, id, label)
    local set = window:GetSelectedSet()
    if not set then
        return
    end

    wipe(tooltip.dataSet)

    if module.Enter then
        module:Enter(window, id, label)
    end

    module:Update(tooltip, set)
    table.sort(tooltip.dataSet, SortDataByValue)
    if #tooltip.dataSet > 0 then
        GameTooltip:AddLine(module.title or module.name, 1, 1, 1)

        local row = 0
        for i = 1, #tooltip.dataSet do
            local data = tooltip.dataSet[i]
            if data.id and row < window.maxTooltipRows then
                row = row + 1
                local text = module.showSpots and row .. ". " .. data.label or data.label
                GameTooltip:AddDoubleLine(text, data.valueText, 1, 1, 1)
            end
        end

        if module.Enter then
            GameTooltip:AddLine(" ")
        end
    end
end

local function CreateBar(window, data, id, label)
    local bar = CreateFrame("StatusBar", nil, window)
    window.bars[id] = bar
    window.numBars = window.numBars + 1

    bar.id = id
    bar.text = label

    local height = 18
    if window.selectedModule == spellModule or window.selectedModule == targetModule then
        bar:SetSize(window:GetWidth(), height)
    else
        bar:SetSize(window:GetWidth() - height, height)

        bar.icon = bar:CreateTexture()
        bar.icon:SetSize(height, height)
        bar.icon:SetPoint("Right", bar, "Left")
        if data.icon then
            bar.icon:SetTexture(data.icon)
            bar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        elseif data.class then
            bar.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
            local l, r, t, b = unpack(CLASS_ICON_TCOORDS[data.class])
            local adj = 0.02
            bar.icon:SetTexCoord(l + adj, r - adj, t + adj, b - adj)
        else
            bar.icon:SetTexture("Interface\\Icons\\inv_misc_questionmark")
            bar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end
    end

    bar:SetStatusBarTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    if data.spellSchool then
        if CombatLog_Color_ColorArrayBySchool then
            local color = CombatLog_Color_ColorArrayBySchool(data.spellSchool)
            bar:SetStatusBarColor(color.r, color.g, color.b)
        end
    elseif data.class then
        local color = RAID_CLASS_COLORS[data.class]
        bar:SetStatusBarColor(color:GetRGB())
    else
        bar:SetStatusBarColor(0.3, 0.3, 0.8)
    end

    bar.leftText = bar:CreateFontString()
    bar.leftText:SetFont(font, 13, "Outline")
    bar.leftText:SetPoint("Left", 3, 0)
    bar.rightText = bar:CreateFontString()
    bar.rightText:SetFont(font, 13, "Outline")
    bar.rightText:SetPoint("Right", -3, 0)

    bar:SetScript("OnMouseDown", function(self, mouse)
        window:Click(mouse, self)
    end)

    bar:SetScript("OnEnter", function()
        GameTooltip:SetOwner(window, "ANCHOR_NONE")
        GameTooltip:SetPoint("TopLeft", window, "TopRight", 10, 0)

        if window.isSummary then
            GameTooltip:ClearLines()
            tooltip.selectedModule = damageModule
            AddSubviewToTooltip(window, tooltip.selectedModule, id, label)
            GameTooltip:Show()
        elseif window.selectedModule then
            GameTooltip:ClearLines()
            local hasClick = window.selectedModule.next1 or window.selectedModule.next2

            if window.selectedModule.Tooltip then
                local numLines = GameTooltip:NumLines()
                window.selectedModule:Tooltip(window, id, label)
                if GameTooltip:NumLines() ~= numLines and hasClick then
                    GameTooltip:AddLine(" ")
                end
            end

            if window.selectedModule.next1 then
                tooltip.selectedModule = window.selectedModule.next1
                AddSubviewToTooltip(window, tooltip.selectedModule, id, label)
            end
            if window.selectedModule.next2 then
                tooltip.selectedModule = window.selectedModule.next2
                AddSubviewToTooltip(window, tooltip.selectedModule, id, label)
            end

            if window.selectedModule.PostTooltip then
                local numLines = GameTooltip:NumLines()
                window.selectedModule:PostTooltip(window, id, label)
                if GameTooltip:NumLines() ~= numLines and hasClick then
                    GameTooltip:AddLine(" ")
                end
            end

            if window.selectedModule.next1 then
                GameTooltip:AddLine("點擊後爲 " .. window.selectedModule.next1.name .. ".", 0.2, 1, 0.2)
            end
            if window.selectedModule.next2 then
                GameTooltip:AddLine("Shift+點擊後爲 " .. window.selectedModule.next2.name .. ".", 0.2, 1, 0.2)
            end

            GameTooltip:Show()
        end
    end)

    bar:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return bar
end

local function UpdateBar(window, bar, index, data)
    bar.index = index
    bar:SetMinMaxValues(0, window.barMaxValue)
    bar:SetValue(data.value)
    if window.selectedModule and window.selectedModule.showSpots then
        bar.leftText:SetFormattedText("%2u. %s", index, data.label)
    else
        bar.leftText:SetText(data.label)
    end
    bar.rightText:SetText(data.valueText)
end

local function UpdateBarVisibility(window)
    local minIndex = 1 + window.barOffset
    local maxIndex = window.maxBars + window.barOffset
    for _, bar in pairs(window.bars) do
        local index = bar.index
        if index >= minIndex and index <= maxIndex then
            bar:SetPoint("TopRight", window.title, "BottomRight", 0, (bar:GetHeight() + 1) * (minIndex - index) - 1)
            bar:Show()
        else
            bar:Hide()
        end
    end
end

local function GetCharSize(char)
    if not char then
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    end
    return 1
end

local function CutOffText(text, maxWidth)
    if #text * 5 <= maxWidth then
        return text
    end
    local length = 0
    local offset = 0
    for i = 1, #text do
        local index = i + offset
        local size = GetCharSize(strbyte(text, index))

        length = length + size
        if length * 5 > maxWidth then
            return strsub(text, 1, index - 1) .. "..."
        end

        offset = offset + size - 1
    end
end

local function CreateWindow()
    local window = CreateFrame("Frame", "MyDamageMeterFrame", UIParent)
    window:SetSize(470, 116)
    window:SetPoint("BottomLeft")
    window:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
    window:SetBackdropColor(0, 0, 0, 0.8)

    window.selectedModule = nil
    window.selectedSet = nil
    window.isSummary = false
    window.dataSet = {}
    window.changed = false
    window.bars = {}
    window.numBars = 0
    window.maxBars = 5
    window.barOffset = 0
    window.barMaxValue = nil
    window.maxTooltipRows = 3
    window.title = CreateTitle(window)
    window.buttons = CreateButtonGroup(window)

    window:SetScript("OnMouseDown", function(self, mouse)
        self:Click(mouse)
    end)

    window:SetScript("OnMouseWheel", function(self, value)
        if value > 0 and self.barOffset > 0 then
            self.barOffset = self.barOffset - 1
            UpdateBarVisibility(self)
        elseif value < 0 and self.numBars - self.maxBars - self.barOffset > 0 then
            self.barOffset = self.barOffset + 1
            UpdateBarVisibility(self)
        end
    end)

    window:RegisterEvent("PLAYER_LOGIN")

    window:SetScript("OnEvent", function(self)
        self.selectedSet = "current"
        self.selectedModule = damageModule
        self:DisplayModule(self.selectedModule)
    end)

    function window:Wipe()
        for i = 1, #self.dataSet do
            wipe(self.dataSet[i])
        end

        self.barOffset = 0
        for _, bar in pairs(self.bars) do
            bar:Hide()
        end
        wipe(self.bars)
        self.numBars = 0
    end

    function window:GetSelectedSet()
        if self.selectedSet == "current" then
            if current ~= nil then
                return current
            elseif last ~= nil then
                return last
            else
                return sets[1]
            end
        elseif self.selectedSet == "total" then
            return total
        else
            return sets[self.selectedSet]
        end
    end

    function window:DeleteSet(set)
        for i = 1, #sets do
            if sets[i] == set then
                wipe(tremove(sets, i))

                if set == last then
                    last = nil
                end

                if self.selectedSet == i or self:GetSelectedSet() == set then
                    self.selectedSet = "current"
                    self.changed = true
                elseif (tonumber(self.selectedSet) or 0) > i then
                    self.selectedSet = self.selectedSet - 1
                    self.changed = true
                end
                break
            end
        end

        self:Wipe()
        UpdateDisplay(true)
    end

    function window:SetModuleTitle()
        if not self.selectedModule or not self.selectedSet then
            return
        end

        local name = self.selectedModule.title or self.selectedModule.name
        local setName
        if self.selectedSet == "current" then
            setName = "目前的"
        elseif self.selectedSet == "total" then
            setName = "總體的"
        else
            local set = self:GetSelectedSet()
            if set then
                setName = (set.name or "Unknown") .. ": " .. FormatTime(set)
            end
        end
        if setName then
            name = name .. ": " .. setName
        end

        local maxWidth = self:GetWidth() - 50
        self.title.text:SetText(CutOffText(name, maxWidth))
    end

    function window:Display()
        if not self.barMaxValue then
            self.barMaxValue = 0
            for i = 1, #self.dataSet do
                if self.dataSet[i].id and self.dataSet[i].value > self.barMaxValue then
                    self.barMaxValue = self.dataSet[i].value
                end
            end
        end

        self:DisplayBars()
        self:SetModuleTitle()
    end

    function window:DisplaySets()
        self:Wipe()
        self.selectedSet = nil
        self.selectedModule = nil
        self.isSummary = false
        self.title.text:SetText("戰鬥")
        self.barMaxValue = 1
        self.changed = true
        UpdateDisplay()
    end

    function window:DisplaySummary(setTime)
        self:Wipe()
        self.selectedModule = nil
        if setTime == "current" or setTime == "total" then
            self.selectedSet = setTime
        else
            for i = 1, #sets do
                if tostring(sets[i].startTime) == setTime then
                    if sets[i].name == "current" then
                        self.selectedSet = "current"
                    elseif sets[i].name == "total" then
                        self.selectedSet = "total"
                    else
                        self.selectedSet = i
                    end
                end
            end
        end
        self.title.text:SetText("概要")
        self.barMaxValue = 1
        self.changed = true
        UpdateDisplay()
    end

    function window:DisplayModule(module)
        self:Wipe()
        self.isSummary = false
        self.selectedModule = module
        self.changed = true
        self:SetModuleTitle()
        UpdateDisplay()
    end

    function window:DisplayBars()
        if self.selectedModule then
            table.sort(self.dataSet, SortDataByValue)
        end

        local index = 1
        for i = 1, #self.dataSet do
            local data = self.dataSet[i]
            if data.id then
                local barID = data.id
                local barText = data.label
                local bar = self.bars[barID] or CreateBar(self, data, barID, barText)
                UpdateBar(self, bar, index, data)
                index = index + 1
            end
        end

        UpdateBarVisibility(self)
    end

    function window:Click(mouse, bar)
        if mouse == "RightButton" then
            if self.isSummary then
                self:DisplaySets()
            elseif self.selectedModule == damageModule then
                self:DisplaySummary(self.selectedSet)
            else
                self:DisplayModule(self.selectedModule.previous)
            end
        elseif bar then
            if self.isSummary then
                self:DisplayModule(damageModule)
            elseif not self.selectedModule then
                self.selectedSet = bar.id
                self:DisplaySummary(self.selectedSet)
            else
                local module = IsShiftKeyDown() and self.selectedModule.next2 or self.selectedModule.next1
                if module then
                    module:Enter(self, bar.id, bar.text)
                    self:DisplayModule(module)
                end
            end
        end
    end

    function window:CreateDeleteSetInfo(i)
        local info = UIDropDownMenu_CreateInfo()
        info.text = (sets[i].name or "Unknown") .. ": " .. FormatTime(sets[i])
        info.func = function()
            self:DeleteSet(sets[i])
        end
        info.notCheckable = 1
        return info
    end

    function window:CreateKeepSetInfo(i)
        local info = UIDropDownMenu_CreateInfo()
        info.text = (sets[i].name or "Unknown") .. ": " .. FormatTime(sets[i])
        info.func = function()
            sets[i].keep = not sets[i].keep
            self:Wipe()
            UpdateDisplay(true)
        end
        info.checked = sets[i].keep
        return info
    end

    function window:CreateSelectSetInfo(i)
        local info = UIDropDownMenu_CreateInfo()
        info.text = (sets[i].name or "Unknown") .. ": " .. FormatTime(sets[i])
        info.func = function()
            self.selectedSet = i
            self:Wipe()
            UpdateDisplay(true)
        end
        info.checked = (self.selectedSet == i)
        return info
    end

    function window:OpenConfigMenu()
        local menu = CreateFrame("Frame")
        menu.displayMode = "MENU"
        local info
        menu.initialize = function(_, level)
            if not level then
                return
            end

            if level == 1 then
                info = UIDropDownMenu_CreateInfo()
                info.text = "刪除分段資料"
                info.hasArrow = 1
                info.notCheckable = 1
                info.value = "delete"
                UIDropDownMenu_AddButton(info, level)

                info = UIDropDownMenu_CreateInfo()
                info.text = "保留分段資料"
                info.notCheckable = 1
                info.hasArrow = 1
                info.value = "keep"
                UIDropDownMenu_AddButton(info, level)
            elseif level == 2 then
                if UIDROPDOWNMENU_MENU_VALUE == "delete" then
                    for i = 1, #sets do
                        info = self:CreateDeleteSetInfo(i)
                        UIDropDownMenu_AddButton(info, level)
                    end
                elseif UIDROPDOWNMENU_MENU_VALUE == "keep" then
                    for i = 1, #sets do
                        info = self:CreateKeepSetInfo(i)
                        UIDropDownMenu_AddButton(info, level)
                    end
                end
            end
        end

        local x, y = GetCursorPosition(UIParent)
        x = x / UIParent:GetEffectiveScale()
        y = y / UIParent:GetEffectiveScale()
        menu.point = "BottomLeft"
        ToggleDropDownMenu(1, nil, menu, "UIParent", x, y)
    end

    function window:Reset()
        self:Wipe()
        pets, players = {}, {}
        CheckGroup()

        if current ~= nil then
            wipe(current)
            current = CreateSet("current")
        end
        if total ~= nil then
            wipe(total)
            total = CreateSet("total")
            MyDamageMeter.total = total
        end
        last = nil

        for i = #sets, 1, -1 do
            if not sets[i].keep then
                wipe(tremove(sets, i))
            end
        end

        if self.selectedSet ~= "total" then
            self.selectedSet = "current"
            self.changed = true
        end

        UpdateDisplay(true)
        print("所有資料已重置。")
        if not InCombatLockdown() then
            collectgarbage()
        end
    end

    function window:OpenSegmentMenu()
        local menu = CreateFrame("Frame")
        menu.displayMode = "MENU"
        local info
        menu.initialize = function(_, level)
            if not level then
                return
            end

            info = UIDropDownMenu_CreateInfo()
            info.isTitle = 1
            info.text = "分段"
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text = "總體的"
            info.func = function()
                self.selectedSet = "total"
                self:Wipe()
                UpdateDisplay(true)
            end
            info.checked = self.selectedSet == "total"
            UIDropDownMenu_AddButton(info, level)

            info = UIDropDownMenu_CreateInfo()
            info.text = "目前的"
            info.func = function()
                self.selectedSet = "current"
                self:Wipe()
                UpdateDisplay(true)
            end
            info.checked = self.selectedSet == "current"
            UIDropDownMenu_AddButton(info, level)

            for i = 1, #sets do
                info = self:CreateSelectSetInfo(i)
                UIDropDownMenu_AddButton(info, level)
            end
        end

        local x, y = GetCursorPosition(UIParent)
        x = x / UIParent:GetEffectiveScale()
        y = y / UIParent:GetEffectiveScale()
        menu.point = "BottomLeft"
        ToggleDropDownMenu(1, nil, menu, "UIParent", x, y)
    end

    return window
end

local function CreateTooltipWindow()
    return {
        selectedModule = nil,
        dataSet = {},
    }
end

meter = CreateWindow()
tooltip = CreateTooltipWindow()