local font = GameFontNormal:GetFont()
local slotNames = {
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

local listener = CreateFrame("Frame")
local tooltip = CreateFrame("GameToolTip", "MyItemInfoTooltip", UIParent, "GameTooltipTemplate")
local chatItemCache = {}

local function GetInfoFrame(button)
    if not button.info then
        local info = CreateFrame("Frame", nil, button)
        info:SetAllPoints()

        local level = info:CreateFontString()
        level:SetFont(font, 12, "Outline")
        level:SetPoint("TopLeft", -3, 2)
        level:SetTextColor(1, 1, 0)
        info.level = level

        local slot = info:CreateFontString()
        slot:SetFont(font, 12, "Outline")
        slot:SetPoint("BottomRight", 5, -2)
        info.slot = slot

        local bind = info:CreateFontString()
        bind:SetFont(font, 12, "Outline")
        bind:SetPoint("BottomLeft", -3, -2)
        bind:SetTextColor(1, 0, 0)
        info.bind = bind

        button.info = info
    end
    return button.info
end

local function SetLevelString(fontString, level)
    fontString:SetText(level)
end

local function SetSlotString(fontString, class, equipSlot, link)
    local text = ""
    if equipSlot and strfind(equipSlot, "INVTYPE_") then
        text = slotNames[equipSlot] or ""
    elseif class == ARMOR then
        text = slotNames[class]
    elseif link and IsArtifactPowerItem(link) then
        text = slotNames["ARTIFACT_POWER"]
    elseif link and IsArtifactRelicItem(link) then
        text = slotNames["RELICSLOT"]
    end
    fontString:SetText(text)
end

local function SetBindString(fontString, bind, isBound)
    fontString:SetText((bind == 2 or bind == 3) and not isBound and "裝" or "")
end

local function ScanItemTooltip(link, bagID, unit, slotID, category)
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    if bagID and slotID and (category == "Bag" or category == "AltEquipment") then
        tooltip:SetBagItem(bagID, slotID)
    elseif unit and slotID or category == "Bank" then
        tooltip:SetInventoryItem(unit, slotID)
    else
        tooltip:SetHyperlink(link)
    end

    local level, isBound
    for i = 2, 5 do
        local text = _G[tooltip:GetName() .. "TextLeft" .. i]:GetText() or ""
        if not level then
            level = strmatch(text, gsub(ITEM_LEVEL, "%%d", "(%%d+)"))
        end
        if not isBound then
            isBound = strfind(text, ITEM_SOULBOUND)
        end
    end
    return level and tonumber(level), isBound
end

local function SetItemInfo(button, link, category, bagID, slotID)
    local info = GetInfoFrame(button)
    if button.origLink == link then
        SetLevelString(info.level, button.origLevel)
        SetSlotString(info.slot, button.origClass, button.origEquipSlot, button.origLink)
        SetBindString(info.bind, button.origBind, button.origIsBound)
    else
        local level, class, equipSlot, bind, isBound, _
        if link and strmatch(link, "item:(%d+):") then
            _, _, _, _, _, class, _, _, equipSlot, _, _, _, _, bind = GetItemInfo(link)
            level, isBound = ScanItemTooltip(link, bagID, "player", slotID, category)
            SetLevelString(info.level, level or "")
            SetSlotString(info.slot, class, equipSlot, link)
            SetBindString(info.bind, bind, isBound)
        else
            SetLevelString(info.level, "")
            SetSlotString(info.slot)
            SetBindString(info.bind)
        end
        button.origLink = link
        button.origLevel = level or ""
        button.origClass = class
        button.origEquipSlot = equipSlot
        button.origBind = bind
        button.origIsBound = isBound
    end
end

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

hooksecurefunc("BankFrameItemButton_Update", function(self)
    if self.isBag then
        return
    end
    local bag = self:GetParent():GetID()
    local slot = self:GetID()
    local link = GetContainerItemLink(bag, slot)
    SetItemInfo(self, link, "Bank", nil, self:GetInventorySlot())
end)

hooksecurefunc("MerchantFrameItem_UpdateQuality", function(self, link)
    SetItemInfo(self.ItemButton, link, "Merchant")
end)

hooksecurefunc("TradeFrame_UpdatePlayerItem", function(id)
    local button = _G["TradePlayerItem" .. id .. "ItemButton"]
    local link = GetTradePlayerItemLink(id)
    SetItemInfo(button, link, "Trade")
end)

hooksecurefunc("TradeFrame_UpdateTargetItem", function(id)
    local button = _G["TradePlayerItem" .. id .. "ItemButton"]
    local link = GetTradeTargetItemLink(id)
    SetItemInfo(button, link, "Trade")
end)

hooksecurefunc("LootFrame_UpdateButton", function(index)
    local button = _G["LootButton" .. index]
    local numLootItems = LootFrame.numLootItems
    local numLootToShow = LOOTFRAME_NUMBUTTONS
    if numLootItems > LOOTFRAME_NUMBUTTONS then
        numLootToShow = numLootToShow - 1
    end
    local slot = (numLootToShow * (LootFrame.page - 1)) + index
    local link = GetLootSlotLink(slot)
    if button:IsShown() then
        SetItemInfo(button, link, "Loot")
    end
end)

if LoadAddOn("Blizzard_GuildBankUI") then
    hooksecurefunc("GuildBankFrame_Update", function()
        if GuildBankFrame.mode == "bank" then
            local tab = GetCurrentGuildBankTab()
            local button, index, column, link
            for i = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
                index = mod(i, NUM_SLOTS_PER_GUILDBANK_GROUP)
                if index == 0 then
                    index = NUM_SLOTS_PER_GUILDBANK_GROUP
                end
                column = ceil((i - 0.5) / NUM_SLOTS_PER_GUILDBANK_GROUP)
                button = _G["GuildBankColumn" .. column .. "Button" .. index]
                link = GetGuildBankItemLink(tab, i)
                SetItemInfo(button, link, "GuildBank")
            end
        end
    end)
end

if LoadAddOn("Blizzard_AuctionUI") then
    hooksecurefunc("AuctionFrameBrowse_Update", function()
        local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)
        local itemButton, link
        for i = 1, NUM_BROWSE_TO_DISPLAY do
            itemButton = _G["BrowseButton" .. i .. "Item"]
            link = GetAuctionItemLink("list", offset + i)
            if itemButton then
                SetItemInfo(itemButton, link, "Auction")
            end
        end
    end)

    hooksecurefunc("AuctionFrameBid_Update", function()
        local offset = FauxScrollFrame_GetOffset(BidScrollFrame)
        local itemButton, link
        for i = 1, NUM_BIDS_TO_DISPLAY do
            itemButton = _G["BidButton" .. i .. "Item"]
            link = GetAuctionItemLink("bidder", offset + i)
            if itemButton then
                SetItemInfo(itemButton, link, "Auction")
            end
        end
    end)

    hooksecurefunc("AuctionFrameAuctions_Update", function()
        local offset = FauxScrollFrame_GetOffset(AuctionsScrollFrame)
        local tokenCount = C_WowTokenPublic.GetNumListedAuctionableTokens()
        local itemButton, link
        for i = 1, NUM_AUCTIONS_TO_DISPLAY do
            itemButton = _G["AuctionsButton" .. i .. "Item"]
            link = GetAuctionItemLink("owner", offset - tokenCount + i)
            if itemButton then
                SetItemInfo(itemButton, link, "Auction")
            end
        end
    end)
