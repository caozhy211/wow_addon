local font = GameFontNormal:GetFont()
local fontHeight = 13
local offset = 2
local bar = CreateFrame("Frame", "MyPerformanceBar", UIParent)
bar:SetSize(119, 45)
bar:SetPoint("BottomRight", -(298 - bar:GetWidth()), 88 - bar:GetHeight())
bar:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
bar:SetBackdropColor(0, 0, 0, 0.2)

local latencyHomeLabel = bar:CreateFontString()
latencyHomeLabel:SetFont(font, fontHeight, "Outline")
latencyHomeLabel:SetPoint("TopLeft", offset, -offset)
latencyHomeLabel:SetText("本地延遲:")

local latencyWorldLabel = bar:CreateFontString()
latencyWorldLabel:SetFont(font, fontHeight, "Outline")
latencyWorldLabel:SetPoint("Left", offset, 0)
latencyWorldLabel:SetText("世界延遲:")

local fpsLabel = bar:CreateFontString()
fpsLabel:SetFont(font, fontHeight, "Outline")
fpsLabel:SetPoint("BottomLeft", offset, offset)
fpsLabel:SetText("幀數:")

local latencyHomeValue = bar:CreateFontString()
latencyHomeValue:SetFont(font, fontHeight, "Outline")
latencyHomeValue:SetPoint("TopRight", -offset, -offset)

local latencyWorldValue = bar:CreateFontString()
latencyWorldValue:SetFont(font, fontHeight, "Outline")
latencyWorldValue:SetPoint("Right", -offset, 0)

local fpsValue = bar:CreateFontString()
fpsValue:SetFont(font, fontHeight, "Outline")
fpsValue:SetPoint("BottomRight", -offset, offset)

local function FormatLatency(latency)
    if latency < 100 then
        return "|cff00ff00" .. latency .. "ms|r"
    elseif latency < 200 then
        return "|cffffff00" .. latency .. "ms|r"
    elseif latency < 1000 then
        return "|cffff0000" .. latency .. "ms|r"
    end
    return format("|cffff0000%.2fs|r", latency / 1000)
end

bar:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 1 then
        return
    end
    self.elapsed = 0

    local fps = format("%.0f", GetFramerate())
    local _, _, latencyHome, latencyWorld = GetNetStats()

    latencyHomeValue:SetText(FormatLatency(latencyHome))
    latencyWorldValue:SetText(FormatLatency(latencyWorld))
    fpsValue:SetText(fps)
end)