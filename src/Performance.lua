---@type Frame
local performanceFrame = CreateFrame("Frame", "WLK_PerformanceFrame", UIParent)
--- MicroButtonAndBagsBar 的大小是（298px，88px），MainMenuBarBackpackButton 右上角相对 MicroButtonAndBagsBar 右上角偏移
--- （-4px，-4px），MainMenuBarBackpackButton 的大小是（40px，40px），CharacterBagSlot 的大小是（30px，30px），
--- CharacterBag0Slot 右边相对 MainMenuBarBackpackButton 左边偏移 -4px，CharacterBagSlot 之间的水平间距是 2px
performanceFrame:SetSize(298 - 4 - 40 - 30 * NUM_BAG_SLOTS - 2 * (NUM_BAG_SLOTS - 1) - 4 - 4, 88 - 4 - 40)
performanceFrame:SetPoint("TOPLEFT", MicroButtonAndBagsBar)
performanceFrame:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background", })

local offset = 2
---@type FontString
local latencyHomeLabel = performanceFrame:CreateFontString(nil, "ARTWORK", "Tooltip_Small")
latencyHomeLabel:SetPoint("TOPLEFT", offset, -offset)
latencyHomeLabel:SetText("本地延遲: ")
---@type FontString
local latencyWorldLabel = performanceFrame:CreateFontString(nil, "ARTWORK", "Tooltip_Small")
latencyWorldLabel:SetPoint("LEFT", offset, 0)
latencyWorldLabel:SetText("世界延遲: ")
---@type FontString
local fpsLabel = performanceFrame:CreateFontString(nil, "ARTWORK", "Tooltip_Small")
fpsLabel:SetPoint("BOTTOMLEFT", offset, offset)
fpsLabel:SetText("每秒幀數: ")

---@type FontString
local latencyHomeValue = performanceFrame:CreateFontString(nil, "ARTWORK", "Tooltip_Small")
latencyHomeValue:SetPoint("TOPRIGHT", -offset, -offset)
---@type FontString
local latencyWorldValue = performanceFrame:CreateFontString(nil, "ARTWORK", "Tooltip_Small")
latencyWorldValue:SetPoint("RIGHT", -offset, 0)
---@type FontString
local fpsValue = performanceFrame:CreateFontString(nil, "ARTWORK", "Tooltip_Small")
fpsValue:SetPoint("BOTTOMRIGHT", -offset, offset)

--- 显示格式化的延迟
---@param label FontString
---@param latency number
local function SetFormattedLatency(label, latency)
    if latency < 100 then
        label:SetFormattedText(GREEN_FONT_COLOR_CODE .. "%dms" .. FONT_COLOR_CODE_CLOSE, latency)
    elseif latency < 200 then
        label:SetFormattedText(YELLOW_FONT_COLOR_CODE .. "%dms" .. FONT_COLOR_CODE_CLOSE, latency)
    elseif latency < 1000 then
        label:SetFormattedText(RED_FONT_COLOR_CODE .. "%dms" .. FONT_COLOR_CODE_CLOSE, latency)
    else
        label:SetFormattedText(RED_FONT_COLOR_CODE .. "%.2fs" .. FONT_COLOR_CODE_CLOSE, latency / 1000)
    end
end

---@type StatusBar
local memoryBar = CreateFrame("StatusBar", "WLK_MemoryBar", UIParent)
--- CharacterBagSlot 右边相对 MainMenuBarBackpackButton 左边垂直偏移 -4px
memoryBar:SetSize(30 * NUM_BAG_SLOTS + 2 * (NUM_BAG_SLOTS - 1) + 4 + 1, (40 - 30) / 2 - 2 + 4 + 4)
memoryBar:SetPoint("TOPLEFT", performanceFrame, "TOPRIGHT")
memoryBar:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark", })
memoryBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
local _, class = UnitClass("player")
memoryBar:SetStatusBarColor(GetClassColor(class))

---@type FontString
local usageLabel = memoryBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
usageLabel:SetPoint("CENTER")

memoryBar:RegisterEvent("PLAYER_LOGIN")

local addons = {}
--- 登录后初始化 addons 表
---@param self StatusBar
memoryBar:SetScript("OnEvent", function(self, event)
    for i = 1, GetNumAddOns() do
        if not addons[i] and IsAddOnLoaded(i) then
            local name = GetAddOnInfo(i)
            local memory = GetAddOnMemoryUsage(i)
            tinsert(addons, { name = name, memory = memory, min = 100000, max = 0, })
        end
    end
    self:UnregisterEvent(event)
end)

