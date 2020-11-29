--- PlayerPowerBarAlt 的大小
local SIZE = 256
local width1 = 240
local height1 = 27
local spacing = 6
local width2 = 296
local height2 = 29
local size = 184
local scale = size / SIZE
local pointBackdrop = { edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 2, }
local barBackdrop = { bgFile = "Interface/RaidFrame/Raid-Bar-Resource-Background", }
---@type WlkPowerPoint[]
local points = {}
local runeIndexes = {}
local unit = "player"
local _, class = UnitClass("player")

---@class WlkPowerPointsFrame:Frame
local pointsFrame = CreateFrame("Frame", "WlkPowerPointsFrame", BuffFrame)
---@type WlkPowerBar
local powerBar1
---@type WlkPowerBar
local powerBar2
---@class WlkStaggerBar:StatusBar
local staggerBar
---@type Frame
local listener = CreateFrame("Frame")

local function abbreviateNumber(value)
    if value >= 1e8 then
        return format("%.2f%s", value / 1e8, SECOND_NUMBER_CAP)
    elseif value >= 1e6 then
        return format("%d%s", value / 1e4, FIRST_NUMBER_CAP)
    elseif value >= 1e4 then
        return format("%.1f%s", value / 1e4, FIRST_NUMBER_CAP)
    end
    return value
end

---@param bar WlkPowerBar
local function updatePowerBar(bar)
    local powerType = bar.powerType
    local power = UnitPower(unit, powerType)
    local _, maxValue = bar:GetMinMaxValues()

    bar:SetValue(power - (bar.cost or 0))
    bar.predictionCost:SetWidth(power / maxValue * bar:GetWidth())
    bar.leftLabel:SetFormattedText("%s/%s", abbreviateNumber(power), abbreviateNumber(maxValue))
    bar.rightLabel:SetText(FormatPercentage(PercentageBetween(power, 0, maxValue)))
end

---@param bar StatusBar
local function updatePowerBarMax(bar)
    local powerType = bar.powerType or UnitPowerType(unit)
    local maxPower = UnitPowerMax(unit, powerType)
    bar:SetMinMaxValues(0, maxPower)
    updatePowerBar(bar)
end

---@param bar StatusBar
local function updateBarColor(bar)
    local color
    if bar.powerType then
        color = PowerBarColor[bar.powerType]
    else
        local powerType, powerToken, altR, altG, altB = UnitPowerType(unit)
        if PowerBarColor[powerToken] then
            color = PowerBarColor[powerToken]
        elseif altR then
            bar:SetStatusBarColor(altR, altG, altB)
            return
        else
            color = PowerBarColor[powerType] or PowerBarColor["MANA"]
        end
    end
    bar:SetStatusBarColor(GetTableColor(color))
end

local function powerBarOnEvent(self, event, ...)
    if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED"
            or event == "UNIT_SPELLCAST_SUCCEEDED" then
        local powerType = self.powerType or UnitPowerType(unit)
        local _, _, _, startTime, endTime, _, _, _, spellId = UnitCastingInfo(unit)
        local cost = 0

        if event == "UNIT_SPELLCAST_START" and startTime ~= endTime then
            local costTable = GetSpellPowerCost(spellId)
            for _, costInfo in ipairs(costTable) do
                if costInfo.type == powerType then
                    cost = costInfo.cost
                    break
                end
            end
            self.cost = cost
        else
            local currentSpellId = select(9, UnitCastingInfo(unit))
            if currentSpellId and self.cost then
                cost = self.cost
            else
                self.cost = nil
            end
        end

        updatePowerBar(self)
    elseif event == "UNIT_MAXPOWER" or event == "UNIT_POWER_FREQUENT" then
        local _, powerToken = ...
        if powerToken == self.powerToken or powerToken == select(2, UnitPowerType("player")) or unit == "vehicle" then
            if event == "UNIT_MAXPOWER" then
                updatePowerBarMax(self)
            elseif event == "UNIT_POWER_FREQUENT" then
                updatePowerBar(self)
            end
        end
    end
end

