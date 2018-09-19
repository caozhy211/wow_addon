local info = CreateFrame("Frame", "InfoFrame", UIParent)

info:SetWidth(120)
info:SetHeight(30)
info:SetPoint("BottomRight", -180, 40)

local text = info:CreateFontString(nil, "Overlay")
text:SetFont(GameFontNormal:GetFont(), 14)
text:SetPoint("Right", 0, 5)

local function SetColor(latency)
    if latency < 100 then
        return "|cff00ff00" .. latency .. "|r"
    elseif latency < 200 then
        return "|cffffff00" .. latency .. "|r"
    end
    return "|cffff0000" .. latency .. "|r"
end

info:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 1 then
        return
    end
    self.elapsed = 0

    local fps = format("%.0f", GetFramerate())
    local _, _, latencyHome, latencyWorld = GetNetStats()
    latencyHome = SetColor(latencyHome)
    latencyWorld = SetColor(latencyWorld)

    text:SetText(" " .. fps .. " | " .. latencyHome .. " | " .. latencyWorld .. " ")
end)