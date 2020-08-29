Minimap:SetMaskTexture("Interface/ChatFrame/CHATFRAMEBACKGROUND")
Minimap:SetBackdrop({ edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 2, })
local _, class = UnitClass("player")
Minimap:SetBackdropBorderColor(GetClassColor(class))

MinimapBorder:Hide()
MinimapBorderTop:Hide()
MiniMapWorldMapButton:Hide()
MinimapZoomIn:Hide()
MinimapZoomOut:Hide()

Minimap:EnableMouseWheel(true)
Minimap:SetScript("OnMouseWheel", function(_, delta)
    if delta > 0 then
        Minimap_ZoomIn()
    else
        Minimap_ZoomOut()
    end
end)
