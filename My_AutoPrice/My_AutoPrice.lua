local UNDERCUT = 0.97; -- 壓價3%
local PRICE_BY = "VENDOR"; -- 拍賣行沒有該物品時的定價方式，QUALITY：按品質定價，VENDOR：按商店售價定價

-- 基於物品品質定價，10000 = 1金
local priceByQuality = { 100000, 200000, 3000000, 5000000, 10000000, }

-- 基於商店售價定價，商店售價 * 物品品質係數
local priceByVendor = { 20, 30, 40, 50, 60, }

-- 拍賣物品
local selectedItem
-- 當前頁數
local currentPage = 0
-- 我的直購價
local myBuyoutPrice
-- 我的起始價
local myStartPrice
-- 是否匹配到有直購價的物品
local exactMatch

local f = CreateFrame("Frame")

f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")

f:SetScript("OnEvent", function(self, event)
    if event == "AUCTION_HOUSE_SHOW" then
        AuctionFrameAuctions.tip = AuctionFrameAuctions:CreateFontString()
        AuctionFrameAuctions.tip:SetFont(GameFontNormal:GetFont(), 14)
        AuctionFrameAuctions.tip:SetPoint("Left", AuctionFrameMoneyFrame, "Right", 5, 0)
        AuctionFrameAuctions.tip:SetTextColor(1, 1, 0)

        AuctionsItemButton:HookScript("OnEvent", function(self, event)
            -- 放置物品拍賣
            if event == "NEW_AUCTION_UPDATE" then
                AuctionFrameAuctions.tip:SetText("")

                self:SetScript("OnUpdate", nil)

                myBuyoutPrice = nil
                myStartPrice = nil
                currentPage = 0
                selectedItem = nil
                exactMatch = false

                -- 獲取拍賣物品信息
                selectedItem = GetAuctionSellItemInfo()
                -- 根據物品名稱在拍賣行查找
                if CanSendAuctionQuery() and selectedItem then
                    ResetCursor()
                    QueryAuctionItems(selectedItem)
                end
            end
        end)
        -- 拍賣行列表更新或排序且拍賣物品欄有物品
    elseif event == "AUCTION_ITEM_LIST_UPDATE" and selectedItem then
        local batch, totalAuctions = GetNumAuctionItems("list")
        local totalPageCount = floor(totalAuctions / 50)

        -- 掃描當前頁
        for i = 1, batch do
            local postedItem, _, count, _, _, _, _, minBid, _, buyoutPrice, _, _, _, owner = GetAuctionItemInfo("list", i)

            -- 拍賣行列表中不是自己的物品與拍賣物品完全匹配且有直購價
            if postedItem == selectedItem and owner ~= UnitName("player") and buyoutPrice > 0 then
                exactMatch = true

                -- 更新拍賣價格
                if (not myBuyoutPrice and not myStartPrice) or myBuyoutPrice > buyoutPrice / count then
                    myBuyoutPrice = buyoutPrice / count * UNDERCUT
                    myStartPrice = minBid / count * UNDERCUT
                end
            end
        end

        -- 掃描其它頁
        if currentPage < totalPageCount then
            AuctionFrameAuctions.tip:SetText("掃描中... " .. currentPage .. " / " .. totalPageCount)

            -- 下一頁
            self:SetScript("OnUpdate", function(self, elapsed)
                self.elapsed = (self.elapsed or 0) + elapsed
                if self.elapsed < 0.1 then
                    return
                end
                self.elapsed = 0

                selectedItem = GetAuctionSellItemInfo()
                -- 檢查拍賣行的下一頁
                if CanSendAuctionQuery() then
                    currentPage = currentPage + 1
                    QueryAuctionItems(selectedItem, nil, nil, currentPage)
                    self:SetScript("OnUpdate", nil)
                end
            end)
            -- 已掃描所有頁面
        else
            self:SetScript("OnUpdate", nil)

            if exactMatch then
                AuctionFrameAuctions.tip:SetText("定價完成")
                -- 拍賣行沒有該物品的直購價
            else
                -- 獲取物品品質和商店售價
                local _, _, selectedItemQuality, _, _, _, _, _, _, _, selectedItemVendorPrice = GetItemInfo(selectedItem)

                -- 更新拍賣價格
                if PRICE_BY == "QUALITY" then
                    myBuyoutPrice = priceByQuality[selectedItemQuality + 1]
                    AuctionFrameAuctions.tip:SetText("拍賣行沒有該物品的直購價，按物品品質定價")
                else
                    myBuyoutPrice = selectedItemVendorPrice * priceByVendor[selectedItemQuality + 1]
                    AuctionFrameAuctions.tip:SetText("拍賣行沒有該物品的直購價，按商店售價定價")
                end

                myStartPrice = myBuyoutPrice
            end

            local stackSize = AuctionsStackSizeEntry:GetNumber()
            if myStartPrice then
                -- price有小數時SetCopper可能會計算錯誤
                myStartPrice = ceil(myStartPrice)
                myBuyoutPrice = ceil(myBuyoutPrice)

                if UIDropDownMenu_GetSelectedValue(PriceDropDown) == 1 then
                    MoneyInputFrame_SetCopper(StartPrice, myStartPrice)
                    MoneyInputFrame_SetCopper(BuyoutPrice, myBuyoutPrice)
                else
                    MoneyInputFrame_SetCopper(StartPrice, myStartPrice * stackSize)
                    MoneyInputFrame_SetCopper(BuyoutPrice, myBuyoutPrice * stackSize)
                end
            end

            -- 根據堆疊數量改變價格
            local startPrice = myStartPrice
            local buyoutPrice = myBuyoutPrice
            AuctionsStackSizeEntry:HookScript("OnTextChanged", function(self)
                local stacks = self:GetNumber()
                if UIDropDownMenu_GetSelectedValue(PriceDropDown) == 1 then
                    MoneyInputFrame_SetCopper(StartPrice, startPrice)
                    MoneyInputFrame_SetCopper(BuyoutPrice, buyoutPrice)
                else
                    MoneyInputFrame_SetCopper(StartPrice, startPrice * stacks)
                    MoneyInputFrame_SetCopper(BuyoutPrice, buyoutPrice * stacks)
                end
            end)
        end
    end
end)