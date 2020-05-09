local addonName = ...
local combats
local wasInParty
local characters = {}
local pets = {}

--- 获取队伍类型和成员数量
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

--- 更新玩家和宠物
local function UpdateCharactersAndPets()
    local type, count = GetGroupTypeAndCount()
    if count > 0 then
        for i = 1, count do
            local unit = type .. i
            local id = UnitGUID(unit)
            characters[id] = true
            local unitPet = unit .. "pet"
            local petID = UnitGUID(unitPet)
            if petID and not pets[petID] then
                local owner = GetUnitName(unit, true)
                pets[petID] = {
                    id = id,
                    name = owner,
                }
            end
        end
    end
    local playerGUID = UnitGUID("player")
    characters[playerGUID] = true
    local petGUID = UnitGUID("playerpet")
    if petGUID and not pets[petGUID] then
        pets[petGUID] = {
            id = playerGUID,
            name = UnitName("player"),
        }
    end
end

local current
local selectedCombat = 0
local encounterNameSaved, encounterTimeSaved
local dmg = {}
local updateFlags = true

--- 查找玩家
local function FindCharacter(combat, id)
    combat.characterIndex = combat.characterIndex or {}
    local character = combat.characterIndex[id]
    if character then
        return character
    end
    for i = 1, #combat.characters do
        if combat.characters[i].id == id then
            combat.characterIndex[id] = combat.characters[i]
            return combat.characters[i]
        end
    end
end

--- 获取玩家
local function GetCharacter(combat, id, name)
    local character = FindCharacter(combat, id)
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
        local playerName = strsplit("-", name, 2)
        character.name = playerName or name
        tinsert(combat.characters, character)
    end
    if character.name == UNKNOWN and name ~= UNKNOWN then
        local playerName = strsplit("-", name, 2)
        character.name = playerName or name
        character.class = select(2, UnitClass(name))
    end
    character.stop = time()
    updateFlags = true
    return character
end

--- 合并宠物
local function FixPets()
    if dmg.playerName then
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

--- 记录伤害
local function LogDamage()
    local character = GetCharacter(current, dmg.playerID, dmg.playerName)
    if character then
        local amount = dmg.amount
        current.damage = current.damage + amount
        character.damage = character.damage + amount

        if not character.spells[dmg.spellName] then
            character.spells[dmg.spellName] = { id = dmg.spellID, totalHits = 0, damage = 0, school = dmg.school, }
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

--- 法术伤害
local function SpellDamage(_, _, srcGUID, srcName, srcFlags, dstGUID, dstName, _, spellID, spellName, spellSchool,
                           sAmount, sOverkill, _, sResisted, sBlocked, sAbsorbed, sCritical, sGlancing, sCrushing,
                           sOffhand)
    if srcGUID ~= dstGUID then
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

        FixPets()
        LogDamage()
    end
end

--- 攻击伤害
local function SwingDamage(_, _, srcGUID, srcName, srcFlags, dstGUID, dstName, _, sAmount, sOverkill, _, sResisted,
                           sBlocked, sAbsorbed, sCritical, sGlancing, sCrushing, sOffhand)
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

        FixPets()
        LogDamage()
    end
end

--- 法术吸收
local function SpellAbsorbed(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
    local chk = ...
    local spellID, spellName, spellSchool, aGUID, aName, aFlags, aRaidFlags, aSpellID, aSpellName, aSpellSchool, aAmount

    if type(chk) == "number" then
        spellID, spellName, spellSchool, aGUID, aName, aFlags, aRaidFlags, aSpellID, aSpellName, aSpellSchool,
        aAmount = ...

        if aSpellID == 184553 then
            return
        end

        if aAmount then
            SpellDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellID,
                    spellName, spellSchool, aAmount)
        end
    else
        aGUID, aName, aFlags, aRaidFlags, aSpellID, aSpellName, aSpellSchool, aAmount = ...

        if aSpellID == 184553 then
            return
        end

        if aAmount then
            SwingDamage(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, aAmount)
        end
    end

end

--- 攻击丢失
local function SwingMissed(_, _, srcGUID, srcName, srcFlags, dstGUID, dstName, _, missed)
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

        FixPets()
        LogDamage()
    end
end

