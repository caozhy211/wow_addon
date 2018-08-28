local UNDERCUT = 0.97; -- 壓價3%
local PRICEBY = "VENDOR"; -- 拍賣行沒有該物品時的定價方式，QUALITY：按品質定價，VENDOR：按商店售價定價

-- 基於物品品質定價，10000 = 1金
local POOR_PRICE = 100000;
local COMMON_PRICE = 200000;
local UNCOMMON_PRICE = 3000000;
local RARE_PRICE = 5000000;
local EPIC_PRICE = 10000000;

-- 基於商店售價定價，商店售價 * 物品品質係數
local POOR_MULTIPLIER = 20;
local COMMON_MULTIPLIER = 30;
local UNCOMMON_MULTIPLIER = 40;
local RARE_MULTIPLIER = 50;
local EPIC_MULTIPLIER = 60;

local auction = CreateFrame("Frame")
auction:RegisterEvent("AUCTION_HOUSE_SHOW")
auction:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")

local selectedItem -- 拍賣物品
local selectedItemVendorPrice -- 商店售價
local selectedItemQuality -- 品質
local currentPage = 0 -- 當前頁數
local myBuyoutPrice, myStartPrice -- 我的直購價，我的起始價
local myName = UnitName("player")

auction:SetScript("OnEvent", function(self, event)
    if event == "AUCTION_HOUSE_SHOW" then
        AuctionFrameAuctions.tip = AuctionFrameAuctions:CreateFontString(nil, "Artwork")
        AuctionFrameAuctions.tip:SetFont("Fonts\\ARHei.ttf", 14, "ThinOutline")
        AuctionFrameAuctions.tip:SetJustifyH("Left")
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
                -- 獲取拍賣物品信息
                selectedItem, _, _, _, _, _, _, _, _, _ = GetAuctionSellItemInfo()
                local canQuery = CanSendAuctionQuery()

                -- 根據物品名稱在拍賣行查找
                if canQuery and selectedItem then
                    ResetCursor()
                    QueryAuctionItems(selectedItem)
                end
            end
        end)
        -- 拍賣行列表更新或排序
    elseif event == "AUCTION_ITEM_LIST_UPDATE" then
        -- 拍賣物品欄有物品
        if (selectedItem ~= nil) then
            local batch, totalAuctions = GetNumAuctionItems("list")
            local totalPageCount = floor(totalAuctions / 50)
            local exactMatch = false

            -- 掃描當前頁
            for i = 1, batch do
                local postedItem, _, count, _, _, _, _, minBid, _,
                buyoutPrice, _, _, _, owner = GetAuctionItemInfo("list", i)

                -- 拍賣行列表中的物品與拍賣物品完全匹配，沒有直購價時buyoutPrice爲0
                if postedItem == selectedItem and owner ~= myName and buyoutPrice > 0 then
                    exactMatch = true

                    if myBuyoutPrice == nil and myStartPrice == nil then
                        myBuyoutPrice = (buyoutPrice / count) * UNDERCUT
                        myStartPrice = (minBid / count) * UNDERCUT
                    elseif myBuyoutPrice > (buyoutPrice / count) then
                        myBuyoutPrice = (buyoutPrice / count) * UNDERCUT
                        myStartPrice = (minBid / count) * UNDERCUT
                    end
                end
            end

            if currentPage < totalPageCount then
                AuctionFrameAuctions.tip:SetText("掃描中... " .. currentPage .. " / " .. totalPageCount)

                -- 下一頁
                self:SetScript("OnUpdate", function(self, elapsed)
                    self.elapsed = (self.elapsed or 0) + elapsed
                    if self.elapsed < 0.2 then
                        return
                    end
                    self.elapsed = 0

                    selectedItem = GetAuctionSellItemInfo()
                    local canQuery = CanSendAuctionQuery()

                    -- 檢查拍賣行的下一頁
                    if canQuery then
                        currentPage = currentPage + 1
                        QueryAuctionItems(selectedItem, nil, nil, currentPage)
                        self:SetScript("OnUpdate", nil)
                    end
                end)

                -- 已掃描所有頁面
            else
                if exactMatch then
                    AuctionFrameAuctions.tip:SetText("定價完成")
                else
                    -- 拍賣行沒有該物品的直購價

                    -- 獲取物品品質和商店售價
                    _, _, selectedItemQuality, _, _, _, _, _, _, _, selectedItemVendorPrice = GetItemInfo(selectedItem)

                    if PRICEBY == "QUALITY" then
                        if selectedItemQuality == 0 then
                            myBuyoutPrice = POOR_PRICE
                        end
                        if selectedItemQuality == 1 then
                            myBuyoutPrice = COMMON_PRICE
                        end
                        if selectedItemQuality == 2 then
                            myBuyoutPrice = UNCOMMON_PRICE
                        end
                        if selectedItemQuality == 3 then
                            myBuyoutPrice = RARE_PRICE
                        end
                        if selectedItemQuality == 4 then
                            myBuyoutPrice = EPIC_PRICE
                        end
                        AuctionFrameAuctions.tip:SetText("拍賣行沒有該物品的直購價，按物品品質定價")
                    elseif PRICEBY == "VENDOR" then
                        if selectedItemQuality == 0 then
                            myBuyoutPrice = selectedItemVendorPrice * POOR_MULTIPLIER
                        end
                        if selectedItemQuality == 1 then
                            myBuyoutPrice = selectedItemVendorPrice * COMMON_MULTIPLIER
                        end
                        if selectedItemQuality == 2 then
                            myBuyoutPrice = selectedItemVendorPrice * UNCOMMON_MULTIPLIER
                        end
                        if selectedItemQuality == 3 then
                            myBuyoutPrice = selectedItemVendorPrice * RARE_MULTIPLIER
                        end
                        if selectedItemQuality == 4 then
                            myBuyoutPrice = selectedItemVendorPrice * EPIC_MULTIPLIER
                        end
                        AuctionFrameAuctions.tip:SetText("拍賣行沒有該物品的直購價，按商店售價定價")
                    end

                    myStartPrice = myBuyoutPrice
                end

                self:SetScript("OnUpdate", nil)
                local stackSize = AuctionsStackSizeEntry:GetNumber()

                if myStartPrice ~= nil then

                    -- 物品堆疊
                    if stackSize > 1 then

                        -- 每一個價格
                        if UIDropDownMenu_GetSelectedValue(PriceDropDown) == 1 then
                            MoneyInputFrame_SetCopper(StartPrice, myStartPrice)
                            MoneyInputFrame_SetCopper(BuyoutPrice, myBuyoutPrice)
                            -- 每一疊價格
                        else
                            MoneyInputFrame_SetCopper(StartPrice, myStartPrice * stackSize)
                            MoneyInputFrame_SetCopper(BuyoutPrice, myBuyoutPrice * stackSize)
                        end
                        -- 沒有堆疊
                    else
                        MoneyInputFrame_SetCopper(StartPrice, myStartPrice)
                        MoneyInputFrame_SetCopper(BuyoutPrice, myBuyoutPrice)
                    end

                end

                local startPrice = myStartPrice
                local buyoutPrice = myBuyoutPrice
                AuctionsStackSizeEntry:HookScript("OnTextChanged", function()
                    local stacks = AuctionsStackSizeEntry:GetNumber()
                    MoneyInputFrame_SetCopper(StartPrice, startPrice * stacks)
                    MoneyInputFrame_SetCopper(BuyoutPrice, buyoutPrice * stacks)
                end)

                myBuyoutPrice = nil
                myStartPrice = nil
                currentPage = 0
                selectedItem = nil
                stackSize = nil
            end
        end
    end
end)