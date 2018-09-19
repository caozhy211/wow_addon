local f = CreateFrame("Frame")

f:RegisterEvent("MERCHANT_SHOW")

f:SetScript("OnEvent", function()
    local totalPrice = 0
    for myBags = 0, 4 do
        for bagSlots = 1, GetContainerNumSlots(myBags) do
            local CurrentItemLink = GetContainerItemLink(myBags, bagSlots)
            if CurrentItemLink then
                local _, _, itemRarity, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(CurrentItemLink)
                local _, itemCount = GetContainerItemInfo(myBags, bagSlots)
                if itemRarity == 0 and itemSellPrice ~= 0 then
                    UseContainerItem(myBags, bagSlots)
                    totalPrice = totalPrice + itemSellPrice * itemCount
                end
            end
        end
    end

    if totalPrice ~= 0 then
        DEFAULT_CHAT_FRAME:AddMessage("出售物品获得: +" .. GetCoinTextureString(totalPrice), 255, 255, 255)
    end
end)