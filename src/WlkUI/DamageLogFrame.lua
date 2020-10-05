local updateFlags = true
local changed
local updateInterval = 1
local dmg = {}
local players = {}
local pets = {}
local current
local temp
local combatDataIndex = 0
local combatDataList = {}
local barMaxValue
local combatView = { name = "戰鬥記錄", showIcon = true, }
local damageView = { name = "傷害數據", sort = true, showIcon = true, showSN = true, }
local playerView = { name = "法術列表", sort = true, showIcon = true, }
local spellView = { name = "法術細節", sort = true, }
local targetView = { name = "目標單位", sort = true, }
local selectedView = damageView
local xOffset = 453
local yOffset = 96
local titleHeight = 20
local backdrop = { bgFile = "Interface/ChatFrame/CHATFRAMEBACKGROUND", }
local frameData = {}
local tooltipData = {}
local maxTooltipRows = 3
local tooltipView
local barHeight = 18
local barWidth1 = xOffset - barHeight
local barWidth2 = xOffset
local numDataBars = 0
---@type table<number|string, WlkDamageLogDataBar>
local dataBars = {}
local barOffset = 0
local maxDisplayDataBars = 5
local bossIcon = "Interface/Icons/achievment_Boss_ultraxion"
local nonBossIcon = "Interface/Icons/Icon_PetFamily_Critter"
local maxCombatData = 10
---@type TickerPrototype
local updateTicker
---@type TickerPrototype
local checkTicker
local encounterNameSaved
local encounterTimeSaved
local combatLogEventFunctions = {}
local PET_FLAGS = bit.bor(COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_GUARDIAN)
local RAID_FLAGS = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY,
        COMBATLOG_OBJECT_AFFILIATION_RAID)
local addonName = ...

---@class WlkDamageLogFrame:Frame
local logFrame = CreateFrame("Frame", "WlkDamageLogFrame", UIParent, "BackdropTemplate")
---@type Frame
local titleFrame = CreateFrame("Frame", "WlkDamageLogTitleFrame", logFrame, "BackdropTemplate")
local titleLabel = titleFrame:CreateFontString("WlkDamageLogTitleLabel", "ARTWORK", "SystemFont_Shadow_Med3")
---@type Button
local resetButton = CreateFrame("Button", "WlkDamageLogResetButton", logFrame)

local function findPlayer(combatData, id)
    combatData.playerIndexes = combatData.playerIndexes or {}
    if combatData.playerIndexes[id] then
        return combatData.playerIndexes[id]
    end
    for _, player in ipairs(combatData.players) do
        if player.id == id then
            combatData.playerIndexes[id] = player
            return player
        end
    end
end

local function getPlayer(combatData, id, name)
    local player = findPlayer(combatData, id)
    if not player then
        if not name then
            return
        end
        player = {
            id = id,
            class = select(2, UnitClass(name)),
            start = time(),
            duration = 0,
            damage = 0,
            spells = {},
            targets = {},
        }
        local playerName = strsplit("-", name, 2)
        player.name = playerName or name
        tinsert(combatData.players, player)
    end
    if player.name == UNKNOWN and name ~= UNKNOWN then
        local playerName = strsplit("-", name, 2)
        player.name = playerName or name
        player.class = select(2, UnitClass(name))
    end
    player.stop = time()
    updateFlags = true
    return player
end

local function getCombatData()
    if combatDataIndex == 0 then
        return current or combatDataList[1]
    elseif combatDataIndex > 0 then
        return combatDataList[combatDataIndex]
    end
end

local function formatCombatTime(combatData)
    local start = combatData.start
    local stop = combatData.stop
    local duration = SecondsToTime(stop - start, false, false, 2)
    return format("%s (%s)", date("%H:%M", start), duration)
end

local function abbreviateNumber(value)
    if value >= 1e8 then
        return format("%.2f%s", value / 1e8, SECOND_NUMBER_CAP)
    elseif value >= 1e4 then
        return format("%.2f%s", value / 1e4, FIRST_NUMBER_CAP)
    end
    return format("%.0f", value)
end

local function formatPercentage(value, endValue)
    return format("%.1f%%", PercentageBetween(value, 0, endValue) * 100)
end

