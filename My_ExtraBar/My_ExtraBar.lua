local bar = CreateFrame("Frame", "ExtraBarFrame", UIParent)

bar:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
bar:RegisterEvent("PLAYER_REGEN_ENABLED")
bar:RegisterEvent("PLAYER_LOGIN")
bar:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
bar:RegisterEvent("PLAYER_UNGHOST")

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
        local hasRange = ItemHasRange(self.link)
        local inRange = IsItemInRange(self.link, "target")

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

local function UpdateButton(index, link)
    local button = buttons[index]

    local itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(link)

    button.itemId = tonumber(link:match("item:(%d+)"))
    -- 設置圖標
    button.icon:SetTexture(itemTexture)
    -- 設置文字
    button.HotKey:SetText("s-" .. bindKeys[index]:sub(-1))

    button:SetAttribute("item", itemName)

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
        local link = GetInventoryItemLink("player", slotId)
        if link and IsUsableItem(link) then
            UpdateButton(index, link)
            index = index + 1
        end
    end

    -- 遍歷任務物品
    for i = 1, #quests do
        if index > maxNumButtons then
            return
        end

        local questId = quests[i]:GetID()
        local link = GetQuestLogSpecialItemInfo(questId)
        if link then
            UpdateButton(index, link)
            index = index + 1
        end
    end

    numHasItemButtons = index - 1

    -- 隱藏沒有物品的按鈕,並把"item"屬性的值設置爲nil
    for i = index, #buttons do
        buttons[i]:Hide()
        buttons[i]:SetAttribute("item", nil)
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