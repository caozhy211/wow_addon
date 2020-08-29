---@param tooltip GameTooltip
local function SetGameTooltipAnchor(tooltip)
    local x, y = GetScaledCursorPosition()
    tooltip:ClearAllPoints()
    tooltip:SetPoint("BOTTOMLEFT", UIParent, x + 30, y + 10)
end

---@type TickerPrototype
local tooltipUpdateTicker

---@param tooltip GameTooltip
hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    tooltip:SetOwner(parent, "ANCHOR_CURSOR")
    SetGameTooltipAnchor(tooltip)
    tooltipUpdateTicker = C_Timer.NewTicker(0.01, function()
        if tooltipUpdateTicker then
            if tooltip:IsShown() and tooltip:GetAnchorType() == "ANCHOR_CURSOR" then
                SetGameTooltipAnchor(tooltip)
            else
                tooltipUpdateTicker:Cancel()
                tooltipUpdateTicker = nil
            end
        end
    end)
end)

local function AbbreviateNumber(number)
    if number >= 1e8 then
        return format("%.2f" .. SECOND_NUMBER_CAP, number / 1e8)
    elseif number >= 1e4 then
        return format("%.1f" .. FIRST_NUMBER_CAP, number / 1e4)
    end
    return number
end

---@type FontString
local statusBarLabel = GameTooltipStatusBar:CreateFontString("WlkGameTooltipStatusBarLabel", "ARTWORK", "Game12Font_o1")
statusBarLabel:SetPoint("CENTER")

GameTooltipStatusBar:HookScript("OnValueChanged", function(_, value)
    local _, maxValue = GameTooltipStatusBar:GetMinMaxValues()
    if maxValue > 0 then
        statusBarLabel:SetFormattedText("%s/%s(%s)", AbbreviateNumber(value), AbbreviateNumber(maxValue),
                FormatPercentage(PercentageBetween(value, 0, maxValue)))
    else
        statusBarLabel:SetText("")
    end
end)

---@type ColorMixin
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR

---@param self GameTooltip
local function ShowItemId(self)
    local _, link = self:GetItem()
    local itemId = link and GetItemInfoFromHyperlink(link)
    if itemId then
        self:AddLine(" ")
        self:AddLine(strconcat(ITEMS, " ", ID, ": ", HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(itemId)))
        self:Show()
    end
end

GameTooltip:HookScript("OnTooltipSetItem", ShowItemId)
ItemRefTooltip:HookScript("OnTooltipSetItem", ShowItemId)
ShoppingTooltip1:HookScript("OnTooltipSetItem", ShowItemId)
ShoppingTooltip2:HookScript("OnTooltipSetItem", ShowItemId)

---@param tooltip GameTooltip
local function ShowAuraId(func, tooltip, ...)
    local id = select(10, func(...))
    if id then
        tooltip:AddLine(" ")
        tooltip:AddLine(strconcat(AURAS, " ", ID, ": ", HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(id)))
        tooltip:Show()
    end
end

hooksecurefunc(GameTooltip, "SetUnitAura", function(self, ...)
    ShowAuraId(UnitAura, self, ...)
end)

hooksecurefunc(GameTooltip, "SetUnitBuff", function(self, ...)
    ShowAuraId(UnitBuff, self, ...)
end)

hooksecurefunc(GameTooltip, "SetUnitDebuff", function(self, ...)
    ShowAuraId(UnitDebuff, self, ...)
end)

hooksecurefunc(NamePlateTooltip, "SetUnitAura", function(self, ...)
    ShowAuraId(UnitAura, self, ...)
end)

GameTooltip:HookScript("OnTooltipSetSpell", function()
    local _, spellId = GameTooltip:GetSpell()
    if spellId and not GameTooltip.spellIdLabel then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(strconcat(SPELLS, " ", ID, ": ", HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(spellId)))
        GameTooltip:Show()
        GameTooltip.spellIdLabel = true
    end
end)

