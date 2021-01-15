local _, class = UnitClass("player")
local SHORT_INV_TYPE = {
    INVTYPE_HEAD = "頭", INVTYPE_NECK = "頸", INVTYPE_SHOULDER = "肩", INVTYPE_BODY = "襯", INVTYPE_CHEST = "胸",
    INVTYPE_ROBE = "胸", INVTYPE_WAIST = "腰", INVTYPE_LEGS = "腿", INVTYPE_FEET = "腳", INVTYPE_WRIST = "腕",
    INVTYPE_HAND = "手", INVTYPE_FINGER = "指", INVTYPE_TRINKET = "飾", INVTYPE_CLOAK = "背", INVTYPE_WEAPON = "單",
    INVTYPE_SHIELD = "副", INVTYPE_2HWEAPON = "雙", INVTYPE_WEAPONMAINHAND = "主", INVTYPE_WEAPONOFFHAND = "副",
    INVTYPE_HOLDABLE = "副", INVTYPE_RANGED = "遠", INVTYPE_RANGEDRIGHT = "遠", INVTYPE_TABARD = "袍",
}
local SHORT_SUBCLASS = {
    [LE_ITEM_CLASS_WEAPON] = {
        [LE_ITEM_WEAPON_AXE1H] = "斧", [LE_ITEM_WEAPON_AXE2H] = "斧", [LE_ITEM_WEAPON_BOWS] = "弓",
        [LE_ITEM_WEAPON_GUNS] = "槍", [LE_ITEM_WEAPON_MACE1H] = "錘", [LE_ITEM_WEAPON_MACE2H] = "錘",
        [LE_ITEM_WEAPON_POLEARM] = "柄", [LE_ITEM_WEAPON_SWORD1H] = "劍", [LE_ITEM_WEAPON_SWORD2H] = "劍",
        [LE_ITEM_WEAPON_WARGLAIVE] = "刃", [LE_ITEM_WEAPON_STAFF] = "法", [LE_ITEM_WEAPON_UNARMED] = "拳",
        [LE_ITEM_WEAPON_DAGGER] = "匕", [LE_ITEM_WEAPON_CROSSBOW] = "弩", [LE_ITEM_WEAPON_WAND] = "魔",
        [LE_ITEM_WEAPON_FISHINGPOLE] = "漁",
    },
    [LE_ITEM_CLASS_ARMOR] = {
        [LE_ITEM_ARMOR_CLOTH] = "布", [LE_ITEM_ARMOR_LEATHER] = "皮", [LE_ITEM_ARMOR_MAIL] = "鎖",
        [LE_ITEM_ARMOR_PLATE] = "鎧", [LE_ITEM_ARMOR_COSMETIC] = "型", [LE_ITEM_ARMOR_SHIELD] = "盾",
    },
}
local ITEM_LEVEL_REGEX = gsub(ITEM_LEVEL, "%%d", "(%%d+)")
local ITEM_LEVEL_ALT_REGEX = gsub(ITEM_LEVEL_ALT, "%%d%(%%d%)", "%%d+%%((%%d+)%%)")
local VOID_DEPOSIT_MAX = 9
local VOID_WITHDRAW_MAX = 9
local VOID_STORAGE_MAX = 80
local INSPECT_BUTTON_NAMES = {
    "InspectHeadSlot", "InspectNeckSlot", "InspectShoulderSlot", "InspectBackSlot", "InspectChestSlot",
    "InspectShirtSlot", "InspectTabardSlot", "InspectWristSlot", "InspectHandsSlot", "InspectWaistSlot",
    "InspectLegsSlot", "InspectFeetSlot", "InspectFinger0Slot", "InspectFinger1Slot", "InspectTrinket0Slot",
    "InspectTrinket1Slot", "InspectMainHandSlot", "InspectSecondaryHandSlot", }