local function getPlayerActiveTime(combatData, player)
    local activeTime = 0
    if player.duration > 0 then
        activeTime = player.duration
    end
    if not combatData.stop and combatData.start then
        activeTime = activeTime + player.stop - player.start
    end
    return activeTime
end

local function getDps(combatData, player)
    local activeTime = getPlayerActiveTime(combatData, player)
    return player.damage / max(1, activeTime)
end

local function updateDamageView(dataList, combatData)
    local maxValue = 0
    local index = 1
    for _, player in ipairs(combatData.players) do
        if player.damage > 0 then
            local dps = getDps(combatData, player)
            local data = dataList[index] or {}
            dataList[index] = data
            data.id = player.id
            data.value = player.damage
            data.leftText = player.name
            data.rightText = format("%s (%s, %s)", abbreviateNumber(player.damage), abbreviateNumber(dps),
                    formatPercentage(player.damage, combatData.damage))
            data.class = player.class
            if player.damage > maxValue then
                maxValue = player.damage
            end
            index = index + 1
        end
    end
    barMaxValue = maxValue
end

local function damageViewOnEnter(id)
    combatDataIndex = id
end

local function setDamageViewExtraTooltip(id)
    local combatData = getCombatData()
    local player = findPlayer(combatData, id)
    if player then
        local activeTime = getPlayerActiveTime(combatData, player)
        local duration = combatData.duration
        GameTooltip:AddDoubleLine("活躍度", formatPercentage(activeTime, max(1, duration)), 1, 1, 1)
    end
end

local function updatePlayerView(dataList, combatData)
    local maxValue = 0
    local player = findPlayer(combatData, playerView.playerId)
    if player then
        local index = 1
        for spellName, spell in pairs(player.spells) do
            local data = dataList[index] or {}
            dataList[index] = data
            data.id = spellName
            data.value = spell.damage
            data.leftText = spellName
            data.rightText = format("%s (%s)", abbreviateNumber(spell.damage), formatPercentage(spell.damage,
                    player.damage))
            data.spellId = spell.id
            local _, _, icon = GetSpellInfo(spell.id)
            data.icon = icon
            if spell.school then
                data.spellSchool = spell.school
            end
            if spell.damage > maxValue then
                maxValue = spell.damage
            end
            index = index + 1
        end
    end
    barMaxValue = maxValue
end

local function playerViewOnEnter(id)
    local player = findPlayer(getCombatData(), id)
    if player then
        playerView.playerId = id
        playerView.title = player.name .. "的傷害"
    end
end

local function setPlayerViewTooltip(text)
    local player = findPlayer(getCombatData(), playerView.playerId)
    if player then
        local spell = player.spells[text]
        if spell then
            GameTooltip:AddLine(player.name .. "-" .. text, 1, 1, 1)
            if spell.school then
                local color = CombatLog_Color_ColorStringBySchool(spell.school)
                if color then
                    GameTooltip:AddLine(GetSchoolString(spell.school), color.r, color.g, color.b)
                end
            end
            if spell.min and spell.max then
                GameTooltip:AddDoubleLine("最小值", abbreviateNumber(spell.min), 1, 1, 1)
                GameTooltip:AddDoubleLine("最大值", abbreviateNumber(spell.max), 1, 1, 1)
            end
            GameTooltip:AddDoubleLine("平均值", abbreviateNumber(spell.damage / spell.totalHits), 1, 1, 1)
        end
    end
end

local function updateSpellData(dataList, text, value)
    local index = spellView.index + 1
    spellView.index = index
    local data = dataList[index] or {}
    dataList[index] = data
    data.id = text
    data.value = value
    data.leftText = text
    data.rightText = format("%s (%s)", value, formatPercentage(value, spellView.totalHits))
    barMaxValue = max(barMaxValue, value)
end

