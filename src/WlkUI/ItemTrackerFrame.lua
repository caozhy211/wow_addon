local maxButtons = 6
local buttonSize = 27
local spacing = 5
local frameWidth = (buttonSize + spacing) * maxButtons - spacing
local frameHeight = buttonSize
local classR, classG, classB = GetClassColor(select(2, UnitClass("player")))
local backdrop = { edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 2, }
local bindKeys = { "ALT-1", "ALT-2", "ALT-3", "ALT-4", "ALT-Q", "ALT-W", "ALT-R", }
---@type WlkItemTrackerButton[]
local buttons = {}
local locale = GetLocale()
---@type table<number, WlkItemTrackerButton>
local buttonIndexes = {}
local scannerName = "WlkItemTrackerScanner"

---@type Frame
local tracker = CreateFrame("Frame", "WlkItemTrackerFrame", BuffFrame)
---@type GameTooltip
local scanner = CreateFrame("GameTooltip", scannerName, UIParent, "GameTooltipTemplate")

---@param self WlkItemTrackerButton
local function buttonOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.2 then
        return
    end
    self.elapsed = 0

    local r, g, b
    local item = self.item
    local hasRange = ItemHasRange(item)
    local inRange = IsItemInRange(item, "target")
    if not hasRange or (hasRange and inRange ~= false) then
        local isUsable, notEnoughMana = IsUsableItem(item)
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

