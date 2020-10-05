--- MicroButtonAndBagsBar 左边相对 UIParent 右边的偏移
local OFFSET_X1 = -298
--- CharacterBag3Slot 边框左边相对 UIParent 右边的偏移
local OFFSET_X2 = -178
--- MainMenuBarBackpackButton 边框左边相对 UIParent 右边的偏移
local OFFSET_X3 = -47
--- MicroButtonAndBagsBar 顶部相对 UIParent 底部的偏移
local OFFSET_Y1 = 88
--- CharacterMicroButton 边框顶部相对 UIParent 底部的偏移
local OFFSET_Y2 = 42
--- CharacterBag3Slot 边框顶部相对 UIParent 底部的偏移
local OFFSET_Y3 = 77
local backdrop = { bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark", }
local padding = 2
local addons = {}

---@type Frame
local performanceFrame = CreateFrame("Frame", "WlkPerformanceFrame", UIParent, "BackdropTemplate")
local latencyHomeLabel = performanceFrame:CreateFontString("WlkLatencyHomeLabel", "ARTWORK", "NumberFont_Shadow_Small")
local latencyWorldLabel = performanceFrame:CreateFontString("WlkLatencyWorldLabel", "ARTWORK",
        "NumberFont_Shadow_Small")
local fpsLabel = performanceFrame:CreateFontString("WlkFpsLabel", "ARTWORK", "NumberFont_Shadow_Small")
local latencyHomeValueLabel = performanceFrame:CreateFontString("WlkLatencyHomeValueLabel", "ARTWORK",
        "NumberFont_Shadow_Small")
local latencyWorldValueLabel = performanceFrame:CreateFontString("WlkLatencyWorldValueLabel", "ARTWORK",
        "NumberFont_Shadow_Small")
local fpsValueLabel = performanceFrame:CreateFontString("WlkFpsValueLabel", "ARTWORK", "NumberFont_Shadow_Small")
---@type StatusBar
local memoryBar = CreateFrame("StatusBar", "WlkMemoryBar", UIParent, "BackdropTemplate")
local memoryLabel = memoryBar:CreateFontString("WlkMemoryLabel", "ARTWORK", "NumberFont_Shadow_Small")

---@param label FontString
local function setFormattedLatency(label, value)
    if value < 1000 then
        label:SetFormattedText("%.0fms", value)
        if value < 100 then
            label:SetTextColor(0, 1, 0)
        elseif value < 200 then
            label:SetTextColor(1, 1, 0)
        else
            label:SetTextColor(1, 0, 0)
        end
    else
        label:SetFormattedText("%.2fs", value / 1000)
        label:SetTextColor(1, 0, 0)
    end
end

local function formatMemory(value)
    if value < 1000 then
        return format("%.2fKB", value)
    end
    return format("%.2fMB", value / 1000)
end

local function memoryBarOnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    GameTooltip:AddDoubleLine("目前值", formatMemory(self.value), nil, nil, nil, 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("最小值", formatMemory(self.minValue), nil, nil, nil, 1, 1, 1)
    GameTooltip:AddDoubleLine("最大值", formatMemory(self.maxValue), nil, nil, nil, 1, 1, 1)
    GameTooltip:Show()
    self.UpdateTooltip = memoryBarOnEnter
end

local function sortByMemory(a, b)
    if not a or a.value == nil then
        return false
    elseif not b or b.value == nil then
        return true
    end
    return a.value > b.value
end

performanceFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", OFFSET_X1, OFFSET_Y1)
performanceFrame:SetPoint("BOTTOMRIGHT", OFFSET_X2, OFFSET_Y2)
performanceFrame:SetBackdrop(backdrop)
performanceFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < PERFORMANCEBAR_UPDATE_INTERVAL then
        return
    end
    self.elapsed = 0

    local _, _, latencyHome, latencyWorld = GetNetStats()
    setFormattedLatency(latencyHomeValueLabel, latencyHome)
    setFormattedLatency(latencyWorldValueLabel, latencyWorld)
    fpsValueLabel:SetFormattedText("%.0f", GetFramerate())
end)

latencyHomeLabel:SetPoint("TOPLEFT", padding, -padding)
latencyHomeLabel:SetText("本地延遲")

latencyWorldLabel:SetPoint("LEFT", padding, 0)
latencyWorldLabel:SetText("世界延遲")

fpsLabel:SetPoint("BOTTOMLEFT", padding, padding)
fpsLabel:SetText("每秒幀數")

latencyHomeValueLabel:SetPoint("TOPRIGHT", -padding, -padding)

latencyWorldValueLabel:SetPoint("RIGHT", -padding, 0)

fpsValueLabel:SetPoint("BOTTOMRIGHT", -padding, padding)

memoryBar:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", OFFSET_X2, OFFSET_Y1)
memoryBar:SetPoint("BOTTOMRIGHT", OFFSET_X3, OFFSET_Y3)
memoryBar:SetBackdrop(backdrop)
memoryBar:SetStatusBarTexture("Interface/Tooltips/UI-Tooltip-Background")
memoryBar:SetStatusBarColor(GetClassColor(select(2, UnitClass("player"))))
memoryBar:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < PERFORMANCEBAR_UPDATE_INTERVAL then
        return
    end
    self.elapsed = 0

    local value = 0
    local minValue = 0
    local maxValue = 0
    UpdateAddOnMemoryUsage()
    for _, addon in ipairs(addons) do
        local memory = GetAddOnMemoryUsage(addon.name)
        addon.memory = memory
        if not addon.minMemory or memory < addon.minMemory then
            addon.minMemory = memory
        end
        if not addon.maxMemory or memory > addon.maxMemory then
            addon.maxMemory = memory
        end
        value = value + addon.memory
        minValue = minValue + addon.minMemory
        maxValue = maxValue + addon.maxMemory
    end
    memoryBar:SetMinMaxValues(0, maxValue)
    memoryBar:SetValue(value)
    memoryLabel:SetText(formatMemory(value))
    self.value = value
    self.minValue = minValue
    self.maxValue = maxValue
end)
memoryBar:SetScript("OnEnter", memoryBarOnEnter)
memoryBar:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
    self.UpdateTooltip = nil
end)
memoryBar:SetScript("OnMouseDown", function()
    table.sort(addons, sortByMemory)
    for i, addon in ipairs(addons) do
        ChatFrame1:AddMessage(format("%d. %s: %s (%s~%s)", i, addon.name, formatMemory(addon.memory),
                formatMemory(addon.minMemory), formatMemory(addon.maxMemory)), 1, 1, 0)
    end
end)
memoryBar:RegisterEvent("PLAYER_LOGIN")
memoryBar:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        for i = 1, GetNumAddOns() do
            if IsAddOnLoaded(i) and not addons[i] then
                tinsert(addons, { name = GetAddOnInfo(i), })
            end
        end
    end
end)

memoryLabel:SetPoint("CENTER")
memoryLabel:SetTextColor(1, 1, 0)
