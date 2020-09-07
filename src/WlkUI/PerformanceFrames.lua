local OFFSET_X1 = -178
local OFFSET_Y1 = 42
local OFFSET_X2 = -47
local OFFSET_Y2 = 77
local OFFSET_X3 = -298
local OFFSET_Y3 = 85
local width1 = OFFSET_X1 - OFFSET_X3
local height1 = OFFSET_Y3 - OFFSET_Y1
local width2 = OFFSET_X2 - OFFSET_X1
local height2 = OFFSET_Y3 - OFFSET_Y2
local backdrop = { bgFile = "Interface/DialogFrame/UI-DialogBox-Background", }
local font = "ChatFontSmall"
local offset = 2
local addons = {}
local tSort = table.sort
---@type Frame
local performanceFrame = CreateFrame("Frame", "WlkPerformanceFrame", UIParent)
---@type FontString
local latencyHomeLabel = performanceFrame:CreateFontString("WlkLatencyHomeLabel", "ARTWORK", font)
---@type FontString
local latencyWorldLabel = performanceFrame:CreateFontString("WlkLatencyWorldLabel", "ARTWORK", font)
---@type FontString
local fpsLabel = performanceFrame:CreateFontString("WlkFPSLabel", "ARTWORK", font)
---@type FontString
local latencyHomeValueLabel = performanceFrame:CreateFontString("WlkLatencyHomeValueLabel", "ARTWORK", font)
---@type FontString
local latencyWorldValueLabel = performanceFrame:CreateFontString("WlkLatencyWorldValueLabel", "ARTWORK", font)
---@type FontString
local fpsValueLabel = performanceFrame:CreateFontString("WlkFPSValueLabel", "ARTWORK", font)
---@type StatusBar
local memoryBar = CreateFrame("StatusBar", "WlkMemoryBarFrame", UIParent)
---@type FontString
local memoryLabel = memoryBar:CreateFontString("WlkMemoryLabel", "ARTWORK", "Game12Font_o1")

---@param label FontString
local function SetFormattedLatency(label, latency)
    if latency < 1000 then
        label:SetFormattedText("%.0fms", latency)
        if latency < 100 then
            label:SetTextColor(0, 1, 0)
        elseif latency < 200 then
            label:SetTextColor(1, 1, 0)
        else
            label:SetTextColor(1, 0, 0)
        end
    else
        label:SetFormattedText("%.2fs", latency / 1000)
        label:SetTextColor(1, 0, 0)
    end
end

local function FormatMemoryUsage(memory)
    if memory < 1000 then
        return format("%.2fKB", memory)
    end
    return format("%.2fMB", memory / 1000)
end

local function UpdateMemoryUsage()
    UpdateAddOnMemoryUsage()
    memoryBar.memory = 0
    memoryBar.min = 0
    memoryBar.max = 0
    for _, addon in ipairs(addons) do
        local memory = GetAddOnMemoryUsage(addon.name)
        addon.memory = memory
        if memory < addon.min then
            addon.min = memory
        end
        if memory > addon.max then
            addon.max = memory
        end
        memoryBar.memory = memoryBar.memory + addon.memory
        memoryBar.min = memoryBar.min + addon.min
        memoryBar.max = memoryBar.max + addon.max
    end
    memoryBar:SetMinMaxValues(0, memoryBar.max)
    memoryBar:SetValue(memoryBar.memory)
    memoryLabel:SetText(FormatMemoryUsage(memoryBar.memory))
end

local function MemoryBarOnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(FormatMemoryUsage(self.memory))
    GameTooltip:AddDoubleLine(MINIMUM, FormatMemoryUsage(self.min), nil, nil, nil, 1, 1, 1)
    GameTooltip:AddDoubleLine(MAXIMUM, FormatMemoryUsage(self.max), nil, nil, nil, 1, 1, 1)
    GameTooltip:Show()
    self.UpdateTooltip = MemoryBarOnEnter
end

local function SortByMemoryUsage(addonA, addonB)
    if not addonA or addonA.memory == nil then
        return false
    elseif not addonB or addonB.memory == nil then
        return true
    else
        return addonA.memory > addonB.memory
    end
end

performanceFrame:SetSize(width1, height1)
performanceFrame:SetPoint("BOTTOMRIGHT", OFFSET_X1, OFFSET_Y1)
performanceFrame:SetBackdrop(backdrop)
performanceFrame:SetFrameStrata("LOW")

latencyHomeLabel:SetPoint("TOPLEFT", offset, -offset)
latencyHomeLabel:SetText("本地延遲：")

latencyWorldLabel:SetPoint("LEFT", offset, 0)
latencyWorldLabel:SetText("世界延遲：")

fpsLabel:SetPoint("BOTTOMLEFT", offset, offset)
fpsLabel:SetText("每秒幀數：")

latencyHomeValueLabel:SetPoint("TOPRIGHT", -offset, -offset)

latencyWorldValueLabel:SetPoint("RIGHT", -offset, 0)

fpsValueLabel:SetPoint("BOTTOMRIGHT", -offset, offset)

performanceFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < PERFORMANCEBAR_UPDATE_INTERVAL then
        return
    end
    self.elapsed = 0

    local _, _, latencyHome, latencyWorld = GetNetStats()
    SetFormattedLatency(latencyHomeValueLabel, latencyHome)
    SetFormattedLatency(latencyWorldValueLabel, latencyWorld)
    fpsValueLabel:SetFormattedText("%.0f", GetFramerate())
end)

memoryBar:SetSize(width2, height2)
memoryBar:SetPoint("BOTTOMRIGHT", OFFSET_X2, OFFSET_Y2)
memoryBar:SetBackdrop(backdrop)
memoryBar:SetStatusBarTexture("Interface/RaidFrame/Raid-Bar-Hp-Fill")
memoryBar:SetFrameStrata("LOW")

memoryLabel:SetPoint("CENTER")
memoryLabel:SetTextColor(1, 1, 0)

memoryBar:RegisterEvent("PLAYER_LOGIN")

memoryBar:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        memoryBar:UnregisterEvent(event)
        for i = 1, GetNumAddOns() do
            if not addons[i] and IsAddOnLoaded(i) then
                local name = GetAddOnInfo(i)
                local memory = GetAddOnMemoryUsage(i)
                addons[#addons + 1] = { name = name, memory = memory, min = 100000, max = 0, }
            end
        end
    end
end)

memoryBar:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < PERFORMANCEBAR_UPDATE_INTERVAL then
        return
    end
    self.elapsed = 0

    UpdateMemoryUsage()
end)

memoryBar:SetScript("OnEnter", MemoryBarOnEnter)

memoryBar:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
    self.UpdateTooltip = nil
end)

memoryBar:SetScript("OnMouseDown", function()
    tSort(addons, SortByMemoryUsage)
    for i, addon in ipairs(addons) do
        local memory = FormatMemoryUsage(addon.memory)
        local minMemory = FormatMemoryUsage(addon.min)
        local maxMemory = FormatMemoryUsage(addon.max)
        ChatFrame1:AddMessage(format("%d. %s：%s (%s~%s)", i, addon.name, memory, minMemory, maxMemory), 1, 1, 0)
    end
end)
