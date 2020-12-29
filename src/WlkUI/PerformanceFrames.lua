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

local function sortByMemory(a, b)
    if not a or a.mem == nil then
        return false
    elseif not b or b.mem == nil then
        return true
    end
    return a.mem > b.mem
end

local function findAddon(name)
    for _, addon in ipairs(addons) do
        if addon.name == name then
            return addon
        end
    end
end

local function memoryBarOnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(format("%s(%s~%s)", formatMemory(self.value), formatMemory(self.minValue),
            formatMemory(self.maxValue)))
    table.sort(addons, sortByMemory)
    for _, addon in ipairs(addons) do
        if addon.mem ~= 0 then
            GameTooltip:AddLine(format("%s: %s(%s~%s)", addon.name, formatMemory(addon.mem), formatMemory(addon.minMem),
                    formatMemory(addon.maxMem)), 1, 1, 1)
        end
    end
    GameTooltip:Show()
    self.UpdateTooltip = memoryBarOnEnter
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

    UpdateAddOnMemoryUsage()
    local totalMem = 0
    local minTotalMem = 0
    local maxTotalMem = 0
    for i = 1, GetNumAddOns() do
        local name = GetAddOnInfo(i)
        local mem = GetAddOnMemoryUsage(i)
        local addon = findAddon(name)
        if not addon then
            tinsert(addons, { name = name, mem = mem, })
            addon = addons[#addons]
        else
            addon.mem = mem
        end
        if not addon.minMem or mem < addon.minMem then
            addon.minMem = mem
        end
        if not addon.maxMem or mem > addon.maxMem then
            addon.maxMem = mem
        end
        totalMem = totalMem + mem
        minTotalMem = minTotalMem + addon.minMem
        maxTotalMem = maxTotalMem + addon.maxMem
    end
    memoryBar:SetMinMaxValues(0, maxTotalMem)
    memoryBar:SetValue(totalMem)
    memoryLabel:SetText(formatMemory(totalMem))
    self.value = totalMem
    self.minValue = minTotalMem
    self.maxValue = maxTotalMem
end)
memoryBar:SetScript("OnEnter", memoryBarOnEnter)
memoryBar:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
    self.UpdateTooltip = nil
end)

memoryLabel:SetPoint("CENTER")
memoryLabel:SetTextColor(1, 1, 0)
