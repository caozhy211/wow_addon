---@type Frame
local bar = CreateFrame("Frame", "WLK_ClassPowerBar", UIParent)
bar:SetSize(228, 20)
bar:SetPoint("BOTTOM", 0, 185)

local showLevel -- 显示所需等级
local showSpec -- 显示所需专精
local powerType, powerTokens
---@type table<number, Frame>
local blocks = {}
local _, class = UnitClass("player")
local maxPowerShown = 0 -- 已显示的最大能量值
local setupEvents -- 建立资源块的事件
local updateEvents -- 更新资源块的事件
local runeIndexes = {}
local unit = UnitInVehicle("player") and "vehicle" or "player"
local blockColor

bar:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
bar:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")

--- 设置资源块颜色
local function SetBlockColor(block)
    if not blockColor then
        if powerTokens then
            for powerToken in pairs(powerTokens) do
                blockColor = PowerBarColor[powerToken]
                break
            end
        end
        blockColor = blockColor or PowerBarColor[powerType] or C_ClassColor.GetClassColor(class)
    end
    block.background:SetColorTexture(GetTableColor(blockColor))
end

--- 注册监听事件
local function RegisterEvents(...)
    for i = 1, select("#", ...) do
        local events = select(i, ...)
        for event, isUnitEvent in pairs(events) do
            if event then
                if not bar:IsEventRegistered(event) then
                    if isUnitEvent then
                        bar:RegisterUnitEvent(event, unit)
                    else
                        bar:RegisterEvent(event)
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
                bar:UnregisterEvent(event)
            end
        end
    end
end

--- 建立资源块
local function SetupBlocks()
    local maxPower = UnitPowerMax(unit, powerType)
    -- 已显示的最大能量值和当前最大能量值相同时，不需要创建
    if maxPower == maxPowerShown then
        return
    end
    maxPowerShown = maxPower
    local spacing = 7
    local width = (bar:GetWidth() - spacing * (maxPower - 1)) / maxPower
    for i = 1, maxPower do
        ---@type Frame
        local resource = blocks[i]
        if not resource then
            resource = CreateFrame("Frame", nil, bar)
            resource:SetSize(width, bar:GetHeight())
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
            resource:SetSize(width, bar:GetHeight())
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
end

--- 根据玩家职业初始化数据
local function Init()
    if unit == "player" then
        if class == "WARLOCK" then
            powerType = Enum.PowerType.SoulShards
            showLevel = SHARDBAR_SHOW_LEVEL
            showSpec = "all"
            powerTokens = { SOUL_SHARDS = true, }
            setupEvents = { PLAYER_TALENT_UPDATE = false, }
            updateEvents = {
                PLAYER_ENTERING_WORLD = false,
                UNIT_DISPLAYPOWER = true,
                UNIT_POWER_FREQUENT = true,
            }

            if UnitLevel("player") < showLevel then
                bar:SetAlpha(0)
                bar:RegisterEvent("PLAYER_LEVEL_UP")
            else
                RegisterEvents(setupEvents, updateEvents)
            end

            ---@type FontString
            local text = bar:CreateFontString(nil, "ARTWORK", "Game15Font_o1")
            text:SetTextColor(GetTableColor(YELLOW_FONT_COLOR))
            bar.text = text
        elseif class == "PALADIN" then
            powerType = Enum.PowerType.HolyPower
            showLevel = PALADINPOWERBAR_SHOW_LEVEL
            showSpec = SPEC_PALADIN_RETRIBUTION
            powerTokens = { HOLY_POWER = true, }
            setupEvents = { PLAYER_TALENT_UPDATE = false, }
            updateEvents = {
                PLAYER_ENTERING_WORLD = false,
                UNIT_DISPLAYPOWER = true,
                UNIT_POWER_FREQUENT = true,
            }

            if UnitLevel("player") < showLevel then
                bar:SetAlpha(0)
                bar:RegisterEvent("PLAYER_LEVEL_UP")
            else
                RegisterEvents(setupEvents)
                -- 如果是初始化登录，GetSpecialization 此时返回 nil，需要在触发 PLAYER_TALENT_UPDATE 事件时注册监听事件
                if showSpec == GetSpecialization() then
                    RegisterEvents(updateEvents)
                end
            end
        elseif class == "MAGE" then
            powerType = Enum.PowerType.ArcaneCharges
            powerTokens = { ARCANE_CHARGES = true, }
            showSpec = SPEC_MAGE_ARCANE
            setupEvents = { PLAYER_TALENT_UPDATE = false, }
            updateEvents = {
                PLAYER_ENTERING_WORLD = false,
                UNIT_DISPLAYPOWER = true,
                UNIT_POWER_FREQUENT = true,
            }

            RegisterEvents(setupEvents)
            if showSpec == GetSpecialization() then
                RegisterEvents(updateEvents)
            end
        elseif class == "MONK" then
            powerType = Enum.PowerType.Chi
            powerTokens = { CHI = true, DARK_FORCE = true, }
            showSpec = SPEC_MONK_WINDWALKER
            setupEvents = {
                PLAYER_TALENT_UPDATE = false,
                PLAYER_ENTERING_WORLD = false,
                UNIT_DISPLAYPOWER = true,
                UNIT_MAXPOWER = true,
            }
            updateEvents = { UNIT_POWER_FREQUENT = true, }

            RegisterEvents(setupEvents)
            if showSpec == GetSpecialization() then
                RegisterEvents(updateEvents)
            end
        elseif class == "ROGUE" then
            powerType = Enum.PowerType.ComboPoints
            powerTokens = { COMBO_POINTS = true, }
            showSpec = "all"
            setupEvents = {
                PLAYER_TALENT_UPDATE = false,
                PLAYER_ENTERING_WORLD = false,
                UNIT_DISPLAYPOWER = true,
                UNIT_MAXPOWER = true,
            }
            updateEvents = { UNIT_POWER_FREQUENT = true, }

            RegisterEvents(setupEvents, updateEvents)
        elseif class == "DRUID" then
            powerType = Enum.PowerType.ComboPoints
            powerTokens = { COMBO_POINTS = true, }
            setupEvents = {
                PLAYER_TALENT_UPDATE = false,
                PLAYER_ENTERING_WORLD = false,
                UNIT_DISPLAYPOWER = true,
                UNIT_MAXPOWER = true,
            }
            updateEvents = { UNIT_POWER_FREQUENT = true, }

            RegisterEvents(setupEvents)
            if UnitPowerType("player") == Enum.PowerType.Energy then
                RegisterEvents(updateEvents)
            end
        elseif class == "DEATHKNIGHT" then
            powerType = Enum.PowerType.Runes
            showSpec = "all"
            setupEvents = {
                PLAYER_ENTERING_WORLD = false,
                RUNE_POWER_UPDATE = false,
            }
            updateEvents = {}

            RegisterEvents(setupEvents)
        end
    end
