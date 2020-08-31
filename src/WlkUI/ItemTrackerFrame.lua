--- LossOfControlFrame 顶部相对 UIParent 底部的偏移值
local offsetY1 = 226
local numTrackerButtons = 7
local size = 27
local spacing = 5
---@type Frame
local trackerFrame = CreateFrame("Frame", "WlkItemTrackerFrame", UIParent)
trackerFrame:SetSize((size + spacing) * numTrackerButtons - spacing, size)
trackerFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", 180, offsetY1)

---@param self Button
local function TrackerButtonOnEnter(self)
    if not self.itemId then
        return
    end
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    if self.bag then
        GameTooltip:SetBagItem(self.bag, self.slot)
    else
        GameTooltip:SetInventoryItem("player", self.slot)
    end
    self.UpdateTooltip = TrackerButtonOnEnter
end

local function TrackerButtonOnLeave(self)
    GameTooltip:Hide()
    self.UpdateTooltip = nil
end

---@param self Button
local function TrackerButtonOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < TOOLTIP_UPDATE_TIME then
        return
    end
    self.elapsed = 0

    local r, g, b
    local itemId = self.itemId
    local hasRange = ItemHasRange(itemId)
    local inRange = IsItemInRange(itemId, "target")
    if not hasRange or (hasRange and (inRange == nil or inRange == 1)) then
        local isUsable, notEnoughMana = IsUsableItem(itemId)
        if isUsable then
            r, g, b = 1, 1, 1
        elseif notEnoughMana then
            r, g, b = 0.5, 0.5, 1
        else
            r, g, b = 0.4, 0.4, 0.4
        end
    else
        r, g, b = 1, 0, 0
    end
    self.icon:SetVertexColor(r, g, b)
end

local _, class = UnitClass("player")
local r, g, b = GetClassColor(class)
local backdrop = { edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 2, }
local bindKeys = { "ALT-1", "ALT-2", "ALT-3", "ALT-4", "ALT-Q", "ALT-W", "ALT-R" }
---@type Button[]
local buttons = {}

