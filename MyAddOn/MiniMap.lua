Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
Minimap:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
local _, class = UnitClass("player")
local color = RAID_CLASS_COLORS[class]
Minimap:SetBackdropBorderColor(color:GetRGB())

Minimap:EnableMouseWheel(true)
Minimap:SetScript("OnMouseWheel", function(_, value)
    if value > 0 then
        MinimapZoomIn:Click()
    else
        MinimapZoomOut:Click()
    end
end)

MinimapBorderTop:Hide()
MinimapBorder:Hide()
MiniMapWorldMapButton:Hide()
MinimapZoomIn:Hide()
MinimapZoomOut:Hide()