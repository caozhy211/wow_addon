--- MicroButtonAndBagsBar 左边相对 UIParent 右边的偏移值
local OFFSET_X1 = -298
--- MiniMapTrackingButton 左边相对 UIParent 右边的偏移值
local OFFSET_X2 = -183
--- OrderHallCommandBar 底部相对 UIParent 顶部的偏移值
local OFFSET_Y1 = -25
--- VehicleSeatIndicator 底部相对 UIParent 顶部的偏移值
local OFFSET_Y2 = -320
local numStatFrames = 9
local spacing = 2
local frameWidth = OFFSET_X2 - OFFSET_X1
local frameHeight = OFFSET_Y1 - OFFSET_Y2
local width = frameWidth
local height = (frameHeight - spacing * (numStatFrames - 1)) / numStatFrames
local primaryStatIndex
local wasSwimming
local keys = {
    "iLevel", "primary", "critical", "haste", "mastery", "versatility", "lifeSteal", "avoidance", "movementSpeed",
}

---@type Frame
local statInfoFrame = CreateFrame("Frame", "WlkStatInfoFrame", UIParent)

local function createStatFrame(index, labelText)
    ---@type CharacterStatFrameTemplate
    local frame = CreateFrame("Frame", nil, statInfoFrame, "CharacterStatFrameTemplate")

    frame:SetSize(width, height)
    frame:SetPoint("TOP", 0, (1 - index) * (height + spacing))

    frame.Background:SetWidth(width)
    frame.Background:SetPoint("TOP")

    frame.Label:SetPoint("LEFT", frame.Background)
    frame.Label:SetText(labelText)

    frame.Value:ClearAllPoints()
    frame.Value:SetPoint("BOTTOMRIGHT")

    statInfoFrame[keys[index]] = frame
end

local function statInfoFrameOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 1 then
        return
    end
    self.elapsed = 0

    local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()
    ---@type CharacterStatFrameTemplate
    local statFrame = self[keys[1]]
    statFrame.Value:SetFormattedText("%.1f/%.1f", avgItemLevelEquipped, avgItemLevel)

    local _, effectiveStat = UnitStat("player", primaryStatIndex)
    statFrame = self[keys[2]]
    statFrame.Value:SetText(BreakUpLargeNumbers(effectiveStat))

    local spellCrit
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
    statFrame = self[keys[3]]
    statFrame.Value:SetFormattedText("%.2f%%", critChance)

    local haste = GetHaste()
    statFrame = self[keys[4]]
    if haste < 0 and not GetPVPGearStatRules() then
        statFrame.Value:SetFormattedText(RED_FONT_COLOR_CODE .. "%.2f%%" .. FONT_COLOR_CODE_CLOSE, haste)
    else
        statFrame.Value:SetFormattedText("%.2f%%", haste)
    end

    statFrame = self[keys[5]]
    statFrame.Value:SetFormattedText("%.2f%%", GetMasteryEffect())

    local damageBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
            + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
    local damageTakenReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN)
            + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN)
    statFrame = self[keys[6]]
    statFrame.Value:SetFormattedText("%.2f%%/%.2f%%", damageBonus, damageTakenReduction)

    statFrame = self[keys[7]]
    statFrame.Value:SetFormattedText("%.2f%%", GetLifesteal())

    statFrame = self[keys[8]]
    statFrame.Value:SetFormattedText("%.2f%%", GetAvoidance())

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
    if IsFalling("player") then
        if wasSwimming then
            speed = swimSpeed
        end
    else
        wasSwimming = swimming
    end
    statFrame = self[keys[9]]
    statFrame.Value:SetFormattedText("%d%%", speed + 0.5)
end

statInfoFrame:SetSize(frameWidth, frameHeight)
statInfoFrame:SetPoint("TOPRIGHT", OFFSET_X2, OFFSET_Y1)
statInfoFrame:SetFrameStrata("BACKGROUND")
statInfoFrame:RegisterEvent("PLAYER_LOGIN")
statInfoFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        primaryStatIndex = select(6, GetSpecializationInfo(GetSpecialization()))
        local primaryStatText = _G["SPELL_STAT" .. primaryStatIndex .. "_NAME"]
        local labelText = {
            STAT_AVERAGE_ITEM_LEVEL, primaryStatText, STAT_CRITICAL_STRIKE, STAT_HASTE, STAT_MASTERY, STAT_VERSATILITY,
            STAT_LIFESTEAL, STAT_AVOIDANCE, STAT_MOVEMENT_SPEED,
        }
        for i = 1, numStatFrames do
            createStatFrame(i, labelText[i])
        end
        statInfoFrame:SetScript("OnUpdate", statInfoFrameOnUpdate)
    end
end)
