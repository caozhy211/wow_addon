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
                    button.bindString:SetPoint("Center", button, "Center", 0, 0)
                    button.bindString:SetFont("Fonts\\ARHei.ttf", 12, "Outline")
                    button.bindString:SetTextColor(1, 0, 0)
                end
                button.bindString:SetText("BoE")
            elseif button.bindString then
                button.bindString:SetText("")
            end
        elseif button.bindString then
            button.bindString:SetText("")
        end
    end
end)