local function createPowerBar(name, width, height)
    ---@class WlkPowerBar:StatusBar
    local bar = CreateFrame("StatusBar", name, BuffFrame, "BackdropTemplate")
    local predictionCost = bar:CreateTexture(nil, "BORDER")
    local leftLabel = bar:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med1")
    local rightLabel = bar:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med1")

    bar:SetSize(width, height)
    bar:SetBackdrop(barBackdrop)
    bar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill")
    bar:SetScript("OnEvent", powerBarOnEvent)

    predictionCost:SetSize(width, height - 4)
    predictionCost:SetPoint("TOPLEFT")
    predictionCost:SetColorTexture(1, 1, 1, 0.55)

    leftLabel:SetPoint("LEFT", 1, 0)

    rightLabel:SetPoint("RIGHT", -1, 0)

    bar.predictionCost = predictionCost
    bar.leftLabel = leftLabel
    bar.rightLabel = rightLabel

    return bar
end

local function runeComparison(runeAIndex, runeBIndex)
    local runeAStart, _, runeARuneReady = GetRuneCooldown(runeAIndex)
    local runeBStart, _, runeBRuneReady = GetRuneCooldown(runeBIndex)

    if runeARuneReady ~= runeBRuneReady then
        return runeARuneReady
    end

    if runeAStart ~= runeBStart then
        return runeAStart < runeBStart
    end

    return runeAIndex < runeBIndex
end

local function updatePowerPoint()
    local powerType = pointsFrame.powerType
    if powerType == Enum.PowerType.SoulShards then
        local power = WarlockPowerBar_UnitPower("player")
        local numShards, numPartials = math.modf(power)
        for i = 1, UnitPowerMax("player", powerType) do
            points[i].background:SetAlpha(i > numShards and 0 or 1)
            if numPartials > 0 and i == numShards + 1 then
                pointsFrame.label:SetText(numPartials * 10)
                pointsFrame.label:SetPoint("CENTER", points[i])
            elseif numPartials == 0 then
                pointsFrame.label:SetText("")
            end
        end
    elseif powerType == Enum.PowerType.Runes then
        table.sort(runeIndexes, runeComparison)
        for i, runeIndex in ipairs(runeIndexes) do
            local start, duration, ready = GetRuneCooldown(runeIndex)
            if ready then
                points[i].background:SetAlpha(1)
            else
                points[i].background:SetAlpha(0)
                CooldownFrame_Set(points[i].cooldown, start, duration, duration > 0, true)
            end
        end
    else
        local power = UnitPower(unit, powerType)
        for i = 1, UnitPowerMax(unit, powerType) do
            local point = points[i]
            if point then
                points[i].background:SetAlpha(i > power and 0 or 1)
            end
        end
    end
end

local function updatePowerPointMax()
    local powerType = pointsFrame.powerType
    local maxPower = UnitPowerMax(unit, powerType)
    local width = (width1 - spacing * (maxPower - 1)) / maxPower
    for i = 1, maxPower do
        local point = points[i]
        if not point then
            ---@class WlkPowerPoint:Frame
            point = CreateFrame("Frame", "WlkPowerPoint" .. i, pointsFrame, "BackdropTemplate")
            point:SetBackdrop(pointBackdrop)
            if powerType == Enum.PowerType.Runes then
                tinsert(runeIndexes, i)
                ---@type Cooldown
                local cooldown = CreateFrame("Cooldown", nil, point, "CooldownFrameTemplate")
                cooldown:SetAllPoints()
                point.cooldown = cooldown
            end
            tinsert(points, point)
            point.background = point:CreateTexture(nil, "BACKGROUND")
            point.background:SetAllPoints()
            point.background:SetTexture("Interface/ChatFrame/CHATFRAMEBACKGROUND")
        else
            point:Show()
        end
        point:SetSize(width, height1)
        point:SetPoint("LEFT", (i - 1) * (width + spacing), 0)
    end
    for i = maxPower + 1, #points do
        points[i]:Hide()
    end
    updatePowerPoint()
end

local function updatePointColor()
    local key = pointsFrame.powerToken or pointsFrame.powerType
    local color = PowerBarColor[key] or C_ClassColor.GetClassColor(class)
    for _, point in ipairs(points) do
        point.background:SetColorTexture(GetTableColor(color))
    end
end

