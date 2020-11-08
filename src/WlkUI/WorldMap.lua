local coordinateLabel = WorldMapFrame.BorderFrame:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med1")

coordinateLabel:SetPoint("RIGHT", WorldMapFrame.BorderFrame.MaximizeMinimizeFrame, "LEFT", -5, 0)

WorldMapFrame:HookScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.2 then
        return
    end
    self.elapsed = 0

    if WorldMapFrame.ScrollContainer:IsMouseOver() then
        local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
        if x and y and x >= 0 and y >= 0 then
            coordinateLabel:SetFormattedText("(%.1f, %.1f)", x * 100, y * 100)
        else
            coordinateLabel:SetText("")
        end
    else
        coordinateLabel:SetText("")
    end
end)

WorldMapFrame.BorderFrame.coordinateLabel = coordinateLabel
