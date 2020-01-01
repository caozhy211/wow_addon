---@type Texture
local borderTop = MinimapBorderTop
borderTop:Hide()
---@type Texture
local border = MinimapBorder
border:Hide()
---@type Button
local worldMapButton = MiniMapWorldMapButton
worldMapButton:Hide()
---@type Button
local zoomInButton = MinimapZoomIn
zoomInButton:Hide()
---@type Button
local zoomOutButton = MinimapZoomOut
zoomOutButton:Hide()

--- 使用方形小地图
Minimap:SetMaskTexture("Interface/ChatFrame/CHATFRAMEBACKGROUND")
--- 使用职业颜色着色小地图边框
Minimap:SetBackdrop({
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = 1,
})
local _, class = UnitClass("player")
Minimap:SetBackdropBorderColor(GetClassColor(class))

--- 使用滚轮缩放小地图
Minimap:EnableMouseWheel(true)
Minimap:SetScript("OnMouseWheel", function(_, value)
    if value > 0 then
        Minimap_ZoomIn()
    else
        Minimap_ZoomOut()
    end
end)