---@type WlkItemButton[]
local highestValueButtons = {}
local linkCaches = {}
local gemsTable = {}
local statsTable = {}
local socketsTable = {}
local replacementTable = {}
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
local chatFiltersEvents = {
    "CHAT_MSG_BN_WHISPER", "CHAT_MSG_CHANNEL", "CHAT_MSG_COMMUNITIES_CHANNEL", "CHAT_MSG_GUILD",
    "CHAT_MSG_GUILD_ITEM_LOOTED", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_LOOT",
    "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_SAY", "CHAT_MSG_WHISPER", "CHAT_MSG_YELL",
}
local scannerName = "WlkItemButtonScanner"

---@type GameTooltip
local scanner = CreateFrame("GameTooltip", scannerName, UIParent, "GameTooltipTemplate")
---@type Frame
local listener = CreateFrame("Frame")

---@param button ItemButton
local function createLabel(button, point, xOffset, yOffset, color)
    local label = button:CreateFontString(nil, "OVERLAY", "Game12Font_o1")
    label:SetPoint(point, xOffset, yOffset)
    if color then
        label:SetTextColor(GetTableColor(color))
    end
    return label
end

local function colorText(equipLocation, text, r, g, b)
    ---@type ColorMixin
    local color = class == "WARLOCK" and equipLocation == "INVTYPE_2HWEAPON" and HIGHLIGHT_FONT_COLOR
            or CreateColor(r, g, b)
    return color:WrapTextInColorCode(text)
end

local function getItemInfo(link, levelOnly, short, scanFunc, ...)
    local level, boe, invType, subclass
    local _, _, quality, _, _, _, subtype, _, equipLoc, _, _, classId, subclassId, bindType = GetItemInfo(link)
    if (classId == LE_ITEM_CLASS_WEAPON or classId == LE_ITEM_CLASS_ARMOR) and quality ~= Enum.ItemQuality.Heirloom then
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
    for i = 2, min(10, scanner:NumLines()) do
        ---@type FontString
        local label = _G[scannerName .. "TextLeft" .. i]
        local text = label:GetText()
        if text == RETRIEVING_ITEM_INFO then
            return "..."
        end
        if not level then
            level = strmatch(text, ITEM_LEVEL_ALT_REGEX) or strmatch(text, ITEM_LEVEL_REGEX)
            if level and levelOnly then
                return level
            end
        else
            if not boe then
                boe = bindType == LE_ITEM_BIND_ON_EQUIP and text == ITEM_BIND_ON_EQUIP
            end
            if text == _G[equipLoc] then
                invType = short and colorText(equipLoc, SHORT_INV_TYPE[equipLoc], label:GetTextColor())
                        or _G[equipLoc]
                label = _G[scannerName .. "TextRight" .. i]
                if label and label:GetText() then
                    subclass = short and colorText(equipLoc, SHORT_SUBCLASS[classId][subclassId],
                            label:GetTextColor()) or subtype
                end
                break
            end
        end
    end
    if classId == LE_ITEM_CLASS_ARMOR and subclassId == LE_ITEM_ARMOR_SHIELD or classId == LE_ITEM_CLASS_WEAPON then
        return level, boe and "裝", invType, subclass
    end
    return level, boe and "裝", subclass, invType
end

---@param button WlkItemButton
local function showInfoOnItemButton(button, link, scanFunc, ...)
    local tlText, blText, trText, brText
    if link then
        if button.originalLink == link then
            tlText = button.tlText
            blText = button.blText
            trText = button.trText
            brText = button.brText
        else
            tlText, blText, trText, brText = getItemInfo(link, false, true, scanFunc, ...)
            if tlText == "..." then
                local args = { ... }
                C_Timer.After(0.1, function()
                    showInfoOnItemButton(button, link, scanFunc, unpack(args))
                end)
                return
            else
                button.tlText = tlText
                button.blText = blText
                button.trText = trText
                button.brText = brText
                button.originalLink = link
            end
        end
    end
    button.tlLabel = button.tlLabel or createLabel(button, "TOPLEFT", -3, 1, YELLOW_FONT_COLOR)
    button.tlLabel:SetText(tlText or "")

    button.blLabel = button.blLabel or createLabel(button, "BOTTOMLEFT", -3, -1, GREEN_FONT_COLOR)
    button.blLabel:SetText(blText or "")

    button.trLabel = button.trLabel or createLabel(button, "TOPRIGHT", 3, 1)
    button.trLabel:SetText(trText or "")

    button.brLabel = button.brLabel or createLabel(button, "BOTTOMRIGHT", 3, -1)
    button.brLabel:SetText(brText or "")
