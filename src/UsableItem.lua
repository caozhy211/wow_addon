local size = 33

---@type Frame
local usableItemFrame = CreateFrame("Frame", "WLK_UsableItemFrame", UIParent)
usableItemFrame:SetSize(228, size)
usableItemFrame:SetPoint("BOTTOM", 0, 185 + 20 + 1)

---@type GameTooltip
local tooltip = CreateFrame("GameTooltip", "WLK_UsableItemTooltip", UIParent, "GameTooltipTemplate")

---@type GameTooltip
tooltip:HookScript("OnTooltipSetItem", function(self)
    local _, link = self:GetItem()
    local id = GetItemInfoFromHyperlink(link)
    if id then
        self:AddLine(" ")
        self:AddLine(ITEMS .. ID .. "：" .. HIGHLIGHT_FONT_COLOR_CODE .. id .. FONT_COLOR_CODE_CLOSE)
        self:Show()
    end
end)

---@type table<number, Button>
local itemButtons = {}
local numItemButtons = 6
local spacing = (228 - size * numItemButtons) / (numItemButtons - 1)

--- 创建按钮
local function CreateItemButton(index)
    ---@type Button
    local itemButton = CreateFrame("Button", "WLK_UsableItemButton" .. index, usableItemFrame,
            "SecureActionButtonTemplate, ActionButtonTemplate")
    itemButton:SetSize(size, size)
    itemButton:SetPoint("LEFT", (size + spacing) * (index - 1), 0)
    itemButton:Hide()
    itemButton:SetAttribute("type*", "item")
    itemButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    ---@type Texture
    local texture = itemButton.NormalTexture
    texture:SetTexture(nil)
    itemButton.cooldown = CreateFrame("Cooldown", nil, itemButton, "CooldownFrameTemplate")
    itemButton.cooldown:SetAllPoints()

    ---@param self Button
    itemButton:SetScript("OnEnter", function(self)
        tooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 30, -30)
        local bagID = self:GetAttribute("bag")
        local slot = self:GetAttribute("slot")
        if bagID then
            tooltip:SetBagItem(bagID, slot)
        else
            tooltip:SetInventoryItem("player", slot)
        end
        self.ticker = C_Timer.NewTicker(TOOLTIP_UPDATE_TIME, function()
            if bagID then
                tooltip:SetBagItem(bagID, slot)
            else
                tooltip:SetInventoryItem("player", slot)
            end
        end)
    end)

    itemButton:SetScript("OnLeave", function(self)
        ---@type TickerPrototype
        local ticker = self.ticker
        ticker:Cancel()
        ticker = nil
        tooltip:Hide()
    end)

    itemButton:SetScript("OnUpdate", function(self)
        local hasRange = ItemHasRange(self.link)
        local inRange = IsItemInRange(self.link, "target")
        ---@type Texture
        local icon = itemButton.icon
        if not hasRange or (hasRange and (inRange == nil or inRange)) then
            icon:SetVertexColor(GetTableColor(WHITE_FONT_COLOR))
        else
            icon:SetVertexColor(GetTableColor(DIM_RED_FONT_COLOR))
        end
    end)

    itemButtons[index] = itemButton
    return itemButton
end

for i = 1, numItemButtons do
    CreateItemButton(i)
end

local bindingKeys = { "ALT-Q", "ALT-W", "ALT-A", "ALT-R", "ALT-T", "ALT-G", }

--- 绑定快捷键
local function SetBindingKey()
    for i = 1, numItemButtons do
        local itemButton = itemButtons[i]
        local bindingKey = bindingKeys[i]
        SetBindingClick(bindingKey, itemButton:GetName())
        ---@type FontString
        local keyLabel = itemButton.HotKey
        keyLabel:SetText("a-" .. strsub(bindingKey, -1))
    end
end

--- 更新物品冷却
local function UpdateCooldown()
    for i = 1, numItemButtons do
        local itemButton = itemButtons[i]
        if itemButton:IsShown() then
            CooldownFrame_Set(itemButton.cooldown, GetItemCooldown(itemButton.itemID))
        end
    end
end

local shownSlots = {}
local shownQuests = {}
local shownBagIDs = {}

--- 更新按钮的属性并显示按钮
local function UpdateItemButton(index, itemID, count, icon, slot, bagID, questID)
    local button = itemButtons[index]
    button.itemID = itemID
    ---@type FontString
    local countLabel = button.Count
    countLabel:SetText(count > 1 and count or "")
    button.icon:SetTexture(icon)
    button:SetAttribute("slot", slot)
    button:SetAttribute("bag", bagID)
    if bagID then
        tinsert(shownBagIDs, bagID)
        tinsert(shownQuests, questID)
    else
        tinsert(shownSlots, slot)
    end
    button:Show()
    CooldownFrame_Set(button.cooldown, GetItemCooldown(button.itemID))
