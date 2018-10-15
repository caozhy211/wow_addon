local addOnName = ...
local sets
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addOn)
    if addOn == addOnName then
        if not DamageMeter then
            DamageMeter = {
                ["sets"] = {},
                ["total"] = {},
            }
        end
        sets = DamageMeter.sets
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

local meter = CreateFrame("Frame", "DamageMeterFrame", UIParent)
meter:SetSize(470, 115)
meter:SetPoint("BottomLeft")
meter:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
meter:SetBackdropColor(0, 0, 0, 0.8)

local damageMode = { name = "傷害" }
local playerMode = { name = "傷害法術列表" }
local spellMode = { name = "傷害法術細節" }
local targetMode = { name = "受到傷害的怪物" }

local selectedSet, selectedMode, tooltipMode
local dataSet, tooltipDataSet = {}, {}
local bars = {}
local barMaxValue
local barHeight = 18
local maxNumShowBars = 5
local offset = 0
local tooltipMaxRows = 3

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

local current, last, total
local pets, players = {}, {}
local maxNumSets = 10
local updateFlag = true
local changed = false
local encounterName, encounterTime
local band = bit.band
local PET_FLAGS = bit.bor(COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_GUARDIAN)
local RAID_FLAGS = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)
local dmg = {}

local function CheckGroup()
    local type, count = GetGroupTypeAndCount()
    if count > 0 then
        for i = 1, count do
            local unit = ("%s%d"):format(type, i)
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

local function CreateSet(name)
    return { players = {}, name = name, startTime = time(), ["time"] = 0, damage = 0, }
end

local function SetPlayerActiveTimes(set)
    for _, player in ipairs(set.players) do
        if player.last then
            player.time = player.time + (player.last - player.first)
        end
    end
end

local function IsRaidInCombat()
    local type, count = GetGroupTypeAndCount()
    if count > 0 then
        for i = 1, count, 1 do
            if UnitExists(type .. i) and UnitAffectingCombat(type .. i) then
                return true
            end
        end
    elseif UnitAffectingCombat("player") then
        return true
    end
end

local function PlayerActiveTime(set, player)
    local maxTime = 0

    if player.time > 0 then
        maxTime = player.time
    end

    if (not set.endTime or set.stopped) and player.first then
        maxTime = maxTime + player.last - player.first
    end
    return maxTime
end

local function GetDPS(set, player)
    local totalTime = PlayerActiveTime(set, player)
    return player.damage / max(1, totalTime)
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

local function Clear()
    wipe(dataSet)

    offset = 0

    for i, bar in ipairs(bars) do
        bar:Hide()
    end
    wipe(bars)
end

local function GetSelectedSet()
    if selectedSet == "current" then
        if current ~= nil then
            return current
        elseif last ~= nil then
            return last
        else
            return sets[1]
        end
    elseif selectedSet == "total" then
        return total
    else
        return sets[selectedSet]
    end
end

local function DeleteSet(set)
    for i, s in ipairs(sets) do
        if s == set then
            wipe(tremove(sets, i))

            if set == last then
                last = nil
            end

            -- Don't leave windows pointing to deleted sets
            if selectedSet == i or GetSelectedSet() == set then
                selectedSet = "current"
                changed = true
            elseif (tonumber(selectedSet) or 0) > i then
                selectedSet = selectedSet - 1
                changed = true
            end
            break
        end
    end

    Clear()
    meter:Update(true)
end

local function FormatTime(set)
    if not set then
        return ""
    end

    local startTime = set.startTime
    local endTime = set.endTime or time()
    local duration = SecondsToTime(endTime - startTime, false, false, 2)
    local text = UIParent:CreateFontString()
    text:SetFont(GameFontNormal:GetFont())
    text:SetText(duration)
    duration = "(" .. text:GetText() .. ")"
    return date("%H:%M", startTime) .. " " .. duration
end

local function FormatNumber(number)
    if number >= 1e8 then
        return ("%02.2f億"):format(number / 1e8)
    end
    if number >= 1e4 then
        return ("%02.2f萬"):format(number / 1e4)
    end
    return floor(number)
end

local function FindPlayer(set, playerId)
    if set then
        set.playerIndex = set.playerIndex or {}
        local player = set.playerIndex[playerId]
        if player then
            return player
        end
        for i, p in ipairs(set.players) do
            if p.id == playerId then
                set.playerIndex[playerId] = p
                return p
            end
        end
    end
end

local function SortByValue(a, b)
    if not a or a.value == nil then
        return false
    elseif not b or b.value == nil then
        return true
    else
        return a.value > b.value
    end
end