GameTooltip:HookScript("OnTooltipCleared", function()
    GameTooltip.spellIdLabel = nil
end)

local X2_INVTYPES = {
    INVTYPE_2HWEAPON = true,
    INVTYPE_RANGEDRIGHT = true,
    INVTYPE_RANGED = true,
}

local X2_EXCEPTIONS = {
    [LE_ITEM_CLASS_WEAPON] = LE_ITEM_WEAPON_WAND
}

local SPEC_WARRIOR_FURY = 72

---@type GameTooltip
local scanner = CreateFrame("GameTooltip", "WlkTooltipInspectMouseoverScanner", UIParent, "GameTooltipTemplate")

local function GetInspectUnitItemLevel()
    if UnitIsUnit("mouseover", "player") then
        local _, itemLevel = GetAverageItemLevel()
        return STAT_AVERAGE_ITEM_LEVEL .. ": " .. HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(floor(itemLevel))
    end
    local fail
    local spec = GetInspectSpecialization("mouseover")
    if not spec or spec == 0 then
        fail = true
    end
    local sum = 0
    local mainLevel = 0
    local offLevel = 0
    local mainQuality, mainEquipLoc, offEquipLoc, mainClassId, mainSubclassId
    for i = INVSLOT_HEAD, INVSLOT_OFFHAND do
        if i ~= INVSLOT_BODY then
            scanner:SetOwner(UIParent, "ANCHOR_NONE")
            scanner:SetInventoryItem("mouseover", i)
            local link = GetInventoryItemLink("mouseover", i) or select(2, scanner:GetItem())
            if link then
                local name, _, quality, _, _, _, _, _, equipLocation, _, _, classId, subclassId = GetItemInfo(link)
                if not name then
                    fail = true
                else
                    local itemLevel = GetDetailedItemLevelInfo(link)
                    if quality == LE_ITEM_QUALITY_HEIRLOOM then
                        for j = 2, scanner:NumLines() do
                            ---@type FontString
                            local label = _G[scanner:GetName() .. "TextLeft" .. j]
                            local text = label:GetText()
                            if text then
                                text = strmatch(text, gsub(ITEM_LEVEL, "%%d", "(%%d+)"))
                                        or strmatch(text, gsub(ITEM_LEVEL_ALT, "%%d%(%%d%)", "%%d+%%%(%(%%d+%)%%%)"))
                                if text then
                                    itemLevel = tonumber(text)
                                    break
                                end
                            end
                        end
                    end
                    if i == INVSLOT_MAINHAND then
                        mainLevel = itemLevel
                        mainEquipLoc = equipLocation
                        mainQuality = quality
                        mainClassId = classId
                        mainSubclassId = subclassId
                    elseif i == INVSLOT_OFFHAND then
                        offLevel = itemLevel
                        offEquipLoc = equipLocation
                    else
                        sum = sum + itemLevel
                    end
                end
            end
        end
    end
    if fail then
        return
    end
    if mainQuality == LE_ITEM_QUALITY_ARTIFACT or (not offEquipLoc and X2_INVTYPES[mainEquipLoc]
            and X2_EXCEPTIONS[mainClassId] ~= mainSubclassId and spec ~= SPEC_WARRIOR_FURY) then
        sum = sum + max(mainLevel, offLevel) * 2
    else
        sum = sum + mainLevel + offLevel
    end
    return STAT_AVERAGE_ITEM_LEVEL .. ": " .. HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(floor(sum / 16))
end

local function GetInspectUnitSpecialization()
    local specName, texturePath, _
    if UnitIsUnit("mouseover", "player") then
        _, specName, _, texturePath = GetSpecializationInfo(GetSpecialization())
    else
        _, specName, _, texturePath = GetSpecializationInfoByID(GetInspectSpecialization("mouseover"))
    end
    if not texturePath or not specName then
        return
    end
    return format("|T%s:0|t %s", texturePath, specName)
