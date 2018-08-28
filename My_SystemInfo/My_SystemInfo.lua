local info = CreateFrame("Frame", "InfoFrame", UIParent)
info:SetWidth(120)
info:SetHeight(30)
info:SetPoint("BottomRight", UIParent, "BottomRight", -180, 40)

local text = info:CreateFontString(nil, "Overlay")
text:SetFont("Fonts\\ARHei.ttf", 14)
text:SetPoint("Right", info, "Right", 0, 5)

function text:SetColor(latency)
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
    local latencyHome = text:SetColor(select(3, GetNetStats()))
    local latencyWorld = text:SetColor(select(4, GetNetStats()))

    text:SetText(" " .. fps .. " | " .. latencyHome .. " | " .. latencyWorld .. " ")
end)