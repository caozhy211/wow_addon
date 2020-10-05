---@type ColorMixin
local YELLOW_FONT_COLOR = YELLOW_FONT_COLOR

local poorItems = {}
local totalValue = 0

---@type Frame
local listener = CreateFrame("Frame")

local function onSoldOut()
    listener:Hide()
    if totalValue > 0 then
        ChatFrame1:AddMessage(YELLOW_FONT_COLOR:WrapTextInColorCode("出售垃圾物品獲得: ") .. GetMoneyString(totalValue))
        totalValue = 0
    end
end

listener:Hide()
listener:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.2 then
        return
    end
    self.elapsed = 0

    local item = poorItems[1]
    if item then
        local bag, slot, value = unpack(item)
        UseContainerItem(bag, slot)
        totalValue = totalValue + value
        tremove(poorItems, 1)
    else
        onSoldOut()
    end
end)
listener:RegisterEvent("MERCHANT_SHOW")
listener:RegisterEvent("MERCHANT_CLOSED")
listener:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_SHOW" then
        wipe(poorItems)
        for bag = 0, NUM_BAG_FRAMES do
            for slot = 1, GetContainerNumSlots(bag) do
                local _, count, _, quality, _, _, link = GetContainerItemInfo(bag, slot)
                if link then
                    local price = select(11, GetItemInfo(link))
                    if quality == Enum.ItemQuality.Poor and price then
                        tinsert(poorItems, { bag, slot, price * count, })
                    end
                end
            end
        end
        listener:Show()

        if CanMerchantRepair() then
            local cost, canRepair = GetRepairAllCost()
            if canRepair and cost > 0 then
                local repaired = false
                if IsInGuild() and CanGuildBankRepair() then
                    local withdraw = GetGuildBankWithdrawMoney()
                    local guildBankMoney = GetGuildBankMoney()
                    local amount = withdraw == -1 and guildBankMoney or min(withdraw, guildBankMoney)
                    if amount >= cost then
                        RepairAllItems(true)
                        repaired = true
                        ChatFrame1:AddMessage(YELLOW_FONT_COLOR:WrapTextInColorCode("使用公會資金修理所有裝備花費: ")
                                .. GetMoneyString(cost))
                    else
                        ChatFrame1:AddMessage(YELLOW_FONT_COLOR:WrapTextInColorCode("公會資金不足, 無法修理所有裝備!"))
                    end
                end
                if not repaired then
                    if GetMoney() >= cost then
                        RepairAllItems()
                        ChatFrame1:AddMessage(YELLOW_FONT_COLOR:WrapTextInColorCode("修理所有裝備花費: ")
                                .. GetMoneyString(cost))
                    else
                        ChatFrame1:AddMessage(YELLOW_FONT_COLOR:WrapTextInColorCode("餘額不足, 無法修理所有裝備!"))
                    end
                end
            end
        end
    elseif event == "MERCHANT_CLOSED" then
        onSoldOut()
    end
end)
