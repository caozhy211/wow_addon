MinimapBorder:Hide()

MinimapBorderTop:Hide()

MiniMapWorldMapButton:Hide()

MinimapZoomIn:Hide()

MinimapZoomOut:Hide()

Mixin(Minimap, BackdropTemplateMixin)

Minimap:SetMaskTexture("Interface/Buttons/WHITE8X8")
Minimap:SetBackdrop({ edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 2, })
Minimap:SetBackdropBorderColor(GetClassColor(select(2, UnitClass("player"))))
Minimap:EnableMouseWheel(true)
Minimap:SetScript("OnMouseWheel", function(_, delta)
    if delta > 0 then
        Minimap_ZoomIn()
    else
        Minimap_ZoomOut()
    end
end)
