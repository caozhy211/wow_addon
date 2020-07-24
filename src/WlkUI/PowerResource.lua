---@type Frame
local frame = CreateFrame("Frame", "WLK_ClassResourceFrame", UIParent)
frame:SetSize(228, 20)
frame:SetPoint("BOTTOM", 0, 185)
frame.shouldShow = false -- 仅用于调用 InitData 函数初始化数据后判断资源框架是否应该显示
frame:SetAlpha(0)

local showLevel -- 显示资源所需等级
local showSpec -- 显示资源所需专精
local powerType, powerTokens
local checkEvents = {}
local updateEvents = {}
local maxPowerShown = 0 -- 已显示的最大能量值
---@type table<number, Frame>
local blocks = {}
local runeIndexes = {}
local unit = UnitInVehicle("player") and "vehicle" or "player"
local _, class = UnitClass("player")

frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
frame:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")

local function ShowResourceFrame()
    if frame:GetAlpha() == 0 then
        frame:SetAlpha(1)
    end
end

local function HideResourceFrame()
    if frame:GetAlpha() == 1 then
        frame:SetAlpha(0)
    end
end

--- 设置资源块颜色
local function SetBlockColor(block)
    local color
    if powerTokens then
        for powerToken in pairs(powerTokens) do
            color = PowerBarColor[powerToken]
            break
        end
    end
    color = color or PowerBarColor[powerType] or C_ClassColor.GetClassColor(class)
    block.background:SetColorTexture(GetTableColor(color))
end

--- 注册监听事件
local function RegisterEvents(...)
    for i = 1, select("#", ...) do
        local events = select(i, ...)
        for event, isUnitEvent in pairs(events) do
            if event then
                if not frame:IsEventRegistered(event) then
                    if isUnitEvent then
                        frame:RegisterUnitEvent(event, unit)
                    else
                        frame:RegisterEvent(event)
                    end
                end
            end
        end
    end
end

--- 取消注册监听事件
local function UnregisterEvents(...)
    for i = 1, select("#", ...) do
        local events = select(i, ...)
        for event in pairs(events) do
            if event then
                frame:UnregisterEvent(event)
            end
        end
    end
end

--- 建立资源块
local function ShowBlocks()
    local maxPower = UnitPowerMax(unit, powerType)
    -- 已显示的最大能量值和当前最大能量值相同时，不需要创建
    if maxPower == maxPowerShown then
        return
    end
    maxPowerShown = maxPower
    local spacing = 7
    local width = (frame:GetWidth() - spacing * (maxPower - 1)) / maxPower
    for i = 1, maxPower do
        ---@type Frame
        local resource = blocks[i]
        if not resource then
            resource = CreateFrame("Frame", nil, frame)
            resource:SetSize(width, frame:GetHeight())
            resource:SetPoint("LEFT", (width + spacing) * (i - 1), 0)
            resource:SetBackdrop({
                edgeFile = "Interface/Buttons/WHITE8X8",
                edgeSize = 2,
            })
            ---@type Texture
            local background = resource:CreateTexture(nil, "BACKGROUND")
            background:SetAllPoints()
            background:SetTexture("Interface/ChatFrame/CHATFRAMEBACKGROUND")
            resource.background = background
            tinsert(blocks, resource)

            -- 资源是符文时，创建 Cooldown 框架
            if powerType == Enum.PowerType.Runes then
                tinsert(runeIndexes, i)
                ---@type Cooldown
                local cooldown = CreateFrame("Cooldown", nil, resource, "CooldownFrameTemplate")
                cooldown:SetAllPoints()
                resource.cooldown = cooldown
            end
        else
            -- 资源块已存在时，只需要调整大小和位置即可
            resource:SetSize(width, frame:GetHeight())
            resource:SetPoint("LEFT", (width + spacing) * (i - 1), 0)
            resource:Show()
        end
        -- 职业资源和载具连击点的颜色可能不同，所以需要设置颜色
        SetBlockColor(resource)
    end
    -- 隐藏资源块表中多余的资源块
    for i = maxPower + 1, #blocks do
        blocks[i]:Hide()
    end
    -- 显示资源框架
    ShowResourceFrame()
end

--- 使用冷却剩余时间升序的比较方式
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