local function GetBar(id)
    bars.barIndex = bars.barIndex or {}
    local bar = bars.barIndex[id]
    if bar then
        return bar
    end
    for _, b in ipairs(bars) do
        if b.id == id then
            bars.barIndex[id] = b
            return b
        end
    end
end

local function UpdateBars()
    local min = 1 + offset
    local max = maxNumShowBars + offset
    for i = 1, #bars do
        local num = bars[i].num
        if num >= min and num <= max then
            bars[i]:SetPoint("TopRight", meter.title, "BottomRight", 0, (barHeight + 1) * (min - num) - 1)
            bars[i]:Show()
        else
            bars[i]:Hide()
        end
    end
end

local function DisplayBars()
    if selectedMode then
        table.sort(dataSet, SortByValue)
    end

    local index = 1
    for _, data in ipairs(dataSet) do
        if data.id then
            local barId = data.id
            local barText = data.label
            local bar = GetBar(barId)
            if bar then
                bar:SetMinMaxValues(0, barMaxValue)
                bar:SetValue(data.value)
                if selectedMode == damageMode then
                    bar.leftText:SetText(format("%2u. %s", index, data.label))
                else
                    bar.leftText:SetText(data.label)
                end
                bar.rightText:SetText(data.valueText)
                bar.num = index
            else
                bar = CreateFrame("StatusBar", nil, meter)
                bar:SetStatusBarTexture("Interface\\Tooltips\\UI-Tooltip-Background")
                tinsert(bars, bar)

                bar.id = barId
                bar.text = barText
                bar.num = index

                if selectedMode == spellMode or selectedMode == targetMode then
                    bar:SetSize(meter:GetWidth(), barHeight)
                else
                    bar:SetSize(meter:GetWidth() - barHeight, barHeight)

                    bar.icon = bar:CreateTexture()
                    bar.icon:SetSize(barHeight, barHeight)
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

                bar:SetScript("OnMouseDown", function(self, mouse)
                    meter:ClickFunc(mouse, self)
                end)

                bar:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(meter, "ANCHOR_NONE")
                    GameTooltip:SetPoint("TopLeft", meter, "TopRight", 10, 0)

                    local set = GetSelectedSet()
                    if selectedMode == damageMode then
                        local player = FindPlayer(set, self.id)
                        local activeTime, totalTime
                        if player then
                            playerMode.playerId = self.id
                            playerMode.title = player.name .. "的傷害"

                            targetMode.playerId = self.id
                            targetMode.title = (player and player.name or "Unknown") .. "的受到傷害的怪物"

                            activeTime = PlayerActiveTime(set, player)
                            totalTime = set.time
                        end

                        tooltipMode = playerMode
                        tooltipMode:Update(set, true)
                        table.sort(tooltipDataSet, SortByValue)
                        if #tooltipDataSet > 0 then
                            GameTooltip:AddLine(tooltipMode.title or tooltipMode.name, 1, 1, 1)

                            local i = 0
                            for _, data in ipairs(tooltipDataSet) do
                                if data.id and i < tooltipMaxRows then
                                    i = i + 1
                                    GameTooltip:AddDoubleLine(data.label, data.valueText, 1, 1, 1)
                                end
                            end
                        end
                        wipe(tooltipDataSet)
                        GameTooltip:AddLine(" ")

                        tooltipMode = targetMode
                        tooltipMode:Update(set, true)
                        table.sort(tooltipDataSet, SortByValue)
                        if #tooltipDataSet > 0 then
                            GameTooltip:AddLine(tooltipMode.title or tooltipMode.name, 1, 1, 1)

                            local i = 0
                            for _, data in ipairs(tooltipDataSet) do
                                if data.id and i < tooltipMaxRows then
                                    i = i + 1
                                    GameTooltip:AddDoubleLine(data.label, data.valueText, 1, 1, 1)
                                end
                            end
                        end
                        wipe(tooltipDataSet)
                        GameTooltip:AddLine(" ")

                        GameTooltip:AddDoubleLine("活躍度", format("%.1f%%", activeTime / max(1, totalTime) * 100), 1, 1, 1)
                    elseif selectedMode == playerMode then
                        local player = FindPlayer(set, playerMode.playerId)
                        if player then
                            spellMode.spellName = self.text
                            spellMode.playerId = playerMode.playerId
                            spellMode.title = player.name .. "的" .. self.text
                        end

                        local spell = player.spells[self.text]
                        if spell then
                            GameTooltip:AddLine(player.name .. " - " .. self.text, 1, 1, 1)
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
                        GameTooltip:AddLine(" ")

                        tooltipMode = spellMode
                        tooltipMode:Update(set, true)
                        table.sort(tooltipDataSet, SortByValue)
                        if #tooltipDataSet > 0 then
                            GameTooltip:AddLine(tooltipMode.title or tooltipMode.name, 1, 1, 1)

                            local i = 0
                            for _, data in ipairs(tooltipDataSet) do
                                if data.id and i < tooltipMaxRows then
                                    i = i + 1
                                    GameTooltip:AddDoubleLine(data.label, data.valueText, 1, 1, 1)
                                end
                            end
                        end
                        wipe(tooltipDataSet)
                    elseif selectedMode == spellMode then
                        local player = FindPlayer(set, spellMode.playerId)
                        if player then
                            local spell = player.spells[spellMode.spellName]
                            if spell then
                                GameTooltip:AddLine(player.name .. " - " .. spellMode.spellName, 1, 1, 1)
                                if self.text == "致命一擊" and spell.criticalAmount then
                                    GameTooltip:AddDoubleLine("最小", FormatNumber(spell.criticalMin), 1, 1, 1)
                                    GameTooltip:AddDoubleLine("最大", FormatNumber(spell.criticalMax), 1, 1, 1)
                                    GameTooltip:AddDoubleLine("平均", FormatNumber(spell.criticalAmount / spell.critical), 1, 1, 1)
                                end
                                if self.text == "命中" and spell.hitAmount then
                                    GameTooltip:AddDoubleLine("最小", FormatNumber(spell.hitMin), 1, 1, 1)
                                    GameTooltip:AddDoubleLine("最大", FormatNumber(spell.hitMax), 1, 1, 1)
                                    GameTooltip:AddDoubleLine("平均", FormatNumber(spell.hitAmount / spell.hit), 1, 1, 1)
                                end
                            end
                        end
                    elseif not selectedMode and set then
                        tooltipMode = damageMode
                        tooltipMode:Update(set, true)
                        table.sort(tooltipDataSet, SortByValue)
                        if #tooltipDataSet > 0 then
                            GameTooltip:AddLine(tooltipMode.title or tooltipMode.name, 1, 1, 1)

                            local i = 0
                            for _, data in ipairs(tooltipDataSet) do
                                if data.id and i < tooltipMaxRows then
                                    i = i + 1
                                    GameTooltip:AddDoubleLine(i .. ". " .. data.label, data.valueText, 1, 1, 1)
                                end
                            end
                        end
                        wipe(tooltipDataSet)
                    end

                    GameTooltip:Show()
                end)

                bar:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                bar:SetMinMaxValues(0, barMaxValue)
                bar:SetValue(data.value)

                if data.spellSchool then
                    if CombatLog_Color_ColorArrayBySchool then
                        local color = CombatLog_Color_ColorArrayBySchool(data.spellSchool)
                        bar:SetStatusBarColor(color.r, color.g, color.b)
                    end
                elseif data.class then
                    local color = RAID_CLASS_COLORS[data.class]
                    bar:SetStatusBarColor(color.r, color.g, color.b)
                else
                    bar:SetStatusBarColor(0.3, 0.3, 0.8)
                end

                bar.leftText = bar:CreateFontString()
                bar.leftText:SetFont(GameFontNormal:GetFont(), 13)
                bar.leftText:SetPoint("Left", 3, 0)
                if selectedMode == damageMode then
                    bar.leftText:SetText(format("%2u. %s", index, data.label))
                else
                    bar.leftText:SetText(data.label)
                end

                bar.rightText = bar:CreateFontString()
                bar.rightText:SetFont(GameFontNormal:GetFont(), 13)
                bar.rightText:SetPoint("Right", -3, 0)
                bar.rightText:SetText(data.valueText)
            end
            index = index + 1
        end
    end

    UpdateBars()
