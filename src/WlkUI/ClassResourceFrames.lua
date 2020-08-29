local width1 = 240
local height1 = 22
local point1 = "BOTTOM"
local offsetX1 = 0
local offsetY1 = 283
local width2 = 297
local height2 = 17
local point2 = "BOTTOMRIGHT"
local offsetX2 = -123
local offsetY2 = 284
local font = "GameFontHighlight"

---@type Frame
local resourceBlocks = CreateFrame("Frame", "WlkClassResourceBlocksFrame", UIParent)
resourceBlocks:SetSize(width1, height1)
resourceBlocks:SetPoint(point1, UIParent, "BOTTOM", offsetX1, offsetY1)

local function CreateClassResourceBarFrame(barName, width, height)
    ---@type StatusBar
    local bar = CreateFrame("StatusBar", barName, UIParent)
    bar:SetSize(width, height)
    bar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill")
    bar.frameType = "bar"

    ---@type Texture
    local background = bar:CreateTexture(barName .. "Background", "BACKGROUND")
    background:SetAllPoints()
    background:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")

    ---@type Texture
    local predictionCost = bar:CreateTexture(barName .. "PredictionCost", "BORDER")
    bar.predictionCost = predictionCost
    predictionCost:SetSize(width, height - 2)
    predictionCost:SetPoint("TOPLEFT")
    predictionCost:SetColorTexture(1, 1, 1, 0.55)

    ---@type FontString
    local leftLabel = bar:CreateFontString(barName .. "ValueLabel", "ARTWORK", font)
    bar.leftLabel = leftLabel
    leftLabel:SetPoint("LEFT", 1, 0)

    ---@type FontString
    local rightLabel = bar:CreateFontString(barName .. "ValueLabel", "ARTWORK", font)
    bar.rightLabel = rightLabel
    rightLabel:SetPoint("RIGHT", -1, 0)

    return bar
end

local resourceBar = CreateClassResourceBarFrame("WlkClassResourceBarFrame", width1, height1)
resourceBar:SetPoint(point1, UIParent, "BOTTOM", offsetX1, offsetY1)

local powerBar = CreateClassResourceBarFrame("WlkClassPowerBarFrame", width2, height2)
powerBar:SetPoint(point2, UIParent, "BOTTOM", offsetX2, offsetY2)

local unit = "player"
---@type Frame[]
local blocks = {}
local maxPowerShown
local blockPowerTypeShown
local spacing = 6
local blockBackdrop = { edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 2, }
local runeIndexes = {}
local _, class = UnitClass("player")

local function RuneComparison(runeAIndex, runeBIndex)
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

local tSort = table.sort

local function UpdateBlocksValue()
    local powerType = resourceBlocks.powerType
    if powerType == Enum.PowerType.SoulShards then
        local power = WarlockPowerBar_UnitPower("player")
        local numShards, numPartials = math.modf(power)
        for i = 1, UnitPowerMax("player", powerType) do
            blocks[i].background:SetAlpha(i > numShards and 0 or 1)
            if numPartials > 0 and i == numShards + 1 then
                resourceBlocks.partialsLabel:SetText(numPartials * 10)
                resourceBlocks.partialsLabel:SetPoint("CENTER", blocks[i])
            elseif numPartials == 0 then
                resourceBlocks.partialsLabel:SetText("")
            end
        end
    elseif powerType == Enum.PowerType.Runes then
        tSort(runeIndexes, RuneComparison)
        for i = 1, #runeIndexes do
            local runeIndex = runeIndexes[i]
            local start, duration, ready = GetRuneCooldown(runeIndex)
            local block = blocks[i]
            if ready then
                block.background:SetAlpha(1)
            else
                block.background:SetAlpha(0)
                CooldownFrame_Set(block.cooldown, start, duration, duration > 0, true)
            end
        end
    else
        local power = UnitPower(unit, powerType)
        for i = 1, UnitPowerMax(unit, powerType) do
            local block = blocks[i]
            if block then
                block.background:SetAlpha(i > power and 0 or 1)
            end
        end
    end
end

