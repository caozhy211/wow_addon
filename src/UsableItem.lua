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
    local itemButton = CreateFrame("Button", "WLK_UsableItemButton", usableItemFrame,
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

local shownItems = {}

local delayShowItemButtons = {}

--- 显示按钮
local function ShowItemButton(link, itemID, count, texture, slot, bagID)
    if InCombatLockdown() then
        usableItemFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        tinsert(delayShowItemButtons, { link, itemID, count, texture, slot, bagID, })
        return
    end
    for i = 1, numItemButtons do
        local itemButton = itemButtons[i]
        if itemButton:IsShown() and itemButton:GetAttribute("slot") == slot
                and itemButton:GetAttribute("bag") == bagID then
            -- 装备界面替换装备，删除 shownItems 中保存的之前的物品 link，并更新按钮的属性
            tDeleteItem(shownItems, itemButton.link)
            itemButton.link = link
            itemButton.itemID = itemID
            ---@type FontString
            local countLabel = itemButton.Count
            countLabel:SetText(count > 1 and count or "")
            ---@type Texture
            local icon = itemButton.icon
            icon:SetTexture(texture)
            UpdateCooldown()
            tinsert(shownItems, link)
            break
        elseif not itemButton:IsShown() then
            -- 新增物品，设置按钮属性后显示按钮
            itemButton:SetAttribute("bag", bagID)
            itemButton:SetAttribute("slot", slot)
            itemButton.link = link
            itemButton.itemID = itemID
            ---@type FontString
            local countLabel = itemButton.Count
            countLabel:SetText(count > 1 and count or "")
            ---@type Texture
            local icon = itemButton.icon
            icon:SetTexture(texture)
            itemButton:Show()
            UpdateCooldown()
            tinsert(shownItems, link)
            break
        end
    end
end

--- 在装备界面和背包中查找是否拥有该物品
local function FindInInventoryOrBag(link)
    for i = INVSLOT_HEAD, INVSLOT_OFFHAND do
        if link == GetInventoryItemLink("player", i) then
            return true
        end
    end
    for bagID = 0, NUM_BAG_FRAMES do
        for slot = 1, GetContainerNumSlots(bagID) do
            if link == GetContainerItemLink(bagID, slot) then
                return true
            end
        end
    end
end

local delayHideItemButtons = {}

--- 隐藏按钮
local function HideItemButton(slot)
    if InCombatLockdown() then
        usableItemFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        tinsert(delayHideItemButtons, { slot, })
        return
    end
    if slot then
        -- 隐藏装备物品
        for i = 1, numItemButtons do
            local itemButton = itemButtons[i]
            if itemButton:IsShown() and not itemButton:GetAttribute("bag")
                    and itemButton:GetAttribute("slot") == slot then
                itemButton:Hide()
                tDeleteItem(shownItems, itemButton.link)
                break
            end
        end
    else
        -- 隐藏任务追踪物品
        for i = 1, numItemButtons do
            local itemButton = itemButtons[i]
            if itemButton:IsShown() and not FindInInventoryOrBag(itemButton.link) then
                itemButton:Hide()
                tDeleteItem(shownItems, itemButton.link)
            end
        end
    end
end

--- 显示背包中可使用的任务物品
hooksecurefunc("QuestObjectiveItem_Initialize", function(_, questLogIndex)
    -- 因为只能是新增物品，所以已显示物品小于按钮数量时才需要显示按钮
    if #shownItems < numItemButtons then
        local link, icon, count = GetQuestLogSpecialItemInfo(questLogIndex)
        -- 该物品必须是未在按钮中显示的
        if not tContains(shownItems, link) then
            local itemID = GetItemInfoFromHyperlink(link)
            if itemID then
                -- 根据 link 找到物品在背包中位置
                for bagID = 0, NUM_BAG_FRAMES do
                    for slot = 1, GetContainerNumSlots(bagID) do
                        if link == GetContainerItemLink(bagID, slot) then
                            ShowItemButton(link, itemID, count, icon, slot, bagID)
                        end
                    end
                end
            end
        end
    end
end)

--- 隐藏背包中可使用的任务物品
hooksecurefunc("QuestObjectiveReleaseBlockButton_Item", function()
    if #shownItems > 0 then
        HideItemButton()
    end
end)

--- 检查装备槽位上的物品是否可使用
local function CheckPaperDollItem(slot)
    local link = GetInventoryItemLink("player", slot)
    if link then
        local itemID = GetItemInfoFromHyperlink(link)
        if itemID and IsUsableItem(link) then
            -- 装备槽位有可使用的物品，按钮显示该物品
            local icon = GetInventoryItemTexture("player", slot)
            ShowItemButton(link, itemID, 1, icon, slot)
        end
    else
        -- 装备槽位没有物品，隐藏之前显示的物品
        HideItemButton(slot)
    end
end

--- 装备界面物品改变时，更新 itemButtons 中的装备按钮
---@param self ItemButton
hooksecurefunc("PaperDollItemSlotButton_OnEvent", function(self, event, ...)
    -- 有可能是移除物品或替换物品，所以已显示物品小于等于按钮数量都需要更新
    if event == "PLAYER_EQUIPMENT_CHANGED" and #shownItems <= numItemButtons then
        local equipmentSlot = ...
        if self:GetID() == equipmentSlot then
            CheckPaperDollItem(equipmentSlot)
        end
    end
end)

--- 检查装备界面所有物品是否可使用
local function CheckAllPaperDollItems()
    for i = INVSLOT_HEAD, INVSLOT_OFFHAND do
        -- 按钮都已经有显示物品时，不再需要遍历
        if #shownItems >= numItemButtons then
            break
        end
        CheckPaperDollItem(i)
    end
end

usableItemFrame:RegisterEvent("PLAYER_LOGIN")
usableItemFrame:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
usableItemFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")

---@param self Frame
usableItemFrame:SetScript("OnEvent", function(self, event, ...)
    -- 首次登录应该在触发 UNIT_INVENTORY_CHANGED 事件时调用 IsUsableItem 才能返回物品是否可使用的正确结果。重新载入后应该在触发
    -- PLAYER_LOGIN 事件时调用 IsUsableItem 来获取物品是否可使用
    if event == "PLAYER_LOGIN" then
        SetBindingKey()
        CheckAllPaperDollItems()
        self:UnregisterEvent(event)
    elseif event == "UNIT_INVENTORY_CHANGED" then
        CheckAllPaperDollItems()
        self:UnregisterEvent(event)
    elseif event == "BAG_UPDATE_COOLDOWN" then
        UpdateCooldown()
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- 隐藏因战斗中锁住的按钮
        for i = 1, #delayHideItemButtons do
            HideItemButton(unpack(delayHideItemButtons[i]))
        end
        wipe(delayHideItemButtons)
        -- 显示因战斗中锁住的按钮
        for i = 1, #delayShowItemButtons do
            ShowItemButton(unpack(delayShowItemButtons[i]))
        end
        wipe(delayShowItemButtons)
        self:UnregisterEvent(event)
    end
end)
