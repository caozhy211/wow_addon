local abbrevSlot = {
    INVTYPE_HEAD = "頭",
    INVTYPE_NECK = "頸",
    INVTYPE_SHOULDER = "肩",
    INVTYPE_CLOAK = "背",
    INVTYPE_CHEST = "胸",
    INVTYPE_ROBE = "胸",
    INVTYPE_BODY = "襯",
    INVTYPE_TABARD = "袍",
    INVTYPE_WRIST = "腕",
    INVTYPE_HAND = "手",
    INVTYPE_WAIST = "腰",
    INVTYPE_LEGS = "腿",
    INVTYPE_FEET = "腳",
    INVTYPE_FINGER = "指",
    INVTYPE_TRINKET = "飾",
    INVTYPE_WEAPON = "單",
    INVTYPE_2HWEAPON = "雙",
    INVTYPE_RANGED = "遠",
    INVTYPE_RANGEDRIGHT = "遠",
    INVTYPE_WEAPONMAINHAND = "主",
    INVTYPE_WEAPONOFFHAND = "副",
    INVTYPE_THROWN = "擲",
    INVTYPE_HOLDABLE = "副",
    INVTYPE_SHIELD = "盾",
    ARMOR = "甲",
    ARTIFACT_POWER = "神",
    RELICSLOT = "聖",
}

local function GetItemInfoFrame(self, category)
    if (not self.itemInfoFrame) then
        self.itemInfoFrame = CreateFrame("Frame", nil, self)
        self.itemInfoFrame:SetSize(self:GetSize())
        self.itemInfoFrame:SetPoint("CENTER")

        self.itemInfoFrame.levelString = self.itemInfoFrame:CreateFontString(nil, "OVERLAY")
        self.itemInfoFrame.levelString:SetFont(GameFontNormal:GetFont(), 12, "Outline")
        self.itemInfoFrame.levelString:SetPoint("TopLeft", -3, 2)
        self.itemInfoFrame.levelString:SetTextColor(1, 0.82, 0)

        self.itemInfoFrame.slotString = self.itemInfoFrame:CreateFontString(nil, "OVERLAY")
        self.itemInfoFrame.slotString:SetFont(GameFontNormal:GetFont(), 12, "Outline")
        self.itemInfoFrame.slotString:SetPoint("BottomRight", 5, -2)
        self.itemInfoFrame.slotString:SetTextColor(1, 1, 1)

        self.itemInfoFrame.bindString = self.itemInfoFrame:CreateFontString(nil, "OVERLAY")
        self.itemInfoFrame.bindString:SetFont(GameFontNormal:GetFont(), 12, "Outline")
        self.itemInfoFrame.bindString:SetPoint("BottomLeft", -3, -2)
        self.itemInfoFrame.bindString:SetTextColor(1, 0, 0)
    end

    return self.itemInfoFrame
end

local function SetLevelString(self, text)
    self:SetText(text)
end

local function SetSlotString(self, class, equipSlot, link)
    local text = ""
    if equipSlot and equipSlot:find("INVTYPE_") then
        text = abbrevSlot[equipSlot] or ""
    elseif class == ARMOR then
        text = abbrevSlot[class]
    elseif link and IsArtifactPowerItem(link) then
        text = abbrevSlot["ARTIFACT_POWER"]
    elseif link and IsArtifactRelicItem(link) then
        text = abbrevSlot["RELICSLOT"]
    end
    self:SetText(text)
end

local function SetBindString(self, bind)
    self:SetText((bind == 2 or bind == 3) and "裝" or "")
end

local scanTip = CreateFrame("GameToolTip", "ScanItemTooltip", UIParent, "GameTooltipTemplate")

local function GetItemLevel(link, bagId, unit, slotId, category, quality)
    if (bagId and slotId and (category == "Bag" or category == "AltEquipment") and (quality == 7 or quality == 6)) then
        scanTip:SetOwner(UIParent, "ANCHOR_NONE")
        scanTip:SetBagItem(bagId, slotId)
    elseif unit and slotId then
        scanTip:SetOwner(UIParent, "ANCHOR_NONE")
        scanTip:SetInventoryItem(unit, slotId)
    else
        scanTip:SetOwner(UIParent, "ANCHOR_NONE")
        scanTip:SetHyperlink(link)
    end

    for i = 2, 5 do
        local text = _G["ScanItemTooltipTextLeft" .. i]:GetText() or ""
        local level = text:match(gsub(ITEM_LEVEL, "%%d", "(%%d+)"))
        if level then
            return tonumber(level)
        end
    end

    return 0
end