local function updateSpellView(dataList, combatData)
    local player = findPlayer(combatData, playerView.playerId)
    if player then
        local spell = player.spells[spellView.spellName]
        if spell then
            spellView.totalHits = spell.totalHits
            spellView.index = 0
            barMaxValue = 0
            if spell.hit and spell.hit > 0 then
                updateSpellData(dataList, HIT, spell.hit)
            end
            if spell.critical and spell.critical > 0 then
                updateSpellData(dataList, CRIT_CHANCE, spell.critical)
            end
            if spell.glancing and spell.glancing > 0 then
                updateSpellData(dataList, GLANCING_TRAILER, spell.glancing)
            end
            if spell.crushing and spell.crushing > 0 then
                updateSpellData(dataList, CRUSHING_TRAILER, spell.crushing)
            end
            if spell.ABSORB and spell.ABSORB > 0 then
                updateSpellData(dataList, ABSORB, spell.ABSORB)
            end
            if spell.BLOCK and spell.BLOCK > 0 then
                updateSpellData(dataList, BLOCK, spell.BLOCK)
            end
            if spell.DEFLECT and spell.DEFLECT > 0 then
                updateSpellData(dataList, DEFLECT, spell.DEFLECT)
            end
            if spell.DODGE and spell.DODGE > 0 then
                updateSpellData(dataList, DODGE, spell.DODGE)
            end
            if spell.EVADE and spell.EVADE > 0 then
                updateSpellData(dataList, EVADE, spell.EVADE)
            end
            if spell.IMMUNE and spell.IMMUNE > 0 then
                updateSpellData(dataList, IMMUNE, spell.IMMUNE)
            end
            if spell.MISS and spell.MISS > 0 then
                updateSpellData(dataList, MISS, spell.MISS)
            end
            if spell.PARRY and spell.PARRY > 0 then
                updateSpellData(dataList, PARRY, spell.PARRY)
            end
            if spell.REFLECT and spell.REFLECT > 0 then
                updateSpellData(dataList, REFLECT, spell.REFLECT)
            end
            if spell.RESIST and spell.RESIST > 0 then
                updateSpellData(dataList, RESIST, spell.RESIST)
            end
        end
    end
end

local function spellViewOnEnter(_, text)
    local player = findPlayer(getCombatData(), playerView.playerId)
    if player then
        spellView.spellName = text
        spellView.playerId = playerView.playerId
        spellView.title = player.name .. "的" .. text
    end
end

local function setSpellViewTooltip(text)
    local player = findPlayer(getCombatData(), spellView.playerId)
    if player then
        local spell = player.spells[spellView.spellName]
        if spell then
            GameTooltip:AddLine(player.name .. " - " .. spellView.spellName, 1, 1, 1)
            if text == CRIT_CHANCE and spell.criticalAmount then
                GameTooltip:AddDoubleLine("最小值", abbreviateNumber(spell.criticalMin), 1, 1, 1)
                GameTooltip:AddDoubleLine("最大值", abbreviateNumber(spell.criticalMax), 1, 1, 1)
                GameTooltip:AddDoubleLine("平均值", abbreviateNumber(spell.criticalAmount / spell.critical), 1, 1, 1)
            end
            if text == HIT and spell.hitAmount then
                GameTooltip:AddDoubleLine("最小值", abbreviateNumber(spell.hitMin), 1, 1, 1)
                GameTooltip:AddDoubleLine("最大值", abbreviateNumber(spell.hitMax), 1, 1, 1)
                GameTooltip:AddDoubleLine("平均值", abbreviateNumber(spell.hitAmount / spell.hit), 1, 1, 1)
            end
        end
    end
end

local function updateTargetView(dataList, combatData)
    local maxValue = 0
    local player = findPlayer(combatData, targetView.playerId)
    if player then
        local index = 1
        for target, amount in pairs(player.targets) do
            local data = dataList[index] or {}
            dataList[index] = data
            data.id = target
            data.value = amount
            data.leftText = target
            data.rightText = format("%s (%s)", abbreviateNumber(amount), formatPercentage(amount, player.damage))
            if amount > maxValue then
                maxValue = amount
            end
            index = index + 1
        end
    end
    barMaxValue = maxValue
end

local function targetViewOnEnter(id)
    local player = findPlayer(getCombatData(), id)
    targetView.playerId = id
    targetView.title = (player.name or UNKNOWN) .. "的目標"
end

local function updateTitle()
    local text = selectedView.title or selectedView.name
    local name
    if selectedView ~= combatView then
        if combatDataIndex == 0 then
            name = "目前的"
        else
            local combatData = getCombatData()
            if combatData then
                name = (combatData.name or UNKNOWN) .. ": " .. formatCombatTime(combatData)
            end
        end
    end
    if name then
        text = text .. ": " .. name
    end
    titleLabel:SetText(text)