end

local function showInfoOnVoidStorageButtons()
    for i = 1, VOID_STORAGE_MAX do
        local button = _G["VoidStorageStorageButton" .. i]
        if button.hasItem then
            local _, link = GetItemInfo(GetVoidItemInfo(VoidStorageFrame.page, i))
            showInfoOnItemButton(button, link, "SetVoidItem", VoidStorageFrame.page, i)
        else
            showInfoOnItemButton(button)
        end
    end
end

---@param button WlkItemButton
local function showInfoOnPaperDollButton(button, unit)
    local slotId = button:GetID()
    local link = GetInventoryItemLink(unit, slotId)
    local level
    if link then
        if button.originalLink == link then
            level = button.levelText
        else
            level = getItemInfo(link, true, true, "SetInventoryItem", unit, slotId)
            button.levelText = level
            button.originalLink = link
        end
    end
    button.levelLabel = button.levelLabel or createLabel(button, "TOPLEFT", -3, 1, YELLOW_FONT_COLOR)
    button.levelLabel:SetText(level or "")
end

local function showInfoOnInspectButtons()
    for _, buttonName in ipairs(INSPECT_BUTTON_NAMES) do
        showInfoOnPaperDollButton(_G[buttonName], InspectFrame.unit)
    end
end

local function showInfoOnQuestRewardButton(self)
    local questLog = self == MapQuestInfoRewardsFrame
    local highestValue = 0

    wipe(highestValueButtons)
    ---@param button WlkItemButton
    for _, button in ipairs(self.RewardButtons) do
        if not button:IsShown() then
            break
        end
        local id = button:GetID()
        if button.objectType == "item" then
            local link = questLog and GetQuestLogItemLink(button.type, id) or GetQuestItemLink(button.type, id)

            showInfoOnItemButton(button, link)
            if button.tlLabel then
                button.tlLabel:SetPoint("TOPLEFT", button.IconBorder, -6, 1)
                button.trLabel:SetPoint("TOPRIGHT", button.IconBorder, 6, 1)
                button.brLabel:SetPoint("BOTTOMRIGHT", button.IconBorder, 6, -1)
            end
            
            if button.type == "choice" then
                local price = link and select(11, GetItemInfo(link))
                if price and price > 0 then
                    local count = questLog and select(3, GetQuestLogChoiceInfo(id))
                            or select(3, GetQuestItemInfo("choice", id))
                    local value = price * count
                    if value > highestValue then
                        highestValue = value
                        wipe(highestValueButtons)
                        highestValueButtons[1] = button
                    elseif value == highestValue then
                        tinsert(highestValueButtons, button)
                    end
                end
            end
        else
            showInfoOnItemButton(button)
        end
        ---@type Texture
        local icon = button.highestValueIcon
        if icon then
            icon:Hide()
        end
    end

    local numChoice = questLog and GetNumQuestLogChoices(C_QuestLog.GetSelectedQuest()) or GetNumQuestChoices()
    if numChoice > 1 then
        for _, button in ipairs(highestValueButtons) do
            if not button.highestValueIcon then
                button.highestValueIcon = button:CreateTexture()
                button.highestValueIcon:SetPoint("TOPRIGHT")
                button.highestValueIcon:SetAtlas("bags-junkcoin", true)
            else
                button.highestValueIcon:Show()
            end
        end
    end