local function SetItemInfo(self, link, category, bagId, slotId)
    local frame = GetItemInfoFrame(self, category)
    if self.link == link then
        SetLevelString(frame.levelString, self.level)
        SetSlotString(frame.slotString, self.class, self.equipSlot, self.link)
        SetBindString(frame.bindString, self.bind)
    else
        local level, class, equipSlot, bind, quality
        if link and link:match("item:(%d+):") then
            _, _, quality, _, _, class, _, _, equipSlot, _, _, _, _, bind = GetItemInfo(link)
            level = GetItemLevel(link, bagId, nil, slotId, category, quality)

            SetLevelString(frame.levelString, level > 0 and level or "")
            SetSlotString(frame.slotString, class, equipSlot, link)
            SetBindString(frame.bindString, bind)
        else
            SetLevelString(frame.levelString, "")
            SetSlotString(frame.slotString)
            SetBindString(frame.bindString)
        end

        self.link = link
        self.level = (level and level > 0) and level or ""
        self.class = class
        self.equipSlot = equipSlot
        self.bind = bind
    end
end

-- 背包
hooksecurefunc("ContainerFrame_Update", function(self)
    local bag = self:GetID()
    local name = self:GetName()
    local button, slot, link
    for i = 1, self.size do
        button = _G[name .. "Item" .. i]
        slot = button:GetID()
        link = GetContainerItemLink(bag, slot)
        SetItemInfo(button, link, "Bag", bag, slot)
    end
end)

-- 銀行
hooksecurefunc("BankFrameItemButton_Update", function(self)
    if (self.isBag) then
        return
    end
    SetItemInfo(self, GetContainerItemLink(self:GetParent():GetID(), self:GetID()), "Bank")
end)

-- 商人
hooksecurefunc("MerchantFrameItem_UpdateQuality", function(self, link)
    SetItemInfo(self.ItemButton, link, "Merchant")
end)

-- 交易
hooksecurefunc("TradeFrame_UpdatePlayerItem", function(id)
    SetItemInfo(_G["TradePlayerItem" .. id .. "ItemButton"], GetTradePlayerItemLink(id), "Trade")
end)
hooksecurefunc("TradeFrame_UpdateTargetItem", function(id)
    SetItemInfo(_G["TradeRecipientItem" .. id .. "ItemButton"], GetTradeTargetItemLink(id), "Trade")
end)

-- 拾取
hooksecurefunc("LootFrame_UpdateButton", function(index)
    local button = _G["LootButton" .. index]
    local numLootItems = LootFrame.numLootItems
    local numLootToShow = LOOTFRAME_NUMBUTTONS
    if (numLootItems > LOOTFRAME_NUMBUTTONS) then
        numLootToShow = numLootToShow - 1
    end
    local slot = (numLootToShow * (LootFrame.page - 1)) + index
    if (button:IsShown()) then
        SetItemInfo(button, GetLootSlotLink(slot), "Loot")
    end
end)

-- 公會銀行
if LoadAddOn("Blizzard_GuildBankUI") then
    hooksecurefunc("GuildBankFrame_Update", function()
        if (GuildBankFrame.mode == "bank") then
            local tab = GetCurrentGuildBankTab()
            local button, index, column
            for i = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
                index = mod(i, NUM_SLOTS_PER_GUILDBANK_GROUP)
                if (index == 0) then
                    index = NUM_SLOTS_PER_GUILDBANK_GROUP
                end
                column = ceil((i - 0.5) / NUM_SLOTS_PER_GUILDBANK_GROUP)
                button = _G["GuildBankColumn" .. column .. "Button" .. index]
                SetItemInfo(button, GetGuildBankItemLink(tab, i), "GuildBank")
            end
        end
    end)
end

-- 拍賣行
if LoadAddOn("Blizzard_AuctionUI") then
    hooksecurefunc("AuctionFrameBrowse_Update", function()
        local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)
        local itemButton
        for i = 1, NUM_BROWSE_TO_DISPLAY do
            itemButton = _G["BrowseButton" .. i .. "Item"]
            if (itemButton) then
                SetItemInfo(itemButton, GetAuctionItemLink("list", offset + i), "Auction")
            end
        end
    end)
    hooksecurefunc("AuctionFrameBid_Update", function()
        local offset = FauxScrollFrame_GetOffset(BidScrollFrame)
        local itemButton
        for i = 1, NUM_BIDS_TO_DISPLAY do
            itemButton = _G["BidButton" .. i .. "Item"]
            if (itemButton) then
                SetItemInfo(itemButton, GetAuctionItemLink("bidder", offset + i), "Auction")
            end
        end
    end)
    hooksecurefunc("AuctionFrameAuctions_Update", function()
        local offset = FauxScrollFrame_GetOffset(AuctionsScrollFrame)
        local tokenCount = C_WowTokenPublic.GetNumListedAuctionableTokens()
        local itemButton
        for i = 1, NUM_AUCTIONS_TO_DISPLAY do
            itemButton = _G["AuctionsButton" .. i .. "Item"]
            if itemButton then
                SetItemInfo(itemButton, GetAuctionItemLink("owner", offset - tokenCount + i), "Auction")
            end
        end
    end)
end