end

--- 检查物品是否是可使用的任务物品
local function IsQuestUsableItem(link)
    local count, _, icon, _, classID, subclassID, bindType = select(8, GetItemInfo(link))
    if (classID == LE_ITEM_CLASS_QUESTITEM and subclassID == LE_QUEST_TAG_TYPE_TAG or bindType == LE_ITEM_BIND_QUEST)
            and IsUsableItem(link) then
        return count, icon
    end
end

--- 获取任务物品的任务 ID
local function GetQuestIDByItemLink(link)
    for i = 1, GetNumQuestLogEntries() do
        if link == GetQuestLogSpecialItemInfo(i) then
            return select(8, GetQuestLogTitle(i))
        end
    end
end

--- 检查装备和背包中可使用的物品，更新 itemButtons
local function UpdateAllItemButtons(questID)
    if InCombatLockdown() then
        usableItemFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    usableItemFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")

    wipe(shownSlots)
    wipe(shownQuests)
    wipe(shownBagIDs)

    local index = 1
    -- 检查装备界面的所有装备
    for slot = INVSLOT_HEAD, INVSLOT_OFFHAND do
        local link = GetInventoryItemLink("player", slot)
        local itemID = link and GetItemInfoFromHyperlink(link)
        if itemID and IsUsableItem(link) then
            local icon = GetInventoryItemTexture("player", slot)
            UpdateItemButton(index, itemID, 1, icon, slot)
            index = index + 1
        end
        if index == numItemButtons then
            return
        end
    end

    -- 检查背包中的所有物品
    if index < numItemButtons then
        for bagID = 0, NUM_BAG_FRAMES do
            for slot = 1, GetContainerNumSlots(bagID) do
                local link = GetContainerItemLink(bagID, slot)
                local itemID = link and GetItemInfoFromHyperlink(link)
                if itemID then
                    local count, icon = IsQuestUsableItem(link)
                    if count and icon then
                        UpdateItemButton(index, itemID, count, icon, slot, bagID, questID or GetQuestIDByItemLink(link))
                        index = index + 1
                    end
                end
                if index == numItemButtons then
                    return
                end
            end
        end
    end

    -- 隐藏没有物品的按钮
    for i = index, numItemButtons do
        itemButtons[i]:Hide()
    end
end

usableItemFrame:RegisterEvent("PLAYER_LOGIN")
usableItemFrame:RegisterEvent("UNIT_INVENTORY_CHANGED", "player")
usableItemFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
usableItemFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
usableItemFrame:RegisterEvent("QUEST_ACCEPTED")
usableItemFrame:RegisterEvent("QUEST_TURNED_IN")
usableItemFrame:RegisterEvent("QUEST_REMOVED")
usableItemFrame:RegisterEvent("BAG_UPDATE")
usableItemFrame:RegisterEvent("PLAYER_UNGHOST")

---@param self Frame
usableItemFrame:SetScript("OnEvent", function(self, event, ...)
    -- 首次登录应该在触发 UNIT_INVENTORY_CHANGED 事件时调用 IsUsableItem 才能返回物品是否可使用的正确结果。重新载入后应该在触发
    -- PLAYER_LOGIN 事件时调用 IsUsableItem 来获取物品是否可使用
    if event == "PLAYER_LOGIN" then
        SetBindingKey()
        UpdateAllItemButtons()
        self:UnregisterEvent(event)
    elseif event == "UNIT_INVENTORY_CHANGED" then
        UpdateAllItemButtons()
        self:UnregisterEvent(event)
    elseif event == "BAG_UPDATE_COOLDOWN" then
        UpdateCooldown()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        local equipmentSlot = ...
        local link = GetInventoryItemLink("player", equipmentSlot)
        -- 该装备槽位现在是可使用的装备或该装备槽位之前有可使用的装备，都需要更新
        if link and IsUsableItem(link) or tContains(shownSlots, equipmentSlot) then
            UpdateAllItemButtons()
        end
    elseif event == "QUEST_ACCEPTED" then
        local questIndex, questID = ...
        local link = GetQuestLogSpecialItemInfo(questIndex)
        -- 接受的任务有可使用的任务物品时，需要更新
        if link and IsQuestUsableItem(link) then
            UpdateAllItemButtons(questID)
        end
    elseif event == "QUEST_TURNED_IN" or event == "QUEST_REMOVED" then
        local questID = ...
        -- 提交任务或放弃任务，且该任务有可使用的任务物品时，需要更新
        if tContains(shownQuests, questID) then
            UpdateAllItemButtons()
        end
    elseif event == "BAG_UPDATE" then
        local bagID = ...
        -- 更新的背包中有可使用的任务物品时，需要更新
        if tContains(shownBagIDs, bagID) then
            UpdateAllItemButtons()
        end
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_UNGHOST" then
        UpdateAllItemButtons()
    end
end)
