local combatDataList = {}
local characters = {}
local pets = {}
local updateInterval = 1

local current, temp
local combatDataIndex = 0
local encounterNameSaved, encounterTimeSaved
local dmg = {}
local updateFlags = true

local function FindCharacter(combatData, id)
    combatData.characterIdIndexes = combatData.characterIdIndexes or {}
    if combatData.characterIdIndexes[id] then
        return combatData.characterIdIndexes[id]
    end
    for _, character in ipairs(combatData.characters) do
        if character.id == id then
            combatData.characterIdIndexes[id] = character
            return character
        end
    end
end

local function GetCharacter(combatData, id, name)
    local character = FindCharacter(combatData, id)
    if not character then
        if not name then
            return
        end
        character = {
            id = id,
            class = select(2, UnitClass(name)),
            start = time(),
            duration = 0,
            damage = 0,
            spells = {},
            targets = {},
        }
        local characterName = strsplit("-", name, 2)
        character.name = characterName or name
        combatData.characters[#combatData.characters + 1] = character
    end
    if character.name == UNKNOWN and name ~= UNKNOWN then
        local characterName = strsplit("-", name, 2)
        character.name = characterName or name
        character.class = select(2, UnitClass(name))
    end
    character.stop = time()
    updateFlags = true
    return character
end

local band = bit.band
local bor = bit.bor

local function FixPets()
    if dmg.characterName then
        local pet = pets[dmg.characterId]
        if pet then
            if dmg.spellName then
                dmg.spellName = dmg.characterName .. ": " .. dmg.spellName
            end
            dmg.characterName = pet.name
            dmg.characterId = pet.id
        else
            if dmg.characterFlags and band(dmg.characterFlags, COMBATLOG_OBJECT_TYPE_GUARDIAN) ~= 0 then
                if band(dmg.characterFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 then
                    if dmg.spellName then
                        dmg.spellName = dmg.characterName .. ": " .. dmg.spellName
                    end
                    dmg.characterName = UnitName("player")
                    dmg.characterId = UnitGUID("player")
                else
                    dmg.characterId = dmg.characterName
                end
            end
        end
    end
end

local function LogDamage()
    -- current 存在时，记录到 current 中，不存在时记录到临时表中
    local combatData = current or temp
    local character = GetCharacter(combatData, dmg.characterId, dmg.characterName)
    if character then
        local amount = dmg.amount
        combatData.damage = combatData.damage + amount
        character.damage = character.damage + amount

        if not character.spells[dmg.spellName] then
            character.spells[dmg.spellName] = { id = dmg.spellId, totalHits = 0, damage = 0, school = dmg.school, }
        end
        local spell = character.spells[dmg.spellName]
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
            if not character.targets[dmg.dstName] then
                character.targets[dmg.dstName] = 0
            end

            character.targets[dmg.dstName] = character.targets[dmg.dstName] + amount
        end
    end
end

local function SpellDamage(_, _, srcGuid, srcName, srcFlags, dstGuid, dstName, _, spellId, spellName, spellSchool,
                           sAmount, sOverkill, _, sResisted, sBlocked, sAbsorbed, sCritical, sGlancing, sCrushing,
                           sOffhand)
    if srcGuid ~= dstGuid then
        dmg.characterId = srcGuid
        dmg.characterFlags = srcFlags
        dmg.dstName = dstName
        dmg.characterName = srcName
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

        FixPets()
        LogDamage()
    end
end

local function SwingDamage(_, _, srcGuid, srcName, srcFlags, dstGuid, dstName, _, sAmount, sOverkill, _, sResisted,
                           sBlocked, sAbsorbed, sCritical, sGlancing, sCrushing, sOffhand)
    if srcGuid ~= dstGuid then
        dmg.characterId = srcGuid
        dmg.characterFlags = srcFlags
        dmg.dstName = dstName
        dmg.characterName = srcName
        dmg.spellId = 6603
        dmg.spellName = MELEE_ATTACK
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

        FixPets()
        LogDamage()
    end
end

local function SpellAbsorbed(timestamp, eventType, srcGuid, srcName, srcFlags, dstGuid, dstName, dstFlags, ...)
    local arg = ...
    local spellId, spellName, spellSchool, aGUID, aName, aFlags, aRaidFlags, aSpellId, aSpellName, aSpellSchool, aAmount

    if type(arg) == "number" then
        spellId, spellName, spellSchool, aGUID, aName, aFlags, aRaidFlags, aSpellId, aSpellName, aSpellSchool,
        aAmount = ...

        if aSpellId == 184553 then
            return
        end

        if aAmount then
            SpellDamage(timestamp, eventType, srcGuid, srcName, srcFlags, dstGuid, dstName, dstFlags, spellId,
                    spellName, spellSchool, aAmount)
        end
    else
        aGUID, aName, aFlags, aRaidFlags, aSpellId, aSpellName, aSpellSchool, aAmount = ...

        if aSpellId == 184553 then
            return
        end

        if aAmount then
            SwingDamage(timestamp, eventType, srcGuid, srcName, srcFlags, dstGuid, dstName, dstFlags, aAmount)
        end
    end

end

local function SwingMissed(_, _, srcGuid, srcName, srcFlags, dstGuid, dstName, _, missed)
    if srcGuid ~= dstGuid then
        dmg.characterId = srcGuid
        dmg.characterFlags = srcFlags
        dmg.dstName = dstName
        dmg.characterName = srcName
        dmg.spellId = 6603
        dmg.spellName = MELEE_ATTACK
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

        FixPets()
        LogDamage()
    end
end

local function SpellMissed(_, _, srcGuid, srcName, srcFlags, dstGuid, dstName, _, spellId, spellName, _, missType)
    if srcGuid ~= dstGuid then
        dmg.characterId = srcGuid
        dmg.characterFlags = srcFlags
        dmg.dstName = dstName
        dmg.characterName = srcName
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

        FixPets()
        LogDamage()
    end
end

--- WlkChatMenuFrame 左边相对 UIParent 左边的偏移值
local offsetX1 = 453
--- ChatFrame1Background 底部相对 UIParent 底部的偏移值
local offsetY1 = 116
local titleHeight = 20
local backdrop = { bgFile = "Interface/ChatFrame/CHATFRAMEBACKGROUND", }

---@type Frame
local titleFrame = CreateFrame("Frame", "WlkDamageLogTitleFrame", UIParent)
titleFrame:SetSize(offsetX1, titleHeight)
titleFrame:SetPoint("BOTTOMLEFT", 0, offsetY1 - titleHeight)
titleFrame:SetBackdrop(backdrop)
titleFrame:SetBackdropColor(0.3, 0.3, 0.3)
---@type FontString
local titleLabel = titleFrame:CreateFontString("WlkDamageLogTitleLabel", "ARTWORK", "ChatFontNormal")
titleLabel:SetWidth(offsetX1 - 30)
titleLabel:SetMaxLines(1)
titleLabel:SetPoint("LEFT", 5, 0)
titleLabel:SetJustifyH("LEFT")

---@type Frame
local logFrame = CreateFrame("Frame", "WlkDamageLogFrame", UIParent)
logFrame:SetSize(offsetX1, offsetY1 - titleHeight)
logFrame:SetPoint("BOTTOMLEFT")
logFrame:SetBackdrop(backdrop)
logFrame:SetBackdropColor(0, 0, 0, 0.8)

logFrame.data = {}
local selectedView

local function GetCombatData()
    if combatDataIndex == 0 then
        return current or combatDataList[1]
    elseif combatDataIndex > 0 then
        return combatDataList[combatDataIndex]
    end
end

local function FormatCombatTime(combat)
    local start = combat.start
    local stop = combat.stop or time()
    local duration = SecondsToTime(stop - start, false, false, 2)
    return format("%s (%s)", date("%H:%M", start), duration)
end

---@type StatusBar[]
local bars = {}
local numBars = 0
local maxBars = 5
local barOffset = 0
local barMaxValue

local function GetCharacterActiveTime(combatData, character)
    local activeTime = 0

    if character.duration > 0 then
        activeTime = character.duration
    end

    if not combatData.stop and character.start then
        activeTime = activeTime + character.stop - character.start
    end
    return activeTime
end

local function GetDPS(combatData, character)
    local activeTime = GetCharacterActiveTime(combatData, character)
    return character.damage / max(1, activeTime)
end

local function AbbreviateNumber(number)
    if number >= 1e8 then
        return format("%.2f%s", number / 1e8, SECOND_NUMBER_CAP)
    elseif number >= 1e4 then
        return format("%.2f%s", number / 1e4, FIRST_NUMBER_CAP)
    end
    return floor(number)
end

local function FormatPercentageBetween(value, endValue)
    return format("%.1f%%", PercentageBetween(value, 0, endValue) * 100)
end

local combatView = { name = COMBAT_LABEL, }
local damageView = { name = DAMAGE, showSN = true, }
local characterView = { name = "傷害法術列表", }
local spellView = { name = SPELL_DETAIL, }
local targetView = { name = "受到傷害的單位", }

local function UpdateDamageView(container, combatData)
    local maxValue = 0
    local index = 1
    for _, character in ipairs(combatData.characters) do
        if character.damage > 0 then
            local dps = GetDPS(combatData, character)
            local data = container.data[index] or {}
            container.data[index] = data

            data.text = character.name
            data.valueText = format("%s (%s, %s)", AbbreviateNumber(character.damage), AbbreviateNumber(dps),
                    FormatPercentageBetween(character.damage, combatData.damage))
            data.value = character.damage
            data.id = character.id
            data.class = character.class
            if character.damage > maxValue then
                maxValue = character.damage
            end
            index = index + 1
        end
    end
    barMaxValue = maxValue
end

local function DamageViewOnEnter(id)
    combatDataIndex = id
end

local function DamageViewExtraTooltip(id)
    local combat = GetCombatData()
    local character = FindCharacter(combat, id)
    if character then
        local activeTime = GetCharacterActiveTime(combat, character)
        local duration = combat.duration
        GameTooltip:AddDoubleLine("活躍度", FormatPercentageBetween(activeTime, max(1, duration)), 1, 1, 1)
    end
end

local function UpdateCharacterView(container, combatData)
    local character = FindCharacter(combatData, characterView.characterId)
    local maxValue = 0
    if character then
        local index = 1
        for spellName, spell in pairs(character.spells) do
            local data = container.data[index] or {}
            container.data[index] = data
            data.text = spellName
            data.id = spellName
            local _, _, icon = GetSpellInfo(spell.id)
            data.icon = icon
            data.spellId = spell.id
            data.value = spell.damage
            if spell.school then
                data.spellSchool = spell.school
            end
            data.valueText = format("%s (%s)", AbbreviateNumber(spell.damage), FormatPercentageBetween(
                    spell.damage, character.damage))
            if spell.damage > maxValue then
                maxValue = spell.damage
            end
            index = index + 1
        end
    end
    barMaxValue = maxValue
end

local function CharacterViewOnEnter(id)
    local character = FindCharacter(GetCombatData(), id)
    if character then
        characterView.characterId = id
        characterView.title = character.name .. "的傷害"
    end
end

local function CharacterViewTooltip(_, text)
    local character = FindCharacter(GetCombatData(), characterView.characterId)
    if character then
        local spell = character.spells[text]
        if spell then
            GameTooltip:AddLine(character.name .. " - " .. text, 1, 1, 1)
            if spell.school then
                local color = CombatLog_Color_ColorArrayBySchool(spell.school)
                if color then
                    GameTooltip:AddLine(GetSchoolString(spell.school), color.r, color.g, color.b)
                end
            end
            if spell.min and spell.max then
                GameTooltip:AddDoubleLine("最小值:", AbbreviateNumber(spell.min), 1, 1, 1)
                GameTooltip:AddDoubleLine("最大值:", AbbreviateNumber(spell.max), 1, 1, 1)
            end
            GameTooltip:AddDoubleLine("平均值:", AbbreviateNumber(spell.damage / spell.totalHits), 1, 1, 1)
        end
    end
end

local function AddSpellDetailBar(container, text, value)
    local index = spellView.index + 1
    spellView.index = index
    local data = container.data[index] or {}
    container.data[index] = data

    data.text = text
    data.value = value
    data.id = text
    data.valueText = format("%s (%s)", value, FormatPercentageBetween(value, spellView.totalHits))
    barMaxValue = max(barMaxValue, value)
end

local function UpdateSpellView(container, combatData)
    local character = FindCharacter(combatData, characterView.characterId)
    if character then
        local spell = character.spells[spellView.spellName]
        if spell then
            spellView.totalHits = spell.totalHits
            spellView.index = 0
            barMaxValue = 0

            if spell.hit and spell.hit > 0 then
                AddSpellDetailBar(container, HIT, spell.hit)
            end
            if spell.critical and spell.critical > 0 then
                AddSpellDetailBar(container, CRIT_CHANCE, spell.critical)
            end
            if spell.glancing and spell.glancing > 0 then
                AddSpellDetailBar(container, GLANCING_TRAILER, spell.glancing)
            end
            if spell.crushing and spell.crushing > 0 then
                AddSpellDetailBar(container, CRUSHING_TRAILER, spell.crushing)
            end
            if spell.ABSORB and spell.ABSORB > 0 then
                AddSpellDetailBar(container, ABSORB, spell.ABSORB)
            end
            if spell.BLOCK and spell.BLOCK > 0 then
                AddSpellDetailBar(container, BLOCK, spell.BLOCK)
            end
            if spell.DEFLECT and spell.DEFLECT > 0 then
                AddSpellDetailBar(container, DEFLECT, spell.DEFLECT)
            end
            if spell.DODGE and spell.DODGE > 0 then
                AddSpellDetailBar(container, DODGE, spell.DODGE)
            end
            if spell.EVADE and spell.EVADE > 0 then
                AddSpellDetailBar(container, EVADE, spell.EVADE)
            end
            if spell.IMMUNE and spell.IMMUNE > 0 then
                AddSpellDetailBar(container, IMMUNE, spell.IMMUNE)
            end
            if spell.MISS and spell.MISS > 0 then
                AddSpellDetailBar(container, MISS, spell.MISS)
            end
            if spell.PARRY and spell.PARRY > 0 then
                AddSpellDetailBar(container, PARRY, spell.PARRY)
            end
            if spell.REFLECT and spell.REFLECT > 0 then
                AddSpellDetailBar(container, REFLECT, spell.REFLECT)
            end
            if spell.RESIST and spell.RESIST > 0 then
                AddSpellDetailBar(container, RESIST, spell.RESIST)
            end
        end
    end
end

local function SpellViewOnEnter(_, text)
    local character = FindCharacter(GetCombatData(), characterView.characterId)
    if character then
        spellView.spellName = text
        spellView.characterId = characterView.characterId
        spellView.title = character.name .. "的" .. text
    end
end

local function SpellViewTooltip(_, text)
    local character = FindCharacter(GetCombatData(), spellView.characterId)
    if character then
        local spell = character.spells[spellView.spellName]
        if spell then
            GameTooltip:AddLine(character.name .. " - " .. spellView.spellName, 1, 1, 1)
            if text == CRIT_CHANCE and spell.criticalAmount then
                GameTooltip:AddDoubleLine(MINIMUM, AbbreviateNumber(spell.criticalMin), 1, 1, 1)
                GameTooltip:AddDoubleLine(MAXIMUM, AbbreviateNumber(spell.criticalMax), 1, 1, 1)
                GameTooltip:AddDoubleLine("平均", AbbreviateNumber(spell.criticalAmount / spell.critical), 1, 1, 1)
            end
            if text == HIT and spell.hitAmount then
                GameTooltip:AddDoubleLine(MINIMUM, AbbreviateNumber(spell.hitMin), 1, 1, 1)
                GameTooltip:AddDoubleLine(MAXIMUM, AbbreviateNumber(spell.hitMax), 1, 1, 1)
                GameTooltip:AddDoubleLine("平均", AbbreviateNumber(spell.hitAmount / spell.hit), 1, 1, 1)
            end
        end
    end
end

local function UpdateTargetView(container, combatData)
    local character = FindCharacter(combatData, targetView.characterId)
    local maxValue = 0
    if character then
        local index = 1
        for target, amount in pairs(character.targets) do
            local data = container.data[index] or {}
            container.data[index] = data
            data.text = target
            data.id = target
            data.value = amount
            data.valueText = format("%s (%s)", AbbreviateNumber(amount), FormatPercentageBetween(
                    amount, character.damage))
            if amount > maxValue then
                maxValue = amount
            end
            index = index + 1
        end
    end
    barMaxValue = maxValue
end

local function TargetViewOnEnter(id)
    local character = FindCharacter(GetCombatData(), id)
    targetView.characterId = id
    targetView.title = (character.name or UNKNOWN) .. "的目標"
end

damageView.update = UpdateDamageView
damageView.enter = DamageViewOnEnter
damageView.extraTooltip = DamageViewExtraTooltip
characterView.update = UpdateCharacterView
characterView.enter = CharacterViewOnEnter
characterView.tooltip = CharacterViewTooltip
spellView.update = UpdateSpellView
spellView.enter = SpellViewOnEnter
spellView.tooltip = SpellViewTooltip
targetView.update = UpdateTargetView
targetView.enter = TargetViewOnEnter

combatView.next1 = damageView
damageView.previous = combatView
damageView.next1 = characterView
damageView.next2 = targetView
characterView.previous = damageView
characterView.next1 = spellView
spellView.previous = characterView
targetView.previous = damageView

selectedView = damageView

local function UpdateTitle()
    local name = selectedView.title or selectedView.name
    local combatName
    if selectedView ~= combatView then
        if combatDataIndex == 0 then
            combatName = "目前的"
        else
            local combat = GetCombatData()
            if combat then
                combatName = (combat.name or UNKNOWN) .. ": " .. FormatCombatTime(combat)
            end
        end
    end
    if combatName then
        name = name .. ": " .. combatName
    end
    titleLabel:SetText(name)
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

local maxTooltipRows = 3
local tooltip = { data = {}, }
local tooltipSelectedView
local tSort = table.sort

local function AddSubviewToTooltip(view, id, text)
    local combatData = GetCombatData()
    if not combatData then
        return
    end
    wipe(tooltip.data)
    if view.enter then
        view["enter"](id, text)
    end
    view["update"](tooltip, combatData)
    tSort(tooltip.data, SortDataByValue)
    if #tooltip.data > 0 then
        GameTooltip:AddLine(view.title or view.name, 1, 1, 1)
        local row = 0
        for _, data in ipairs(tooltip.data) do
            if data.id and row < maxTooltipRows then
                row = row + 1
                local leftText = view.showSN and (row .. ". " .. data.text) or data.text
                GameTooltip:AddDoubleLine(leftText, data.valueText, 1, 1, 1)
            end
        end

        if view.enter then
            GameTooltip:AddLine(" ")
        end
    end
end

local function DataBarOnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("BOTTOMLEFT", logFrame, "BOTTOMRIGHT")

    if selectedView ~= combatView then
        GameTooltip:ClearLines()
        local hasClick = selectedView.next1

        if selectedView.tooltip then
            local numLines = GameTooltip:NumLines()
            selectedView["tooltip"](self.id, self.text)
            if GameTooltip:NumLines() ~= numLines and hasClick then
                GameTooltip:AddLine(" ")
            end
        end

        if selectedView.next1 then
            tooltipSelectedView = selectedView.next1
            AddSubviewToTooltip(tooltipSelectedView, self.id, self.text)
        end
        if selectedView.next2 then
            tooltipSelectedView = selectedView.next2
            AddSubviewToTooltip(tooltipSelectedView, self.id, self.text)
        end

        if selectedView.extraTooltip then
            local numLines = GameTooltip:NumLines()
            selectedView["extraTooltip"](self.id, self.text)
            if GameTooltip:NumLines() ~= numLines and hasClick then
                GameTooltip:AddLine(" ")
            end
        end

        if selectedView.next1 then
            GameTooltip:AddLine("點擊後爲 " .. selectedView.next1.name .. ".", 0.2, 1, 0.2)
        end
        if selectedView.next2 then
            GameTooltip:AddLine("Shift+點擊後爲 " .. selectedView.next2.name .. ".", 0.2, 1, 0.2)
        end

        GameTooltip:Show()

        self.UpdateTooltip = DataBarOnEnter
    end
end

local function DataBarOnLeave(self)
    GameTooltip:Hide()
    self.UpdateTooltip = nil
end

local function DataBarOnMouseDown(self, button)
    logFrame["click"](logFrame, self, button)
end

local barHeight = 18

local function CreateDataBar(data)
    numBars = numBars + 1
    ---@type StatusBar
    local bar = CreateFrame("StatusBar", "WlkDamageLogDataBar" .. numBars, logFrame)
    bars[data.id] = bar
    bar.id = data.id
    bar.text = data.text
    if selectedView == spellView or selectedView == targetView then
        bar:SetSize(offsetX1, barHeight)
    else
        bar:SetSize(offsetX1 - barHeight, barHeight)
        bar.icon = bar:CreateTexture()
        bar.icon:SetSize(barHeight, barHeight)
        bar.icon:SetPoint("RIGHT", bar, "LEFT")
        if data.icon then
            bar.icon:SetTexture(data.icon)
            bar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        elseif data.class then
            bar.icon:SetTexture("Interface/Glues/CharacterCreate/UI-CharacterCreate-Classes")
            local l, r, t, b = unpack(CLASS_ICON_TCOORDS[data.class])
            local adj = 0.02
            bar.icon:SetTexCoord(l + adj, r - adj, t + adj, b - adj)
        else
            bar.icon:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
            bar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end
    end
    bar:SetStatusBarTexture("Interface/Tooltips/UI-Tooltip-Background")
    if data.spellSchool then
        if CombatLog_Color_ColorArrayBySchool then
            local color = CombatLog_Color_ColorArrayBySchool(data.spellSchool)
            bar:SetStatusBarColor(GetTableColor(color))
        end
    elseif data.class then
        bar:SetStatusBarColor(GetClassColor(data.class))
    else
        bar:SetStatusBarColor(0.3, 0.3, 0.8)
    end
    ---@type FontString
    bar.leftLabel = bar:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
    bar.leftLabel:SetPoint("LEFT", 3, 0)
    ---@type FontString
    bar.rightLabel = bar:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
    bar.rightLabel:SetPoint("RIGHT", -3, 0)

    bar:SetScript("OnMouseDown", DataBarOnMouseDown)
    bar:SetScript("OnEnter", DataBarOnEnter)
    bar:SetScript("OnLeave", DataBarOnLeave)

    return bar
end

---@param bar StatusBar
local function UpdateDataBar(bar, index, data)
    bar.index = index
    bar:SetMinMaxValues(0, barMaxValue)
    bar:SetValue(data.value)
    if selectedView and selectedView.showSN then
        bar.leftLabel:SetFormattedText("%2u. %s", index, data.text)
    else
        bar.leftLabel:SetText(data.text)
    end
    bar.rightLabel:SetText(data.valueText)
end

local function UpdateBarVisibility()
    local minIndex = 1 + barOffset
    local maxIndex = maxBars + barOffset
    for _, bar in pairs(bars) do
        local index = bar.index
        if index >= minIndex and index <= maxIndex then
            bar:SetPoint("TOPRIGHT", 0, (barHeight + 1) * (minIndex - index) - 1)
            bar:Show()
        else
            bar:Hide()
        end
    end
end

local function UpdateDisplay()
    if selectedView ~= combatView then
        tSort(logFrame.data, SortDataByValue)
    end
    local index = 1
    for _, data in ipairs(logFrame.data) do
        if data.id then
            local bar = bars[data.id] or CreateDataBar(data)
            UpdateDataBar(bar, index, data)
            index = index + 1
        end
    end
    UpdateBarVisibility()
end

local function ClearLogFrame()
    for _, data in ipairs(logFrame.data) do
        wipe(data)
    end
    barOffset = 0
    for _, bar in pairs(bars) do
        bar:Hide()
    end
    wipe(bars)
    numBars = 0
end

local BOSS_ICON = "Interface/Icons/achievment_Boss_ultraxion"
local NON_BOSS_ICON = "Interface/Icons/Icon_PetFamily_Critter"

local function UpdateData(force)
    if force then
        updateFlags = true
    end
    if updateFlags or logFrame.changed or current then
        logFrame.changed = false
        if selectedView ~= combatView then
            local combatData = GetCombatData()
            if combatData then
                selectedView["update"](logFrame, combatData)
            end
        else
            barMaxValue = 1
            local index = 1
            local data = logFrame.data[index] or {}
            logFrame.data[index] = data
            data.id = index - 1
            data.text = "目前的"
            data.value = 1
            data.valueText = ""
            data.icon = current and current.gotBoss and BOSS_ICON or NON_BOSS_ICON
            for _, combatData in ipairs(combatDataList) do
                index = index + 1
                data = logFrame.data[index] or {}
                logFrame.data[index] = data
                data.id = index - 1
                data.text = combatData.name
                data.value = 1
                data.valueText = FormatCombatTime(combatData)
                data.icon = combatData.gotBoss and BOSS_ICON or NON_BOSS_ICON
            end
        end
        UpdateDisplay()
    end
    updateFlags = false
end

local function SetCharacterActiveTime(combatData)
    for _, character in ipairs(combatData.characters) do
        if character.stop then
            character.duration = character.duration + (character.stop - character.start)
        end
    end
end

local maxNumCombatData = 15
---@type TickerPrototype
local updateTicker, checkTicker

local function CombatEnd()
    if not current then
        return
    end
    if current.targetName ~= nil and time() - current.start > 5 then
        if not current.stop then
            current.stop = time()
        end
        current.duration = current.stop - current.start
        SetCharacterActiveTime(current)

        local name = current.targetName
        local count = 0
        for _, combatData in ipairs(combatDataList) do
            if combatData.name == name and count == 0 then
                count = 1
            else
                local n, c = strmatch(combatData.name, "^(.-)%s*%((%d+)%)$")
                if n == name then
                    count = max(count, tonumber(c) or 0)
                end
            end
        end
        if count > 0 then
            name = format("%s(%d)", name, count + 1)
        end
        current.name = name

        tinsert(combatDataList, 1, current)
    end
    if #combatDataList > maxNumCombatData then
        local combatData
        for i = #combatDataList, 2, -1 do
            if not combatDataList[i].gotBoss then
                combatData = tremove(combatDataList, i)
                break
            end
        end
        if not combatData then
            tremove(combatDataList, #combatDataList)
        end
    end
    current = nil
    ClearLogFrame()
    UpdateData(true)
    if updateTicker then
        updateTicker:Cancel()
    end
    if checkTicker then
        checkTicker:Cancel()
    end
    updateTicker = nil
    checkTicker = nil
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

local function UpdateCharactersAndPets()
    local type, count = GetGroupTypeAndCount()
    if count > 0 then
        for i = 1, count do
            local unit = type .. i
            local id = UnitGUID(unit)
            characters[id] = true
            local unitPet = unit .. "pet"
            local petId = UnitGUID(unitPet)
            if petId and not pets[petId] then
                local owner = GetUnitName(unit, true)
                pets[petId] = { id = id, name = owner, }
            end
        end
    end
    local id = UnitGUID("player")
    characters[id] = true
    local petId = UnitGUID("playerpet")
    if petId and not pets[petId] then
        pets[petId] = { id = id, name = UnitName("player"), }
    end
end

local function IsInRaidCombat()
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

local function CheckCombat()
    if current and not InCombatLockdown() and not IsInRaidCombat() then
        CombatEnd()
    end
end

local function InitCombatData()
    return { characters = {}, start = time(), duration = 0, damage = 0, }
end

local function UpdateDataTicker()
    UpdateData()
end

local function CheckCombatTicker()
    CheckCombat()
end

local function CombatStart()
    if updateTicker then
        CombatEnd()
    end
    ClearLogFrame()
    if temp and temp.start == time() then
        -- 有临时数据且该次数据的记录时间和战斗开始时间相同时，使用此次临时数据
        current = temp
    else
        -- 没有临时数据时，创建新的
        current = InitCombatData()
    end
    if encounterNameSaved and GetTime() < (encounterTimeSaved or 0) + 15 then
        current.targetName = encounterNameSaved
        current.gotBoss = true
        encounterNameSaved = nil
        encounterTimeSaved = nil
    end
    UpdateData(true)
    updateTicker = C_Timer.NewTicker(updateInterval, UpdateDataTicker)
    checkTicker = C_Timer.NewTicker(updateInterval, CheckCombatTicker)
end

local combatFunctions = {
    DAMAGE_SHIELD = SpellDamage,
    SPELL_DAMAGE = SpellDamage,
    SPELL_PERIODIC_DAMAGE = SpellDamage,
    SPELL_BUILDING_DAMAGE = SpellDamage,
    RANGE_DAMAGE = SpellDamage,
    SPELL_ABSORBED = SpellAbsorbed,
    SWING_DAMAGE = SwingDamage,
    SWING_MISSED = SwingMissed,
    SPELL_MISSED = SpellMissed,
    SPELL_PERIODIC_MISSED = SpellMissed,
    RANGE_MISSED = SpellMissed,
    SPELL_BUILDING_MISSED = SpellMissed,
}

local PET_FLAGS = bor(COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_GUARDIAN)
local RAID_FLAGS = bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY,
        COMBATLOG_OBJECT_AFFILIATION_RAID)

local function HandleCombatLogEvent(timestamp, eventType, _, srcGuid, srcName, srcFlags, _, dstGuid, dstName, dstFlags,
                                    _, ...)
    local srcFilter, dstFilter
    local func = combatFunctions[eventType]
    if func then
        srcFilter = band(srcFlags, RAID_FLAGS) ~= 0 or (band(srcFlags, PET_FLAGS) ~= 0 and pets[srcGuid])
                or characters[srcGuid]
        dstFilter = band(dstFlags, RAID_FLAGS) ~= 0 or (band(dstFlags, PET_FLAGS) ~= 0 and pets[dstGuid])
                or characters[dstGuid]
        if srcFilter and not dstFilter then
            -- current 不存在时，使用临时表记录此次伤害数据，目前只发现第一次伤害有时候会比触发 PLAYER_REGEN_DISABLED 早，导致记
            -- 录不到数据
            if not current then
                temp = InitCombatData()
            end
            func(timestamp, eventType, srcGuid, srcName, srcFlags, dstGuid, dstName, dstFlags, ...)
        end
    end
    if current and srcFilter and not current.gotBoss and band(dstFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) == 0
            and not current.targetName then
        current.targetName = dstName
    end
    if eventType == "SPELL_SUMMON" and (band(srcFlags, RAID_FLAGS) ~= 0 or band(srcFlags, PET_FLAGS) ~= 0
            or band(dstFlags, PET_FLAGS) ~= 0 and pets[dstGuid]) then
        pets[dstGuid] = { id = srcGuid, name = srcName, }
        if pets[srcGuid] then
            pets[dstGuid].id = pets[srcGuid].id
            pets[dstGuid].name = pets[srcGuid].name
        end
    end
end

local function DisplayView(view)
    ClearLogFrame()
    selectedView = view
    logFrame.changed = true
    UpdateTitle()
    UpdateData()
end

local wasInParty

local function DelayUpdateCharactersAndPets()
    wasInParty = not not IsInGroup()
    UpdateCharactersAndPets()
end

local addonName = ...

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
    if event == "ADDON_LOADED" and ... == addonName then
        logFrame:UnregisterEvent(event)
        if not WlkCombatData then
            WlkCombatData = combatDataList
        else
            combatDataList = WlkCombatData
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        wasInParty = not not IsInGroup()
        UpdateCharactersAndPets()
    elseif event == "UNIT_PET" then
        UpdateCharactersAndPets()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if wasInParty == nil then
            C_Timer.After(1, DelayUpdateCharactersAndPets)
        end
        DisplayView(selectedView)
    elseif event == "PLAYER_REGEN_DISABLED" then
        if not current then
            CombatStart()
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        HandleCombatLogEvent(CombatLogGetCurrentEventInfo())
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
            combatData.characterIdIndexes = nil
        end
    end
end)

local function logFrameOnMouseDown(_, bar, button)
    if button == "RightButton" then
        local view = selectedView.previous
        if view then
            DisplayView(view)
        end
    elseif bar then
        local view = IsShiftKeyDown() and selectedView.next2 or selectedView.next1
        if view then
            view["enter"](bar.id, bar.text)
            DisplayView(view)
        end
    end
end

logFrame.click = logFrameOnMouseDown

logFrame:SetScript("OnMouseDown", function(_, button)
    logFrameOnMouseDown(logFrame, nil, button)
end)

logFrame:SetScript("OnMouseWheel", function(_, value)
    if value > 0 and barOffset > 0 then
        barOffset = barOffset - 1
        UpdateBarVisibility()
    elseif value < 0 and numBars - maxBars - barOffset > 0 then
        barOffset = barOffset + 1
        UpdateBarVisibility()
    end
end)

---@type Button
local resetButton = CreateFrame("Button", "WlkDamageLogResetButton", titleFrame)
resetButton:SetSize(12, 12)
resetButton:SetPoint("RIGHT", -5, 0)
resetButton:SetNormalTexture("Interface/Buttons/UI-StopButton")
resetButton:SetHighlightTexture("Interface/Buttons/UI-StopButton", 1)
resetButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
resetButton:SetScript("OnClick", function()
    ClearLogFrame()
    wipe(pets)
    wipe(characters)
    UpdateCharactersAndPets()
    if current then
        current = InitCombatData()
    end
    wipe(combatDataList)
    combatDataIndex = 0
    logFrame.changed = true
    UpdateData(true)
    ChatFrame1:AddMessage("已清除所有統計數據。", 1, 1, 0)
    if not InCombatLockdown() then
        collectgarbage()
    end
end)
