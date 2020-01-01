---@type Frame
local borderFrame = WorldMapFrame.BorderFrame
---@type FontString
local playerLabel = borderFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
playerLabel:SetPoint("RIGHT", WorldMapFrameCloseButton, "LEFT", -40, 0)
---@type FontString
local cursorLabel = borderFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
cursorLabel:SetPoint("RIGHT", playerLabel, "LEFT", -10, 0)

---@type POIFrame
local worldMap = WorldMapFrame

---@param self POIFrame 世界地图
worldMap:HookScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < TOOLTIP_UPDATE_TIME then
        return
    end
    self.elapsed = 0

    local position = C_Map.GetPlayerMapPosition(MapUtil.GetDisplayableMapForPlayer(), "player")
    if position then
        playerLabel:SetFormattedText(PLAYER .. "：%.1f, %.1f", position.x * 100, position.y * 100)
    else
        playerLabel:SetText("")
    end

    -- 区域地图才显示坐标
    if MapUtil.IsMapTypeZone(self:GetMapID()) then
        local cx, cy = GetCursorPosition()
        ---@type ScrollFrame
        local container = worldMap.ScrollContainer
        local scale = container:GetEffectiveScale()
        local x = (cx / scale - container:GetLeft()) / container:GetWidth()
        local y = (container:GetTop() - cy / scale) / container:GetHeight()
        if x > 0 and x < 1 and y > 0 and y < 1 then
            cursorLabel:SetFormattedText("滑鼠：%.1f, %.1f", x * 100, y * 100)
        else
            cursorLabel:SetText("")
        end
    else
        cursorLabel:SetText("")
    end
end)