--- 法术丢失
local function SpellMissed(_, _, srcGUID, srcName, srcFlags, dstGUID, dstName, _, spellID, spellName, _, missType)
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

        FixPets()
        LogDamage()
    end
end

--- 战斗事件对应的函数
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

local PET_FLAGS = bit.bor(COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_GUARDIAN)
local RAID_FLAGS = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY,
        COMBATLOG_OBJECT_AFFILIATION_RAID)

--- 处理战斗日志事件
local function HandleCombatLogEvent(timestamp, eventType, _, srcGUID, srcName, srcFlags, _, dstGUID, dstName, dstFlags,
                                    _, ...)
    local srcFilter, dstFilter
    local func = combatFunctions[eventType]
    if current and func then
        srcFilter = bit.band(srcFlags, RAID_FLAGS) ~= 0 or (bit.band(srcFlags, PET_FLAGS) ~= 0 and pets[srcGUID])
                or characters[srcGUID]
        dstFilter = bit.band(dstFlags, RAID_FLAGS) ~= 0 or (bit.band(dstFlags, PET_FLAGS) ~= 0 and pets[dstGUID])
                or characters[dstGUID]
        if srcFilter and not dstFilter then
            func(timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
        end
    end
    if current and srcFilter and not current.gotBoss and bit.band(dstFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) == 0
            and not current.targetName then
        current.targetName = dstName
    end
    if eventType == "SPELL_SUMMON" and (bit.band(srcFlags, RAID_FLAGS) ~= 0 or bit.band(srcFlags, PET_FLAGS) ~= 0
            or bit.band(dstFlags, PET_FLAGS) ~= 0 and pets[dstGUID]) then
        pets[dstGUID] = { id = srcGUID, name = srcName, }
        if pets[srcGUID] then
            pets[dstGUID].id = pets[srcGUID].id
            pets[dstGUID].name = pets[srcGUID].name
        end
    end
end

---@type Frame
local title = CreateFrame("Frame", "WLK_DamageMeterTitle", UIParent)
title:SetSize(540 - 116 / 4 * 3, 20)
title:SetPoint("BOTTOMLEFT", 0, 116 - title:GetHeight())
title:SetBackdrop({ bgFile = "Interface/ChatFrame/CHATFRAMEBACKGROUND", })
title:SetBackdropColor(0.3, 0.3, 0.3)
title.text = title:CreateFontString(nil, "ARTWORK", "Game13Font_o1")
title.text:SetWidth(title:GetWidth() - 30)
title.text:SetMaxLines(1)
title.text:SetPoint("LEFT", 5, 0)
title.text:SetJustifyH("LEFT")

---@type Frame
local window = CreateFrame("Frame", "WLK_DamageMeter", UIParent)
window:SetSize(title:GetWidth(), 116 - title:GetHeight())
window:SetPoint("TOP", title, "BOTTOM")
window:SetBackdrop({ bgFile = "Interface/ChatFrame/CHATFRAMEBACKGROUND", })
window:SetBackdropColor(0, 0, 0, 0.8)

window.data = {}
local windowView

--- 获取选择的战斗
local function GetCombat()
    if selectedCombat == 0 then
        if current then
            return current
        else
            return combats[1]
        end
    elseif selectedCombat > 0 then
        return combats[selectedCombat]
    end
end

--- 格式化战斗时间
local function FormatCombatTime(combat)
    local start = combat.start
    local stop = combat.stop or time()
    local duration = SecondsToTime(stop - start, false, false, 2)
    return date("%H:%M", start) .. " (" .. duration .. ")"
end

---@type table<number, StatusBar>
local bars = {}
local numBars = 0
local maxBars = 5
local barOffset = 0
local barMaxValue

--- 计算玩家的活跃时间
local function GetCharacterActiveTime(combat, character)
    local activeTime = 0

    if character.duration > 0 then
        activeTime = character.duration
    end

    if not combat.stop and character.start then
        activeTime = activeTime + character.stop - character.start
    end
    return activeTime
end

--- 计算 DPS
local function GetDPS(combat, character)
    local activeTime = GetCharacterActiveTime(combat, character)
    return character.damage / max(1, activeTime)
end

--- 格式化伤害数字
local function FormatDamage(amount)
    if amount >= 1e8 then
        return format("%02.2f億", amount / 1e8)
    end
    if amount >= 1e4 then
        return format("%02.2f萬", amount / 1e4)
    end
    return floor(amount)
end

local combatView = { name = "戰鬥", }
local damageView = { name = "傷害", showSN = true, }
local playerView = { name = "傷害法術列表", }
local spellView = { name = "傷害法術細節", }
local targetView = { name = "受到傷害的單位", }

--- 更新伤害视图数据
local function UpdateDamageView(container, combat)
    local maxValue = 0
    local index = 1
    for i = 1, #combat.characters do
        local character = combat.characters[i]
        if character.damage > 0 then
            local dps = GetDPS(combat, character)
            local data = container.data[index] or {}
            container.data[index] = data

            data.label = character.name
            data.valueText = FormatDamage(character.damage) .. " (" .. FormatDamage(dps) .. ", "
                    .. format("%.1f%%", character.damage / combat.damage * 100) .. ")"
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

--- 进入伤害视图
local function DamageViewOnEnter(id)
    selectedCombat = id
end

--- 伤害视图的额外鼠标提示
local function DamageViewExtraTooltip(id)
    local combat = GetCombat()
    local character = FindCharacter(combat, id)
    if character then
        local activeTime = GetCharacterActiveTime(combat, character)
        local duration = combat.duration
        GameTooltip:AddDoubleLine("活躍度", format("%.1f%%", activeTime / max(1, duration) * 100), 1, 1, 1)
    end
end

--- 更新玩家视图数据
local function UpdatePlayerView(container, combat)
    local character = FindCharacter(combat, playerView.playerID)
    local maxValue = 0
    if character then
        local index = 1
        for spellName, spell in pairs(character.spells) do
            local data = container.data[index] or {}
            container.data[index] = data
            data.label = spellName
            data.id = spellName
            local _, _, icon = GetSpellInfo(spell.id)
            data.icon = icon
            data.spellID = spell.id
            data.value = spell.damage
            if spell.school then
                data.spellSchool = spell.school
            end
            data.valueText = FormatDamage(spell.damage) .. " " .. format("(%.1f%%)",
                    spell.damage / character.damage * 100)
            if spell.damage > maxValue then
                maxValue = spell.damage
            end
            index = index + 1
        end
    end
    barMaxValue = maxValue
end

--- 进入玩家视图
local function PlayerViewOnEnter(id)
    local character = FindCharacter(GetCombat(), id)
    if character then
        playerView.playerID = id
        playerView.title = character.name .. "的傷害"
    end
end

--- 玩家视图数据条的鼠标提示
local function PlayerViewTooltip(_, label)
    local character = FindCharacter(GetCombat(), playerView.playerID)
    if character then
        local spell = character.spells[label]
        if spell then
            GameTooltip:AddLine(character.name .. " - " .. label, 1, 1, 1)
            if spell.school then
                local color = CombatLog_Color_ColorArrayBySchool(spell.school)
                if color then
                    GameTooltip:AddLine(GetSchoolString(spell.school), color.r, color.g, color.b)
                end
            end
            if spell.min and spell.max then
                GameTooltip:AddDoubleLine("最小值:", FormatDamage(spell.min), 1, 1, 1)
                GameTooltip:AddDoubleLine("最大值:", FormatDamage(spell.max), 1, 1, 1)
            end
            GameTooltip:AddDoubleLine("平均值:", FormatDamage(spell.damage / spell.totalHits), 1, 1, 1)
        end
    end
end

--- 添加法术视图数据条
local function AddSpellDetailBar(container, label, value)
    local index = spellView.index + 1
    spellView.index = index
    local data = container.data[index] or {}
    container.data[index] = data

    data.label = label
    data.value = value
    data.id = label
    data.valueText = value .. " " .. format("(%.1f%%)", value / spellView.totalHits * 100)
    barMaxValue = max(barMaxValue, value)
end

--- 更新法术视图数据
local function UpdateSpellView(container, combat)
    local character = FindCharacter(combat, playerView.playerID)
    if character then
        local spell = character.spells[spellView.spellName]
        if spell then
            spellView.totalHits = spell.totalHits
            spellView.index = 0
            barMaxValue = 0

            if spell.hit and spell.hit > 0 then
                AddSpellDetailBar(container, "命中", spell.hit)
            end
            if spell.critical and spell.critical > 0 then
                AddSpellDetailBar(container, "致命一擊", spell.critical)
            end
            if spell.glancing and spell.glancing > 0 then
                AddSpellDetailBar(container, "偏斜", spell.glancing)
            end
            if spell.crushing and spell.crushing > 0 then
                AddSpellDetailBar(container, "碾壓", spell.crushing)
            end
            if spell.ABSORB and spell.ABSORB > 0 then
                AddSpellDetailBar(container, "吸收", spell.ABSORB)
            end
            if spell.BLOCK and spell.BLOCK > 0 then
                AddSpellDetailBar(container, "格擋", spell.BLOCK)
            end
            if spell.DEFLECT and spell.DEFLECT > 0 then
                AddSpellDetailBar(container, "偏斜", spell.DEFLECT)
            end
            if spell.DODGE and spell.DODGE > 0 then
                AddSpellDetailBar(container, "閃躲", spell.DODGE)
            end
            if spell.EVADE and spell.EVADE > 0 then
                AddSpellDetailBar(container, "閃避", spell.EVADE)
            end
            if spell.IMMUNE and spell.IMMUNE > 0 then
                AddSpellDetailBar(container, "免疫", spell.IMMUNE)
            end
            if spell.MISS and spell.MISS > 0 then
                AddSpellDetailBar(container, "未擊中", spell.MISS)
            end
            if spell.PARRY and spell.PARRY > 0 then
                AddSpellDetailBar(container, "招架", spell.PARRY)
            end
            if spell.REFLECT and spell.REFLECT > 0 then
                AddSpellDetailBar(container, "反射", spell.REFLECT)
            end
            if spell.RESIST and spell.RESIST > 0 then
                AddSpellDetailBar(container, "抵抗", spell.RESIST)
            end
        end
    end
end

--- 进入法术视图
local function SpellViewOnEnter(_, label)
    local character = FindCharacter(GetCombat(), playerView.playerID)
    if character then
        spellView.spellName = label
        spellView.playerID = playerView.playerID
        spellView.title = character.name .. "的" .. label
    end
end

--- 法术视图数据条的鼠标提示
local function SpellViewTooltip(_, label)
    local character = FindCharacter(GetCombat(), spellView.playerID)
    if character then
        local spell = character.spells[spellView.spellName]
        if spell then
            GameTooltip:AddLine(character.name .. " - " .. spellView.spellName, 1, 1, 1)
            if label == "致命一擊" and spell.criticalAmount then
                GameTooltip:AddDoubleLine("最小", FormatDamage(spell.criticalMin), 1, 1, 1)
                GameTooltip:AddDoubleLine("最大", FormatDamage(spell.criticalMax), 1, 1, 1)
                GameTooltip:AddDoubleLine("平均", FormatDamage(spell.criticalAmount / spell.critical), 1, 1, 1)
            end
            if label == "命中" and spell.hitAmount then
                GameTooltip:AddDoubleLine("最小", FormatDamage(spell.hitMin), 1, 1, 1)
                GameTooltip:AddDoubleLine("最大", FormatDamage(spell.hitMax), 1, 1, 1)
                GameTooltip:AddDoubleLine("平均", FormatDamage(spell.hitAmount / spell.hit), 1, 1, 1)
            end
        end
    end
end

--- 更新目标视图数据
local function UpdateTargetView(container, combat)
    local character = FindCharacter(combat, targetView.playerID)
    local maxValue = 0
    if character then
        local index = 1
        for target, amount in pairs(character.targets) do
            local data = container.data[index] or {}
            container.data[index] = data
            data.label = target
            data.id = target
            data.value = amount
            data.valueText = FormatDamage(amount) .. " " .. format("(%.1f%%)", amount / character.damage * 100)
            if amount > maxValue then
                maxValue = amount
            end
            index = index + 1
        end
    end
    barMaxValue = maxValue
end

--- 进入目标视图
local function TargetViewOnEnter(id)
    local character = FindCharacter(GetCombat(), id)
    targetView.playerID = id
    targetView.title = (character.name or UNKNOWN) .. "的目標"
end

damageView.update = UpdateDamageView
damageView.enter = DamageViewOnEnter
damageView.extraTooltip = DamageViewExtraTooltip
playerView.update = UpdatePlayerView
playerView.enter = PlayerViewOnEnter
playerView.tooltip = PlayerViewTooltip
spellView.update = UpdateSpellView
spellView.enter = SpellViewOnEnter
spellView.tooltip = SpellViewTooltip
targetView.update = UpdateTargetView
targetView.enter = TargetViewOnEnter

combatView.next1 = damageView
damageView.previous = combatView
damageView.next1 = playerView
damageView.next2 = targetView
playerView.previous = damageView
playerView.next1 = spellView
spellView.previous = playerView
targetView.previous = damageView

windowView = damageView

--- 更新标题
local function UpdateTitle()
    local name = windowView.title or windowView.name
    local combatName
    if windowView ~= combatView then
        if selectedCombat == 0 then
            combatName = "目前的"
        else
            local combat = GetCombat()
            if combat then
                combatName = (combat.name or UNKNOWN) .. ": " .. FormatCombatTime(combat)
            end
        end
    end
    if combatName then
        name = name .. ": " .. combatName
    end
    title.text:SetText(name)
end

--- 根据 value 排序
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
local tooltip = {
    data = {},
}
local tooltipView

--- 添加子视图到鼠标提示
local function AddSubviewToTooltip(view, id, label)
    local combat = GetCombat()
    if not combat then
        return
    end
    wipe(tooltip.data)
    if view.enter then
        view["enter"](id, label)
    end
    view["update"](tooltip, combat)
    table.sort(tooltip.data, SortDataByValue)
    if #tooltip.data > 0 then
        GameTooltip:AddLine(view.title or view.name, 1, 1, 1)
        local row = 0
        for i = 1, #tooltip.data do
            local data = tooltip.data[i]
            if data.id and row < maxTooltipRows then
                row = row + 1
                local text = view.showSN and row .. ". " .. data.label or data.label
                GameTooltip:AddDoubleLine(text, data.valueText, 1, 1, 1)
            end
        end

        if view.enter then
            GameTooltip:AddLine(" ")
        end
    end
end

--- 创建数据条
local function CreateBar(data)
    ---@type StatusBar
    local bar = CreateFrame("StatusBar", nil, window)
    bars[data.id] = bar
    numBars = numBars + 1
    bar.id = data.id
    bar.text = data.label
    local height = 18
    if windowView == spellView or windowView == targetView then
        bar:SetSize(window:GetWidth(), height)
    else
        bar:SetSize(window:GetWidth() - height, height)
        bar.icon = bar:CreateTexture()
        bar.icon:SetSize(height, height)
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
        bar:SetStatusBarColor(GetTableColor(RAID_CLASS_COLORS[data.class]))
    else
        bar:SetStatusBarColor(0.3, 0.3, 0.8)
    end
    ---@type FontString
    bar.leftText = bar:CreateFontString(nil, "ARTWORK", "Game13Font_o1")
    bar.leftText:SetPoint("LEFT", 3, 0)
    ---@type FontString
    bar.rightText = bar:CreateFontString(nil, "ARTWORK", "Game13Font_o1")
    bar.rightText:SetPoint("RIGHT", -3, 0)

    bar:SetScript("OnMouseDown", function(self, mouse)
        window["click"](mouse, self)
    end)

    bar:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(window, "ANCHOR_NONE")
        GameTooltip:SetPoint("BOTTOMLEFT", window, "BOTTOMRIGHT")

        if windowView ~= combatView then
            GameTooltip:ClearLines()
            local hasClick = windowView.next1

            if windowView.tooltip then
                local numLines = GameTooltip:NumLines()
                windowView["tooltip"](self.id, self.text)
                if GameTooltip:NumLines() ~= numLines and hasClick then
                    GameTooltip:AddLine(" ")
                end
            end

            if windowView.next1 then
                tooltipView = windowView.next1
                AddSubviewToTooltip(tooltipView, self.id, self.text)
            end
            if windowView.next2 then
                tooltipView = windowView.next2
                AddSubviewToTooltip(tooltipView, self.id, self.text)
            end

            if windowView.extraTooltip then
                local numLines = GameTooltip:NumLines()
                windowView["extraTooltip"](self.id, self.text)
                if GameTooltip:NumLines() ~= numLines and hasClick then
                    GameTooltip:AddLine(" ")
                end
            end

            if windowView.next1 then
                GameTooltip:AddLine("點擊後爲 " .. windowView.next1.name .. ".", 0.2, 1, 0.2)
            end
            if windowView.next2 then
                GameTooltip:AddLine("Shift+點擊後爲 " .. windowView.next2.name .. ".", 0.2, 1, 0.2)
            end

            GameTooltip:Show()
        end
    end)

    bar:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return bar