end

local function SetModeTitle()
    if not selectedMode or not selectedSet then
        return
    end

    local name = selectedMode.title or selectedMode.name
    local setName
    if selectedSet == "current" then
        setName = "目前的"
    elseif selectedSet == "total" then
        setName = "總體的"
    else
        local set = GetSelectedSet()
        if set then
            setName = (set.name or "Unknown") .. ": " .. FormatTime(set)
        end
    end
    if setName then
        name = name .. ": " .. setName
    end

    local maxWidth = meter:GetWidth() - 50
    if name:len() * 5 > maxWidth then
        local endIndex = floor(maxWidth / 15) * 3
        name = name:sub(1, endIndex) .. "..."
    end

    meter.title.text:SetText(name)
end

local function UpdateDisplay()
    if not barMaxValue then
        barMaxValue = 0
        for _, data in ipairs(dataSet) do
            if data.id and data.value > barMaxValue then
                barMaxValue = data.value
            end
        end
    end

    DisplayBars()
    SetModeTitle()
end

function meter:Update(force)
    if force then
        updateFlag = true
    end

    if updateFlag or changed or current then
        changed = false

        if selectedMode then
            local set = GetSelectedSet()
            if set then
                if selectedMode.Update then
                    selectedMode:Update(set)
                end

                UpdateDisplay()
            end
        elseif selectedSet then
            local set = GetSelectedSet()
            local data = dataSet[1] or {}
            dataSet[1] = data
            data.id = damageMode.name
            data.label = damageMode.name
            data.value = 1
            if set then
                data.valueText = FormatNumber(set.damage) .. " (" .. FormatNumber(GetRaidDPS(set)) .. ")"
            end
            data.icon = "Interface\\Icons\\Inv_throwingaxe_01"

            UpdateDisplay()
        else
            local index = 1
            local data = dataSet[index] or {}
            dataSet[index] = data

            data.id = "total"
            data.label = "總體的"
            data.value = 1
            data.valueText = ""
            data.icon = "Interface\\Icons\\icon_petfamily_critter"

            index = index + 1
            data = dataSet[index] or {}
            dataSet[index] = data

            data.id = "current"
            data.label = "目前的"
            data.value = 1
            data.valueText = ""
            data.icon = "Interface\\Icons\\icon_petfamily_critter"

            for _, set in ipairs(sets) do
                index = index + 1
                data = dataSet[index] or {}
                dataSet[index] = data

                data.id = tostring(set.startTime)
                data.label = set.name
                data.value = 1
                data.valueText = FormatTime(set)
                data.icon = "Interface\\Icons\\icon_petfamily_critter"
            end

            UpdateDisplay()
        end
    end

    updateFlag = false
