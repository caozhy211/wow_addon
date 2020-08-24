---@type ColorMixin
local color = YELLOW_FONT_COLOR

---@type Frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:SetScript("OnEvent", function()
    local totalSellPrice = 0
    for i = 1, NUM_BAG_FRAMES do
        for j = 1, GetContainerNumSlots(i) do
            local _, count, _, quality, _, _, link = GetContainerItemInfo(i, j)
            if link then
                local sellPrice = select(11, GetItemInfo(link))
                if quality == LE_ITEM_QUALITY_POOR and sellPrice then
                    UseContainerItem(i, j)
                    totalSellPrice = totalSellPrice + sellPrice * count
                end
            end
        end
    end
    if totalSellPrice > 0 then
        ChatFrame1:AddMessage(color:WrapTextInColorCode("出售物品獲得：") .. GetMoneyString(totalSellPrice))
    end

    if CanMerchantRepair() then
        local cost, canRepair = GetRepairAllCost()
        if canRepair and cost > 0 then
            local guildRepair = false
            if IsInGuild() and CanGuildBankRepair() then
                local withdraw = GetGuildBankWithdrawMoney()
                local guildBankMoney = GetGuildBankMoney()
                withdraw = withdraw == -1 and guildBankMoney or min(withdraw, guildBankMoney)
                if withdraw >= cost then
                    RepairAllItems(true)
                    guildRepair = true
                    ChatFrame1:AddMessage(color:WrapTextInColorCode("使用公會資金" .. REPAIR_COST)
                            .. GetCoinTextureString(cost))
                end
            end
            if GetMoney() >= cost and not guildRepair then
                RepairAllItems(false)
                ChatFrame1:AddMessage(color:WrapTextInColorCode(REPAIR_COST) .. GetCoinTextureString(cost))
            end
        end
    end
end)
