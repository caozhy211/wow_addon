local listener = CreateFrame("Frame")

listener:RegisterEvent("MERCHANT_SHOW")

listener:SetScript("OnEvent", function()
    if CanMerchantRepair() then
        local cost, canRepair = GetRepairAllCost()
        if canRepair and cost > 0 then
            local guildRepaired = false
            if IsInGuild() and CanGuildBankRepair() then
                local amount = GetGuildBankWithdrawMoney()
                local guildBankMoney = GetGuildBankMoney()
                amount = amount == -1 and guildBankMoney or min(amount, guildBankMoney)
                if amount >= cost then
                    RepairAllItems(true)
                    guildRepaired = true
                    print("裝備已使用公修修理")
                end
            end

            if cost <= GetMoney() and not guildRepaired then
                RepairAllItems(false)
                print("修理裝備花費: -" .. GetCoinTextureString(cost))
            end
        end
    end

    local totalPrice = 0
    for bag = 0, NUM_BAG_FRAMES do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local _, _, rarity, _, _, _, _, _, _, _, price = GetItemInfo(link)
                local _, count = GetContainerItemInfo(bag, slot)
                if rarity == 0 and price ~= 0 then
                    UseContainerItem(bag, slot)
                    totalPrice = totalPrice + price * count
                end
            end
        end
    end

    if totalPrice ~= 0 then
        print("出售物品獲得: +" .. GetCoinTextureString(totalPrice))
    end
end)