end

--- 更新数据条
---@param bar StatusBar
local function UpdateBar(bar, index, data)
    bar.index = index
    bar:SetMinMaxValues(0, barMaxValue)
    bar:SetValue(data.value)
    if windowView and windowView.showSN then
        bar.leftText:SetFormattedText("%2u. %s", index, data.label)
    else
        bar.leftText:SetText(data.label)
    end
    bar.rightText:SetText(data.valueText)
end

--- 更新数据条的可见性
local function UpdateBarVisibility()
    local minIndex = 1 + barOffset
    local maxIndex = maxBars + barOffset
    for _, bar in pairs(bars) do
        local index = bar.index
        if index >= minIndex and index <= maxIndex then
            bar:SetPoint("TOPRIGHT", 0, (bar:GetHeight() + 1) * (minIndex - index) - 1)
            bar:Show()
        else
            bar:Hide()
        end
    end
end

--- 更新显示
local function UpdateDisplay()
    if windowView ~= combatView then
        table.sort(window.data, SortDataByValue)
    end
    local index = 1
    for i = 1, #window.data do
        local data = window.data[i]
        if data.id then
            local bar = bars[data.id] or CreateBar(data)
            UpdateBar(bar, index, data)
            index = index + 1
        end
    end
    UpdateBarVisibility()
