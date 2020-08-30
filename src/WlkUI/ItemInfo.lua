---@param button ItemButton
---@param color ColorMixin
local function CreateItemButtonLabel(button, position, offsetX, offsetY, color)
    ---@type FontString
    local label = button:CreateFontString(nil, "OVERLAY", "Game12Font_o1")
    label:SetPoint(position, offsetX, offsetY)
    if color then
        label:SetTextColor(color:GetRGB())
    end
    return label
end

local _, class = UnitClass("player")

local function ColorText(equipLoc, text, r, g, b)
    ---@type ColorMixin
    local color = equipLoc == "INVTYPE_2HWEAPON" and class == "WARLOCK" and HIGHLIGHT_FONT_COLOR
            or CreateColor(r, g, b)
    return color:WrapTextInColorCode(text)
end

local SHORT_INV_TYPE = {
    INVTYPE_HEAD = "頭",
    INVTYPE_NECK = "頸",
    INVTYPE_SHOULDER = "肩",
    INVTYPE_BODY = "襯",
    INVTYPE_CHEST = "胸",
    INVTYPE_ROBE = "胸",
    INVTYPE_WAIST = "腰",
    INVTYPE_LEGS = "腿",
    INVTYPE_FEET = "腳",
    INVTYPE_WRIST = "腕",
    INVTYPE_HAND = "手",
    INVTYPE_FINGER = "指",
    INVTYPE_TRINKET = "飾",
    INVTYPE_CLOAK = "背",
    INVTYPE_WEAPON = "單",
    INVTYPE_SHIELD = "副",
    INVTYPE_2HWEAPON = "雙",
    INVTYPE_WEAPONMAINHAND = "主",
    INVTYPE_WEAPONOFFHAND = "副",
    INVTYPE_HOLDABLE = "副",
    INVTYPE_RANGED = "遠",
    INVTYPE_RANGEDRIGHT = "遠",
    INVTYPE_TABARD = "袍",
}

local SHORT_SUBCLASS = {
    [LE_ITEM_CLASS_WEAPON] = {
        [LE_ITEM_WEAPON_AXE1H] = "斧",
        [LE_ITEM_WEAPON_AXE2H] = "斧",
        [LE_ITEM_WEAPON_BOWS] = "弓",
        [LE_ITEM_WEAPON_GUNS] = "槍",
        [LE_ITEM_WEAPON_MACE1H] = "錘",
        [LE_ITEM_WEAPON_MACE2H] = "錘",
        [LE_ITEM_WEAPON_POLEARM] = "柄",
        [LE_ITEM_WEAPON_SWORD1H] = "劍",
        [LE_ITEM_WEAPON_SWORD2H] = "劍",
        [LE_ITEM_WEAPON_WARGLAIVE] = "刃",
        [LE_ITEM_WEAPON_STAFF] = "法",
        [LE_ITEM_WEAPON_UNARMED] = "拳",
        [LE_ITEM_WEAPON_DAGGER] = "匕",
        [LE_ITEM_WEAPON_CROSSBOW] = "弩",
        [LE_ITEM_WEAPON_WAND] = "魔",
        [LE_ITEM_WEAPON_FISHINGPOLE] = "漁",
    },
    [LE_ITEM_CLASS_ARMOR] = {
        [LE_ITEM_ARMOR_CLOTH] = "布",
        [LE_ITEM_ARMOR_LEATHER] = "皮",
        [LE_ITEM_ARMOR_MAIL] = "鎖",
        [LE_ITEM_ARMOR_PLATE] = "鎧",
        [LE_ITEM_ARMOR_COSMETIC] = "型",
        [LE_ITEM_ARMOR_SHIELD] = "盾",
    },
}

---@type GameTooltip
local scanner = CreateFrame("GameTooltip", "WlkItemInfoScanner", UIParent, "GameTooltipTemplate")