for i = 1, numTrackerButtons do
    ---@type Button|ActionButtonTemplate
    local button = CreateFrame("Button", "WlkItemTrackerButton" .. i, trackerFrame,
            "ActionButtonTemplate, SecureActionButtonTemplate")
    buttons[#buttons + 1] = button
    button:SetAlpha(0)
    button:SetSize(size, size)
    button:SetPoint("LEFT", (i - 1) * (size + spacing), 0)
    button:SetBackdrop(backdrop)
    button:SetBackdropBorderColor(r, g, b)

    button.NormalTexture:SetTexture(nil)
    button.HotKey:SetPoint("TOPRIGHT", 3, 0)
    local bindKey = bindKeys[i]
    button.HotKey:SetText(strlower(strsub(bindKey, 1, 1)) .. strmatch(bindKey, "%-.+"))
    button.cooldown:SetSwipeColor(0, 0, 0)

    button:SetAttribute("type", "item")
    button:SetAttribute("checkfocuscast", true)
    button:SetAttribute("unit2", "player")
    button:RegisterForClicks()

    button:SetScript("OnEnter", TrackerButtonOnEnter)
    button:SetScript("OnLeave", TrackerButtonOnLeave)
end

local locale = GetLocale()

---@type GameTooltip
local scanner = CreateFrame("GameTooltip", "WlkItemTrackerScanner", UIParent, "GameTooltipTemplate")

local function ItemIsUsable(link, scanFunc, ...)
    if IsUsableItem(link) then
        return true
    end
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner[scanFunc](scanner, ...)
    for i = 2, scanner:NumLines() do
        ---@type FontString
        local label = _G[scanner:GetName() .. "TextLeft" .. i]
        local text = label:GetText()
        if text and strmatch(text, "^" .. USE .. (locale == "zhCN" and "：" or ": ")) then
            return true
        end
    end
end

local function IsTrackedItem(link, scanFunc, ...)
    if scanFunc == "SetBagItem" then
        local classId, _, bindType = select(12, GetItemInfo(link))
        local isQuestItem = classId == LE_ITEM_CLASS_QUESTITEM or bindType == LE_ITEM_BIND_QUEST
        return isQuestItem and ItemIsUsable(link, scanFunc, ...)
    end
    return ItemIsUsable(link, scanFunc, ...)
end

local function GetTrackerButtonByItemId(itemId)
    for i = 1, numTrackerButtons do
        if buttons[i].itemId == itemId then
            return buttons[i]
        end
    end
end

local attributesToBeUpdate = {}

---@param button Button|ActionButtonTemplate
local function UpdateTrackerButtonAttribute(button, value)
    if not value then
        button.HotKey:Hide()
    end
    if InCombatLockdown() then
        trackerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        attributesToBeUpdate[button] = value
    else
        button:SetAttribute("item", value)
        if value then
            button.HotKey:Show()
        end
    end
end

---@param button Button
local function HideTrackerButton(button)
    button:SetAlpha(0)
    button.itemId = nil
    button.bag = nil
    button.slot = nil
    button:RegisterForClicks()
    button:SetScript("OnUpdate", nil)
    UpdateTrackerButtonAttribute(button)
end

local function ShowTrackerButton(texture, count, itemId, slotId, bagId)
    for i = 1, numTrackerButtons do
        local button = buttons[i]
        if not button.itemId then
            button:SetAlpha(1)
            button.icon:SetTexture(texture)
            button.Count:SetText(count > 1 and count or "")
            button.itemId = itemId
            button.bag = bagId
            button.slot = slotId
            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            button:SetScript("OnUpdate", TrackerButtonOnUpdate)
            local itemName = GetItemInfo(itemId)
            UpdateTrackerButtonAttribute(button, itemName)
            break
        end
    end
end

local function UpdateInventorySlotTrackedItem(slotId)
    -- 显示或更新
    local link = GetInventoryItemLink("player", slotId)
    if link and IsTrackedItem(link, "SetInventoryItem", "player", slotId) then
        local itemId = GetInventoryItemID("player", slotId)
        local trackerButton = GetTrackerButtonByItemId(itemId)
        if trackerButton then
            trackerButton.slot = slotId
        else
            local texture = GetInventoryItemTexture("player", slotId)
            ShowTrackerButton(texture, 1, itemId, slotId)
        end
    end
    -- 隐藏
    for i = 1, numTrackerButtons do
        local button = buttons[i]
        local bag = button.bag
        local slot = button.slot
        if not bag and slot then
            local itemId = GetInventoryItemID("player", slot)
            if itemId ~= button.itemId then
                HideTrackerButton(button)
            end
        end
    end
end

local function UpdateContainerTrackedItems()
    -- 显示或更新
    for i = 0, NUM_BAG_FRAMES do
        for j = 1, GetContainerNumSlots(i) do
            local texture, count, _, _, _, _, link, _, _, itemId = GetContainerItemInfo(i, j)
            if link and IsTrackedItem(link, "SetBagItem", i, j) then
                local trackerButton = GetTrackerButtonByItemId(itemId)
                if trackerButton then
                    trackerButton.bag = i
                    trackerButton.slot = j
                    trackerButton.Count:SetText(count > 1 and count or "")
                else
                    ShowTrackerButton(texture, count, itemId, j, i)
                end
            end
        end
    end
    -- 隐藏
    for j = 1, numTrackerButtons do
        local button = buttons[j]
        local bag = button.bag
        local slot = button.slot
        if bag and slot then
            local itemId = select(10, GetContainerItemInfo(bag, slot))
            if itemId ~= button.itemId then
                HideTrackerButton(buttons[j])
            end
        end
    end
end

local function UpdateTrackedItems()
    for i = INVSLOT_HEAD, INVSLOT_OFFHAND do
        UpdateInventorySlotTrackedItem(i)
    end
    UpdateContainerTrackedItems()
end

local function RegisterEventBagUpdate()
    trackerFrame:RegisterEvent("BAG_UPDATE")
end

trackerFrame:RegisterEvent("PLAYER_LOGIN")
trackerFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
trackerFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")

trackerFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        trackerFrame:UnregisterEvent(event)
        for i = 1, numTrackerButtons do
            SetBindingClick(bindKeys[i], buttons[i]:GetName())
        end
        -- 首次登录或初始化登录时鼠标提示文本可能不完整，更新两次确保获取正确的结果
        C_Timer.NewTicker(0.1, UpdateTrackedItems, 2)
        -- 登录时的 BAG_UPDATE 触发时不更新背包追踪物品 
        C_Timer.After(1, RegisterEventBagUpdate)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        local slotId = ...
        UpdateInventorySlotTrackedItem(slotId)
    elseif event == "BAG_UPDATE" then
        UpdateContainerTrackedItems()
    elseif event == "PLAYER_REGEN_ENABLED" then
        trackerFrame:UnregisterEvent(event)
        for button, value in pairs(attributesToBeUpdate) do
            UpdateTrackerButtonAttribute(button, value)
        end
        wipe(attributesToBeUpdate)
    elseif event == "BAG_UPDATE_COOLDOWN" then
        for i = 1, numTrackerButtons do
            if buttons[i].itemId then
                CooldownFrame_Set(buttons[i].cooldown, GetItemCooldown(buttons[i].itemId))
            end
        end
    end
end)