end

--- 清除窗口
local function ClearWindow()
    for i = 1, #window.data do
        wipe(window.data[i])
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

--- 更新数据
local function UpdateData(force)
    if force then
        updateFlags = true
    end
    if updateFlags or window.changed or current then
        window.changed = false
        if windowView ~= combatView then
            local combat = GetCombat()
            if combat then
                windowView["update"](window, combat)
            end
        else
            barMaxValue = 1
            local index = 1
            local data = window.data[index] or {}
            window.data[index] = data
            data.id = index - 1
            data.label = "目前的"
            data.value = 1
            data.valueText = ""
            if current and current.gotBoss then
                data.icon = BOSS_ICON
            else
                data.icon = NON_BOSS_ICON
            end
            for i = 1, #combats do
                index = index + 1
                data = window.data[index] or {}
                window.data[index] = data
                data.id = index - 1
                data.label = combats[i].name
                data.value = 1
                data.valueText = FormatCombatTime(combats[i])
                if combats[i].gotBoss then
                    data.icon = BOSS_ICON
                else
                    data.icon = NON_BOSS_ICON
                end
            end
        end
        UpdateDisplay()
    end
    updateFlags = false
end

--- 设置玩家的活跃时间
local function SetCharacterActiveTimes(combat)
    for i = 1, #combat.characters do
        local character = combat.characters[i]
        if character.stop then
            character.duration = character.duration + (character.stop - character.start)
        end
    end
