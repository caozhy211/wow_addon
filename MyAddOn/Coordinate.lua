local font = GameFontNormal:GetFont()

local player = WorldMapFrame.BorderFrame:CreateFontString()
player:SetFont(font, 14, "Outline")
player:SetPoint("Right", WorldMapFrameCloseButton, "Left", -40, 0)
player:SetTextColor(1, 1, 0)

local mouse = WorldMapFrame.BorderFrame:CreateFontString()
mouse:SetFont(font, 14, "Outline")
mouse:SetPoint("Right", player, "Left", -10, 0)

WorldMapFrame:HookScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.2 then
        return
    end
    self.elapsed = 0

    local position = C_Map.GetPlayerMapPosition(MapUtil.GetDisplayableMapForPlayer(), "player")
    if position then
        player:SetFormattedText("玩家: %.1f, %.1f", position.x * 100, position.y * 100)
    else
        player:SetText("")
    end

    local mapInfo = C_Map.GetMapInfo(self:GetMapID())
    if mapInfo and mapInfo.mapType == 3 then
        local x, y = self.ScrollContainer:GetNormalizedCursorPosition()
        if x and y and x > 0 and x < 1 and y > 0 and y < 1 then
            mouse:SetFormattedText("滑鼠: %.1f, %.1f", x * 100, y * 100)
        else
            mouse:SetText("")
        end
    else
        mouse:SetText("")
    end
end)