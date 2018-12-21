local font = GameFontNormal:GetFont()
local fontHeight = 13
local offset = 2
local frame = CreateFrame("Frame", "MyPerformanceFrame", UIParent)
frame:SetSize(119, 45)
frame:SetPoint("BottomRight", -(298 - frame:GetWidth()), 88 - frame:GetHeight())
frame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
frame:SetBackdropColor(0, 0, 0, 0.2)

local latencyHomeLabel = frame:CreateFontString()
latencyHomeLabel:SetFont(font, fontHeight, "Outline")
latencyHomeLabel:SetPoint("TopLeft", offset, -offset)
latencyHomeLabel:SetText("本地延遲:")

local latencyWorldLabel = frame:CreateFontString()
latencyWorldLabel:SetFont(font, fontHeight, "Outline")
latencyWorldLabel:SetPoint("Left", offset, 0)
latencyWorldLabel:SetText("世界延遲:")

local fpsLabel = frame:CreateFontString()
fpsLabel:SetFont(font, fontHeight, "Outline")
fpsLabel:SetPoint("BottomLeft", offset, offset)
fpsLabel:SetText("幀數:")

local latencyHomeValue = frame:CreateFontString()
latencyHomeValue:SetFont(font, fontHeight, "Outline")
latencyHomeValue:SetPoint("TopRight", -offset, -offset)

local latencyWorldValue = frame:CreateFontString()
latencyWorldValue:SetFont(font, fontHeight, "Outline")
latencyWorldValue:SetPoint("Right", -offset, 0)

local fpsValue = frame:CreateFontString()
fpsValue:SetFont(font, fontHeight, "Outline")
fpsValue:SetPoint("BottomRight", -offset, offset)

local function FormatLatency(latency)
    if latency < 100 then
        return "|cff00ff00%dms|r", latency
    elseif latency < 200 then
        return "|cffffff00%dms|r", latency
    elseif latency < 1000 then
        return "|cffff0000%dms|r", latency
    end
    return "|cffff0000%.2fs|r", latency / 1000
end

frame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 1 then
        return
    end
    self.elapsed = 0

    local fps = format("%.0f", GetFramerate())
    local _, _, latencyHome, latencyWorld = GetNetStats()

    latencyHomeValue:SetFormattedText(FormatLatency(latencyHome))
    latencyWorldValue:SetFormattedText(FormatLatency(latencyWorld))
    fpsValue:SetText(fps)
end)