end

---@type TickerPrototype
local updateTicker, checkTicker

--- 战斗结束
local function CombatEnd()
    if not current then
        return
    end
    if current.targetName ~= nil and time() - current.start > 5 then
        if not current.stop then
            current.stop = time()
        end
        current.duration = current.stop - current.start
        SetCharacterActiveTimes(current)

        local name = current.targetName
        local count = 0
        for i = 1, #combats do
            if combats[i].name == name and count == 0 then
                count = 1
            else
                local n, c = strmatch(combats[i].name, "^(.-)%s*%((%d+)%)$")
                if n == name then
                    count = max(count, tonumber(c) or 0)
                end
            end
        end
        if count > 0 then
            name = name .. "(" .. (count + 1) .. ")"
        end
        current.name = name

        tinsert(combats, 1, current)
    end
    current = nil
    ClearWindow()
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

--- 检查是否在副本战斗中
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

--- 检查战斗是否结束
local function CheckCombat()
    if current and not InCombatLockdown() and not IsRaidInCombat() then
        CombatEnd()
    end
end

--- 战斗开始
local function CombatStart()
    if updateTicker then
        CombatEnd()
    end
    ClearWindow()
    if not current then
        current = {
            characters = {},
            start = time(),
            duration = 0,
            damage = 0,
        }
    end
    if encounterNameSaved and GetTime() < (encounterTimeSaved or 0) + 15 then
        current.targetName = encounterNameSaved
        current.gotBoss = true
        encounterNameSaved = nil
        encounterTimeSaved = nil
    end
    UpdateData(true)
    updateTicker = C_Timer.NewTicker(1, function()
        UpdateData()
    end)
    checkTicker = C_Timer.NewTicker(1, function()
        CheckCombat()
    end)