---@param self WlkItemTrackerButton
local function buttonOnEnter(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    if self.bag then
        GameTooltip:SetBagItem(self.bag, self.slot)
    else
        GameTooltip:SetInventoryItem("player", self.slot)
    end
    self.UpdateTooltip = buttonOnEnter
end

local function buttonOnLeave(self)
    GameTooltip:Hide()
    self.UpdateTooltip = nil
end

---@param button WlkItemTrackerButton
local function updateButtonAttribute(button)
    button:SetAttribute("macrotext", "/use " .. (button.bag and ("item:" .. button.item) or button.slot))
    button:SetBackdropBorderColor(classR, classG, classB)
    button.HotKey:Show()
end

---@param self WlkItemTrackerButton
local function buttonOnEvent(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        self:UnregisterEvent(event)
        updateButtonAttribute(self)
    end
end

local function showButton(texture, count, item, slot, bag)
    for i = 1, maxButtons do
        local button = buttons[i]
        if not button.item then
            buttonIndexes[item] = button

            button.icon:SetTexture(texture)
            button.Count:SetText(count > 1 and count or "")
            button:SetAlpha(1)

            button.item = item
            button.bag = bag
            button.slot = slot

            button:SetScript("OnUpdate", buttonOnUpdate)
            button:SetScript("OnEnter", buttonOnEnter)
            button:SetScript("OnLeave", buttonOnLeave)
            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

            if InCombatLockdown() then
                -- 战斗中不能更新按钮属性
                button:RegisterEvent("PLAYER_REGEN_ENABLED")
                button:SetBackdropBorderColor(0, 0, 0)
                button.HotKey:Hide()
            else
                updateButtonAttribute(button)
            end

            CooldownFrame_Set(button.cooldown, GetItemCooldown(item))

            break
        end
    end
end

---@param button WlkItemTrackerButton
local function hideButton(button)
    if button.item then
        buttonIndexes[button.item] = nil
    end

    button:SetAlpha(0)

    button:SetScript("OnUpdate", nil)
    button:SetScript("OnEnter", nil)
    button:SetScript("OnLeave", nil)
    button:RegisterForClicks()

    button.item = nil
    button.bag = nil
    button.slot = nil
end

local function isUsableItem(link, scanFunc, ...)
    if IsUsableItem(link) then
        return true
    end
    scanner:SetOwner(UIParent, "ANCHOR_NONE")
    scanner[scanFunc](scanner, ...)
    for i = 2, scanner:NumLines() do
        ---@type FontString
        local label = _G[scannerName .. "TextLeft" .. i]
        local text = label:GetText()
        if text and strmatch(text, "^" .. USE .. (locale == "zhCN" and "：" or ": ")) then
            return true
        end
    end
end

local function updateInventoryItems(slot)
    local link = GetInventoryItemLink("player", slot)
    if link and isUsableItem(link, "SetInventoryItem", "player", slot) then
        local itemId = GetInventoryItemID("player", slot)
        local button = buttonIndexes[itemId]
        if button then
            button.slot = slot
        else
            local texture = GetInventoryItemTexture("player", slot)
            showButton(texture, 1, itemId, slot)
        end
    end
    for _, button in pairs(buttonIndexes) do
        if button.slot and not button.bag and button.item ~= GetInventoryItemID("player", button.slot) then
            hideButton(button)
        end
    end
end

local function updateBagItems()
    for i = 0, NUM_BAG_FRAMES do
        for j = 1, GetContainerNumSlots(i) do
            local texture, count, _, _, _, _, link, _, _, itemId = GetContainerItemInfo(i, j)
            if link then
                local classId, _, bind = select(12, GetItemInfo(link))
                local isQuestItem = classId == LE_ITEM_CLASS_QUESTITEM or bind == LE_ITEM_BIND_QUEST
                if isQuestItem and isUsableItem(link, "SetBagItem", i, j) then
                    local button = buttonIndexes[itemId]
                    if button then
                        button.bag = i
                        button.slot = j
                        button.Count:SetText(count > 1 and count or "")
                    else
                        showButton(texture, count, itemId, j, i)
                    end
                end
            end
        end
    end
    for _, button in pairs(buttonIndexes) do
        if button.bag and button.slot and button.item ~= GetContainerItemID(button.bag, button.slot) then
            hideButton(button)
        end
    end
end

local function registerEventBagUpdate()
    tracker:RegisterEvent("BAG_UPDATE")
end

local function updateAllItems()
    for i = INVSLOT_HEAD, INVSLOT_OFFHAND do
        updateInventoryItems(i)
    end
    updateBagItems()
end

for i = 1, maxButtons do
    local bindKey = bindKeys[i]
    ---@class WlkItemTrackerButton:ActionButtonTemplate
    local button = CreateFrame("Button", "WlkItemTrackerButton" .. i, tracker,
            "ActionButtonTemplate, SecureActionButtonTemplate, BackdropTemplate")

    button:SetSize(buttonSize, buttonSize)
    button:SetPoint("LEFT", (i - 1) * (buttonSize + spacing), 0)
    button:SetBackdrop(backdrop)
    button:SetAttribute("type", "macro")
    button:SetAttribute("checkfocuscast", true)
    button:SetAttribute("unit2", "player")
    button:SetScript("OnEvent", buttonOnEvent)

    button.NormalTexture:SetTexture(nil)

    button.HotKey:SetPoint("TOPRIGHT", 3, 0)
    button.HotKey:SetText(strlower(strsub(bindKey, 1, 1)) .. strmatch(bindKey, "%-.+"))

    button.cooldown:SetSwipeColor(0, 0, 0)

    buttons[i] = button
end

tracker:SetSize(frameWidth, frameHeight)
tracker:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", 147, 208)
tracker:RegisterEvent("PLAYER_LOGIN")
tracker:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
tracker:RegisterEvent("BAG_UPDATE_COOLDOWN")
tracker:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        for i = 1, maxButtons do
            SetBindingClick(bindKeys[i], buttons[i]:GetName())
            hideButton(buttons[i])
        end
        C_Timer.NewTicker(0.1, updateAllItems, 2)
        C_Timer.After(1, registerEventBagUpdate)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        local slot = ...
        C_Timer.NewTicker(0.1, function()
            updateInventoryItems(slot)
        end, 2)
    elseif event == "BAG_UPDATE" then
        C_Timer.NewTicker(0.1, updateBagItems, 2)
    elseif event == "BAG_UPDATE_COOLDOWN" then
        for _, button in pairs(buttonIndexes) do
            CooldownFrame_Set(button.cooldown, GetItemCooldown(button.item))
        end
    end
end)