end

Init()

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
    -- 灵魂碎片
    if powerType == Enum.PowerType.SoulShards then
        local power = WarlockPowerBar_UnitPower("player")
        local numShards, numPartials = math.modf(power)
        for i = 1, #blocks do
            blocks[i].background:SetAlpha(i > numShards and 0 or 1)
            -- 显示灵魂碎片裂片数量
            if numPartials > 0 and i == numShards + 1 then
                bar.text:SetText(numPartials * 10)
                bar.text:SetPoint("CENTER", blocks[i])
            elseif numPartials == 0 then
                bar.text:SetText("")
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
        for i = 1, #blocks do
            blocks[i].background:SetAlpha(i > power and 0 or 1)
        end
    end
end

---@param self Frame
bar:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_ENTERED_VEHICLE" and PlayerVehicleHasComboPoints() then
        unit = "vehicle"
        -- 取消注册之前的监听事件
        UnregisterEvents(setupEvents, updateEvents)
        maxPowerShown = 0
        for i = 1, #blocks do
            blocks[i]:Hide()
        end
        -- 需要重新设置资源块颜色
        blockColor = nil
        showSpec = "all"
        powerType = Enum.PowerType.ComboPoints
        powerTokens = { COMBO_POINTS = true, }
        setupEvents = {}
        updateEvents = { UNIT_POWER_FREQUENT = true, }

        RegisterEvents(setupEvents, updateEvents)

        -- 建立资源块
        SetupBlocks()
        -- 重新载入时，如果立即更新，返回的能量始终是 0，所以延迟更新
        C_Timer.After(0.1, function()
            UpdateBlocks()
        end)
        -- 如果未显示，则显示
        if self:GetAlpha() == 0 then
            self:SetAlpha(1)
        end
    elseif event == "UNIT_EXITED_VEHICLE" then
        unit = "player"
        UnregisterEvents(setupEvents, updateEvents)
        maxPowerShown = 0
        for i = 1, #blocks do
            blocks[i]:Hide()
        end
        blockColor = nil
        showSpec = nil
        -- 重新初始化数据
        Init()

        -- 建立并更新一次
        SetupBlocks()
        UpdateBlocks()
        if self:GetAlpha() == 0 then
            self:SetAlpha(1)
        end
    elseif event == "PLAYER_LEVEL_UP" then
        local level = ...
        if level >= showLevel then
            self:UnregisterEvent(event)
            RegisterEvents(setupEvents)
            if showSpec == "all" or showSpec == GetSpecialization() then
                RegisterEvents(updateEvents)
                self:SetAlpha(1)
                SetupBlocks()
                UpdateBlocks()
            end
        end
    elseif setupEvents[event] ~= nil then
        -- 职业是德鲁伊时，根据使用的能量类型判断，showSpec 是 nil，非德鲁伊职业按照专精显示条件判断
        if class == "DRUID" and UnitPowerType("player") == Enum.PowerType.Energy or showSpec == "all"
                or showSpec == GetSpecialization() then
            RegisterEvents(updateEvents)
            SetupBlocks()
            UpdateBlocks()
            if self:GetAlpha() == 0 then
                self:SetAlpha(1)
            end
        else
            self:SetAlpha(0)
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
