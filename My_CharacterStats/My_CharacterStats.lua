local stats = CreateFrame("Frame", "CharacterStatsFrame", UIParent)

stats:SetFrameStrata("Background")
stats:SetWidth(115)
stats:SetHeight(284)
stats:SetPoint("TopLeft", UIParent, "TopRight", -290, -38)

local labels = {
    STAT_AVERAGE_ITEM_LEVEL,
    _G["SPELL_STAT" .. LE_UNIT_STAT_INTELLECT .. "_NAME"],
    STAT_CRITICAL_STRIKE,
    STAT_HASTE,
    STAT_MASTERY,
    STAT_VERSATILITY,
    STAT_LIFESTEAL,
    STAT_AVOIDANCE,
    STAT_MOVEMENT_SPEED,
}

for i = 1, #labels do
    stats["stat" .. i] = CreateFrame("Frame", nil, stats, "CharacterStatFrameTemplate")
    stats["stat" .. i]:SetWidth(115)
    stats["stat" .. i]:SetPoint("TopLeft", 0, -31.5 * i + 31.5)
    stats["stat" .. i].Value:SetPoint("Right", 0, -15)
    stats["stat" .. i].Label:SetText(labels[i])
end

stats:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.25 then
        return
    end
    self.elapsed = 0

    -- 物品等級
    local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()

    -- 智力
    local _, effectiveStat = UnitStat("player", LE_UNIT_STAT_INTELLECT)

    -- 致命一擊
    local spellCrit, rangedCrit, meleeCrit;
    local critChance;

    -- Start at 2 to skip physical damage
    local holySchool = 2;
    local minCrit = GetSpellCritChance(holySchool);
    for i = holySchool + 1, MAX_SPELL_SCHOOLS do
        spellCrit = GetSpellCritChance(i);
        minCrit = min(minCrit, spellCrit);
    end
    spellCrit = minCrit
    rangedCrit = GetRangedCritChance();
    meleeCrit = GetCritChance();

    if spellCrit >= rangedCrit and spellCrit >= meleeCrit then
        critChance = spellCrit;
    elseif rangedCrit >= meleeCrit then
        critChance = rangedCrit;
    else
        critChance = meleeCrit;
    end

    -- 臨機應變
    local versatilityDamageBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE);
    local versatilityDamageTakenReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN);

    -- 移動速度
    local _, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed("player");
    runSpeed = runSpeed / BASE_MOVEMENT_SPEED * 100;
    flightSpeed = flightSpeed / BASE_MOVEMENT_SPEED * 100;
    swimSpeed = swimSpeed / BASE_MOVEMENT_SPEED * 100;

    local speed = runSpeed;
    local swimming = IsSwimming("player");
    if swimming then
        speed = swimSpeed;
    elseif IsFlying("player") then
        speed = flightSpeed;
    end

    local wasSwimming
    if IsFalling("player") then
        if wasSwimming then
            speed = swimSpeed;
        end
    else
        wasSwimming = swimming
    end

    local values = {
        format("%.1f/%.1f", avgItemLevelEquipped, avgItemLevel),
        BreakUpLargeNumbers(effectiveStat),
        format("%.2f%%", critChance),
        format("%.2f%%", GetHaste()),
        format("%.2f%%", GetMasteryEffect()),
        format("%.2f%%/%.2f%%", versatilityDamageBonus, versatilityDamageTakenReduction),
        format("%.2f%%", GetLifesteal()),
        format("%.2f%%", GetAvoidance()),
        format("%d%%", speed + 0.5),
    }

    for i = 1, #values do
        stats["stat" .. i].Value:SetText(values[i])
    end
end)