end

local function getTexturePath(fileId)
    local texture = listener:CreateTexture()
    texture:SetTexture(fileId)
    return texture:GetTexture()
end

local function getSocketInfo(link)
    wipe(gemsTable)
    wipe(statsTable)
    wipe(socketsTable)
    GetItemStats(link, statsTable)
    for key, value in pairs(statsTable) do
        if EMPTY_SOCKETS[key] then
            for _ = 1, value do
                tinsert(socketsTable, key)
            end
        end
    end
    for i, socket in ipairs(socketsTable) do
        local _, gemLink = GetItemGem(link, i)
        local gemId = gemLink and GetItemInfoFromHyperlink(gemLink)
        local socketText = gemId and getTexturePath(GetItemIcon(gemId)) or ("Interface/ItemSocketingFrame/"
                .. EMPTY_SOCKETS[socket])
        tinsert(gemsTable, "|T" .. socketText .. ":0|t")
    end
    if #socketsTable > 0 then
        tinsert(gemsTable, " ")
    end
    return table.concat(gemsTable)
end

local function showInfoOnItemLink(link)
    if linkCaches[link] then
        return linkCaches[link]
    end
    local level, bind, subclass, invType = getItemInfo(link)
    if level or bind or subclass or invType then
        wipe(replacementTable)
        tinsert(replacementTable, "%1")
        if level and level ~= "" then
            tinsert(replacementTable, level)
        end
        if bind then
            tinsert(replacementTable, "<裝綁>")
        end
        if subclass and invType then
            tinsert(replacementTable, format("(%s/%s)", subclass, invType))
        elseif subclass or invType then
            tinsert(replacementTable, format("(%s)", subclass or invType))
        end
        tinsert(replacementTable, ": ")
        tinsert(replacementTable, "%2")
        tinsert(replacementTable, getSocketInfo(link))
        linkCaches[link] = gsub(link, "(|h%[)(.-%]|h)", table.concat(replacementTable))
        return linkCaches[link]
    end
    return link
end

local function filterChatMessage(_, _, message, ...)
    message = gsub(message, "|Hitem:%d+:.-|h.-|h", showInfoOnItemLink)
    return false, message, ...
end

---@param self Frame
hooksecurefunc("ContainerFrame_Update", function(self)
    local bagId = self:GetID()
    for i = 1, self.size do
        ---@type ItemButton
        local button = _G[self:GetName() .. "Item" .. i]
        local slotId = button:GetID()
        local link = GetContainerItemLink(bagId, slotId)
        showInfoOnItemButton(button, link, "SetBagItem", bagId, slotId)
    end
end)

---@param button ItemButton
hooksecurefunc("BankFrameItemButton_Update", function(button)
    if button.isBag then
        return
    end
    ---@type Frame
    local container = button:GetParent()
    local bagId = container:GetID()
    local slotId = bagId == REAGENTBANK_CONTAINER and ReagentButtonInventorySlot(button) or ButtonInventorySlot(button)
    local link = GetContainerItemLink(bagId, button:GetID())
    showInfoOnItemButton(button, link, "SetInventoryItem", "player", slotId)
end)

hooksecurefunc("MerchantFrameItem_UpdateQuality", function(self, link)
    ---@type ItemButton
    local button = self.ItemButton
    if self == MerchantBuyBackItem then
        showInfoOnItemButton(button, link, "SetBuybackItem", GetNumBuybackItems())
    elseif MerchantFrame.selectedTab == 1 then
        showInfoOnItemButton(button, link)
    else
        showInfoOnItemButton(button, link, "SetBuybackItem", strmatch(button:GetName(), "(%d+)"))
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
        showInfoOnItemButton(button, link, "SetBagItem", arg, slotId)
    else
        local link = GetInventoryItemLink("player", slotId)
        showInfoOnItemButton(button, link, "SetInventoryItem", "player", slotId)
    end
end)

