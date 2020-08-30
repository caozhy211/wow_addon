--- MicroButtonAndBagsBar 左边相对 UIParent 右边的偏移值
local OFFSET_X1 = -298
--- MiniMapTrackingButton 左边相对 UIParent 右边的偏移值
local OFFSET_X2 = -183
--- OrderHallCommandBar 底部相对 UIParent 顶部的偏移值
local OFFSET_Y1 = -25
--- VehicleSeatIndicator 底部相对 UIParent 顶部的偏移值
local OFFSET_Y2 = -320
---@type Frame
local statInfoFrame = CreateFrame("Frame", "WlkStatInfoFrame", UIParent)
statInfoFrame:SetSize(OFFSET_X2 - OFFSET_X1, OFFSET_Y1 - OFFSET_Y2)
statInfoFrame:SetPoint("TOPRIGHT", OFFSET_X2, OFFSET_Y1)
statInfoFrame:SetFrameStrata("BACKGROUND")

local numStatFrames = 9
local spacing = 2
local width = statInfoFrame:GetWidth()
local height = (statInfoFrame:GetHeight() - spacing * (numStatFrames - 1)) / numStatFrames

local function CreateStatFrame(name, index, labelName)
    ---@type Frame|CharacterStatFrameTemplate
    local frame = CreateFrame("Frame", "WlkStat" .. name .. "InfoFrame", statInfoFrame, "CharacterStatFrameTemplate")
    frame:SetSize(width, height)
    frame:SetPoint("TOP", 0, (1 - index) * (height + spacing))
    frame.Background:SetWidth(width)
    frame.Background:SetPoint("TOP")
    frame.Label:SetPoint("LEFT", frame.Background)
    frame.Label:SetText(labelName)
    frame.Value:ClearAllPoints()
    frame.Value:SetPoint("BOTTOMRIGHT")
    return frame
end

local primaryStatIndex
local wasSwimming

local itemLevelFrame = CreateStatFrame("ItemLevel", 1, STAT_AVERAGE_ITEM_LEVEL)
---@type CharacterStatFrameTemplate
local primaryStatFrame
local criticalStrikeFrame = CreateStatFrame("CriticalStrike", 3, STAT_CRITICAL_STRIKE)
local hasteFrame = CreateStatFrame("Haste", 4, STAT_HASTE)
local masteryFrame = CreateStatFrame("Mastery", 5, STAT_MASTERY)
local versatilityFrame = CreateStatFrame("Versatility", 6, STAT_VERSATILITY)
local lifeStealFrame = CreateStatFrame("LifeSteal", 7, STAT_LIFESTEAL)
local avoidanceFrame = CreateStatFrame("Avoidance", 8, STAT_AVOIDANCE)
local movementSpeedFrame = CreateStatFrame("MovementSpeed", 9, STAT_MOVEMENT_SPEED)

local function StatInfoFrameOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < TOOLTIP_UPDATE_TIME then
        return
    end
    self.elapsed = 0

    local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()
    itemLevelFrame.Value:SetFormattedText("%.1f/%.1f", avgItemLevelEquipped, avgItemLevel)

    local _, effectiveStat = UnitStat("player", primaryStatIndex)
    primaryStatFrame.Value:SetText(BreakUpLargeNumbers(effectiveStat))

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
    criticalStrikeFrame.Value:SetFormattedText("%.2f%%", critChance)

    local haste = GetHaste()
    if haste < 0 and not GetPVPGearStatRules() then
        hasteFrame.Value:SetFormattedText(RED_FONT_COLOR_CODE .. "%.2f%%" .. FONT_COLOR_CODE_CLOSE, haste)
    else
        hasteFrame.Value:SetFormattedText("%.2f%%", haste)
    end

    masteryFrame.Value:SetFormattedText("%.2f%%", GetMasteryEffect())

    local damageBonus = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
            + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
    local damageTakenReduction = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN)
            + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_TAKEN)
    versatilityFrame.Value:SetFormattedText("%.2f%%/%.2f%%", damageBonus, damageTakenReduction)

    lifeStealFrame.Value:SetFormattedText("%.2f%%", GetLifesteal())

    avoidanceFrame.Value:SetFormattedText("%.2f%%", GetAvoidance())

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
    movementSpeedFrame.Value:SetFormattedText("%d%%", speed + 0.5)
end

statInfoFrame:RegisterEvent("PLAYER_LOGIN")

statInfoFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        primaryStatIndex = select(6, GetSpecializationInfo(GetSpecialization()))
        primaryStatFrame = CreateStatFrame("PrimaryStat", 2, _G["SPELL_STAT" .. primaryStatIndex .. "_NAME"])
        statInfoFrame:SetScript("OnUpdate", StatInfoFrameOnUpdate)
    end
end)