local function GetItemInfoText(link, levelOnly, short, scanFunc, ...)
    local topLeftText, bottomLeftText, topRightText, bottomRightText
    local _, _, quality, _, _, _, subtype, _, equipLoc, _, _, classId, subclassId, bindType = GetItemInfo(link)

    if classId == LE_ITEM_CLASS_WEAPON or classId == LE_ITEM_CLASS_ARMOR then
        local level, bind, invType, subclass

        if quality ~= LE_ITEM_QUALITY_HEIRLOOM then
            level = GetDetailedItemLevelInfo(link)
            if levelOnly then
                return level
            end
        end
        scanner:SetOwner(UIParent, "ANCHOR_NONE")
        if scanFunc then
            scanner[scanFunc](scanner, ...)
        else
            scanner:SetHyperlink(link)
        end
        for i = 2, min(9, scanner:NumLines()) do
            ---@type FontString
            local label = _G[scanner:GetName() .. "TextLeft" .. i]
            local text = label:GetText()
            if text then
                if not level then
                    level = strmatch(text, gsub(ITEM_LEVEL, "%%d", "(%%d+)"))
                            or strmatch(text, gsub(ITEM_LEVEL_ALT, "%%d%(%%d%)", "%%d+%%%(%(%%d+%)%%%)"))
                    if level and levelOnly then
                        return level
                    end
                else
                    if not bind then
                        bind = bindType ~= LE_ITEM_BIND_ON_EQUIP or strmatch(text, ITEM_SOULBOUND)
                    end
                    if text == _G[equipLoc] then
                        invType = short and ColorText(equipLoc, SHORT_INV_TYPE[equipLoc], label:GetTextColor())
                                or _G[equipLoc]
                        label = _G[scanner:GetName() .. "TextRight" .. i]
                        if label and label:GetText() then
                            subclass = short and ColorText(equipLoc, SHORT_SUBCLASS[classId][subclassId],
                                    label:GetTextColor()) or subtype
                        end
                        break
                    end
                end
            end
        end

        topLeftText = level
        bottomLeftText = not bind and "裝"
        if classId == LE_ITEM_CLASS_ARMOR and subclassId == LE_ITEM_ARMOR_SHIELD or classId == LE_ITEM_CLASS_WEAPON then
            topRightText = invType
            bottomRightText = subclass
        else
            topRightText = subclass
            bottomRightText = invType
        end
    end

    return topLeftText, bottomLeftText, topRightText, bottomRightText
end

local function AddInfoToItemButton(button, link, scanFunc, ...)
    button.topLeftLabel = button.topLeftLabel or CreateItemButtonLabel(button, "TOPLEFT", -3, 1, YELLOW_FONT_COLOR)
    button.bottomLeftLabel = button.bottomLeftLabel or CreateItemButtonLabel(button, "BOTTOMLEFT", -3, -1,
            GREEN_FONT_COLOR)
    button.topRightLabel = button.topRightLabel or CreateItemButtonLabel(button, "TOPRIGHT", 3, 1)
    button.bottomRightLabel = button.bottomRightLabel or CreateItemButtonLabel(button, "BOTTOMRIGHT", 3, -1)

    local topLeftText, bottomLeftText, topRightText, bottomRightText
    if link then
        if button.originalLink == link then
            topLeftText = button.topLeftText
            bottomLeftText = button.bottomLeftText
            topRightText = button.topRightText
            bottomRightText = button.bottomRightText
        else
            button.originalLink = link
            topLeftText, bottomLeftText, topRightText, bottomRightText = GetItemInfoText(link, false, true, scanFunc,
                    ...)
            button.topLeftText = topLeftText
            button.bottomLeftText = bottomLeftText
            button.topRightText = topRightText
            button.bottomRightText = bottomRightText
        end
    end

    button.topLeftLabel:SetText(topLeftText or "")
    button.bottomLeftLabel:SetText(bottomLeftText or "")
    button.topRightLabel:SetText(topRightText or "")
    button.bottomRightLabel:SetText(bottomRightText or "")
end

---@param self Frame
hooksecurefunc("ContainerFrame_Update", function(self)
    local bagId = self:GetID()
    for i = 1, self.size do
        ---@type ItemButton
        local button = _G[self:GetName() .. "Item" .. i]
        local slotId = button:GetID()
        local link = GetContainerItemLink(bagId, slotId)
        AddInfoToItemButton(button, link, "SetBagItem", bagId, slotId)
    end
end)

---@param button ItemButton
hooksecurefunc("BankFrameItemButton_Update", function(button)
    if button.isBag then
        return
    end
    ---@type Frame
    local container = button:GetParent()
    local link = GetContainerItemLink(container:GetID(), button:GetID())
    AddInfoToItemButton(button, link, "SetInventoryItem", "player", ButtonInventorySlot(button))
end)

hooksecurefunc("MerchantFrameItem_UpdateQuality", function(self, link)
    ---@type ItemButton
    local button = self.ItemButton
    if button == MerchantBuyBackItemItemButton then
        AddInfoToItemButton(button, link, "SetBuybackItem", GetNumBuybackItems())
    elseif MerchantFrame.selectedTab == 1 then
        AddInfoToItemButton(button, link)
    else
        AddInfoToItemButton(button, link, "SetBuybackItem", strmatch(button:GetName(), "(%d+)"))
    end
end)

