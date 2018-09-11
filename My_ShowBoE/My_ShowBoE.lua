hooksecurefunc("ContainerFrame_Update", function(self)
    local bag = self:GetID()
    local name = self:GetName()
    local button, slot
    for i = 1, self.size do
        button = _G[name .. "Item" .. i]
        slot = button:GetID()
        local itemLink = GetContainerItemLink(bag, slot)
        if itemLink then
            local bindType = select(14, GetItemInfo(itemLink))

            if bindType == 2 or bindType == 3 then
                if not button.bindString then
                    button.bindString = button:CreateFontString(nil, "Artwork")
                    button.bindString:SetPoint("BottomLeft", button, "BottomLeft", -2, 2)
                    button.bindString:SetFont("Fonts\\ARHei.ttf", 9, "Outline")
                    button.bindString:SetTextColor(1, 0, 0)
                end
                button.bindString:SetText("裝\n綁")
            elseif button.bindString then
                button.bindString:SetText("")
            end
        elseif button.bindString then
            button.bindString:SetText("")
        end
    end
end)