--- 更新资源块显示
local function UpdateBlocks()
    -- 初始化登录时，创建的资源块可能会比资源最大值小
    if #blocks < UnitPowerMax(unit, powerType) then
        ShowBlocks()
    end
    -- 灵魂碎片
    if powerType == Enum.PowerType.SoulShards then
        local power = WarlockPowerBar_UnitPower("player")
        local numShards, numPartials = math.modf(power)
        for i = 1, UnitPowerMax("player", powerType) do
            blocks[i].background:SetAlpha(i > numShards and 0 or 1)
            -- 显示灵魂碎片裂片数量
            if numPartials > 0 and i == numShards + 1 then
                frame.text:SetText(numPartials * 10)
                frame.text:SetPoint("CENTER", blocks[i])
            elseif numPartials == 0 then
                frame.text:SetText("")
            end
        end
    elseif powerType == Enum.PowerType.Runes then
        -- 符文
        table.sort(runeIndexes, RuneComparison)
        for i = 1, #runeIndexes do
            local runeIndex = runeIndexes[i]
            local start, duration, ready = GetRuneCooldown(runeIndex)
            local block = blocks[i]
            if ready then
                block.background:SetAlpha(1)
            else
                block.background:SetAlpha(0)
                -- 显示符文冷却时间
                block.cooldown:SetCooldown(start, duration)
            end
        end
    else
        -- 其他资源
        local power = UnitPower(unit, powerType)
        for i = 1, UnitPowerMax(unit, powerType) do
            blocks[i].background:SetAlpha(i > power and 0 or 1)
        end
    end
end

--- 根据玩家职业初始化数据
local function InitData()
    if unit == "player" then
        local spec = GetSpecialization()
        if spec == nil then
            C_Timer.After(0.1, function()
                InitData()
                return
            end)
        end

        if class == "WARLOCK" then
            showLevel = SHARDBAR_SHOW_LEVEL
            showSpec = "all"
            powerType = Enum.PowerType.SoulShards
            powerTokens = { SOUL_SHARDS = true, }
            checkEvents = { PLAYER_TALENT_UPDATE = false, }
            updateEvents = {
                PLAYER_ENTERING_WORLD = false,
                UNIT_DISPLAYPOWER = true,
                UNIT_POWER_FREQUENT = true,
            }

            if UnitLevel("player") < showLevel then
                frame:RegisterEvent("PLAYER_LEVEL_UP")
            else
                frame.shouldShow = true
                RegisterEvents(checkEvents, updateEvents)
            end

            if not frame.text then
                ---@type FontString
                frame.text = frame:CreateFontString(nil, "ARTWORK", "Game15Font_o1")
                frame.text:SetTextColor(GetTableColor(YELLOW_FONT_COLOR))
            end
        elseif class == "PALADIN" then
            showLevel = PALADINPOWERBAR_SHOW_LEVEL
            showSpec = SPEC_PALADIN_RETRIBUTION
            powerType = Enum.PowerType.HolyPower
            powerTokens = { HOLY_POWER = true, }
            checkEvents = { PLAYER_TALENT_UPDATE = false, }
            updateEvents = {
                PLAYER_ENTERING_WORLD = false,
                UNIT_DISPLAYPOWER = true,
                UNIT_POWER_FREQUENT = true,
            }

            if UnitLevel("player") < showLevel then
                frame:RegisterEvent("PLAYER_LEVEL_UP")
            else
                RegisterEvents(checkEvents)
                if spec == showSpec then
                    frame.shouldShow = true
                    RegisterEvents(updateEvents)
                    frame.getMaxHolyPower = C_Timer.NewTicker(0.5, function()
                        local maxPower = UnitPowerMax("player", Enum.PowerType.HolyPower)
                        if maxPower > HOLY_POWER_FULL then
                            ShowBlocks()
                            UpdateBlocks()
                            ---@type TickerPrototype
                            local ticker = frame.getMaxHolyPower
                            ticker:Cancel()
                            ticker = nil
                        end
                    end)
                end
            end
        elseif class == "MAGE" then
            showSpec = SPEC_MAGE_ARCANE
            powerType = Enum.PowerType.ArcaneCharges
            powerTokens = { ARCANE_CHARGES = true, }
            checkEvents = { PLAYER_TALENT_UPDATE = false, }
            updateEvents = {
                PLAYER_ENTERING_WORLD = false,
                UNIT_DISPLAYPOWER = true,
                UNIT_POWER_FREQUENT = true,
            }

            RegisterEvents(checkEvents)
            if spec == showSpec then
                frame.shouldShow = true
                RegisterEvents(updateEvents)
            end
        elseif class == "MONK" then
            showSpec = SPEC_MONK_WINDWALKER
            powerType = Enum.PowerType.Chi
            powerTokens = { CHI = true, DARK_FORCE = true, }
            checkEvents = {
                PLAYER_TALENT_UPDATE = false,
                PLAYER_ENTERING_WORLD = false,
                UNIT_DISPLAYPOWER = true,
                UNIT_MAXPOWER = true,
            }
            updateEvents = { UNIT_POWER_FREQUENT = true, }

            RegisterEvents(checkEvents)
            if spec == showSpec then
                frame.shouldShow = true
                RegisterEvents(updateEvents)
            end
        elseif class == "ROGUE" then
            showSpec = "all"
            powerType = Enum.PowerType.ComboPoints
            powerTokens = { COMBO_POINTS = true, }
            checkEvents = {
                PLAYER_TALENT_UPDATE = false,
                PLAYER_ENTERING_WORLD = false,
                UNIT_DISPLAYPOWER = true,
                UNIT_MAXPOWER = true,
            }
            updateEvents = { UNIT_POWER_FREQUENT = true, }

            frame.shouldShow = true
            RegisterEvents(checkEvents, updateEvents)
        elseif class == "DRUID" then
            powerType = Enum.PowerType.ComboPoints
            powerTokens = { COMBO_POINTS = true, }
            checkEvents = {
                PLAYER_TALENT_UPDATE = false,
                PLAYER_ENTERING_WORLD = false,
                UNIT_DISPLAYPOWER = true,
                UNIT_MAXPOWER = true,
            }
            updateEvents = { UNIT_POWER_FREQUENT = true, }

            RegisterEvents(checkEvents)
            if UnitPowerType("player") == Enum.PowerType.Energy then
                frame.shouldShow = true
                RegisterEvents(updateEvents)
            end
        elseif class == "DEATHKNIGHT" then
            showSpec = "all"
            powerType = Enum.PowerType.Runes
            checkEvents = {
                PLAYER_ENTERING_WORLD = false,
                RUNE_POWER_UPDATE = false,
            }
            updateEvents = {}

            frame.shouldShow = true
            RegisterEvents(checkEvents)
        end
    end
