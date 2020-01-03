---@type Frame
local eventListener = CreateFrame("Frame")

eventListener:RegisterEvent("MERCHANT_SHOW")

eventListener:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_SHOW" then
        if CanMerchantRepair() then
            -- 修理装备
            local cost, canRepair = GetRepairAllCost()
            if canRepair and cost > 0 then
                local guildRepaired = false
                if IsInGuild() and CanGuildBankRepair() then
                    -- 可以从公会银行提取的资金
                    local amount = GetGuildBankWithdrawMoney()
                    -- 公会资金
                    local guildBankMoney = GetGuildBankMoney()
                    -- 会长可以使用所有公会资金
                    amount = amount == -1 and guildBankMoney or min(amount, guildBankMoney)
                    if amount >= cost then
                        -- 使用公会资金修理
                        RepairAllItems(true)
                        guildRepaired = true
                        print("裝備已使用公會資金修理")
                    end
                end
                -- 使用自己的钱修理
                if GetMoney() >= cost and not guildRepaired then
                    RepairAllItems(false)
                    print(REPAIR_COST .. GetCoinTextureString(cost))
                end
            end
        end

        local totalPrice = 0
        for bagID = 0, NUM_BAG_FRAMES do
            for slot = 1, GetContainerNumSlots(bagID) do
                local link = GetContainerItemLink(bagID, slot)
                if link then
                    local _, _, rarity, _, _, _, _, _, _, _, price = GetItemInfo(link)
                    local _, count = GetContainerItemInfo(bagID, slot)
                    if rarity == LE_ITEM_QUALITY_POOR and price > 0 then
                        -- 出售垃圾物品
                        UseContainerItem(bagID, slot)
                        totalPrice = totalPrice + price * count
                    end
                end
            end
        end
        if totalPrice > 0 then
            print("出售物品獲得：" .. GetCoinTextureString(totalPrice))
        end
    end
end)