end

function meter:EndSegment()
    if not current then
        return
    end

    if current.mobName ~= nil and time() - current.startTime >= 5 then
        if not current.endTime then
            current.endTime = time()
        end
        current.time = current.endTime - current.startTime
        SetPlayerActiveTimes(current)
        current.stopped = nil

        local name = current.mobName
        local count = 0
        for _, set in ipairs(sets) do
            if set.name == name and count == 0 then
                count = 1
            else
                local n, c = set.name:match("^(.-)%s*%((%d+)%)$")
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
    for _, player in ipairs(total.players) do
        player.first = nil
        player.last = nil
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

    Clear()
    self:Update(true)
    self:SetScript("OnUpdate", nil)
end

local function DisplaySets()
    Clear()
    selectedSet = nil
    selectedMode = nil
    meter.title.text:SetText("戰鬥")
    barMaxValue = 1
    changed = true
    meter:Update()
end

local function DisplaySummary(setTime)
    Clear()
    selectedMode = nil
    if setTime == "current" or setTime == "total" then
        selectedSet = setTime
    else
        for i, set in ipairs(sets) do
            if tostring(set.startTime) == setTime then
                if set.name == "current" then
                    selectedSet = "current"
                elseif set.name == "total" then
                    selectedSet = "total"
                else
                    selectedSet = i
                end
            end
        end
    end
    meter.title.text:SetText("概要")
    barMaxValue = 1
    changed = true
    meter:Update()
end

local function DisplayMode(mode)
    Clear()
    selectedMode = mode
    SetModeTitle()
    changed = true
    meter:Update()
end

function meter:StartCombat()
    if not current then
        current = CreateSet("current")
    end

    Clear()

    if encounterName and GetTime() < (encounterTime or 0) + 15 then
        current.mobName = encounterName
        encounterName = nil
        encounterTime = nil
    end

    if not total then
        total = CreateSet("total")
        DamageMeter.total = total
    end

    self:Update(true)

    self:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 1 then
            return
        end
        self.elapsed = 0

        self:Update()

        if current and not InCombatLockdown() and not IsRaidInCombat() then
            self:EndSegment()
        end
    end)
end

local function GetPlayer(set, playerId, playerName)
    local player = FindPlayer(set, playerId)

    if not player then
        if not playerName then
            return
        end

        local _, playerClass = UnitClass(playerName)
        player = {
            id = playerId,
            class = playerClass,
            name = playerName,
            first = time(),
            ["time"] = 0,
            damage = 0,
            spells = {},
            targets = {},
        }

        local name, realm = string.split("-", playerName, 2)
        player.name = name or playerName

        tinsert(set.players, player)
    end

    if player.name == UNKNOWN and playerName ~= UNKNOWN then
        local name, realm = string.split("-", playerName, 2)
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