hooksecurefunc("TradeFrame_UpdatePlayerItem", function(id)
    local button = _G["TradePlayerItem" .. id .. "ItemButton"]
    local link = GetTradePlayerItemLink(id)
    showInfoOnItemButton(button, link)
end)

hooksecurefunc("TradeFrame_UpdateTargetItem", function(id)
    local button = _G["TradeRecipientItem" .. id .. "ItemButton"]
    local link = GetTradeTargetItemLink(id)
    showInfoOnItemButton(button, link)
end)

hooksecurefunc("InboxFrame_Update", function()
    for i = 1, INBOXITEMS_TO_DISPLAY do
        local button = _G["MailItem" .. i .. "Button"]
        if button.hasItem then
            local link = select(15, GetInboxHeaderInfo(button.index))
            showInfoOnItemButton(button, link)
        else
            showInfoOnItemButton(button)
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
            showInfoOnItemButton(button, link)
        end
    end
end)

hooksecurefunc("SendMailFrame_Update", function()
    for i = 1, ATTACHMENTS_MAX_SEND do
        local button = SendMailFrame.SendMailAttachments[i]
        local link = GetSendMailItemLink(i)
        showInfoOnItemButton(button, link)
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
            showInfoOnItemButton(button, link)
        end
    end
end)

hooksecurefunc("VoidStorage_ItemsUpdate", function(doDeposit, doContents)
    if doDeposit then
        for i = 1, VOID_DEPOSIT_MAX do
            local button = _G["VoidStorageDepositButton" .. i]
            if button.hasItem then
                local _, link = GetItemInfo(GetVoidTransferDepositInfo(i))
                showInfoOnItemButton(button, link, "SetVoidDepositItem", i)
            else
                showInfoOnItemButton(button)
            end
        end
    end
    if doContents then
        for i = 1, VOID_WITHDRAW_MAX do
            local button = _G["VoidStorageWithdrawButton" .. i]
            if button.hasItem then
                local _, link = GetItemInfo(GetVoidTransferWithdrawalInfo(i))
                showInfoOnItemButton(button, link, "SetVoidWithdrawalItem", i)
            else
                showInfoOnItemButton(button)
            end
        end
        showInfoOnVoidStorageButtons()
    end
end)

hooksecurefunc("VoidStorage_SetPageNumber", showInfoOnVoidStorageButtons)

hooksecurefunc("PaperDollItemSlotButton_OnShow", function(self)
    showInfoOnPaperDollButton(self, "player")
end)

---@param self ItemButton
hooksecurefunc("PaperDollItemSlotButton_OnEvent", function(self, event, ...)
    if event == "PLAYER_EQUIPMENT_CHANGED" then
        local equipmentSlot = ...
        if self:GetID() == equipmentSlot then
            showInfoOnPaperDollButton(self, "player")
        end
    end
end)

listener:RegisterEvent("ADDON_LOADED")
listener:RegisterEvent("INSPECT_READY")
listener:RegisterEvent("UNIT_INVENTORY_CHANGED")
listener:SetScript("OnEvent", function(_, event, ...)
    if not InspectFrame then
        return
    end
    if event == "INSPECT_READY" then
        local guid = ...
        if InspectFrame.unit and (UnitGUID(InspectFrame.unit) == guid) then
            showInfoOnInspectButtons()
        end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        local unit = ...
        if InspectFrame.unit and unit == InspectFrame.unit then
            showInfoOnInspectButtons()
        end
    end
end)

hooksecurefunc(MapQuestInfoRewardsFrame, "Show", showInfoOnQuestRewardButton)
hooksecurefunc(QuestInfoRewardsFrame, "Show", showInfoOnQuestRewardButton)

for _, event in ipairs(chatFiltersEvents) do
    ChatFrame_AddMessageEventFilter(event, filterChatMessage)
end

---@class WlkItemButton:ItemButton