end

InitData()

---@param self Frame
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_ENTERED_VEHICLE" and UnitHasVehiclePlayerFrameUI("player") then
        unit = "vehicle"
        -- 取消注册之前的监听事件
        UnregisterEvents(checkEvents, updateEvents)
        -- 隐藏资源框架
        HideResourceFrame()
        maxPowerShown = 0
        if PlayerVehicleHasComboPoints() then
            powerType = Enum.PowerType.ComboPoints
            powerTokens = { COMBO_POINTS = true, }
            checkEvents = {}
            updateEvents = { UNIT_POWER_FREQUENT = true, }
            RegisterEvents(checkEvents, updateEvents)

            ShowBlocks()
            -- 重新载入时，如果立即更新，返回的能量始终是 0，所以延迟更新
            C_Timer.After(0.1, function()
                UpdateBlocks()
            end)
        end
    elseif event == "UNIT_EXITING_VEHICLE" then
        unit = "player"
        UnregisterEvents(checkEvents, updateEvents)
        HideResourceFrame()
        maxPowerShown = 0

        InitData()
        if frame.shouldShow then
            ShowBlocks()
            UpdateBlocks()
        end
    elseif event == "PLAYER_LEVEL_UP" then
        local level = ...
        if level >= showLevel then
            self:UnregisterEvent(event)
            RegisterEvents(checkEvents)
            if showSpec == "all" or showSpec == GetSpecialization() then
                RegisterEvents(updateEvents)
                ShowBlocks()
                UpdateBlocks()
            end
        end
    elseif checkEvents[event] ~= nil then
        -- 职业是德鲁伊时，根据使用的能量类型判断，showSpec 是 nil，非德鲁伊职业按照专精显示条件判断
        if class == "DRUID" and UnitPowerType("player") == Enum.PowerType.Energy or showSpec == "all"
                or showSpec == GetSpecialization() then
            RegisterEvents(updateEvents)
            ShowBlocks()
            UpdateBlocks()
        else
            -- 隐藏资源块
            HideResourceFrame()
            maxPowerShown = 0
            UnregisterEvents(updateEvents)
        end
    elseif event == "UNIT_POWER_FREQUENT" then
        -- 事件是 UNIT_POWER_FREQUENT 时，需要根据能量标志进行判断
        local _, powerToken = ...
        if powerTokens[powerToken] then
            UpdateBlocks()
        end
    elseif updateEvents[event] ~= nil then
        UpdateBlocks()
    end