hooksecurefunc("EquipmentFlyout_DisplayButton", function(button)
    local location = button.location
    if not location then
        return
    end
    local _, _, bags, _, slotId, arg = EquipmentManager_UnpackLocation(location)
    if bags then
        local link = GetContainerItemLink(arg, slotId)
        AddInfoToItemButton(button, link, "SetBagItem", arg, slotId)
    else
        local link = GetInventoryItemLink("player", slotId)
        AddInfoToItemButton(button, link, "SetInventoryItem", "player", slotId)
    end
end)

hooksecurefunc("TradeFrame_UpdatePlayerItem", function(id)
    local button = _G["TradePlayerItem" .. id .. "ItemButton"]
    local link = GetTradePlayerItemLink(id)
    AddInfoToItemButton(button, link)
end)

hooksecurefunc("TradeFrame_UpdateTargetItem", function(id)
    local button = _G["TradeRecipientItem" .. id .. "ItemButton"]
    local link = GetTradeTargetItemLink(id)
    AddInfoToItemButton(button, link)
end)

hooksecurefunc("InboxFrame_Update", function()
    for i = 1, INBOXITEMS_TO_DISPLAY do
        local button = _G["MailItem" .. i .. "Button"]
        if button.hasItem then
            local link = select(15, GetInboxHeaderInfo(button.index))
            AddInfoToItemButton(button, link)
        end
    end
end)

hooksecurefunc("OpenMail_Update", function()
    if not InboxFrame.openMailID then
        return
    end
    if OpenMailFrame.activeAttachmentButtons then
        for i, button in ipairs(OpenMailFrame.activeAttachmentButtons) do
            local link = GetInboxItemLink(InboxFrame.openMailID, i)
            AddInfoToItemButton(button, link)
        end
    end
end)

hooksecurefunc("SendMailFrame_Update", function()
    for i = 1, ATTACHMENTS_MAX_SEND do
        local button = SendMailFrame.SendMailAttachments[i]
        local link = GetSendMailItemLink(i)
        AddInfoToItemButton(button, link)
    end
end)

hooksecurefunc("GuildBankFrame_Update", function()
    if GuildBankFrame.mode == "bank" then
        local tab = GetCurrentGuildBankTab()
        for i = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
            local index = i % NUM_SLOTS_PER_GUILDBANK_GROUP
            if index == 0 then
                index = NUM_SLOTS_PER_GUILDBANK_GROUP
            end
            local column = ceil((i - 0.5) / NUM_SLOTS_PER_GUILDBANK_GROUP)
            local button = _G[strconcat("GuildBankColumn", column, "Button", index)]
            local link = GetGuildBankItemLink(tab, i)
            AddInfoToItemButton(button, link)
        end
    end
end)

local VOID_DEPOSIT_MAX = 9
local VOID_WITHDRAW_MAX = 9
local VOID_STORAGE_MAX = 80

local function AddInfoToVoidStorageButtons()
    for i = 1, VOID_STORAGE_MAX do
        local button = _G["VoidStorageStorageButton" .. i]
        if button.hasItem then
            local _, link = GetItemInfo(GetVoidItemInfo(VoidStorageFrame.page, i))
            AddInfoToItemButton(button, link, "SetVoidItem", VoidStorageFrame.page, i)
        else
            AddInfoToItemButton(button)
        end
    end
end

hooksecurefunc("VoidStorage_ItemsUpdate", function(doDeposit, doContents)
    if doDeposit then
        for i = 1, VOID_DEPOSIT_MAX do
            local button = _G["VoidStorageDepositButton" .. i]
            if button.hasItem then
                local _, link = GetItemInfo(GetVoidTransferDepositInfo(i))
                AddInfoToItemButton(button, link, "SetVoidDepositItem", i)
            else
                AddInfoToItemButton(button)
            end
        end
    end
    if doContents then
        for i = 1, VOID_WITHDRAW_MAX do
            local button = _G["VoidStorageWithdrawButton" .. i]
            if button.hasItem then
                local _, link = GetItemInfo(GetVoidTransferWithdrawalInfo(i))
                AddInfoToItemButton(button, link, "SetVoidWithdrawalItem", i)
            else
                AddInfoToItemButton(button)
            end
        end
        AddInfoToVoidStorageButtons()
    end
end)