end

local function sortByValue(a, b)
    if not a or a.value == nil then
        return false
    elseif not b or b.value == nil then
        return true
    else
        return a.value > b.value
    end
end

local function setViewTooltip(view, id, text)
    local combatData = getCombatData()
    if not combatData then
        return
    end
    wipe(tooltipData)
    if view.onEnter then
        view.onEnter(id, text)
    end
    view.update(tooltipData, combatData)
    table.sort(tooltipData, sortByValue)
    if #tooltipData > 0 then
        GameTooltip:AddLine(view.title or view.name, 1, 1, 1)
        local row = 0
        for _, data in ipairs(tooltipData) do
            if data.id and row < maxTooltipRows then
                local leftText = view.showSN and (row .. ". " .. data.leftText) or data.leftText
                GameTooltip:AddDoubleLine(leftText, data.rightText, 1, 1, 1)
                row = row + 1
            end
        end
        if view.onEnter then
            GameTooltip:AddLine(" ")
        end
    end
end

local function dataBarOnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("BOTTOMLEFT", logFrame, "BOTTOMRIGHT")
    if selectedView.onEnter then
        GameTooltip:ClearLines()
        if selectedView.setTooltip then
            local numLines = GameTooltip:NumLines()
            selectedView.setTooltip(self.id, self.text)
            if GameTooltip:NumLines() ~= numLines and selectedView.next1 then
                GameTooltip:AddLine(" ")
            end
        end
        if selectedView.next1 then
            tooltipView = selectedView.next1
            setViewTooltip(tooltipView, self.id, self.text)
        end
        if selectedView.next2 then
            tooltipView = selectedView.next2
            setViewTooltip(tooltipView, self.id, self.text)
        end
        if selectedView.setExtraTooltip then
            local numLines = GameTooltip:NumLines()
            selectedView.setExtraTooltip(self.id, self.text)
            if GameTooltip:NumLines() ~= numLines and selectedView.next1 then
                GameTooltip:AddLine(" ")
            end
        end
        if selectedView.next1 then
            GameTooltip:AddLine("點擊後爲 " .. selectedView.next1.name, 0.2, 1, 0.2)
        end
        if selectedView.next2 then
            GameTooltip:AddLine("Shift+點擊後爲 " .. selectedView.next2.name, 0.2, 1, 0.2)
        end
        GameTooltip:Show()
        self.UpdateTooltip = dataBarOnEnter
    end
end

local function dataBarOnLeave(self)
    GameTooltip:Hide()
    self.UpdateTooltip = nil
end

local function dataBarOnMouseDown(self, button)
    logFrame.click(nil, self, button)
end

local function createDataBar(data)
    numDataBars = numDataBars + 1
    ---@class WlkDamageLogDataBar:StatusBar
    local bar = CreateFrame("StatusBar", "WlkDamageLogDataBar" .. numDataBars, logFrame)
    local leftLabel = bar:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med3")
    local rightLabel = bar:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med3")

    if selectedView.showIcon then
        bar:SetSize(barWidth1, barHeight)
        local icon = bar:CreateTexture()
        icon:SetSize(barHeight, barHeight)
        icon:SetPoint("RIGHT", bar, "LEFT")
        if data.icon then
            icon:SetTexture(data.icon)
            icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        elseif data.class then
            icon:SetTexture("Interface/Glues/CharacterCreate/UI-CharacterCreate-Classes")
            local l, r, t, b = unpack(CLASS_ICON_TCOORDS[data.class])
            local adj = 0.02
            icon:SetTexCoord(l + adj, r - adj, t + adj, b - adj)
        else
            icon:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
            icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end
        bar.icon = icon
    else
        bar:SetSize(barWidth2, barHeight)
    end
    bar:SetStatusBarTexture("Interface/Tooltips/UI-Tooltip-Background")
    if data.spellSchool then
        local color = CombatLog_Color_ColorArrayBySchool(data.spellSchool)
        bar:SetStatusBarColor(GetTableColor(color))
    elseif data.class then
        bar:SetStatusBarColor(GetClassColor(data.class))
    else
        bar:SetStatusBarColor(0.3, 0.3, 0.8)
    end
    bar:SetScript("OnMouseDown", dataBarOnMouseDown)
    bar:SetScript("OnEnter", dataBarOnEnter)
    bar:SetScript("OnLeave", dataBarOnLeave)

    leftLabel:SetPoint("LEFT", 3, 0)

    rightLabel:SetPoint("RIGHT", -3, 0)

    bar.id = data.id
    bar.text = data.leftText
    bar.leftLabel = leftLabel
    bar.rightLabel = rightLabel

    dataBars[data.id] = bar

    return bar
