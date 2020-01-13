---@type Frame
local statsPane = CreateFrame("Frame", "WLK_CharacterStatsPane", UIParent)
--- BuffFrame 右边相对屏幕右边偏移 -295px，MiniMapTrackingButtonBorder 左边相对屏幕右边偏移 -183px，OrderHallCommandBar 底部
--- 相对屏幕顶部偏移 -25px，ObjectiveTrackerBlocksFrame 顶部相对屏幕顶部偏移 -330px
statsPane:SetSize(295 - 183, 330 - 25)
statsPane:SetPoint("TOPRIGHT", -183, -25)
--- 降低框架层级，防止覆盖背包界面
statsPane:SetFrameStrata("BACKGROUND")

---@type table<string, Frame>
local statFrames = {}
local statFrameCreated = false
--- 主属性
local primaryStatIndex

--- 创建统计框架
local function CreateStatFrame()
    local specIndex = GetSpecialization()
    primaryStatIndex = select(6, GetSpecializationInfo(specIndex))
    if not primaryStatIndex then
        return
    end

    local statNames = {
        STAT_AVERAGE_ITEM_LEVEL,
        _G["SPELL_STAT" .. primaryStatIndex .. "_NAME"],
        STAT_CRITICAL_STRIKE,
        STAT_HASTE,
        STAT_MASTERY,
        STAT_VERSATILITY,
        STAT_LIFESTEAL,
        STAT_AVOIDANCE,
        STAT_MOVEMENT_SPEED,
    }

    for i = 1, #statNames do
        ---@type Frame
        local statFrame = CreateFrame("Frame", nil, statsPane, "CharacterStatFrameTemplate")
        statFrame:SetSize(statsPane:GetWidth(), (statsPane:GetHeight() - (#statNames - 1)) / #statNames)
        statFrame:SetPoint("TOP", statsPane, 0, (statFrame:GetHeight() + 1) * (1 - i))
        ---@type Texture
        local background = statFrame.Background
        background:SetWidth(statFrame:GetWidth())
        background:SetPoint("TOP")
        ---@type FontString
        local nameLabel = statFrame.Label
        nameLabel:SetPoint("LEFT", background)
        nameLabel:SetText(statNames[i])
        ---@type FontString
        local valueLabel = statFrame.Value
        valueLabel:ClearAllPoints()
        valueLabel:SetPoint("BOTTOMRIGHT")
        tinsert(statFrames, statFrame)
    end

    statFrameCreated = true
end

local wasSwimming

--- 更新统计数据
local function UpdateStats()
    if not statFrameCreated then
        return
    end

    local index = 1
    -- 更新装等
    local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()
    ---@type FontString
    local valueLabel = statFrames[index].Value
    valueLabel:SetFormattedText("%.1f/%.1f", avgItemLevelEquipped, avgItemLevel)
    index = index + 1

    -- 更新主属性
    local _, effectiveStat = UnitStat("player", primaryStatIndex)
    valueLabel = statFrames[index].Value
    valueLabel:SetText(BreakUpLargeNumbers(effectiveStat))
    index = index + 1

    -- 更新暴击
    local spellCrit
    -- 从 2 开始，跳过物理伤害
    local holySchool = 2
    local minCrit = GetSpellCritChance(holySchool)
    for i = holySchool + 1, MAX_SPELL_SCHOOLS do
        spellCrit = GetSpellCritChance(i)
        minCrit = min(minCrit, spellCrit)
    end

    spellCrit = minCrit
    local rangedCrit = GetRangedCritChance()
    local meleeCrit = GetCritChance()
    local critChance
    if spellCrit >= rangedCrit and spellCrit >= meleeCrit then
        critChance = spellCrit
    elseif rangedCrit >= meleeCrit then
        critChance = rangedCrit
    else
        critChance = meleeCrit
    end
    valueLabel = statFrames[index].Value
    valueLabel:SetFormattedText("%.2f%%", critChance)
    index = index + 1

    -- 更新急速
    local haste = GetHaste()
    valueLabel = statFrames[index].Value
    if haste < 0 and not GetPVPGearStatRules() then
        valueLabel:SetFormattedText(RED_FONT_COLOR_CODE .. "%.2f%%" .. FONT_COLOR_CODE_CLOSE, haste)
    else
        valueLabel:SetFormattedText("%.2f%%", haste)
    end
    index = index + 1

    -- 更新精通
    valueLabel = statFrames[index].Value
    valueLabel:SetFormattedText("%.2f%%", GetMasteryEffect())
    index = index + 1

    -- 更新全能
    local damageBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
            + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
    local damageTakenReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN)
            + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN)
    valueLabel = statFrames[index].Value
    valueLabel:SetFormattedText("%.2f%%/%.2f%%", damageBonus, damageTakenReduction)
    index = index + 1

    -- 更新吸血
    valueLabel = statFrames[index].Value
    valueLabel:SetFormattedText("%.2f%%", GetLifesteal())
    index = index + 1

    -- 更新躲避
    valueLabel = statFrames[index].Value
    valueLabel:SetFormattedText("%.2f%%", GetAvoidance())
    index = index + 1

    -- 更新移速
    local _, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed("player")
    runSpeed = runSpeed / BASE_MOVEMENT_SPEED * 100
    flightSpeed = flightSpeed / BASE_MOVEMENT_SPEED * 100
    swimSpeed = swimSpeed / BASE_MOVEMENT_SPEED * 100

    local speed = runSpeed
    local swimming = IsSwimming("player")
    if swimming then
        speed = swimSpeed
    elseif IsFlying("player") then
        speed = flightSpeed
    end
    -- 从水中出来时不改变移速
    if IsFalling("player") then
        if wasSwimming then
            speed = swimSpeed
        end
    else
        wasSwimming = swimming
    end
    valueLabel = statFrames[index].Value
    valueLabel:SetFormattedText("%d%%", speed + 0.5)
end

statsPane:RegisterUnitEvent("UNIT_DAMAGE", "player")
statsPane:RegisterUnitEvent("UNIT_ATTACK_SPEED", "player")
statsPane:RegisterUnitEvent("UNIT_RANGEDDAMAGE", "player")
statsPane:RegisterUnitEvent("UNIT_ATTACK", "player")
statsPane:RegisterUnitEvent("UNIT_STATS", "player")
statsPane:RegisterUnitEvent("UNIT_RANGED_ATTACK_POWER", "player")
statsPane:RegisterUnitEvent("UNIT_SPELL_HASTE", "player")
statsPane:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
statsPane:RegisterUnitEvent("UNIT_AURA", "player")
statsPane:RegisterUnitEvent("UNIT_RESISTANCES", "player")
statsPane:RegisterEvent("COMBAT_RATING_UPDATE")
statsPane:RegisterEvent("MASTERY_UPDATE")
statsPane:RegisterEvent("SPEED_UPDATE")
statsPane:RegisterEvent("LIFESTEAL_UPDATE")
statsPane:RegisterEvent("AVOIDANCE_UPDATE")
statsPane:RegisterEvent("BAG_UPDATE")
statsPane:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
statsPane:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
statsPane:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
statsPane:RegisterEvent("PLAYER_TARGET_CHANGED")
statsPane:RegisterEvent("PLAYER_TALENT_UPDATE")
statsPane:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
statsPane:RegisterEvent("SPELL_POWER_CHANGED")

statsPane:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_TALENT_UPDATE" and not statFrameCreated then
        CreateStatFrame()
    end
    UpdateStats()
end)