hooksecurefunc("VoidStorage_SetPageNumber", AddInfoToVoidStorageButtons)

---@param button ItemButton
local function AddInfoToPaperDollButton(button, unit)
    local slotId = button:GetID()
    local link = GetInventoryItemLink(unit, slotId)
    button.levelLabel = button.levelLabel or CreateItemButtonLabel(button, "TOPLEFT", -3, 1, YELLOW_FONT_COLOR)
    button.levelLabel:SetText(link and GetItemInfoText(link, true, true, "SetInventoryItem", unit, slotId) or "")
end

hooksecurefunc("PaperDollItemSlotButton_OnShow", function(self)
    AddInfoToPaperDollButton(self, "player")
end)

hooksecurefunc("PaperDollItemSlotButton_OnEvent", function(self, event, ...)
    if event == "PLAYER_EQUIPMENT_CHANGED" then
        local equipmentSlot = ...
        if self:GetID() == equipmentSlot then
            AddInfoToPaperDollButton(self, "player")
        end
    end
end)

local INSPECT_BUTTON_NAMES = {
    "InspectHeadSlot", "InspectNeckSlot", "InspectShoulderSlot", "InspectBackSlot", "InspectChestSlot",
    "InspectShirtSlot", "InspectTabardSlot", "InspectWristSlot", "InspectHandsSlot", "InspectWaistSlot",
    "InspectLegsSlot", "InspectFeetSlot", "InspectFinger0Slot", "InspectFinger1Slot", "InspectTrinket0Slot",
    "InspectTrinket1Slot", "InspectMainHandSlot", "InspectSecondaryHandSlot", }

local function AddInfoToInspectPaperDollButtons()
    for _, buttonName in ipairs(INSPECT_BUTTON_NAMES) do
        AddInfoToPaperDollButton(_G[buttonName], InspectFrame.unit)
    end
end

---@type Frame
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("INSPECT_READY")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if not InspectFrame then
        return
    end
    if event == "INSPECT_READY" then
        local guid = ...
        if InspectFrame.unit and (UnitGUID(InspectFrame.unit) == guid) then
            AddInfoToInspectPaperDollButtons()
        end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        if InspectFrame.unit and unit == InspectFrame.unit then
            AddInfoToInspectPaperDollButtons()
        end
    end
end)

---@type ItemButton[]
local highestPriceButtons = {}

