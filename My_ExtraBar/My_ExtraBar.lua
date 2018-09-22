local bar = CreateFrame("Frame", "ExtraBarFrame", UIParent)

bar:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
bar:RegisterEvent("PLAYER_REGEN_ENABLED")
bar:RegisterEvent("PLAYER_LOGIN")
bar:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
bar:RegisterEvent("PLAYER_UNGHOST")
bar:RegisterEvent("ZONE_CHANGED_NEW_AREA")

local maxNumButtons = 6
local buttonSize = 33
local buttonSpacing = 6

bar:SetWidth(buttonSize * maxNumButtons + buttonSpacing * (maxNumButtons - 1))
bar:SetHeight(buttonSize)
bar:SetPoint("Bottom", 0, 207)

local slots = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot",
    "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot",
    "MainHandSlot", "SecondaryHandSlot",
}

local bindKeys = {
    "SHIFT-W",
    "SHIFT-E",
    "SHIFT-R",
    "SHIFT-S",
    "SHIFT-D",
    "SHIFT-F",
}

local buttons = {}
local quests = {}
local numHasItemButtons = 0

for index = 1, maxNumButtons do
    local button = CreateFrame("Button", "ExtraButton" .. index, bar, "SecureActionButtonTemplate, ActionButtonTemplate")
    button:SetWidth(buttonSize)
    button:SetHeight(buttonSize)

    -- 清除按鈕正常材質的錨點
    button.NormalTexture:ClearAllPoints()

    -- 創建冷卻框架
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()

    -- 位置
    if index == 1 then
        button:SetPoint("TopLeft")
    else
        button:SetPoint("Left", buttons[index - 1], "Right", buttonSpacing, 0)
    end

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetAttribute("type*", "item")

    button:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.2 then
            return
        end
        self.elapsed = 0

        -- 目標不在距離內時著色
        local hasRange = ItemHasRange(self.itemId)
        local inRange = IsItemInRange(self.itemId, "target")

        if not hasRange or (hasRange and (inRange == nil or inRange)) then
            self.icon:SetVertexColor(1, 1, 1)
        else
            self.icon:SetVertexColor(1, 0, 0)
        end
    end)

    -- 綁定按鍵
    SetBindingClick(bindKeys[index], button:GetName())

    buttons[index] = button
end

local function UpdateButton(index, bag, slot, itemId, texture, count)
    local button = buttons[index]

    button.itemId = itemId
    -- 設置圖標
    button.icon:SetTexture(texture)
    -- 設置數量
    button.Count:SetText(count and count > 1 and count or "")
    -- 設置文字
    button.HotKey:SetText("s-" .. bindKeys[index]:sub(-1))

    button:SetAttribute("bag", bag)
    button:SetAttribute("slot", slot)

    button:Show()
end

hooksecurefunc("QuestObjectiveItem_OnShow", function(self)
    if #quests == 0 then
        table.insert(quests, self)
    end

    for i = 1, #quests do
        if quests[i]:GetID() ~= self:GetID() then
            table.insert(quests, self)
        end
    end

    bar:Update()
end)

hooksecurefunc("QuestObjectiveItem_OnHide", function(self)
    for i = 1, #quests do
        if quests[i]:GetID() == self:GetID() then
            table.remove(quests, i)
            bar:Update()
            return
        end
    end
end)

function bar:Update()
    if InCombatLockdown() then
        return
    end

    local index = 1

    -- 遍歷已裝備物品
    for i = 1, #slots do
        if index > maxNumButtons then
            return
        end

        local slotId = GetInventorySlotInfo(slots[i])
        local itemId = GetInventoryItemID("player", slotId)
        if itemId and IsUsableItem(itemId) then
            local texture = GetInventoryItemTexture("player", slotId)
            UpdateButton(index, nil, slotId, itemId, texture)
            index = index + 1
        end
    end

    -- 遍歷背包物品
    for bag = 0, 4 do
        if index > maxNumButtons then
            return
        end

        for slot = 1, GetContainerNumSlots(bag) do
            if index > maxNumButtons then
                return
            end

            local texture, count, _, _, _, _, _, _, _, itemId = GetContainerItemInfo(bag, slot)
            for i = 1, #quests do
                local questId = quests[i]:GetID()
                local link = GetQuestLogSpecialItemInfo(questId)
                local questItemId = link and tonumber(link:match("item:(%d+)"))
                if itemId == questItemId then
                    UpdateButton(index, bag, slot, itemId, texture, count)
                    index = index + 1
                    break
                end
            end
        end
    end

    numHasItemButtons = index - 1

    -- 隱藏沒有物品的按鈕
    for i = index, #buttons do
        buttons[i]:Hide()
    end

    self:UpdateCooldown()
end

function bar:UpdateCooldown()
    for i = 1, numHasItemButtons do
        CooldownFrame_Set(buttons[i].cooldown, GetItemCooldown(buttons[i].itemId))
    end
end

bar:SetScript("OnEvent", function(self, event)
    if event == "ACTIONBAR_UPDATE_COOLDOWN" then
        self:UpdateCooldown()
    else
        self:Update()
    end
end)