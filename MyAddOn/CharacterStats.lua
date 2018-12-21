local stats = CreateFrame("Frame", "MyCharacterStatsFrame", UIParent)

stats:SetFrameStrata("Background")
stats:SetSize(295 - 180, 330 - 25)
stats:SetPoint("TopRight", -180, -25)

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
    local stat = stats["stat" .. i]
    stat:SetSize(stats:GetWidth(), (stats:GetHeight() - 8) / #labels)
    stat:SetPoint("Top", 0, stat:GetHeight() * (1 - i))
    stat.Background:SetWidth(stat:GetWidth())
    stat.Label:SetText(labels[i])
    stat.Value:SetPoint("Right", 0, -stat:GetHeight() / 2)
end

stats:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.2 then
        return
    end
    self.elapsed = 0

    local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()

    local _, effectiveStat = UnitStat("player", LE_UNIT_STAT_INTELLECT)

    local spellCrit, rangedCrit, meleeCrit
    local critChance

    local holySchool = 2
    local minCrit = GetSpellCritChance(holySchool)
    for i = holySchool + 1, MAX_SPELL_SCHOOLS do
        spellCrit = GetSpellCritChance(i)
        minCrit = min(minCrit, spellCrit)
    end
    spellCrit = minCrit
    rangedCrit = GetRangedCritChance()
    meleeCrit = GetCritChance()

    if spellCrit >= rangedCrit and spellCrit >= meleeCrit then
        critChance = spellCrit
    elseif rangedCrit >= meleeCrit then
        critChance = rangedCrit
    else
        critChance = meleeCrit
    end

    local versatilityDamageBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
    local versatilityDamageTakenReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN)

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

    local wasSwimming
    if IsFalling("player") then
        if wasSwimming then
            speed = swimSpeed
        end
    else
        wasSwimming = swimming
    end

    self.stat1.Value:SetFormattedText("%.1f/%.1f", avgItemLevelEquipped, avgItemLevel)
    self.stat2.Value:SetText(BreakUpLargeNumbers(effectiveStat))
    self.stat3.Value:SetFormattedText("%.2f%%", critChance)
    self.stat4.Value:SetFormattedText("%.2f%%", GetHaste())
    self.stat5.Value:SetFormattedText("%.2f%%", GetMasteryEffect())
    self.stat6.Value:SetFormattedText("%.2f%%/%.2f%%", versatilityDamageBonus, versatilityDamageTakenReduction)
    self.stat7.Value:SetFormattedText("%.2f%%", GetLifesteal())
    self.stat8.Value:SetFormattedText("%.2f%%", GetAvoidance())
    self.stat9.Value:SetFormattedText("%d%%", speed + 0.5)
end)