local function UpdateBlocksMaxValue()
    local powerType = resourceBlocks.powerType
    local maxPower = UnitPowerMax(unit, powerType)
    if powerType == blockPowerTypeShown and maxPower == maxPowerShown then
        return
    end
    blockPowerTypeShown = powerType
    maxPowerShown = maxPower
    local width = (width1 - spacing * (maxPower - 1)) / maxPower
    for i = 1, maxPower do
        local block = blocks[i]
        if not block then
            block = CreateFrame("Frame", "WlkClassResourceBlock" .. i, resourceBlocks)
            blocks[#blocks + 1] = block
            block:SetBackdrop(blockBackdrop)
            block.background = block:CreateTexture(block:GetName() .. "Background", "BACKGROUND")
            block.background:SetAllPoints()
            block.background:SetTexture("Interface/ChatFrame/CHATFRAMEBACKGROUND")
            if powerType == Enum.PowerType.Runes then
                runeIndexes[#runeIndexes + 1] = i
                ---@type Cooldown
                local cooldown = CreateFrame("Cooldown", block:GetName() .. "Cooldown", block, "CooldownFrameTemplate")
                block.cooldown = cooldown
                cooldown:SetAllPoints()
                cooldown:SetDrawEdge(true)
            end
        else
            block:Show()
        end
        block:SetSize(width, height1)
        block:SetPoint("LEFT", (i - 1) * (width + spacing), 0)
    end
    for i = maxPower + 1, #blocks do
        blocks[i]:Hide()
    end
    UpdateBlocksValue()
end

local function UpdateBlocksColor()
    local powerTokens = resourceBlocks.powerTokens
    local powerToken = powerTokens and powerTokens[1]
    local powerType = resourceBlocks.powerType
    local color = PowerBarColor[powerToken] or PowerBarColor[powerType] or C_ClassColor.GetClassColor(class)
    for _, block in ipairs(blocks) do
        block.background:SetColorTexture(GetTableColor(color))
    end
end

local function AbbreviateNumber(number)
    if number >= 1e8 then
        return format("%.2f%s", number / 1e8, SECOND_NUMBER_CAP)
    elseif number >= 1e6 then
        return format("%d%s", number / 1e4, FIRST_NUMBER_CAP)
    elseif number >= 1e4 then
        return format("%.1f%s", number / 1e4, FIRST_NUMBER_CAP)
    end
    return number
end

---@param bar StatusBar
local function UpdateBarValue(bar)
    local powerType = bar.powerType
    local power = UnitPower(unit, powerType)
    bar:SetValue(power - (bar.cost or 0))
    local _, maxValue = bar:GetMinMaxValues()
    bar.predictionCost:SetWidth(power / maxValue * bar:GetWidth())
    bar.leftLabel:SetText(AbbreviateNumber(power) .. "/" .. AbbreviateNumber(maxValue))
    bar.rightLabel:SetText(FormatPercentage(PercentageBetween(power, 0, maxValue)))
end

---@param bar StatusBar
local function UpdateBarMaxValue(bar)
    local powerType = bar.powerType or UnitPowerType(unit)
    local maxPower = UnitPowerMax(unit, powerType)
    bar:SetMinMaxValues(0, maxPower)
    UpdateBarValue(bar)
end

---@param bar StatusBar
local function UpdateBarColor(bar)
    local r, g, b
    if bar.powerType then
        r, g, b = GetTableColor(PowerBarColor[bar.powerType])
    else
        local powerType, powerToken, altR, altG, altB = UnitPowerType(unit)
        local color = PowerBarColor[powerToken]
        if color then
            r, g, b = GetTableColor(color)
        elseif altR then
            r, g, b = altR, altG, altB
        else
            color = PowerBarColor[powerType] or PowerBarColor["MANA"]
            r, g, b = GetTableColor(color)
        end
    end
    bar:SetStatusBarColor(r, g, b)
end

local function ClassResourceFrameOnEvent(self, event, ...)
    if event == "RUNE_POWER_UPDATE" then
        UpdateBlocksValue()
    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED"
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

        UpdateBarValue(self)
    else
        local _, powerToken = ...
        local powerTokens = self.powerTokens
        if powerTokens and tContains(powerTokens, powerToken) or (not powerTokens and unit == "vehicle"
                or (unit == "player" and select(2, UnitPowerType("player")) == powerToken)) then
            if event == "UNIT_MAXPOWER" then
                if self.frameType == "bar" then
                    UpdateBarMaxValue(self)
                else
                    UpdateBlocksMaxValue()
                end
            elseif event == "UNIT_POWER_FREQUENT" then
                if self.frameType == "bar" then
                    UpdateBarValue(self)
                else
                    UpdateBlocksValue()
                end
            end
        end
    end
end

resourceBlocks:SetScript("OnEvent", ClassResourceFrameOnEvent)
resourceBar:SetScript("OnEvent", ClassResourceFrameOnEvent)
powerBar:SetScript("OnEvent", ClassResourceFrameOnEvent)

---@type Frame
local eventFrame = CreateFrame("Frame")

---@type StatusBar
local staggerBar
if class == "MONK" then
    staggerBar = CreateFrame("StatusBar", "WlkStaggerBarFrame", UIParent)
    staggerBar:SetSize(width2, height2)
    staggerBar:SetPoint(point2, UIParent, "BOTTOM", offsetX2, offsetY2)
    staggerBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill")
    staggerBar.background = staggerBar:CreateTexture("WlkStaggerBarBackground", "BACKGROUND")
    staggerBar.background:SetAllPoints()
    staggerBar.background:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")
    ---@type FontString
    staggerBar.staggerLabel = staggerBar:CreateFontString("WlkStaggerLabel", "ARTWORK", font)
    staggerBar.staggerLabel:SetPoint("LEFT", 1, 0)
    ---@type FontString
    staggerBar.staggerPercentLabel = staggerBar:CreateFontString("WlkStaggerPercentLabel", "ARTWORK", font)
    staggerBar.staggerPercentLabel:SetPoint("RIGHT", -1, 0)

    local function UpdateMaxStagger()
        local maxHealth = UnitHealthMax("player")
        staggerBar:SetMinMaxValues(0, maxHealth)
        local stagger = UnitStagger("player")
        staggerBar.staggerLabel:SetText(AbbreviateNumber(stagger) .. "/" .. AbbreviateNumber(maxHealth))
        staggerBar.staggerPercentLabel:SetText(FormatPercentage(PercentageBetween(stagger, 0, maxHealth)))
    end

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
        UpdateMaxStagger()

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
        staggerBar:SetStatusBarColor(info.r, info.g, info.b)
    end)
elseif class == "WARLOCK" then
    ---@type FontString
    local label = resourceBlocks:CreateFontString("WlkPartialShardsLabel", "ARTWORK", font)
    resourceBlocks.partialsLabel = label
end

---@param frame Frame
local function ShowClassResourceFrame(frame)
    if frame.powerType == Enum.PowerType.Runes then
        frame:RegisterEvent("RUNE_POWER_UPDATE")
    else
        frame:RegisterUnitEvent("UNIT_MAXPOWER", unit)
        frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", unit)
    end
    if frame.frameType == "bar" then
        frame:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
        frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
        frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
        frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)
    end
    frame:Show()