-- 裝備選擇
if EquipmentFlyout_DisplayButton then
    hooksecurefunc("EquipmentFlyout_DisplayButton", function(button)
        local location = button.location
        if not location then
            return
        end

        local player, bank, bags, voidStorage, slot, bag, tab, voidSlot = EquipmentManager_UnpackLocation(location)
        if (not player and not bank and not bags and not voidStorage) or voidStorage then
            SetItemInfo(button)
            return
        end

        local link
        if bags then
            link = GetContainerItemLink(bag, slot)
            SetItemInfo(button, link, "AltEquipment", bag, slot)
        else
            link = GetInventoryItemLink("player", slot)
            SetItemInfo(button, link, "AltEquipment")
        end
    end)
end

-- 公會新聞
local GuildNewsItemCache = {}
if LoadAddOn("Blizzard_GuildUI") then
    hooksecurefunc("GuildNewsButton_SetText", function(button, text_color, text, text1, text2, ...)
        if text2 and type(text2) == "string" then
            local link = string.match(text2, "|H(item:%d+:.-)|h.-|h")
            if link then
                local level = GuildNewsItemCache[link] or GetItemLevel(link)
                if level > 0 then
                    GuildNewsItemCache[link] = level
                    text2 = text2:gsub("(%|Hitem:%d+:.-%|h%[)(.-)(%]%|h)", "%1" .. level .. ":%2%3")
                    button.text:SetFormattedText(text, text1, text2, ...)
                end
            end
        end
    end)
end

-- 角色欄顯示物品等級
local function SetPaperDollItemLevel(self, unit)
    local slotId = self:GetID()
    local frame = GetItemInfoFrame(self, "PaperDoll")
    local level = GetItemLevel(nil, nil, unit, slotId)
    SetLevelString(frame.levelString, level > 0 and level or "")
end

hooksecurefunc("PaperDollItemSlotButton_OnShow", function(self)
    SetPaperDollItemLevel(self, "player")
end)

hooksecurefunc("PaperDollItemSlotButton_OnEvent", function(self, event, id, ...)
    if (event == "PLAYER_EQUIPMENT_CHANGED" and self:GetID() == id) then
        SetPaperDollItemLevel(self, "player")
    end
end)

local f = CreateFrame("Frame")

f:RegisterEvent("INSPECT_READY")

f:SetScript("OnEvent", function(self, event)
    if InspectFrame and InspectFrame.unit then
        for _, button in pairs({
            InspectHeadSlot, InspectNeckSlot, InspectShoulderSlot, InspectBackSlot, InspectChestSlot, InspectWristSlot,
            InspectHandsSlot, InspectWaistSlot, InspectLegsSlot, InspectFeetSlot, InspectFinger0Slot, InspectFinger1Slot,
            InspectTrinket0Slot, InspectTrinket1Slot, InspectMainHandSlot, InspectSecondaryHandSlot
        }) do
            SetPaperDollItemLevel(button, InspectFrame.unit)
        end
    end
end)

-- 聊天框
local caches = {}

local function GetItemGemInfo(itemLink)
    local total = 0
    local info = {}
    local stats = GetItemStats(itemLink)
    for key, num in pairs(stats) do
        if key:find("EMPTY_SOCKET_") then
            for i = 1, num do
                total = total + 1
                table.insert(info, { name = _G[key] or EMPTY, link = nil })
            end
        end
    end

    local _, _, quality = GetItemInfo(itemLink)
    if quality > 6 and total > 0 then
        total = 3
        for i = 1, total - #info do
            table.insert(info, { name = RELICSLOT or EMPTY, link = nil })
        end
    end

    local name, link
    for i = 1, 4 do
        name, link = GetItemGem(itemLink, i)
        if link then
            if link[i] then
                info[i].name = name
                info[i].link = link
            else
                table.insert(info, { name = name, link = link })
            end
        end
    end

    return total, info
end

local function ChatItemInfo(hyperlink)
    if caches[hyperlink] then
        return caches[hyperlink]
    end

    local link = hyperlink:match("|H(.-)|h")
    local name, _, _, _, _, class, subclass, _, equipSlot = GetItemInfo(link)
    local level = GetItemLevel(link)
    local checkGem = true
    if level then
        if equipSlot and equipSlot:find("INVTYPE_") then
            level = format("%s(%s)", level, _G[equipSlot] or equipSlot)
        elseif class == ARMOR then
            level = format("%s(%s)", level, class)
        elseif subclass and subclass:find(RELICSLOT) then
            level = format("%s(%s)", level, RELICSLOT)
        else
            checkGem = false
        end

        if checkGem then
            local gem = ""
            local num, info = GetItemGemInfo(link)
            for i = 1, num do
                gem = gem .. "|TInterface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic:0|t"
            end
            if gem ~= "" then
                gem = gem .. " "
            end

            hyperlink = hyperlink:gsub("|h%[(.-)%]|h", "|h[" .. level .. ":" .. name .. "]|h" .. gem)
        end

        caches[hyperlink] = hyperlink
    end

    return hyperlink
end

local function filter(self, event, msg, ...)
    msg = msg:gsub("(|Hitem:%d+:.-|h.-|h)", ChatItemInfo)
    return false, msg, ...
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BATTLEGROUND", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", filter)