end

--- 显示视图
local function DisplayView(view)
    ClearWindow()
    windowView = view
    window.changed = true
    UpdateTitle()
    UpdateData()
end

window:RegisterEvent("ADDON_LOADED")
window:RegisterEvent("GROUP_ROSTER_UPDATE")
window:RegisterEvent("UNIT_PET")
window:RegisterEvent("PLAYER_ENTERING_WORLD")
window:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
window:RegisterEvent("ENCOUNTER_START")
window:RegisterEvent("ENCOUNTER_END")
window:RegisterEvent("PLAYER_REGEN_DISABLED")
window:RegisterEvent("PLAYER_LOGOUT")

---@param self Frame
window:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        if not WLK_DamageDB then
            WLK_DamageDB = {}
        end
        combats = WLK_DamageDB
        self:UnregisterEvent(event)
    elseif event == "GROUP_ROSTER_UPDATE" then
        wasInParty = not not IsInGroup()
        UpdateCharactersAndPets()
    elseif event == "UNIT_PET" then
        UpdateCharactersAndPets()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if wasInParty == nil then
            C_Timer.After(1, function()
                wasInParty = not not IsInGroup()
                UpdateCharactersAndPets()
            end)
        end
        DisplayView(windowView)
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
    elseif event == "PLAYER_REGEN_DISABLED" then
        if not current then
            CombatStart()
        end
    elseif event == "PLAYER_LOGOUT" then
        for i = 1, #combats do
            combats[i].characterIndex = nil
        end
    end