--- 格式化内存占用
---@param memory number
---@param type string 类型
local function FormatMemoryUsage(memory, type)
    local prefix
    if type == "min" then
        prefix = GREEN_FONT_COLOR_CODE .. MINIMUM .. ": "
    elseif type == "max" then
        prefix = RED_FONT_COLOR_CODE .. MAXIMUM .. ": "
    else
        prefix = YELLOW_FONT_COLOR_CODE
    end
    if memory < 1000 then
        return format(prefix .. "%.2fKB" .. FONT_COLOR_CODE_CLOSE, memory)
    end
    return format(prefix .. "%.2fMB" .. FONT_COLOR_CODE_CLOSE, memory / 1000)
end

--- 更新插件占用内存数据
local function UpdateMemoryUsage()
    UpdateAddOnMemoryUsage()
    memoryBar.memory = 0
    memoryBar.min = 0
    memoryBar.max = 0
    for i = 1, #addons do
        local addon = addons[i]
        local memoryUsage = GetAddOnMemoryUsage(addon.name)
        -- 更新插件占用的内存
        addon.memory = memoryUsage
        if memoryUsage < addon.min then
            addon.min = memoryUsage
        end
        if memoryUsage > addon.max then
            addon.max = memoryUsage
        end
        -- 将该插件数据添加到总计数据
        memoryBar.memory = memoryBar.memory + addon.memory
        memoryBar.min = memoryBar.min + addon.min
        memoryBar.max = memoryBar.max + addon.max
    end
    -- 更新数据条
    memoryBar:SetMinMaxValues(0, memoryBar.max)
    memoryBar:SetValue(memoryBar.memory)
    usageLabel:SetText(FormatMemoryUsage(memoryBar.memory))
    collectgarbage()
end

--- 每秒更新性能数据
C_Timer.NewTicker(PERFORMANCEBAR_UPDATE_INTERVAL, function()
    local _, _, latencyHome, latencyWorld = GetNetStats()
    SetFormattedLatency(latencyHomeValue, latencyHome)
    SetFormattedLatency(latencyWorldValue, latencyWorld)
    fpsValue:SetFormattedText("%.0f", GetFramerate())
    UpdateMemoryUsage()
end)

--- 鼠标移动到数据条上时在鼠标提示上显示插件占用内存数据
memoryBar:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, offset)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(FormatMemoryUsage(self.memory))
    GameTooltip:AddLine(FormatMemoryUsage(self.min, "min"))
    GameTooltip:AddLine(FormatMemoryUsage(self.max, "max"))
    GameTooltip:Show()
    -- 更新鼠标提示显示数据
    self.ticker = C_Timer.NewTicker(PERFORMANCEBAR_UPDATE_INTERVAL, function()
        ---@type FontString
        local label1 = GameTooltipTextLeft1
        label1:SetText(FormatMemoryUsage(self.memory))
        ---@type FontString
        local label2 = GameTooltipTextLeft2
        label2:SetText(FormatMemoryUsage(self.min, "min"))
        ---@type FontString
        local label3 = GameTooltipTextLeft3
        label3:SetText(FormatMemoryUsage(self.max, "max"))
    end)
end)

memoryBar:SetScript("OnLeave", function(self)
    ---@type TickerPrototype
    local ticker = self.ticker
    ticker:Cancel()
    ticker = nil
    GameTooltip:Hide()
end)

--- 点击数据条在聊天窗口显示内存占用数据
memoryBar:SetScript("OnMouseDown", function()
    local data = addons
    -- 按照当前占用内存从大到小排序
    table.sort(data, function(a, b)
        if not a or a.memory == nil then
            return false
        elseif not b or b.memory == nil then
            return true
        else
            return a.memory > b.memory
        end
    end)

    local minSum = 0
    local sum = 0
    local maxSum = 0
    print("--------------------------------------------------------------------")
    for i = 1, #data do
        local addon = data[i]
        local name = addon.name
        local memory = FormatMemoryUsage(addon.memory)
        local min = FormatMemoryUsage(addon.min, "min")
        local max = FormatMemoryUsage(addon.max, "max")
        print(name .. ": " .. memory .. "，" .. min .. "，" .. max)

        minSum = minSum + addon.min
        sum = sum + addon.memory
        maxSum = maxSum + addon.max
    end
    print("共計 " .. #data .. " 個插件: " .. FormatMemoryUsage(sum) .. "，" .. FormatMemoryUsage(minSum, "min")
            .. "，" .. FormatMemoryUsage(maxSum, "max"))
    print("--------------------------------------------------------------------")
end)