end)

---@type StatusBar
local bar = CreateFrame("StatusBar", "WLK_ClassPowerBar", UIParent)
if frame.shouldShow then
    bar:Hide()
end
bar:SetSize(228, 20)
bar:SetPoint("BOTTOM", 0, 185)
bar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Resource-Fill", "BORDER")
---@type Texture
local background = bar:CreateTexture(nil, "BACKGROUND")
background:SetAllPoints()
background:SetTexture("Interface/RaidFrame/Raid-Bar-Resource-Background")

---@type FontString
local leftLabel = bar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
leftLabel:SetPoint("LEFT")
---@type FontString
local rightLabel = bar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
rightLabel:SetPoint("RIGHT")

bar.unit = "player"

bar:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
bar:RegisterUnitEvent("UNIT_EXITING_VEHICLE", "player")

local POWER_EVENTS = {
    UNIT_POWER_FREQUENT = true,
    UNIT_MAXPOWER = true,
    UNIT_DISPLAYPOWER = true,
    PLAYER_ENTERING_WORLD = false,
}

local function RegisterPowerEvents()
    for event, isUnitEvent in pairs(POWER_EVENTS) do
        if isUnitEvent then
            bar:RegisterUnitEvent(event, bar.unit)
        else
            bar:RegisterEvent(event)
        end
    end
end

local function UnregisterPowerEvents()
    for event in pairs(POWER_EVENTS) do
        bar:UnregisterEvent(event)
    end
end

local function FormatNumber(number)
    if number >= 1e8 then
        return format("%.2f" .. SECOND_NUMBER_CAP, number / 1e8)
    elseif number >= 1e6 then
        return format("%d" .. SECOND_NUMBER, number / 1e4)
    elseif number >= 1e4 then
        return format("%.1f" .. SECOND_NUMBER, number / 1e4)
    end
    return number
end

local function UpdateMaxPower()
    local maxPower = UnitPowerMax(bar.unit)
    if maxPower > 0 then
        local power = UnitPower(bar.unit)
        bar:SetMinMaxValues(0, maxPower)
        leftLabel:SetText(FormatNumber(power) .. "/" .. FormatNumber(maxPower))
        if not bar:IsShown() and frame:GetAlpha() == 0 then
            bar:Show()
        end
    else
        bar:Hide()
    end
end

local function UpdatePower()
    local maxPower = UnitPowerMax(bar.unit)
    if maxPower > 0 then
        local power = UnitPower(bar.unit)
        bar:SetValue(power)
        leftLabel:SetText(FormatNumber(power) .. "/" .. FormatNumber(maxPower))
        rightLabel:SetFormattedText("%d%%", power / maxPower * 100)
    end
end

local function UpdateBarColor()
    local pType, pToken, altR, altG, altB = UnitPowerType(bar.unit)
    local color = PowerBarColor[pToken]
    if color then
        bar:SetStatusBarColor(GetTableColor(color))
    elseif not altR then
        color = PowerBarColor[pType] or PowerBarColor["MANA"]
        bar:SetStatusBarColor(GetTableColor(color))
    else
        bar:SetStatusBarColor(altR, altG, altB)
    end
end

RegisterPowerEvents()

bar:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_ENTERED_VEHICLE" and UnitHasVehiclePlayerFrameUI("player") then
        self.unit = "vehicle"
        UnregisterPowerEvents()
        RegisterPowerEvents()
        UpdateMaxPower()
        UpdatePower()
        UpdateBarColor()
    elseif event == "UNIT_EXITING_VEHICLE" then
        self.unit = "player"
        UnregisterPowerEvents()
        RegisterPowerEvents()
        UpdateMaxPower()
        UpdatePower()
        UpdateBarColor()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        UpdateMaxPower()
        UpdatePower()
        UpdateBarColor()
    elseif event == "UNIT_POWER_FREQUENT" then
        local _, powerToken = ...
        if powerToken == select(2, UnitPowerType(self.unit)) then
            UpdatePower()
        end
    end
end)

hooksecurefunc(frame, "SetAlpha", function(_, alpha)
    if alpha == 1 then
        bar:Hide()
    else
        bar:Show()
    end
end)