---@param frame Frame
local function setPowerFrameShown(frame, show)
    if show then
        if frame.powerType == Enum.PowerType.Runes then
            frame:RegisterEvent("RUNE_POWER_UPDATE")
        else
            frame:RegisterUnitEvent("UNIT_MAXPOWER", unit)
            frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", unit)
        end
        if frame:GetObjectType() == "StatusBar" then
            frame:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
            frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
            frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
            frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)
            updatePowerBarMax(frame)
            updateBarColor(frame)
        else
            updatePowerPointMax()
            updatePointColor()
        end
        frame:Show()
    else
        frame:Hide()
        frame:UnregisterAllEvents()
    end
end

local function setPowerFramesShown(showPoint, showBar1, showBar2)
    setPowerFrameShown(pointsFrame, showPoint)
    setPowerFrameShown(powerBar1, showBar1)
    setPowerFrameShown(powerBar2, showBar2)
end

local function updatePowerFramesVisibility()
    if unit == "vehicle" then
        local maxPower = UnitPowerMax(unit)
        if PlayerVehicleHasComboPoints() then
            pointsFrame.powerType = Enum.PowerType.ComboPoints
            pointsFrame.powerToken = "COMBO_POINTS"
            setPowerFramesShown(true, false, maxPower > 0)
        else
            setPowerFramesShown(false, maxPower > 0, false)
        end
    elseif unit == "player" then
        local spec = GetSpecialization()
        local powerType = UnitPowerType("player")
        if class == "WARLOCK" then
            pointsFrame.powerType = Enum.PowerType.SoulShards
            pointsFrame.powerToken = "SOUL_SHARDS"
            setPowerFramesShown(true, false, true)
        elseif class == "PALADIN" then
            pointsFrame.powerType = Enum.PowerType.HolyPower
            pointsFrame.powerToken = "HOLY_POWER"
            setPowerFramesShown(true, false, true)
        elseif class == "MAGE" then
            if spec == SPEC_MAGE_ARCANE then
                pointsFrame.powerType = Enum.PowerType.ArcaneCharges
                pointsFrame.powerToken = "ARCANE_CHARGES"
                setPowerFramesShown(true, false, true)
            else
                setPowerFramesShown(false, true, false)
            end
        elseif class == "MONK" then
            if spec == SPEC_MONK_WINDWALKER then
                pointsFrame.powerType = Enum.PowerType.Chi
                pointsFrame.powerToken = "CHI"
                setPowerFramesShown(true, false, true)
                staggerBar:Hide()
            elseif spec == SPEC_MONK_BREWMASTER then
                setPowerFramesShown(false, true, false)
                staggerBar:Show()
            else
                setPowerFramesShown(false, true, false)
                staggerBar:Hide()
            end
        elseif class == "ROGUE" then
            pointsFrame.powerType = Enum.PowerType.ComboPoints
            pointsFrame.powerToken = "COMBO_POINTS"
            setPowerFramesShown(true, false, true)
        elseif class == "DRUID" then
            if powerType == Enum.PowerType.Energy then
                pointsFrame.powerType = Enum.PowerType.ComboPoints
                pointsFrame.powerToken = "COMBO_POINTS"
                powerBar2.powerType = nil
                powerBar2.powerToken = nil
                setPowerFramesShown(true, false, true)
            elseif powerType == Enum.PowerType.LunarPower then
                powerBar2.powerType = Enum.PowerType.Mana
                powerBar2.powerToken = "MANA"
                setPowerFramesShown(false, true, true)
            else
                setPowerFramesShown(false, true, false)
            end
        elseif class == "DEATHKNIGHT" then
            pointsFrame.powerType = Enum.PowerType.Runes
            setPowerFramesShown(true, false, true)
        elseif class == "SHAMAN" then
            if powerType == Enum.PowerType.Maelstrom then
                powerBar2.powerType = Enum.PowerType.Mana
                powerBar2.powerToken = "MANA"
                setPowerFramesShown(false, true, true)
            else
                setPowerFramesShown(false, true, false)
            end
        elseif class == "PRIEST" then
            if powerType == Enum.PowerType.Insanity then
                powerBar2.powerType = Enum.PowerType.Mana
                powerBar2.powerToken = "MANA"
                powerBar1.powerToken = "INSANITY"
                setPowerFramesShown(false, true, true)
            else
                powerBar1.powerToken = nil
                setPowerFramesShown(false, true, false)
            end
        else
            setPowerFramesShown(false, true, false)
        end
    end
end