local function FixPets(dmg)
    if dmg and dmg.playerName then
        local pet = pets[dmg.playerId]
        if pet then
            if dmg.spellName then
                dmg.spellName = dmg.playerName .. ": " .. dmg.spellName
            end
            dmg.playerName = pet.name
            dmg.playerId = pet.id
        else
            -- Fix for guardians; requires "playerflags" to be set from CL.
            -- This only works for one self. Other player's guardians are all lumped into one.
            if dmg.playerFlags and band(dmg.playerFlags, COMBATLOG_OBJECT_TYPE_GUARDIAN) ~= 0 then
                if band(dmg.playerFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 then
                    if dmg.spellName then
                        dmg.spellName = dmg.playerName .. ": " .. dmg.spellName
                    end
                    dmg.playerName = UnitName("player")
                    dmg.playerId = UnitGUID("player")
                else
                    -- Nothing decent in place here yet. Modify guid so that there will only be 1 similar entry at least.
                    dmg.playerId = dmg.playerName
                end
            end
        end
    end
end

local function LogDamage(set, dmg)
    local player = GetPlayer(set, dmg.playerId, dmg.playerName)
    if player then
        local amount = dmg.amount
        set.damage = set.damage + amount
        player.damage = player.damage + amount

        if not player.spells[dmg.spellName] then
            player.spells[dmg.spellName] = { id = dmg.spellId, totalHits = 0, damage = 0, school = dmg.school }
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

function meter:SpellDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, sAmount, sOverkill, sSchool, sResisted, sBlocked, sAbsorbed, sCritical, sGlancing, sCrushing, sOffhand)
    --local function SpellDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, sAmount, sOverkill, sSchool, sResisted, sBlocked, sAbsorbed, sCritical, sGlancing, sCrushing, sOffhand)
    if srcGUID ~= dstGUID then
        -- XXX WoD quick fix for Mage's Prismatic Crystal talent
        -- All damage done to the crystal is transferred, so ignore it
        -- Now with extra Legion "quick fix" for Warlock's Soul Effigy!
        if dstGUID:match("^Creature%-0%-%d+%-%d+%-%d+%-76933%-%w+$") or dstGUID:match("^Creature%-0%-%d+%-%d+%-%d+%-103679%-%w+$") then
            return
        end

        dmg.playerId = srcGUID
        dmg.playerFlags = srcFlags
        dmg.dstName = dstName
        dmg.playerName = srcName
        dmg.spellId = spellId
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

function meter:SwingDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, sAmount, sOverkill, sSchool, sResisted, sBlocked, sAbsorbed, sCritical, sGlancing, sCrushing, sOffhand)
    --local function SwingDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, sAmount, sOverkill, sSchool, sResisted, sBlocked, sAbsorbed, sCritical, sGlancing, sCrushing, sOffhand)
    if srcGUID ~= dstGUID then
        dmg.playerId = srcGUID
        dmg.playerFlags = srcFlags
        dmg.dstName = dstName
        dmg.playerName = srcName
        dmg.spellId = 6603
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

function meter:SpellAbsorbed(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
    --local function SpellAbsorbed(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
    local chk = ...
    local spellId, spellName, spellSchool, aGUID, aName, aFlags, aRaidFlags, aspellId, aspellName, aspellSchool, aAmount

    if type(chk) == "number" then
        spellId, spellName, spellSchool, aGUID, aName, aFlags, aRaidFlags, aspellId, aspellName, aspellSchool, aAmount = ...

        if aspellId == 184553 then
            return
        end

        if aAmount then
            self:SpellDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, aAmount)
            --SpellDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, aAmount)
        end
    else
        aGUID, aName, aFlags, aRaidFlags, aspellId, aspellName, aspellSchool, aAmount = ...

        if aspellId == 184553 then
            return
        end

        if aAmount then
            self:SwingDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, aAmount)
            --SwingDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, aAmount)
        end
    end
end

function meter:SwingMissed(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missed)
    --local function SwingMissed(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, missed)
    if srcGUID ~= dstGUID then
        dmg.playerId = srcGUID
        dmg.playerFlags = srcFlags
        dmg.dstName = dstName
        dmg.playerName = srcName
        dmg.spellId = 6603
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

function meter:SpellMissed(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, missType)
    --local function SpellMissed(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, missType)
    if srcGUID ~= dstGUID then
        dmg.playerId = srcGUID
        dmg.playerFlags = srcFlags
        dmg.dstName = dstName
        dmg.playerName = srcName
        dmg.spellId = spellId
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