---@param self Frame
local function AddInfoToQuestRewardButton(self)
    local questLog = self == MapQuestInfoRewardsFrame
    local highestPrice = 0
    wipe(highestPriceButtons)
    ---@param button ItemButton
    for _, button in ipairs(self.RewardButtons) do
        if not button:IsShown() then
            break
        end
        local id = button:GetID()
        if button.type == "choice" then
            local link = questLog and GetQuestLogItemLink("choice", id) or GetQuestItemLink("choice", id)
            local numItems = questLog and select(3, GetQuestLogChoiceInfo(id))
                    or select(3, GetQuestItemInfo("choice", id))
            local sellPrice = link and select(11, GetItemInfo(link)) or 0
            local price = sellPrice * numItems
            if price > highestPrice then
                highestPrice = price
                wipe(highestPriceButtons)
                highestPriceButtons[1] = button
            elseif price == highestPrice then
                highestPriceButtons[#highestPriceButtons + 1] = button
            end
        end
        if button.objectType == "item" then
            local link = questLog and GetQuestLogItemLink(button.type, id) or GetQuestItemLink(button.type, id)
            AddInfoToItemButton(button, link)
            ---@type FontString
            local label = button.topLeftLabel
            label:SetPoint("TOPLEFT", button.IconBorder, -6, 1)
            label = button.topRightLabel
            label:SetPoint("TOPRIGHT", button.IconBorder, 6, 1)
            label = button.bottomRightLabel
            label:SetPoint("BOTTOMRIGHT", button.IconBorder, 6, -1)
        else
            AddInfoToItemButton(button)
        end
        ---@type Texture
        local icon = button.highestPriceIcon
        if icon then
            icon:Hide()
        end
    end

    local numChoice = questLog and GetNumQuestLogChoices() or GetNumQuestChoices()
    if numChoice > 1 then
        for _, button in ipairs(highestPriceButtons) do
            ---@type Texture
            local icon = button.highestPriceIcon
            if not icon then
                icon = button:CreateTexture()
                button.highestPriceIcon = icon
                icon:SetAtlas("bags-junkcoin", true)
                icon:SetPoint("TOPRIGHT")
            else
                icon:Show()
            end
        end
    end
end

hooksecurefunc(MapQuestInfoRewardsFrame, "Show", AddInfoToQuestRewardButton)
hooksecurefunc(QuestInfoRewardsFrame, "Show", AddInfoToQuestRewardButton)

local linkCaches = {}
local gemsTable = {}
local statsTable = {}
local socketsTable = {}
local EMPTY_SOCKETS = {
    EMPTY_SOCKET_BLUE = "UI-EmptySocket-Blue",
    EMPTY_SOCKET_COGWHEEL = "UI-EMPTYSOCKET-COGWHEEL",
    EMPTY_SOCKET_HYDRAULIC = "UI-EMPTYSOCKET-HYDRAULIC",
    EMPTY_SOCKET_META = "UI-EMPTYSOCKET-META",
    EMPTY_SOCKET_NO_COLOR = "UI-EMPTYSOCKET",
    EMPTY_SOCKET_PRISMATIC = "UI-EmptySocket-Prismatic",
    EMPTY_SOCKET_PUNCHCARDBLUE = "UI-EmptySocket-PunchcardBlue",
    EMPTY_SOCKET_PUNCHCARDRED = "UI-EmptySocket-PunchcardRed",
    EMPTY_SOCKET_PUNCHCARDYELLOW = "UI-EmptySocket-PunchcardYellow",
    EMPTY_SOCKET_RED = "UI-EmptySocket-Red",
    EMPTY_SOCKET_YELLOW = "UI-EmptySocket-Yellow",
}
local tConcat = table.concat

local function GetPathFromFileId(fileId)
    ---@type Frame
    local frame = CreateFrame("Frame")
    ---@type Texture
    local texture = frame:CreateTexture()
    texture:SetTexture(fileId)
    return texture:GetTexture()
end

local function GetSocketInfoText(link)
    wipe(gemsTable)
    wipe(statsTable)
    wipe(socketsTable)
    GetItemStats(link, statsTable)
    for key, value in pairs(statsTable) do
        if EMPTY_SOCKETS[key] then
            for _ = 1, value do
                socketsTable[#socketsTable + 1] = key
            end
        end
    end
    for i, socket in ipairs(socketsTable) do
        local _, gemLink = GetItemGem(link, i)
        local gemId = gemLink and GetItemInfoFromHyperlink(gemLink)
        local socketText = gemId and GetPathFromFileId(GetItemIcon(gemId))
                or ("Interface/ItemSocketingFrame/" .. EMPTY_SOCKETS[socket])
        gemsTable[#gemsTable + 1] = "|T" .. socketText .. ":0|t"
    end
    if #socketsTable > 0 then
        gemsTable[#gemsTable + 1] = " "
    end
    return tConcat(gemsTable)
end

local replacementTable = {}

local function AddInfoToItemLink(link)
    if linkCaches[link] then
        return linkCaches[link]
    end
    wipe(replacementTable)
    replacementTable[#replacementTable + 1] = "%1"
    local level, bind, subclass, invType = GetItemInfoText(link)
    if level then
        replacementTable[#replacementTable + 1] = level
    end
    if bind then
        replacementTable[#replacementTable + 1] = "(裝綁)"
    end
    if subclass and invType then
        replacementTable[#replacementTable + 1] = format("(%s/%s)", subclass, invType)
    elseif subclass or invType then
        replacementTable[#replacementTable + 1] = "(" .. (subclass or invType) .. ")"
    end
    if level or bind or subclass or invType then
        replacementTable[#replacementTable + 1] = ": "
    end
    replacementTable[#replacementTable + 1] = "%2"
    replacementTable[#replacementTable + 1] = GetSocketInfoText(link)
    linkCaches[link] = gsub(link, "(|h%[)(.-%]|h)", tConcat(replacementTable))
    return linkCaches[link]
end

local function FilterChatMessage(_, _, message, ...)
    message = gsub(message, "|Hitem:%d+:.-|h.-|h", AddInfoToItemLink)
    return false, message, ...
end

local chatFiltersEvents = {
    "CHAT_MSG_BN_WHISPER",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_COMMUNITIES_CHANNEL",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_GUILD_ITEM_LOOTED",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_LOOT",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_SAY",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_YELL",
}

for _, event in ipairs(chatFiltersEvents) do
    ChatFrame_AddMessageEventFilter(event, FilterChatMessage)
end