end

---@param bar WlkDamageLogDataBar
local function updateDataBar(bar, index, data)
    bar.index = index
    bar:SetMinMaxValues(0, barMaxValue)
    bar:SetValue(data.value)
    if selectedView.showSN then
        bar.leftLabel:SetFormattedText("%2u. %s", index, data.leftText)
    else
        bar.leftLabel:SetText(data.leftText)
    end
    bar.rightLabel:SetText(data.rightText)
end

local function updateDataBarVisible()
    local minIndex = 1 + barOffset
    local maxIndex = maxDisplayDataBars + barOffset
    for _, bar in pairs(dataBars) do
        local index = bar.index
        if index >= minIndex and index <= maxIndex then
            bar:SetPoint("TOPRIGHT", 0, (barHeight + 1) * (minIndex - index) - 1)
            bar:Show()
        else
            bar:Hide()
        end
    end
end

local function updateDisplay()
    if selectedView.sort then
        table.sort(frameData, sortByValue)
    end
    local index = 1
    for _, data in ipairs(frameData) do
        if data.id then
            local bar = dataBars[data.id] or createDataBar(data)
            updateDataBar(bar, index, data)
            index = index + 1
        end
    end
    updateDataBarVisible()
end

local function clearDisplay()
    for _, data in ipairs(frameData) do
        wipe(data)
    end
    for _, bar in pairs(dataBars) do
        bar:Hide()
    end
    wipe(dataBars)
    numDataBars = 0
    barOffset = 0
end

local function updateData(force)
    if force then
        updateFlags = true
    end
    if updateFlags or changed or current then
        changed = false
        if selectedView.update then
            local combatData = getCombatData()
            if combatData then
                selectedView.update(frameData, combatData)
            end
        else
            barMaxValue = 1
            local index = 1
            local data = frameData[index] or {}
            frameData[index] = data
            data.id = index - 1
            data.value = 1
            data.leftText = "目前的"
            data.rightText = ""
            data.icon = current and current.gotBoss and bossIcon or nonBossIcon
            for _, combatData in ipairs(combatDataList) do
                index = index + 1
                data = frameData[index] or {}
                frameData[index] = data
                data.id = index - 1
                data.value = 1
                data.leftText = combatData.name
                data.rightText = formatCombatTime(combatData)
                data.icon = combatData.gotBoss and bossIcon or nonBossIcon
            end
        end
        updateDisplay()
    end
    updateFlags = false
end

local function setPlayersActiveTime(combatData)
    for _, player in ipairs(combatData.players) do
        if player.stop then
            player.duration = player.duration + (player.stop - player.start)
        end
    end
end