powerBar1 = createPowerBar("WlkPowerBar", width1, height1)
powerBar1:SetPoint("BOTTOM", UIParent, 0, 273)

powerBar2 = createPowerBar("WlkAdditionalPowerBar", width2, height2)
powerBar2:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -122, 271)

pointsFrame:SetSize(width1, height1)
pointsFrame:SetPoint("BOTTOM", UIParent, 0, 273)
pointsFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "RUNE_POWER_UPDATE" then
        updatePowerPoint()
    elseif event == "UNIT_MAXPOWER" or event == "UNIT_POWER_FREQUENT" then
        local _, powerToken = ...
        if powerToken == self.powerToken or powerToken == select(2, UnitPowerType("player")) or unit == "vehicle" then
            if event == "UNIT_MAXPOWER" then
                updatePowerPointMax()
            elseif event == "UNIT_POWER_FREQUENT" then
                updatePowerPoint()
            end
        end
    end
end)

if class == "MONK" then
    local leftLabel = staggerBar:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med1")
    local rightLabel = staggerBar:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med1")

    local function updateStaggerMax()
        local maxHealth = UnitHealthMax("player")
        local stagger = UnitStagger("player")
        staggerBar:SetMinMaxValues(0, maxHealth)
        leftLabel:SetFormattedText("%s/%s", abbreviateNumber(stagger), abbreviateNumber(maxHealth))
        rightLabel:SetText(FormatPercentage(PercentageBetween(stagger, 0, maxHealth)))
    end

    leftLabel:SetPoint("LEFT", 1, 0)

    rightLabel:SetPoint("RIGHT", -1, 0)

    staggerBar = CreateFrame("StatusBar", "WlkStaggerBar", BuffFrame, "BackdropTemplate")
    staggerBar:SetSize(width2, height2)
    staggerBar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -122, 271)
    staggerBar:SetBackdrop(barBackdrop)
    staggerBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill")
    staggerBar:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.01 then
            return
        end
        self.elapsed = 0

        local stagger = UnitStagger("player")
        if not stagger then
            return
        end
        staggerBar:SetValue(stagger)
        updateStaggerMax()

        local _, maxStagger = staggerBar:GetMinMaxValues()
        local percent = stagger / maxStagger
        local info = PowerBarColor[BREWMASTER_POWER_BAR_NAME]
        if percent >= STAGGER_RED_TRANSITION then
            info = info[STAGGER_RED_INDEX]
        elseif percent >= STAGGER_YELLOW_TRANSITION then
            info = info[STAGGER_YELLOW_INDEX]
        else
            info = info[STAGGER_GREEN_INDEX]
        end
        staggerBar:SetStatusBarColor(GetTableColor(info))
    end)

    staggerBar.leftLabel = leftLabel
    staggerBar.rightLabel = rightLabel
elseif class == "WARLOCK" then
    pointsFrame.label = pointsFrame:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med1")
end

listener:RegisterEvent("PLAYER_LOGIN")
listener:RegisterEvent("PLAYER_ENTERING_WORLD")
listener:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
listener:RegisterUnitEvent("UNIT_MAXPOWER", "player")
listener:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
listener:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")
listener:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        PlayerPowerBarAlt:ClearAllPoints()
        PlayerPowerBarAlt:SetPoint("CENTER", UIParent, "BOTTOM", (180 + size / 2) / scale, (300 + size / 2) / scale)
        PlayerPowerBarAlt:SetMovable(false)
    elseif event == "UNIT_DISPLAYPOWER" or event == "UNIT_MAXPOWER" or event == "PLAYER_ENTERING_WORLD" then
        updatePowerFramesVisibility()
    elseif event == "UNIT_ENTERED_VEHICLE" and UnitInVehicle("player") and UnitHasVehicleUI("player")
            and unit == "player" then
        unit = "vehicle"
        C_Timer.After(0.1, updatePowerFramesVisibility)
    elseif event == "UNIT_EXITING_VEHICLE" and unit == "vehicle" then
        unit = "player"
        updatePowerFramesVisibility()
    end
end)

PlayerPowerBarAlt:SetScale(scale)
PlayerPowerBarAlt:SetMovable(true)
PlayerPowerBarAlt:SetUserPlaced(true)

PlayerPowerBarAlt.statusFrame.text:SetScale(1 / scale)

RegisterCVar("alternateResourceText", "1")
