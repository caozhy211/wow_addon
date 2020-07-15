local size = 33

---@type Frame
local objectiveItemFrame = CreateFrame("Frame", "WLK_ObjectiveItemFrame", UIParent)
objectiveItemFrame:SetSize(228, size)
objectiveItemFrame:SetPoint("BOTTOM", 0, 185 + 20 + 1)

---@type GameTooltip
local tooltip = CreateFrame("GameTooltip", "WLK_ObjectiveItemTooltip", UIParent, "GameTooltipTemplate")

---@type GameTooltip
tooltip:HookScript("OnTooltipSetItem", function(self)
    local _, link = self:GetItem()
    local id = GetItemInfoFromHyperlink(link)
    if id then
        self:AddLine(" ")
        self:AddLine(ITEMS .. " " .. ID .. ": " .. HIGHLIGHT_FONT_COLOR_CODE .. id .. FONT_COLOR_CODE_CLOSE)
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
    local itemButton = CreateFrame("Button", "WLK_ObjectiveItemButton" .. index, objectiveItemFrame,
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

    itemButton:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < TOOLTIP_UPDATE_TIME then
            return
        end
        self.elapsed = 0

        local hasRange = ItemHasRange(self.itemID)
        local inRange = IsItemInRange(self.itemID, "target")
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
        if itemButton:IsShown() and itemButton.itemID then
            CooldownFrame_Set(itemButton.cooldown, GetItemCooldown(itemButton.itemID))
        end
    end
end

local shownSlots = {}
local shownBagIDs = {}
local shownItems = {}
local questObjectiveItems = {}

--- 更新按钮的属性并显示按钮
local function UpdateItemButton(index, itemID, count, icon, slot, bagID)
    local button = itemButtons[index]
    button.itemID = itemID
    ---@type FontString
    local countLabel = button.Count
    countLabel:SetText(count > 1 and count or "")
    button.icon:SetTexture(icon)
    button:SetAttribute("slot", slot)
    button:SetAttribute("bag", bagID)
    button:Show()
    CooldownFrame_Set(button.cooldown, GetItemCooldown(button.itemID))
end

local locale = GetLocale()
---@type GameTooltip
local scanner = CreateFrame("GameTooltip", "WLK_ObjectiveItemScanner", UIParent, "GameTooltipTemplate")
scanner:SetOwner(UIParent, "ANCHOR_NONE")

--- 检查装备物品是否是追踪物品
local function IsInventoryObjectiveItem(slot)
    scanner:SetInventoryItem("player", slot, false, true)
    for i = 2, scanner:NumLines() do
        ---@type FontString
        local line = _G[scanner:GetName() .. "TextLeft" .. i]
        local text = line:GetText()
        if strfind(text, "^" .. USE .. (locale == "zhCN" and "：" or ":")) then
            return true
        end
    end
end

local firstUpdate

--- 检查装备和背包中的追踪物品，更新 itemButtons
local function UpdateAllItemButtons()
    if InCombatLockdown() then
        objectiveItemFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    if firstUpdate == nil then
        firstUpdate = true
    end

    wipe(shownSlots)
    wipe(shownBagIDs)
    wipe(shownItems)

    local index = 1
    -- 检查装备界面的所有装备
    for slot = INVSLOT_HEAD, INVSLOT_OFFHAND do
        local link = GetInventoryItemLink("player", slot)
        local itemID = link and GetItemInfoFromHyperlink(link)
        if itemID and (IsUsableItem(link) or IsInventoryObjectiveItem(slot)) then
            local icon = GetInventoryItemTexture("player", slot)
            UpdateItemButton(index, itemID, 1, icon, slot)
            shownSlots[slot] = true
            index = index + 1
            if index > numItemButtons then
                return
            end
        end
    end

    -- 检查背包中的所有物品
    if index <= numItemButtons then
        for bagID = 0, NUM_BAG_FRAMES do
            for slot = 1, GetContainerNumSlots(bagID) do
                local icon, count, _, _, _, _, link, _, _, itemID = GetContainerItemInfo(bagID, slot)
                if itemID and questObjectiveItems[link] then
                    UpdateItemButton(index, itemID, count, icon, slot, bagID)
                    shownBagIDs[bagID] = true
                    shownItems[link] = true
                    index = index + 1
                    if index > numItemButtons then
                        return
                    end
                end
            end
        end
    end

    -- 隐藏没有物品的按钮
    for i = index, numItemButtons do
        itemButtons[i]:Hide()
    end
end

--- 更新任务追踪物品
local function UpdateQuestObjectiveItem()
    wipe(questObjectiveItems)
    for i = 1, GetNumQuestLogEntries() do
        local link = GetQuestLogSpecialItemInfo(i)
        if link then
            questObjectiveItems[link] = true
        end
    end
end

objectiveItemFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
objectiveItemFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
objectiveItemFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
objectiveItemFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
objectiveItemFrame:RegisterEvent("BAG_UPDATE")
objectiveItemFrame:RegisterEvent("QUEST_REMOVED")

---@param self Frame
objectiveItemFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        SetBindingKey()
        UpdateAllItemButtons()
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        -- 第一次登录时 IsUsableItem 一定返回 false，需要在触发 GET_ITEM_INFO_RECEIVED 事件且成功时更新
        local _, success = ...
        if success then
            UpdateAllItemButtons()
            self:UnregisterEvent(event)
            -- 第一次扫描已装备物品的鼠标提示信息时无法获取完整内容，需要再次更新
            if firstUpdate then
                firstUpdate = false
                C_Timer.After(0.3, function()
                    UpdateAllItemButtons()
                end)
            end
        end
    elseif event == "BAG_UPDATE_COOLDOWN" then
        UpdateCooldown()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        local equipmentSlot = ...
        local link = GetInventoryItemLink("player", equipmentSlot)
        -- 该装备槽位现在是追踪物品或该装备槽位之前有追踪物品，都需要更新
        if shownSlots[equipmentSlot] or link and IsUsableItem(link) or IsInventoryObjectiveItem(equipmentSlot) then
            UpdateAllItemButtons()
        end
    elseif event == "BAG_UPDATE" then
        -- 物品更换位置或者被移除，更新的背包中有任务追踪物品时，需要更新
        local bagID = ...
        if shownBagIDs[bagID] then
            UpdateAllItemButtons()
        end
    elseif event == "QUEST_REMOVED" then
        UpdateQuestObjectiveItem()
    elseif event == "PLAYER_REGEN_ENABLED" then
        UpdateAllItemButtons()
        self:UnregisterEvent(event)
        if firstUpdate then
            firstUpdate = false
            C_Timer.After(0.3, function()
                UpdateAllItemButtons()
            end)
        end
    end
end)

hooksecurefunc("QuestObjectiveSetupBlockButton_Item", function(_, questLogIndex, isQuestComplete)
    local link, item, _, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)
    local shouldShowItem = item and (not isQuestComplete or showItemWhenComplete)
    if shouldShowItem then
        if not questObjectiveItems[link] then
            questObjectiveItems[link] = true
        end
        if not shownItems[link] then
            UpdateAllItemButtons()
        end
    end
end)