end)

--- 点击窗口
local function ClickOnWindow(mouse, bar)
    if mouse == "RightButton" then
        local view = windowView.previous
        if view then
            DisplayView(view)
        end
    elseif bar then
        local view = IsShiftKeyDown() and windowView.next2 or windowView.next1
        if view then
            view["enter"](bar.id, bar.text)
            DisplayView(view)
        end
    end
end

window.click = ClickOnWindow

window:SetScript("OnMouseDown", function(_, mouse)
    ClickOnWindow(mouse)
end)

window:SetScript("OnMouseWheel", function(_, value)
    if value > 0 and barOffset > 0 then
        barOffset = barOffset - 1
        UpdateBarVisibility()
    elseif value < 0 and numBars - maxBars - barOffset > 0 then
        barOffset = barOffset + 1
        UpdateBarVisibility()
    end
end)

---@type Button
local resetButton = CreateFrame("Button", nil, title)
resetButton:SetSize(12, 12)
resetButton:SetPoint("RIGHT", -5, 0)
resetButton:SetNormalTexture("Interface/Buttons/UI-StopButton")
resetButton:SetHighlightTexture("Interface/Buttons/UI-StopButton", 1)
resetButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
resetButton:SetScript("OnClick", function()
    ClearWindow()
    pets, characters = {}, {}
    UpdateCharactersAndPets()
    if current then
        wipe(current)
        current = {
            characters = {},
            start = time(),
            duration = 0,
            damage = 0,
        }
    end
    wipe(combats)
    selectedCombat = 0
    window.changed = true
    UpdateData(true)
    print("已清除所有統計數據。")
    if not InCombatLockdown() then
        collectgarbage()
    end
end)