end

local inspectItemLevel, inspectSpec, inspecting
---@type Frame
local eventFrame = CreateFrame("Frame")
---@type ColorMixin
local RED_FONT_COLOR = RED_FONT_COLOR

eventFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.5 then
        return
    end
    self.elapsed = 0

    if (not inspectItemLevel or not inspectSpec) and not inspecting and UnitExists("mouseover")
            and CanInspect("mouseover") then
        NotifyInspect("mouseover")
        eventFrame:RegisterEvent("INSPECT_READY")
    end

    ---@type FontString
    local targetLabel
    for i = 2, GameTooltip:NumLines() do
        ---@type FontString
        local label = _G["GameTooltipTextLeft" .. i]
        local text = label:GetText()
        if text and strmatch(text, TARGET .. ": ") then
            targetLabel = label
            break
        end
    end
    if UnitExists("mouseovertarget") and GameTooltip:GetUnit() then
        local targetText
        if UnitIsUnit("mouseovertarget", "player") then
            targetText = RED_FONT_COLOR:WrapTextInColorCode(">>" .. YOU .. "<<")
        else
            local name = UnitName("mouseovertarget")
            if UnitIsPlayer("mouseovertarget") then
                targetText = GetClassColoredTextForUnit("mouseovertarget", name)
            else
                targetText = HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(name)
            end
        end
        if targetLabel then
            targetLabel:SetText(TARGET .. ": " .. targetText)
        else
            GameTooltip:AddLine(TARGET .. ": " .. targetText)
        end
        GameTooltip:Show()
    elseif targetLabel then
        targetLabel:SetText("")
        GameTooltip:Show()
    end
end)

eventFrame:SetScript("OnEvent", function(_, event, ...)
    inspecting = true
    eventFrame:UnregisterEvent(event)
    local guid = ...
    if UnitExists("mouseover") and UnitGUID("mouseover") == guid then
        local itemLevel = GetInspectUnitItemLevel()
        local specialization = GetInspectUnitSpecialization()
        if itemLevel or specialization then
            for i = 4, GameTooltip:NumLines() do
                ---@type FontString
                local label = _G["GameTooltipTextLeft" .. i]
                if strmatch(label:GetText(), STAT_AVERAGE_ITEM_LEVEL) then
                    if itemLevel then
                        label:SetText(itemLevel)
                    end
                    if specialization then
                        label = _G["GameTooltipTextRight" .. i]
                        label:SetText(specialization)
                    end
                    GameTooltip:Show()
                    break
                end
            end
        end
        inspectItemLevel = itemLevel
        inspectSpec = specialization
    end
    inspecting = false
end)

local guildR, guildG, guildB = 0.25, 1, 0.25

GameTooltip:HookScript("OnTooltipSetUnit", function()
    local _, unit = GameTooltip:GetUnit()
    if UnitIsPlayer(unit) then
        local index = 2
        ---@type FontString
        local line
        if GetGuildInfo(unit) then
            line = _G["GameTooltipTextLeft" .. index]
            line:SetTextColor(guildR, guildG, guildB)
            index = index + 1
        end
        line = _G["GameTooltipTextLeft" .. index]
        local _, class = UnitClass(unit)
        line:SetTextColor(GetClassColor(class))
        index = index + 1
        local factionColor = GetFactionColor(UnitFactionGroup(unit))
        if factionColor then
            line = _G["GameTooltipTextLeft" .. index]
            line:SetTextColor(GetTableColor(factionColor))
        end
    end
    if unit and CanInspect(unit) then
        GameTooltip:AddDoubleLine(STAT_AVERAGE_ITEM_LEVEL .. ": " .. HIGHLIGHT_FONT_COLOR:WrapTextInColorCode("..."),
                "...", nil, nil, nil, 1, 1, 1)
        GameTooltip:Show()
        inspectItemLevel = nil
        inspectSpec = nil
        inspecting = nil
    end
end)