local function onCombatStop()
    if not current then
        return
    end
    if current.targetName ~= nil and time() - current.start > 5 then
        if not current.stop then
            current.stop = time()
        end
        current.duration = current.stop - current.start
        setPlayersActiveTime(current)
        local text = current.targetName
        local count = 0
        for _, data in ipairs(combatDataList) do
            if data.name == text and count == 0 then
                count = 1
            else
                local name, suffix = strmatch(data.name, "^(.-)%s*%((%d+)%)$")
                if name == text then
                    count = max(count, tonumber(suffix) or 0)
                end
            end
        end
        if count > 0 then
            text = format("%s(%d)", text, count + 1)
        end
        current.name = text
        tinsert(combatDataList, 1, current)
    end
    if #combatDataList > maxCombatData then
        tremove(combatDataList, #combatDataList)
    end
    current = nil
    clearDisplay()
    updateData(true)
    if updateTicker then
        updateTicker:Cancel()
    end
    if checkTicker then
        checkTicker:Cancel()
    end
    updateTicker = nil
    checkTicker = nil
end

local function getGroupInfo()
    local prefix
    local count = GetNumGroupMembers()
    if IsInRaid() then
        prefix = "raid"
    elseif IsInGroup() then
        prefix = "party"
        count = count - 1
    end
    return prefix, count
end

local function updateUnits()
    local prefix, count = getGroupInfo()
    for i = 1, count do
        local unit = prefix .. i
        local id = UnitGUID(unit)
        if id then
            players[id] = true
            local pet = unit .. "pet"
            local petId = UnitGUID(pet)
            if petId and not pets[petId] then
                pets[petId] = { id = id, name = GetUnitName(unit, true), }
            end
        end
    end
    local id = UnitGUID("player")
    if id then
        players[id] = true
        local petId = UnitGUID("playerpet")
        if petId and not pets[petId] then
            pets[petId] = { id = id, name = UnitName("player"), }
        end
    end
end

local function isAffectingCombat()
    local prefix, count = getGroupInfo()
    for i = 1, count do
        local unit = prefix .. i
        if UnitExists(unit) and UnitAffectingCombat(unit) then
            return true
        end
    end
    return UnitAffectingCombat("player")
end

local function checkCombatStop()
    if current and not InCombatLockdown() and not isAffectingCombat() then
        onCombatStop()
    end
end

local function initCombatData()
    return { players = {}, start = time(), duration = 0, damage = 0, }
end

local function onCombatStart()
    if updateTicker then
        onCombatStop()
    end
    clearDisplay()
    if temp and temp.start == time() then
        current = temp
    else
        current = initCombatData()
    end
    if encounterNameSaved and GetTime() < (encounterTimeSaved or 0) + 15 then
        current.targetName = encounterNameSaved
        current.gotBoss = true
        encounterNameSaved = nil
        encounterTimeSaved = nil
    end
    updateData(true)
    updateTicker = C_Timer.NewTicker(updateInterval, updateData)
    checkTicker = C_Timer.NewTicker(updateInterval, checkCombatStop)
end

local function displayView(view)
    clearDisplay()
    selectedView = view
    changed = true
    updateTitle()
    updateData()
end

local function fixPets()
    if dmg.playerName then
        local pet = pets[dmg.playerId]
        if pet then
            if dmg.spellName then
                dmg.spellName = dmg.playerName .. ": " .. dmg.spellName
            end
            dmg.playerName = pet.name
            dmg.playerId = pet.id
        else
            if dmg.playerFlags and bit.band(dmg.playerFlags, COMBATLOG_OBJECT_TYPE_GUARDIAN) ~= 0 then
                if bit.band(dmg.playerFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 then
                    if dmg.spellName then
                        dmg.spellName = dmg.playerName .. ": " .. dmg.spellName
                    end
                    dmg.playerName = UnitName("player")
                    dmg.playerId = UnitGUID("player")
                else
                    dmg.playerId = dmg.playerName
                end
            end
        end
    end
end

local function logDamage()
    local combatData = current or temp
    local player = getPlayer(combatData, dmg.playerId, dmg.playerName)
    if player then
        local amount = dmg.amount
        combatData.damage = combatData.damage + amount
        player.damage = player.damage + amount

        if not player.spells[dmg.spellName] then
            player.spells[dmg.spellName] = { id = dmg.spellId, totalHits = 0, damage = 0, school = dmg.school, }
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

        if dmg.dstName and amount > 0 then
            if not player.targets[dmg.dstName] then
                player.targets[dmg.dstName] = 0
            end
            player.targets[dmg.dstName] = player.targets[dmg.dstName] + amount
        end
    end
end

local function spellDamage(srcGuid, srcName, srcFlags, dstName, spellId, spellName, spellSchool, amount, _, _, _, _, _,
                           critical, glancing, crushing)
    dmg.playerId = srcGuid
    dmg.playerName = srcName
    dmg.playerFlags = srcFlags
    dmg.dstName = dstName
    dmg.spellId = spellId
    dmg.spellName = spellName
    dmg.school = spellSchool
    dmg.amount = amount
    dmg.critical = critical
    dmg.glancing = glancing
    dmg.crushing = crushing
    dmg.missed = nil

    fixPets()
    logDamage()
end

local function swingDamage(srcGuid, srcName, srcFlags, dstName, amount, _, _, _, _, _, critical, glancing, crushing)
    dmg.playerId = srcGuid
    dmg.playerName = srcName
    dmg.playerFlags = srcFlags
    dmg.dstName = dstName
    dmg.spellId = 6603
    dmg.spellName = MELEE_ATTACK
    dmg.school = 1
    dmg.amount = amount
    dmg.critical = critical
    dmg.glancing = glancing
    dmg.crushing = crushing
    dmg.missed = nil

    fixPets()
    logDamage()
end

local function spellMissed(srcGuid, srcName, srcFlags, dstName, spellId, spellName, spellSchool, missType)
    dmg.playerId = srcGuid
    dmg.playerName = srcName
    dmg.playerFlags = srcFlags
    dmg.dstName = dstName
    dmg.spellId = spellId
    dmg.spellName = spellName
    dmg.school = spellSchool
    dmg.amount = 0
    dmg.critical = nil
    dmg.glancing = nil
    dmg.crushing = nil
    dmg.missed = missType

    fixPets()
    logDamage()
end

local function swingMissed(srcGuid, srcName, srcFlags, dstName, missType)
    dmg.playerId = srcGuid
    dmg.playerName = srcName
    dmg.playerFlags = srcFlags
    dmg.dstName = dstName
    dmg.spellId = 6603
    dmg.spellName = MELEE_ATTACK
    dmg.school = nil
    dmg.amount = 0
    dmg.critical = nil
    dmg.glancing = nil
    dmg.crushing = nil
    dmg.missed = missType

    fixPets()
    logDamage()
end

local function onCombatLogEvent(_, event, _, srcGuid, srcName, srcFlags, dstFlags, dstGuid, dstName, _, _, ...)
    local srcFilter, dstFilter
    local func = combatLogEventFunctions[event]
    if func and srcGuid ~= dstGuid then
        srcFilter = bit.band(srcFlags, RAID_FLAGS) ~= 0 or (bit.band(srcFlags, PET_FLAGS) ~= 0 and pets[srcGuid])
                or players[srcGuid]
        dstFilter = bit.band(dstFlags, RAID_FLAGS) ~= 0 or (bit.band(dstFlags, PET_FLAGS) ~= 0 and pets[dstGuid])
                or players[dstGuid]
        if srcFilter and not dstFilter then
            if not current then
                temp = initCombatData()
            end
            func(srcGuid, srcName, srcFlags, dstName, ...)
        end
    end
    if current and srcFilter and not current.gotBoss and bit.band(dstFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) == 0
            and not current.targetName then
        current.targetName = dstName
    end
    if event == "SPELL_SUMMON" and (bit.band(srcFlags, RAID_FLAGS) ~= 0 or bit.band(srcFlags, PET_FLAGS) ~= 0
            or (bit.band(dstFlags, PET_FLAGS) ~= 0 and pets[dstGuid])) then
        pets[dstGuid] = { id = srcGuid, name = srcName, }
        if pets[srcGuid] then
            pets[dstGuid].id = pets[srcGuid].id
            pets[dstGuid].name = pets[srcGuid].name
        end
    end
end

local function clickLogFrame(_, bar, button)
    if button == "RightButton" then
        local view = selectedView.previous
        if view then
            displayView(view)
        end
    elseif bar then
        local view = IsShiftKeyDown() and selectedView.next2 or selectedView.next1
        if view then
            view.onEnter(bar.id, bar.text)
            displayView(view)
        end
    end
end

logFrame:SetPoint("BOTTOMLEFT")
logFrame:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", xOffset, yOffset)
logFrame:SetBackdrop(backdrop)
logFrame:SetBackdropColor(0, 0, 0, 0.8)
logFrame:RegisterEvent("ADDON_LOADED")
logFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
logFrame:RegisterEvent("UNIT_PET")
logFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
logFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
logFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
logFrame:RegisterEvent("ENCOUNTER_START")
logFrame:RegisterEvent("ENCOUNTER_END")
logFrame:RegisterEvent("PLAYER_LOGOUT")
logFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            logFrame:UnregisterEvent(event)
            if WlkCombatData then
                combatDataList = WlkCombatData
            else
                WlkCombatData = combatDataList
            end
        end
    elseif event == "GROUP_ROSTER_UPDATE" or event == "UNIT_PET" then
        updateUnits()
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        if isInitialLogin or isReloadingUi then
            C_Timer.After(1, updateUnits)
        end
        displayView(selectedView)
    elseif event == "PLAYER_REGEN_DISABLED" then
        if not current then
            onCombatStart()
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        onCombatLogEvent(CombatLogGetCurrentEventInfo())
    elseif event == "ENCOUNTER_START" then
        local _, encounterName = ...
        if current then
            current.targetName = encounterName
            current.gotBoss = true
        else
            encounterNameSaved = encounterName
            encounterTimeSaved = GetTime()
        end
    elseif event == "ENCOUNTER_END" then
        local _, encounterName = ...
        if current and not current.gotBoss then
            current.targetName = encounterName
            current.gotBoss = true
        end
    elseif event == "PLAYER_LOGOUT" then
        for _, combatData in ipairs(combatDataList) do
            combatData.playerIndexes = nil
        end
    end
end)
logFrame:SetScript("OnMouseDown", function(_, button)
    clickLogFrame(nil, nil, button)
end)
logFrame:SetScript("OnMouseWheel", function(_, delta)
    if delta > 0 and barOffset > 0 then
        barOffset = barOffset - 1
        updateDataBarVisible()
    elseif delta < 0 and numDataBars - maxDisplayDataBars - barOffset > 0 then
        barOffset = barOffset + 1
        updateDataBarVisible()
    end
end)

titleFrame:SetPoint("BOTTOMLEFT", logFrame, "TOPLEFT")
titleFrame:SetPoint("TOPRIGHT", 0, titleHeight)
titleFrame:SetBackdrop(backdrop)
titleFrame:SetBackdropColor(0.3, 0.3, 0.3)

titleLabel:SetWidth(xOffset - 30)
titleLabel:SetMaxLines(1)
titleLabel:SetPoint("LEFT", 5, 0)
titleLabel:SetJustifyH("LEFT")

resetButton:SetSize(12, 12)
resetButton:SetPoint("RIGHT", titleFrame, -5, 0)
resetButton:SetNormalTexture("Interface/Buttons/UI-StopButton")
resetButton:SetHighlightTexture("Interface/Buttons/UI-StopButton", 1)
resetButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
resetButton:SetScript("OnClick", function()
    clearDisplay()
    wipe(players)
    wipe(pets)
    updateUnits()
    if current then
        current = initCombatData()
    end
    wipe(combatDataList)
    combatDataIndex = 0
    changed = true
    updateData(true)
    ChatFrame1:AddMessage("統計數據已重置", 1, 1, 0)
    if not InCombatLockdown() then
        collectgarbage("collect")
    end
end)

combatView.next1 = damageView

damageView.update = updateDamageView
damageView.onEnter = damageViewOnEnter
damageView.setExtraTooltip = setDamageViewExtraTooltip
damageView.next1 = playerView
damageView.next2 = targetView
damageView.previous = combatView

playerView.update = updatePlayerView
playerView.onEnter = playerViewOnEnter
playerView.setTooltip = setPlayerViewTooltip
playerView.next1 = spellView
playerView.previous = damageView

spellView.update = updateSpellView
spellView.onEnter = spellViewOnEnter
spellView.setTooltip = setSpellViewTooltip
spellView.previous = playerView

targetView.update = updateTargetView
targetView.onEnter = targetViewOnEnter
targetView.previous = damageView

combatLogEventFunctions.DAMAGE_SHIELD = spellDamage
combatLogEventFunctions.SPELL_DAMAGE = spellDamage
combatLogEventFunctions.SPELL_PERIODIC_DAMAGE = spellDamage
combatLogEventFunctions.SPELL_BUILDING_DAMAGE = spellDamage
combatLogEventFunctions.RANGE_DAMAGE = spellDamage
combatLogEventFunctions.SWING_DAMAGE = swingDamage
combatLogEventFunctions.SPELL_MISSED = spellMissed
combatLogEventFunctions.SPELL_PERIODIC_MISSED = spellMissed
combatLogEventFunctions.RANGE_MISSED = spellMissed
combatLogEventFunctions.SPELL_BUILDING_MISSED = spellMissed
combatLogEventFunctions.SWING_MISSED = swingMissed

logFrame.click = clickLogFrame
