local undercut = 0.97
local priceByQuality = { 100000, 200000, 3000000, 5000000, 10000000, }
local priceByVendor = { 20, 30, 40, 50, 60, }
local priceBy = "vendor"
local item, current, start, buyout, isMatch, tips
local listener = CreateFrame("Frame")

local function QueryItem()
    item = GetAuctionSellItemInfo()
    if CanSendAuctionQuery() and item then
        if current > 0 then
            listener:SetScript("OnUpdate", nil)
        end
        QueryAuctionItems(item, nil, nil, current)
        current = current + 1
    end
end

local function OnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.3 then
        return
    end
    self.elapsed = 0

    QueryItem()
end

local function ScanCurrentPage(num)
    listener:SetScript("OnUpdate", nil)

    for i = 1, num do
        local name, _, count, _, _, _, _, minBid, _, buyoutPrice, _, _, _, owner = GetAuctionItemInfo("list", i)

        if name == item and owner ~= UnitName("player") and buyoutPrice > 0 then
            isMatch = true

            if (not buyout and not start) or buyout > buyoutPrice / count then
                buyout = buyoutPrice / count * undercut
                start = minBid / count * undercut
            end
        end
    end
end

local function SetCopper()
    local stack = AuctionsStackSizeEntry:GetNumber()
    local isPriceByEveryOne = UIDropDownMenu_GetSelectedValue(PriceDropDown) == 1
    MoneyInputFrame_SetCopper(StartPrice, start * (isPriceByEveryOne and 1 or stack))
    MoneyInputFrame_SetCopper(BuyoutPrice, buyout * (isPriceByEveryOne and 1 or stack))
end

local function ConfirmPrice()
    if isMatch then
        tips:SetText("定價完成")
    else
        local _, _, quality, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(item)
        if priceBy == "quality" then
            buyout = priceByQuality[quality + 1]
            tips:SetText("拍賣行沒有該物品的直購價，按物品品質定價")
        else
            buyout = vendorPrice * priceByVendor[quality + 1]
            tips:SetText("拍賣行沒有該物品的直購價，按商店售價定價")
        end
        start = buyout
    end
    start = ceil(start)
    buyout = ceil(buyout)
end

if LoadAddOn("Blizzard_AuctionUI") then
    tips = AuctionFrameAuctions:CreateFontString()
    tips:SetFont(GameFontNormal:GetFont(), 14, "Outline")
    tips:SetPoint("Left", AuctionFrameMoneyFrame, "Right", 5, 0)
    tips:SetTextColor(1, 1, 0)

    AuctionsItemButton:HookScript("OnEvent", function(_, event)
        if event == "NEW_AUCTION_UPDATE" then
            tips:SetText("")
            start = nil
            buyout = nil
            item = nil
            isMatch = nil
            current = 0
            listener:SetScript("OnUpdate", OnUpdate)
        end
    end)

    AuctionsStackSizeEntry:HookScript("OnTextChanged", function()
        if not buyout then
            return
        end
        SetCopper()
    end)

    AuctionFrameAuctions:HookScript("OnShow", function()
        if not item or not current then
            return
        end
        current = current - 1
        QueryItem()
    end)
end

listener:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")

listener:SetScript("OnEvent", function(self)
    if not item or not current or not AuctionFrameAuctions:IsShown() then
        return
    end

    local numBatch, totalAuctions = GetNumAuctionItems("list")
    local total = ceil(totalAuctions / NUM_AUCTION_ITEMS_PER_PAGE)
    ScanCurrentPage(numBatch)
    if current < total then
        tips:SetText(current == 0 and "" or "掃描中... " .. current .. " / " .. total)
        self:SetScript("OnUpdate", OnUpdate)
    else
        self:SetScript("OnUpdate", nil)
        current = nil
        ConfirmPrice()
        SetCopper()
    end
end)