end

if EquipmentFlyout_DisplayButton then
    hooksecurefunc("EquipmentFlyout_DisplayButton", function(button)
        local location = button.location
        if not location then
            return
        end

        local player, bank, bags, voidStorage, slot, bag = EquipmentManager_UnpackLocation(location)
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

if LoadAddOn("Blizzard_GuildUI") then
    local GuildNewsItemCache = {}
    hooksecurefunc("GuildNewsButton_SetText", function(button, _, text, text1, text2, ...)
        if text2 and type(text2) == "string" then
            local link = strmatch(text2, "|H(item:%d+:.-)|h.-|h")
            if link then
                local level = GuildNewsItemCache[link] or ScanItemTooltip(link)
                if level then
                    GuildNewsItemCache[link] = level
                    text2 = gsub(text2, "(%|Hitem:%d+:.-%|h%[)(.-)(%]%|h)", "%1" .. level .. ":%2%3")
                    button.text:SetFormattedText(text, text1, text2, ...)
                end
            end
        end
    end)
end

local function SetPaperDollItemLevel(button, unit)
    if not unit then
        return
    end
    local slotID = button:GetID()
    local info = GetInfoFrame(button)
    local level = ScanItemTooltip(nil, nil, unit, slotID)
    if not button.hasItem then
        level = ""
    end
    if level then
        SetLevelString(info.level, level)
    else
        local iterations = 0
        info:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            if self.elapsed < 0.8 then
                return
            end
            self.elapsed = 0

            SetLevelString(self.level, "...")
            level = ScanItemTooltip(nil, nil, unit, slotID)
            iterations = iterations + 1
            if level then
                SetLevelString(self.level, level)
                self:SetScript("OnUpdate", nil)
            elseif iterations == 5 then
                SetLevelString(self.level, "")
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end

hooksecurefunc("PaperDollItemSlotButton_OnShow", function(self)
    SetPaperDollItemLevel(self, "player")
end)

hooksecurefunc("PaperDollItemSlotButton_OnEvent", function(self, event, id)
    if event == "PLAYER_EQUIPMENT_CHANGED" and self:GetID() == id then
        SetPaperDollItemLevel(self, "player")
    end
end)

listener:RegisterEvent("INSPECT_READY")

listener:SetScript("OnEvent", function()
    if InspectFrame and InspectFrame.unit then
        local inspectSlots = {
            InspectHeadSlot, InspectNeckSlot, InspectShoulderSlot, InspectBackSlot, InspectChestSlot, InspectWristSlot,
            InspectHandsSlot, InspectWaistSlot, InspectLegsSlot, InspectFeetSlot, InspectFinger0Slot, InspectFinger1Slot,
            InspectTrinket0Slot, InspectTrinket1Slot, InspectMainHandSlot, InspectSecondaryHandSlot
        }

        for i = 1, #inspectSlots do
            SetPaperDollItemLevel(inspectSlots[i], InspectFrame.unit)
        end
    end
end)

local function GetItemGemInfo(itemLink)
    local total = 0
    local info = {}
    local stats = GetItemStats(itemLink)
    for key, num in pairs(stats) do
        if strfind(key, "EMPTY_SOCKET_") then
            local i = 1
            while i <= num do
                total = total + 1
                info[#info + 1] = { name = _G[key] or EMPTY, link = nil }
                i = i + 1
            end
        end
    end

    local _, _, quality = GetItemInfo(itemLink)
    if quality > 6 and total > 0 then
        total = 3
        local i = 1
        while i <= total - #info do
            info[#info + 1] = { name = RELICSLOT or EMPTY, link = nil }
            i = i + 1
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
                info[#info + 1] = { name = name, link = link }
            end
        end
    end

    return total
end

local function ChatItemInfo(hyperlink)
    if chatItemCache[hyperlink] then
        return chatItemCache[hyperlink]
    end

    local link = strmatch(hyperlink, "|H(.-)|h")
    local name, _, _, _, _, class, subclass, _, equipSlot = GetItemInfo(link)
    local level = GetDetailedItemLevelInfo(link)
    local checkGem = true
    if level then
        if equipSlot and strfind(equipSlot, "INVTYPE_") then
            level = format("%s(%s)", level, _G[equipSlot] or equipSlot)
        elseif class == ARMOR then
            level = format("%s(%s)", level, class)
        elseif subclass and strfind(subclass, RELICSLOT) then
            level = format("%s(%s)", level, RELICSLOT)
        else
            checkGem = false
        end

        if checkGem then
            local gem = ""
            local num = GetItemGemInfo(link)
            local i = 1
            while i <= num do
                gem = gem .. "|TInterface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic:0|t"
                i = i + 1
            end
            if gem ~= "" then
                gem = gem .. " "
            end

            hyperlink = gsub(hyperlink, "|h%[(.-)%]|h", "|h[" .. level .. ":" .. name .. "]|h" .. gem)
        end

        chatItemCache[hyperlink] = hyperlink
    end

    return hyperlink
end

local function filter(_, _, msg, ...)
    msg = gsub(msg, "(|Hitem:%d+:.-|h.-|h)", ChatItemInfo)
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