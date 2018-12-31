local questToken = (GetItemClassInfo and GetItemClassInfo(LE_ITEM_CLASS_QUESTITEM or 12)) or LOOT_JOURNAL_LEGENDARIES_SOURCE_QUEST or "Quest"
local tooltip = CreateFrame("GameTooltip", "MyUsableItemTooltip", UIParent, "GameTooltipTemplate")
local scanTooltip = CreateFrame("GameTooltip", "MyScanUsableItemTooltip", UIParent, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
local buttons = {}
local maxButtons = 6
local numHasItemButtons = 0
local bindKeys = { "ALT-Q", "ALT-W", "ALT-A", "ALT-R", "ALT-T", "ALT-G", }
local bar = CreateFrame("Frame", "MyUsableItemBar", UIParent)
bar:SetSize(228, 33)
bar:SetPoint("BottomRight", CastingBarFrame, "TopRight", 0, 3 + 2 + 20)
local height = bar:GetHeight()
local width = height
local spacing = (bar:GetWidth() - width * maxButtons) / (maxButtons - 1)
local questObjectiveItems = {}

local function CreateItemButton(id)
    local button = CreateFrame("Button", "MyUsableItemButton" .. id, bar, "SecureActionButtonTemplate, ActionButtonTemplate")
    button:SetSize(width, height)
    button:SetPoint("Left", (id - 1) * (width + spacing), 0)

    button.NormalTexture:SetTexture(nil)
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()

    button:SetAttribute("type*", "item")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button:SetScript("OnEnter", function(self)
        tooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 30, -12)
        local bag = self:GetAttribute("bag")
        local slot = self:GetAttribute("slot")
        if bag then
            tooltip:SetBagItem(bag, slot)
        else
            tooltip:SetInventoryItem("player", slot)
        end
        self:SetScript("OnUpdate", function(_, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            if self.elapsed < TOOLTIP_UPDATE_TIME then
                return
            end
            self.elapsed = 0
            if bag then
                tooltip:SetBagItem(bag, slot)
            else
                tooltip:SetInventoryItem("player", slot)
            end
        end)
    end)

    button:SetScript("OnLeave", function(self)
        self:SetScript("OnUpdate", nil)
        tooltip:Hide()
    end)

    C_Timer.NewTicker(TOOLTIP_UPDATE_TIME, function()
        local hasRange = ItemHasRange(button.itemID)
        local inRange = IsItemInRange(button.itemID, "target")

        if not hasRange or (hasRange and (inRange == nil or inRange)) then
            button.icon:SetVertexColor(1, 1, 1)
        else
            button.icon:SetVertexColor(1, 0, 0)
        end
    end)

    return button
end

for i = 1, maxButtons do
    buttons[i] = CreateItemButton(i)
end

local function SetBindingKey()
    for i = 1, maxButtons do
        SetBindingClick(bindKeys[i], buttons[i]:GetName())
    end
end

local function UpdateCooldown()
    for i = 1, numHasItemButtons do
        CooldownFrame_Set(buttons[i].cooldown, GetItemCooldown(buttons[i].itemID))
    end
end

local function UpdateButton(index, bag, slot, itemID, texture, count)
    local button = buttons[index]

    button.itemID = itemID
    button.icon:SetTexture(texture)
    button.Count:SetText(count and count > 1 and count or "")
    button.HotKey:SetText("a-" .. strsub(bindKeys[index], -1))

    button:SetAttribute("bag", bag)
    button:SetAttribute("slot", slot)

    button:Show()
end

local function IsQuestItem(link)
    local _, _, _, _, _, class, subClass = GetItemInfo(link)
    scanTooltip:SetHyperlink(link)
    local text = _G[scanTooltip:GetName() .. "TextLeft2"]:GetText() or ""
    return class == questToken or subClass == questToken or text == ITEM_BIND_QUEST or text == GetZoneText()
end

local function FindInQuestObjectiveItems(id)
    for i = 1, #questObjectiveItems do
        if id == questObjectiveItems[i] then
            return true
        end
    end
    return false
end

local function UpdateBar()
    if InCombatLockdown() then
        bar:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    bar:UnregisterEvent("PLAYER_REGEN_ENABLED")

    local index = 1

    for slot = 1, 18 do
        if index > maxButtons then
            return
        end
        local itemID = GetInventoryItemID("player", slot)
        if itemID and IsUsableItem(itemID) then
            local texture = GetInventoryItemTexture("player", slot)
            UpdateButton(index, nil, slot, itemID, texture)
            index = index + 1
        end
    end

    for bag = 0, NUM_BAG_FRAMES do
        for slot = 1, GetContainerNumSlots(bag) do
            if index > maxButtons then
                return
            end
            local link = GetContainerItemLink(bag, slot)
            local itemID = link and tonumber(strmatch(link, "item:(%d+)"))
            if itemID then
                if IsQuestItem(link) and (IsUsableItem(itemID) or FindInQuestObjectiveItems(itemID)) then
                    local texture, count = GetContainerItemInfo(bag, slot)
                    UpdateButton(index, bag, slot, itemID, texture, count)
                    index = index + 1
                end
            end
        end
    end

    numHasItemButtons = index - 1
    for i = index, maxButtons do
        buttons[i]:Hide()
    end

    UpdateCooldown()
end

bar:RegisterEvent("PLAYER_LOGIN")
bar:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
bar:RegisterEvent("BAG_UPDATE")
bar:RegisterEvent("QUEST_ACCEPTED")
bar:RegisterEvent("PLAYER_DEAD")
bar:RegisterEvent("PLAYER_UNGHOST")

bar:SetScript("OnEvent", function(_, event)
    if event == "ACTIONBAR_UPDATE_COOLDOWN" then
        UpdateCooldown()
    elseif event == "PLAYER_LOGIN" then
        SetBindingKey()
        UpdateBar()
    else
        UpdateBar()
    end
end)

hooksecurefunc("QuestObjectiveSetupBlockButton_Item", function(_, questLogIndex, isQuestComplete)
    local link, item, _, showItemWhenComplete = GetQuestLogSpecialItemInfo(questLogIndex)
    local shouldShowItem = item and (not isQuestComplete or showItemWhenComplete)
    if shouldShowItem then
        local itemID = tonumber(strmatch(link, "item:(%d+)"))
        if not FindInQuestObjectiveItems(itemID) then
            questObjectiveItems[#questObjectiveItems + 1] = itemID
            UpdateBar()
        end
    end
end)