local combatLogEvents = {
    ["SpellDamage"] = { "DAMAGE_SHIELD", "SPELL_DAMAGE", "SPELL_PERIODIC_DAMAGE", "SPELL_BUILDING_DAMAGE", "RANGE_DAMAGE" },
    ["SpellAbsorbed"] = { "SPELL_ABSORBED" },
    ["SwingDamage"] = { "SWING_DAMAGE" },
    ["SwingMissed"] = { "SWING_MISSED" },
    ["SpellMissed"] = { "SPELL_MISSED", "SPELL_PERIODIC_MISSED", "RANGE_MISSED", "SPELL_BUILDING_MISSED" },
}

local function IsCombatLogEvent(eventType)
    for func, events in pairs(combatLogEvents) do
        for _, event in ipairs(events) do
            if event == eventType then
                return func
            end
        end
    end
end

function meter:CombatLogEvent(timestamp, eventType, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, ...)
    local srcIsInteresting, dstIsInteresting

    if current and IsCombatLogEvent(eventType) then
        if current.stopped then
            return
        end

        local func = IsCombatLogEvent(eventType)
        srcIsInteresting = band(srcFlags, RAID_FLAGS) ~= 0 or (band(srcFlags, PET_FLAGS) ~= 0 and pets[srcGUID]) or players[srcGUID]
        dstIsInteresting = band(dstFlags, RAID_FLAGS) ~= 0 or (band(dstFlags, PET_FLAGS) ~= 0 and pets[dstGUID]) or players[dstGUID]
        if srcIsInteresting and not dstIsInteresting then
            self[func](self, timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
        end
    end

    if current and srcIsInteresting and band(dstFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) == 0 and not current.mobName then
        current.mobName = dstName
    end

    if eventType == "SPELL_SUMMON" and ((band(srcFlags, RAID_FLAGS) ~= 0) or ((band(srcFlags, PET_FLAGS)) ~= 0) or ((band(dstFlags, PET_FLAGS) ~= 0) and pets[dstGUID])) then
        pets[dstGUID] = { id = srcGUID, name = srcName }
        if pets[srcGUID] then
            -- the pets owner is a pet -> change it to the owner of the pet
            -- this check may no longer be necessary?
            pets[dstGUID].id = pets[srcGUID].id
            pets[dstGUID].name = pets[srcGUID].name
        end
    end
end

meter:RegisterEvent("PLAYER_ENTERING_WORLD")
meter:RegisterEvent("GROUP_ROSTER_UPDATE")
meter:RegisterEvent("UNIT_PET")
meter:RegisterEvent("PLAYER_REGEN_DISABLED")
meter:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
meter:RegisterEvent("ENCOUNTER_START")
meter:RegisterEvent("ENCOUNTER_END")
meter:RegisterEvent("PLAYER_LOGIN")
meter:RegisterEvent("PLAYER_LOGOUT")
meter:SetScript("OnEvent", function(self, event)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        self:CombatLogEvent(CombatLogGetCurrentEventInfo())
    elseif event == "PLAYER_REGEN_DISABLED" then
        self:StartCombat()
    elseif event == "ENCOUNTER_START" then
        if current then
            -- already in combat, update the segment name
            current.mobName = encounterName
        else
            -- we are not in combat yet
            -- if we StartCombat here, the segment will immediately end by Tick
            -- just save the encounter name for use when we enter combat
            encounterName = encounterName
            encounterTime = GetTime()
        end
    elseif event == "ENCOUNTER_END" then
        if current then
            current.mobName = encounterName
        end
    elseif event == "PLAYER_LOGIN" then
        selectedSet = "current"
        selectedMode = damageMode
        DisplayMode(selectedMode)
    elseif event == "PLAYER_LOGOUT" then
        total.playerIndex = nil
        for i = 1, #sets do
            sets[i].playerIndex = nil
        end
    else
        CheckGroup()
    end
end)

function damageMode:Update(set, isTooltip)
    local maxValue = 0
    local index = 1
    for _, player in ipairs(set.players) do
        if player.damage > 0 then
            local ds = isTooltip and tooltipDataSet or dataSet
            local dps = GetDPS(set, player)
            local data = ds[index] or {}
            ds[index] = data

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
    if not isTooltip then
        barMaxValue = maxValue
    end
end

function playerMode:Update(set, isTooltip)
    local player = FindPlayer(set, self.playerId)
    local maxValue = 0
    if player then
        local index = 1
        for spellName, spell in pairs(player.spells) do
            local ds = isTooltip and tooltipDataSet or dataSet
            local data = ds[index] or {}
            ds[index] = data
            data.label = spellName
            data.id = spellName
            local _, _, icon = GetSpellInfo(spell.id)
            data.icon = icon
            data.spellId = spell.id
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
    if not isTooltip then
        barMaxValue = maxValue
    end
end

local function AddDetailBar(label, value, isTooltip)
    local index = spellMode.index + 1
    spellMode.index = index
    local ds = isTooltip and tooltipDataSet or dataSet
    local data = ds[index] or {}
    ds[index] = data

    data.label = label
    data.value = value
    data.id = label
    data.valueText = value .. " " .. format("(%.1f%%)", value / spellMode.totalHits * 100)
    if not isTooltip then
        barMaxValue = max(barMaxValue, value)
    end
end

function spellMode:Update(set, isTooltip)
    local player = FindPlayer(set, playerMode.playerId)
    if player then
        local spell = player.spells[self.spellName]
        if spell then
            self.totalHits = spell.totalHits
            self.index = 0
            if not isTooltip then
                barMaxValue = 0
            end

            if spell.hit and spell.hit > 0 then
                AddDetailBar("命中", spell.hit, isTooltip)
            end
            if spell.critical and spell.critical > 0 then
                AddDetailBar("致命一擊", spell.critical, isTooltip)
            end
            if spell.glancing and spell.glancing > 0 then
                AddDetailBar("偏斜", spell.glancing, isTooltip)
            end
            if spell.crushing and spell.crushing > 0 then
                AddDetailBar("碾壓", spell.crushing, isTooltip)
            end
            if spell.ABSORB and spell.ABSORB > 0 then
                AddDetailBar("吸收", spell.ABSORB, isTooltip)
            end
            if spell.BLOCK and spell.BLOCK > 0 then
                AddDetailBar("格擋", spell.BLOCK, isTooltip)
            end
            if spell.DEFLECT and spell.DEFLECT > 0 then
                AddDetailBar("偏斜", spell.DEFLECT, isTooltip)
            end
            if spell.DODGE and spell.DODGE > 0 then
                AddDetailBar("閃躲", spell.DODGE, isTooltip)
            end
            if spell.EVADE and spell.EVADE > 0 then
                AddDetailBar("閃避", spell.EVADE, isTooltip)
            end
            if spell.IMMUNE and spell.IMMUNE > 0 then
                AddDetailBar("免疫", spell.IMMUNE, isTooltip)
            end
            if spell.MISS and spell.MISS > 0 then
                AddDetailBar("未擊中", spell.MISS, isTooltip)
            end
            if spell.PARRY and spell.PARRY > 0 then
                AddDetailBar("招架", spell.PARRY, isTooltip)
            end
            if spell.REFLECT and spell.REFLECT > 0 then
                AddDetailBar("反射", spell.REFLECT, isTooltip)
            end
            if spell.RESIST and spell.RESIST > 0 then
                AddDetailBar("抵抗", spell.RESIST, isTooltip)
            end
        end
    end
end

function targetMode:Update(set, isTooltip)
    local player = FindPlayer(set, self.playerId)
    local maxValue = 0
    if player then
        local ds = isTooltip and tooltipDataSet or dataSet
        local index = 1
        for target, amount in pairs(player.targets) do
            local data = ds[index] or {}
            ds[index] = data
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
    if not isTooltip then
        barMaxValue = maxValue
    end
end

local title = meter:CreateTexture()
title:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
title:SetColorTexture(0.3, 0.3, 0.3)
title:SetSize(meter:GetWidth(), 20)
title:SetPoint("Top")
meter.title = title
title.text = meter:CreateFontString()
title.text:SetFont(GameFontNormal:GetFont(), 13)
title.text:SetPoint("Left", title, 3, 0)

function meter:ClickFunc(mouse, bar)
    if mouse == "RightButton" then
        if selectedMode == damageMode then
            DisplaySummary(selectedSet)
        elseif selectedMode == playerMode or selectedMode == targetMode then
            DisplayMode(damageMode)
        elseif selectedMode == spellMode then
            DisplayMode(playerMode)
        elseif selectedSet then
            DisplaySets()
        end
    elseif mouse == "LeftButton" and bar then
        if selectedMode == damageMode then
            local player = FindPlayer(GetSelectedSet(), bar.id)
            if IsShiftKeyDown() then
                targetMode.playerId = bar.id
                targetMode.title = (player and player.name or "Unknown") .. "的受到傷害的怪物"
                DisplayMode(targetMode)
            else
                if player then
                    playerMode.playerId = bar.id
                    playerMode.title = player.name .. "的傷害"
                    DisplayMode(playerMode)
                end
            end
        elseif selectedMode == playerMode then
            local player = FindPlayer(GetSelectedSet(), playerMode.playerId)
            if player then
                spellMode.spellName = bar.text
                spellMode.playerId = playerMode.playerId
                spellMode.title = player.name .. "的" .. bar.text
                DisplayMode(spellMode)
            end
        elseif not selectedMode and selectedSet then
            DisplayMode(damageMode)
        elseif not selectedSet then
            selectedSet = bar.id
            DisplaySummary(selectedSet)
        end
    end
end

meter:SetScript("OnMouseDown", function(self, mouse)
    self:ClickFunc(mouse)
end)

meter:SetScript("OnMouseWheel", function(self, value)
    if value > 0 and offset > 0 then
        offset = offset - 1
        UpdateBars()
    elseif value < 0 and #bars - maxNumShowBars - offset > 0 then
        offset = offset + 1
        UpdateBars()
    end
end)

local function OpenConfigMenu()
    local menu = CreateFrame("Frame")
    menu.displayMode = "MENU"
    local info
    menu.initialize = function(self, level)
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
                for i, set in ipairs(sets) do
                    info = UIDropDownMenu_CreateInfo()
                    info.text = (set.name or "Unknown") .. ": " .. FormatTime(set)
                    info.func = function()
                        DeleteSet(set)
                    end
                    info.notCheckable = 1
                    UIDropDownMenu_AddButton(info, level)
                end
            elseif UIDROPDOWNMENU_MENU_VALUE == "keep" then
                for i, set in ipairs(sets) do
                    info = UIDropDownMenu_CreateInfo()
                    info.text = (set.name or "Unknown") .. ": " .. FormatTime(set)
                    info.func = function()
                        set.keep = not set.keep
                        Clear()
                        meter:Update(true)
                    end
                    info.checked = set.keep
                    UIDropDownMenu_AddButton(info, level)
                end
            end
        end
    end

    local x, y = GetCursorPosition(UIParent);
    x = x / UIParent:GetEffectiveScale();
    y = y / UIParent:GetEffectiveScale();
    menu.point = "BottomLeft"
    ToggleDropDownMenu(1, nil, menu, "UIParent", x, y)
end

local function Reset()
    Clear()
    pets, players = {}, {}
    CheckGroup()

    if current ~= nil then
        wipe(current)
        current = CreateSet("current")
    end
    if total ~= nil then
        wipe(total)
        total = CreateSet("total")
        DamageMeter.total = total
    end
    last = nil

    for i = #sets, 1, -1 do
        if not sets[i].keep then
            wipe(tremove(sets, i))
        end
    end

    if selectedSet ~= "total" then
        selectedSet = "current"
        changed = true
    end

    meter:Update(true)

    if not InCombatLockdown() then
        collectgarbage("collect")
    end
end

local function OpenSegmentMenu()
    local menu = CreateFrame("Frame")
    menu.displayMode = "MENU"
    local info
    menu.initialize = function(self, level)
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
            selectedSet = "total"
            Clear()
            meter:Update(true)
        end
        info.checked = selectedSet == "total"
        UIDropDownMenu_AddButton(info, level)

        info = UIDropDownMenu_CreateInfo()
        info.text = "目前的"
        info.func = function()
            selectedSet = "current"
            Clear()
            meter:Update(true)
        end
        info.checked = selectedSet == "current"
        UIDropDownMenu_AddButton(info, level)

        for i, set in ipairs(sets) do
            info = UIDropDownMenu_CreateInfo()
            info.text = (set.name or "Unknown") .. ": " .. FormatTime(set)
            info.func = function()
                selectedSet = i
                Clear()
                meter:Update(true)
            end
            info.checked = (selectedSet == i)
            UIDropDownMenu_AddButton(info, level)
        end
    end

    local x, y = GetCursorPosition(UIParent);
    x = x / UIParent:GetEffectiveScale();
    y = y / UIParent:GetEffectiveScale();
    menu.point = "BottomLeft"
    ToggleDropDownMenu(1, nil, menu, "UIParent", x, y)
end

local config = CreateFrame("Button", nil, meter)
config:SetSize(12, 12)
config:SetPoint("Right", meter.title, -6, 0)
config:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
config:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton", 1)
config:RegisterForClicks("LeftButtonUp", "RightButtonUp")
config:SetScript("OnClick", OpenConfigMenu)

local reset = CreateFrame("Button", nil, meter)
reset:SetSize(12, 12)
reset:SetPoint("Right", config, "Left", -3, 0)
reset:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
reset:SetHighlightTexture("Interface\\Buttons\\UI-StopButton", 1)
reset:RegisterForClicks("LeftButtonUp", "RightButtonUp")
reset:SetScript("OnClick", Reset)

local segment = CreateFrame("Button", nil, meter)
segment:SetSize(12, 12)
segment:SetPoint("Right", reset, "Left", -3, 0)
segment:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
segment:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up", 1)
segment:RegisterForClicks("LeftButtonUp", "RightButtonUp")
segment:SetScript("OnClick", OpenSegmentMenu)