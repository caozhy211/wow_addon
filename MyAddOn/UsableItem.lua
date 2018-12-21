local tooltip = CreateFrame("GameTooltip", "MyUsableItemTooltip", UIParent, "GameTooltipTemplate")
local buttons = {}
local maxButtons = 6
local numButtons = 0
local bindKeys = { "ALT-Q", "ALT-W", "ALT-A", "ALT-R", "ALT-T", "ALT-G", }
local bar = CreateFrame("Frame", "MyUsableItemBar", UIParent)
bar:SetSize(228, 33)
bar:SetPoint("BottomRight", CastingBarFrame, "TopRight", 0, 3 + 2 + 20)
local height = bar:GetHeight()
local width = height
local spacing = (bar:GetWidth() - width * maxButtons) / (maxButtons - 1)

local function OnEnter(self)
    tooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 30, -12)
    local bag = self:GetAttribute("bag")
    local slot = self:GetAttribute("slot")
    if bag then
        tooltip:SetBagItem(bag, slot)
    else
        tooltip:SetInventoryItem("player", slot)
    end
end

local function OnLeave()
    tooltip:Hide()
end

local function OnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.2 then
        return
    end
    self.elapsed = 0

    local hasRange = ItemHasRange(self.itemID)
    local inRange = IsItemInRange(self.itemID, "target")

    if not hasRange or (hasRange and (inRange == nil or inRange)) then
        self.icon:SetVertexColor(1, 1, 1)
    else
        self.icon:SetVertexColor(1, 0, 0)
    end
end

for i = 1, maxButtons do
    local button = CreateFrame("Button", "MyUsableItemButton" .. i, bar, "SecureActionButtonTemplate, ActionButtonTemplate")
    button:SetSize(width, height)
    button:SetPoint("Left", (i - 1) * (width + spacing), 0)

    button.NormalTexture:SetTexture(nil)
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()

    button:SetAttribute("type*", "item")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", OnLeave)
    button:SetScript("OnUpdate", OnUpdate)

    buttons[i] = button
end

local function SetBindingKey()
    for i = 1, maxButtons do
        SetBindingClick(bindKeys[i], buttons[i]:GetName())
    end
end

local function UpdateCooldown()
    for i = 1, numButtons do
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

local function UpdateBar()
    if InCombatLockdown() then
        return
    end

    local index = 1

    for i = 1, 18 do
        if index > maxButtons then
            return
        end
        local itemID = GetInventoryItemID("player", i)
        if itemID and IsUsableItem(itemID) then
            local texture = GetInventoryItemTexture("player", i)
            UpdateButton(index, nil, i, itemID, texture)
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
                local isQuestItem, questID, isActive = GetContainerItemQuestInfo(bag, slot)
                if (isQuestItem or questID and not isActive) and IsUsableItem(itemID) then
                    local texture, count = GetContainerItemInfo(bag, slot)
                    UpdateButton(index, bag, slot, itemID, texture, count)
                    index = index + 1
                    break
                end
            end
        end
    end

    numButtons = index - 1
    for i = index, maxButtons do
        buttons[i]:Hide()
    end

    UpdateCooldown()
end

bar:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
bar:RegisterEvent("PLAYER_REGEN_ENABLED")
bar:RegisterEvent("PLAYER_LOGIN")
bar:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
bar:RegisterEvent("BAG_UPDATE")
bar:RegisterEvent("QUEST_ACCEPTED")

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