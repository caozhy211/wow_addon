WorldMapFrame.playerPos = WorldMapFrame.BorderFrame:CreateFontString()
WorldMapFrame.playerPos:SetFont(GameFontNormal:GetFont(), 14, "Outline")
WorldMapFrame.playerPos:SetPoint("Right", WorldMapFrameCloseButton, "Left", -40, 0)
WorldMapFrame.playerPos:SetTextColor(1, 0.82, 0.1)
WorldMapFrame.mousePos = WorldMapFrame.BorderFrame:CreateFontString()
WorldMapFrame.mousePos:SetFont(GameFontNormal:GetFont(), 14, "Outline")
WorldMapFrame.mousePos:SetPoint("Right", WorldMapFrameCloseButton, "Left", -160, 0)

WorldMapFrame:HookScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.2 then
        return
    end
    self.elapsed = 0

    -- 玩家坐標
    local position = C_Map.GetPlayerMapPosition(MapUtil.GetDisplayableMapForPlayer(), "player")
    if position then
        self.playerPos:SetText(format("玩家: %.1f, %.1f", position.x * 100, position.y * 100))
    else
        self.playerPos:SetText("")
    end

    -- 滑鼠坐標
    local mapInfo = C_Map.GetMapInfo(self:GetMapID())
    if mapInfo and mapInfo.mapType == 3 then
        local x, y = self.ScrollContainer:GetNormalizedCursorPosition()
        if x and y and x > 0 and x < 1 and y > 0 and y < 1 then
            self.mousePos:SetText(format("滑鼠: %.1f, %.1f", x * 100, y * 100))
        else
            self.mousePos:SetText("")
        end
    else
        self.mousePos:SetText("")
    end
end)