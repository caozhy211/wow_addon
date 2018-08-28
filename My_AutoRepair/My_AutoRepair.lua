local f = CreateFrame("Frame")
f:RegisterEvent("MERCHANT_SHOW")
f:SetScript("OnEvent", function(self, event)
    if (CanMerchantRepair()) then
        local repairAllCost, canRepair = GetRepairAllCost()
        if (canRepair and repairAllCost > 0) then
            -- 使用公會修理
            local guildRepairedItems = false
            if (IsInGuild() and CanGuildBankRepair()) then
                -- 檢查公會是否有足夠的錢
                local amount = GetGuildBankWithdrawMoney()
                local guildBankMoney = GetGuildBankMoney()
                amount = amount == -1 and guildBankMoney or min(amount, guildBankMoney)
                if (amount >= repairAllCost) then
                    RepairAllItems(true)
                    guildRepairedItems = true
                    DEFAULT_CHAT_FRAME:AddMessage("装备已使用公修修理", 255, 255, 255)
                end
            end

            -- 使用自己的錢修理
            if (repairAllCost <= GetMoney() and not guildRepairedItems) then
                RepairAllItems(false)
                DEFAULT_CHAT_FRAME:AddMessage("修理装备花费: -" .. GetCoinTextureString(repairAllCost), 255, 255, 255)
            end
        end
    end
end)