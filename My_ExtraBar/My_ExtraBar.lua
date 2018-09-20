local bar = CreateFrame("Frame", "ExtraBarFrame", UIParent)

bar:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
bar:RegisterEvent("PLAYER_REGEN_ENABLED")
bar:RegisterEvent("PLAYER_LOGIN")
bar:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")

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

local items = {}
local quests = {}
local shownItems = 0

local predefinedItems = {}

bar.tip = CreateFrame("GameTooltip", "ExtraBarFrameTip", nil, "GameTooltipTemplate")
bar.tip:SetOwner(UIParent, "ANCHOR_NONE")

local function CreateButton(index)
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
        button:SetPoint("Left", items[index - 1], "Right", buttonSpacing, 0)
    end

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetAttribute("type*", "item")

    -- 鼠標懸停時顯示鼠標提示
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR_RIGHT", 30, -12)
        local slot = self:GetAttribute("slot")
        local questId = self:GetAttribute("questId")
        if slot then
            GameTooltip:SetInventoryItem("player", slot)
        elseif questId then
            GameTooltip:SetQuestLogSpecialItem(questId)
        end
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

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

    items[index] = button
    return button
end

local function SetButton(index, questId, slot, link)
    local button = items[index] or CreateButton(index)

    button.link = link
    local itemName, _, _, _, _, _, _, itemCount, _, itemTexture = GetItemInfo(link)

    -- 設置個數
    button.Count:SetText(itemCount and itemCount > 1 and itemCount or "")
    -- 設置圖標
    button.icon:SetTexture(itemTexture)
    -- 設置文字
    button.HotKey:SetText("s-" .. bindKeys[index]:sub(-1))

    button:SetAttribute("questId", questId)
    button:SetAttribute("slot", slot)
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

    for i = 1, #slots do
        if index > maxNumButtons then
            return
        end

        local slotId = GetInventorySlotInfo(slots[i])
        local link = GetInventoryItemLink("player", slotId)
        if link and IsUsableItem(link) then
            SetButton(index, nil, slotId, link)
            index = index + 1
        end
    end

    if quests then
        for i = 1, #quests do
            if index > maxNumButtons then
                return
            end

            local questId = quests[i]:GetID()
            local link = GetQuestLogSpecialItemInfo(questId)
            if link then
                SetButton(index, questId, nil, link)
                index = index + 1
            end
        end
    end

    shownItems = index - 1

    -- 隱藏沒有物品的按鈕,並把"item"屬性的值設置爲nil
    for i = index, #items do
        items[i]:Hide()
        items[i]:SetAttribute("item", nil)
    end

    self:UpdateCooldown()
end

function bar:UpdateCooldown()
    for i = 1, shownItems do
        local slot = items[i]:GetAttribute("slot");
        local questId = items[i]:GetAttribute("questId")
        if slot then
            CooldownFrame_Set(items[i].cooldown, GetInventoryItemCooldown("player", slot));
        else
            CooldownFrame_Set(items[i].cooldown, GetQuestLogSpecialItemCooldown(questId));
        end
    end
end

bar:SetScript("OnEvent", function(self, event)
    if event == "ACTIONBAR_UPDATE_COOLDOWN" then
        self:UpdateCooldown()
    else
        self:Update()
    end
end)