PlayerPowerBarAlt:SetMovable(true)
PlayerPowerBarAlt:SetUserPlaced(true)

local listener = CreateFrame("Frame")

listener:RegisterEvent("PLAYER_LOGIN")

listener:SetScript("OnEvent", function()
    PlayerPowerBarAlt:ClearAllPoints()
    PlayerPowerBarAlt:SetPoint("Bottom", 255, 330)
end)

hooksecurefunc("UnitPowerBarAltStatus_ToggleFrame", function(self)
    if self.enabled then
        self:Show()
        UnitPowerBarAltStatus_UpdateText(self)
    end
end)