end

---@param frame Frame
local function HideResourceFrame(frame)
    frame:UnregisterAllEvents()
    frame:Hide()
end

local function SetClassResourceFramesShown(showBlocksFrame, showResourceBar, showPowerBar)
    if showBlocksFrame then
        ShowClassResourceFrame(resourceBlocks)
        UpdateBlocksMaxValue()
        UpdateBlocksColor()
    else
        HideResourceFrame(resourceBlocks)
    end
    if showResourceBar then
        ShowClassResourceFrame(resourceBar)
        UpdateBarMaxValue(resourceBar)
        UpdateBarColor(resourceBar)
    else
        HideResourceFrame(resourceBar)
    end
    if showPowerBar then
        ShowClassResourceFrame(powerBar)
        UpdateBarMaxValue(powerBar)
        UpdateBarColor(powerBar)
    else
        HideResourceFrame(powerBar)
    end
end

local blocksShowLevel = class == "WARLOCK" and SHARDBAR_SHOW_LEVEL or class == "PALADIN" and PALADINPOWERBAR_SHOW_LEVEL
        or 0
resourceBlocks.powerTokens = {}

local function UpdateClassResourceFrames()
    wipe(resourceBlocks.powerTokens)
    if unit == "vehicle" then
        local maxPower = UnitPowerMax(unit)
        if PlayerVehicleHasComboPoints() then
            resourceBlocks.powerType = Enum.PowerType.ComboPoints
            resourceBlocks.powerTokens[1] = "COMBO_POINTS"
            SetClassResourceFramesShown(true, false, maxPower > 0)
        else
            SetClassResourceFramesShown(false, maxPower > 0, false)
        end
    elseif unit == "player" then
        local level = UnitLevel("player")
        local spec = GetSpecialization()
        local powerType = UnitPowerType("player")
        if class == "WARLOCK" then
            if level < blocksShowLevel then
                eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
                SetClassResourceFramesShown(false, true, false)
            else
                resourceBlocks.powerType = Enum.PowerType.SoulShards
                resourceBlocks.powerTokens[1] = "SOUL_SHARDS"
                SetClassResourceFramesShown(true, false, true)
            end
        elseif class == "PALADIN" then
            if level < blocksShowLevel then
                eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
                SetClassResourceFramesShown(false, true, false)
            else
                if spec == SPEC_PALADIN_RETRIBUTION then
                    resourceBlocks.powerType = Enum.PowerType.HolyPower
                    resourceBlocks.powerTokens[1] = "HOLY_POWER"
                    SetClassResourceFramesShown(true, false, true)
                else
                    SetClassResourceFramesShown(false, true, false)
                end
            end
        elseif class == "MAGE" then
            if spec == SPEC_MAGE_ARCANE then
                resourceBlocks.powerType = Enum.PowerType.ArcaneCharges
                resourceBlocks.powerTokens[1] = "ARCANE_CHARGES"
                SetClassResourceFramesShown(true, false, true)
            else
                SetClassResourceFramesShown(false, true, false)
            end
        elseif class == "MONK" then
            if spec == SPEC_MONK_WINDWALKER then
                resourceBlocks.powerType = Enum.PowerType.Chi
                resourceBlocks.powerTokens[1] = "CHI"
                resourceBlocks.powerTokens[2] = "DARK_FORCE"
                SetClassResourceFramesShown(true, false, true)
                staggerBar:Hide()
            elseif spec == SPEC_MONK_BREWMASTER then
                SetClassResourceFramesShown(false, true, false)
                staggerBar:Show()
            else
                SetClassResourceFramesShown(false, true, false)
                staggerBar:Hide()
            end
        elseif class == "ROGUE" then
            resourceBlocks.powerType = Enum.PowerType.ComboPoints
            resourceBlocks.powerTokens[1] = "COMBO_POINTS"
            SetClassResourceFramesShown(true, false, true)
        elseif class == "DRUID" then
            if powerType == Enum.PowerType.Energy then
                resourceBlocks.powerType = Enum.PowerType.ComboPoints
                resourceBlocks.powerTokens[1] = "COMBO_POINTS"
                powerBar.powerType = nil
                powerBar.powerTokens = nil
                SetClassResourceFramesShown(true, false, true)
            elseif powerType == Enum.PowerType.LunarPower then
                powerBar.powerType = Enum.PowerType.Mana
                powerBar.powerTokens = { "MANA", }
                SetClassResourceFramesShown(false, true, true)
            else
                SetClassResourceFramesShown(false, true, false)
            end
        elseif class == "DEATHKNIGHT" then
            resourceBlocks.powerType = Enum.PowerType.Runes
            SetClassResourceFramesShown(true, false, true)
        elseif class == "SHAMAN" then
            if powerType == Enum.PowerType.Maelstrom then
                powerBar.powerType = Enum.PowerType.Mana
                powerBar.powerTokens = { "MANA", }
                SetClassResourceFramesShown(false, true, true)
            else
                SetClassResourceFramesShown(false, true, false)
            end
        elseif class == "PRIEST" then
            if powerType == Enum.PowerType.Insanity then
                powerBar.powerType = Enum.PowerType.Mana
                powerBar.powerTokens = { "MANA", }
                resourceBar.powerTokens = { "INSANITY", }
                SetClassResourceFramesShown(false, true, true)
            else
                resourceBar.powerTokens = nil
                SetClassResourceFramesShown(false, true, false)
            end
        else
            SetClassResourceFramesShown(false, true, false)
        end
    end
end

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
eventFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
eventFrame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "UNIT_DISPLAYPOWER" or event == "PLAYER_ENTERING_WORLD" then
        UpdateClassResourceFrames()
    elseif event == "PLAYER_LEVEL_UP" then
        local level = ...
        if level >= blocksShowLevel then
            eventFrame:UnregisterEvent(event)
            UpdateClassResourceFrames()
        end
    elseif event == "UNIT_ENTERED_VEHICLE" and UnitInVehicle("player") and UnitHasVehicleUI("player") then
        unit = "vehicle"
        C_Timer.After(0.1, UpdateClassResourceFrames)
    elseif event == "UNIT_EXITING_VEHICLE" and unit == "vehicle" then
        unit = "player"
        UpdateClassResourceFrames()
    end
end)
