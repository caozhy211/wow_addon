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

--- 更新按钮的属性并显示按钮
local function ShowItemButton(index, itemID, count, icon, slot, bagID)
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

--- 检查物品是否是追踪物品
local function IsObjectiveItem(slot, bagID)
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    if bagID then
        scanner:SetBagItem(bagID, slot)
    else
        scanner:SetInventoryItem("player", slot, false, true)
    end
    for i = 2, scanner:NumLines() do
        ---@type FontString
        local line = _G[scanner:GetName() .. "TextLeft" .. i]
        local text = line:GetText()
        if strfind(text, "^" .. USE .. (locale == "zhCN" and "：" or ":")) then
            return true
        end
    end
end

local questObjectiveItems = {}

local firstUpdate
local shownSlots = {}
local shownItems = {}

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
    wipe(shownItems)

    local index = 1
    -- 检查装备界面的所有装备
    for slot = INVSLOT_HEAD, INVSLOT_OFFHAND do
        local link = GetInventoryItemLink("player", slot)
        local itemID = link and GetItemInfoFromHyperlink(link)
        if itemID and (IsUsableItem(link) or IsObjectiveItem(slot)) then
            local icon = GetInventoryItemTexture("player", slot)
            ShowItemButton(index, itemID, 1, icon, slot)
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
                if itemID then
                    local item = questObjectiveItems[link]
                    -- 如果该物品在任务追踪物品表中且对应的任务未完成或不在任务追踪物品表中的可主动使用的任务物品（“战损之剑”），显
                    -- 示该物品。不在任务追踪物品表中的物品只要在背包中就会一直显示，因为无法获取到与它关联的任务
                    if item and not item.completed or not item and GetContainerItemQuestInfo(bagID, slot)
                            and (IsUsableItem(link) or IsObjectiveItem(slot, bagID)) then
                        ShowItemButton(index, itemID, count, icon, slot, bagID)
                        shownItems[link] = true
                        index = index + 1
                        if index > numItemButtons then
                            return
                        end
                    end
                end
            end
        end
    end

    -- 隐藏没有物品的按钮
    for i = index, numItemButtons do
        ---@type Button
        local button = itemButtons[i]
        button:Hide()
        button:SetAttribute("bag", nil)
        button:SetAttribute("slot", nil)
    end
end

objectiveItemFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
objectiveItemFrame:RegisterEvent("PLAYER_LOGIN")
objectiveItemFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
objectiveItemFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
objectiveItemFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
objectiveItemFrame:RegisterEvent("BAG_UPDATE")
objectiveItemFrame:RegisterEvent("QUEST_REMOVED")

---@param self Frame
objectiveItemFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        SetBindingKey()
        self:UnregisterEvent(event)
    elseif event == "PLAYER_ENTERING_WORLD" then
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
        if shownSlots[equipmentSlot] or link and IsUsableItem(link) or IsObjectiveItem(equipmentSlot) then
            UpdateAllItemButtons()
        end
    elseif event == "BAG_UPDATE" then
        -- 背包更新（新增物品、更换位置、移除物品）就需要更新，因为有些可主动使用的任务物品不会出现在任务追踪栏，例如 “战损之剑”
        UpdateAllItemButtons()
    elseif event == "PLAYER_REGEN_ENABLED" then
        UpdateAllItemButtons()
        self:UnregisterEvent(event)
        if firstUpdate then
            firstUpdate = false
            C_Timer.After(0.3, function()
                UpdateAllItemButtons()
            end)
        end
    elseif event == "QUEST_REMOVED" then
        local questID = ...
        for link, item in pairs(questObjectiveItems) do
            if item.questID == questID then
                -- 从任务追踪物品表中移除该任务的物品
                questObjectiveItems[link] = nil
                -- 部分物品在任务移除后仍然在背包中，不会触发 BAG_UPDATE 事件，需要在此更新隐藏物品
                if shownItems[link] then
                    UpdateAllItemButtons()
                end
                return
            end
        end
    end
end)

hooksecurefunc("QuestObjectiveSetupBlockButton_Item", function(_, questLogIndex, isQuestComplete)
    local link, item, _, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)
    -- 把物品添加至任务追踪物品表中
    if link and not questObjectiveItems[link] then
        questObjectiveItems[link] = { questID = select(8, GetQuestLogTitle(questLogIndex)), }
    end
    local shouldShowItem = item and (not isQuestComplete or showItemWhenComplete)
    if shouldShowItem then
        -- 更新显示该物品
        if not shownItems[link] then
            UpdateAllItemButtons()
        end
    elseif link and not shouldShowItem then
        -- 在任务追踪物品中但不在任务追踪栏显示时，该任务已完成
        questObjectiveItems[link].completed = true
        -- 更新隐藏该物品
        if shownItems[link] then
            UpdateAllItemButtons()
        end
    end
end)
