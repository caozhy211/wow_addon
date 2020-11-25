---@type ColorMixin
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR
---@type ColorMixin
local RED_FONT_COLOR = RED_FONT_COLOR

local X2_INVTYPES = { INVTYPE_2HWEAPON = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_RANGED = true, }
local X2_EXCEPTIONS = { [LE_ITEM_CLASS_WEAPON] = LE_ITEM_WEAPON_WAND, }
local SPEC_WARRIOR_FURY = 72
local ITEM_LEVEL_REGEX = gsub(ITEM_LEVEL, "%%d", "(%%d+)")
---@type TickerPrototype
local updateTicker
local spellIdShown
local guildR, guildG, guildB = 0.25, 1, 0.25
local inspecting, inspectItemLevel, inspectSpec
local scannerName = "WlkTooltipInspectScanner"

local barLabel = GameTooltipStatusBar:CreateFontString("WlkGameTooltipLabel", "ARTWORK", "NumberFont_Shadow_Small")
---@type Frame
local listener = CreateFrame("Frame")
---@type GameTooltip
local scanner = CreateFrame("GameTooltip", scannerName, UIParent, "GameTooltipTemplate")

---@param tooltip GameTooltip
local function setTooltipAnchor(tooltip)
    local x, y = GetScaledCursorPosition()
    tooltip:ClearAllPoints()
    tooltip:SetPoint("BOTTOMLEFT", UIParent, x + 30, y + 10)
end

local function abbreviateNumber(value)
    if value >= 1e8 then
        return format("%.2f%s", value / 1e8, SECOND_NUMBER_CAP)
    elseif value >= 1e4 then
        return format("%.1f%s", value / 1e4, FIRST_NUMBER_CAP)
    end
    return value
end

---@param tooltip GameTooltip
local function showItemId(tooltip)
    local _, link = tooltip:GetItem()
    local itemId = link and GetItemInfoFromHyperlink(link)
    if itemId then
        tooltip:AddLine(" ")
        tooltip:AddLine("ID: " .. HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(itemId))
        tooltip:Show()
    end
end

---@param tooltip GameTooltip
local function showAuraId(func, tooltip, ...)
    local id = select(10, func(...))
    if id then
        tooltip:AddLine(" ")
        tooltip:AddLine("ID: " .. HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(id))
        tooltip:Show()
    end
end

local function getInspectSpec()
    local specName, texturePath, _
    if UnitIsUnit("player", "mouseover") then
        _, specName, _, texturePath = GetSpecializationInfo(GetSpecialization())
    else
        _, specName, _, texturePath = GetSpecializationInfoByID(GetInspectSpecialization("mouseover"))
    end
    if specName and texturePath then
        return format("|T%s:0|t %s", texturePath, specName)
    end
end

local function getInspectItemLevel()
    if UnitIsUnit("player", "mouseover") then
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
                local _, _, quality, _, _, _, _, _, equipLoc, texture, _, classId, subclassId = GetItemInfo(link)
                if not texture then
                    fail = true
                else
                    local itemLevel = GetDetailedItemLevelInfo(link)
                    if quality == Enum.ItemQuality.Heirloom then
                        for j = 2, min(5, scanner:NumLines()) do
                            ---@type FontString
                            local label = _G[scannerName .. "TextLeft" .. j]
                            local text = label:GetText()
                            local level = text and strmatch(text, ITEM_LEVEL_REGEX)
                            if level then
                                itemLevel = tonumber(level)
                                break
                            end
                        end
                    end
                    if i == INVSLOT_MAINHAND then
                        mainLevel = itemLevel
                        mainEquipLoc = equipLoc
                        mainQuality = quality
                        mainClassId = classId
                        mainSubclassId = subclassId
                    elseif i == INVSLOT_OFFHAND then
                        offLevel = itemLevel
                        offEquipLoc = equipLoc
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
    if mainQuality == Enum.ItemQuality.Artifact or (not offEquipLoc and X2_INVTYPES[mainEquipLoc]
            and X2_EXCEPTIONS[mainClassId] ~= mainSubclassId and spec ~= SPEC_WARRIOR_FURY) then
        sum = sum + max(mainLevel, offLevel) * 2
    else
        sum = sum + mainLevel + offLevel
    end
    return STAT_AVERAGE_ITEM_LEVEL .. ": " .. HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(floor(sum / 16))
end

---@param tooltip GameTooltip
hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    tooltip:SetOwner(parent, "ANCHOR_CURSOR")
    setTooltipAnchor(tooltip)
    updateTicker = C_Timer.NewTicker(0.03, function()
        if tooltip:IsShown() and tooltip:GetAnchorType() == "ANCHOR_CURSOR" then
            setTooltipAnchor(tooltip)
        else
            updateTicker:Cancel()
        end
    end)
end)

hooksecurefunc("PetBattleAbilityButton_OnEnter", function(self)
    PetBattleAbilityTooltip_Show("BOTTOMLEFT", self, "TOPRIGHT")
end)

barLabel:SetPoint("CENTER")

GameTooltipStatusBar:SetStatusBarTexture("Interface/Tooltips/UI-Tooltip-Background")
GameTooltipStatusBar:HookScript("OnValueChanged", function(_, value)
    local _, maxValue = GameTooltipStatusBar:GetMinMaxValues()
    if maxValue > 0 then
        barLabel:SetFormattedText("%s/%s(%s)", abbreviateNumber(value), abbreviateNumber(maxValue),
                FormatPercentage(PercentageBetween(value, 0, maxValue)))
    else
        barLabel:SetText("")
    end
end)

GameTooltip:HookScript("OnTooltipSetItem", showItemId)

ItemRefTooltip:HookScript("OnTooltipSetItem", showItemId)

ShoppingTooltip1:HookScript("OnTooltipSetItem", showItemId)

ShoppingTooltip2:HookScript("OnTooltipSetItem", showItemId)

hooksecurefunc(GameTooltip, "SetUnitAura", function(self, ...)
    showAuraId(UnitAura, self, ...)
end)

hooksecurefunc(GameTooltip, "SetUnitBuff", function(self, ...)
    showAuraId(UnitBuff, self, ...)
end)

hooksecurefunc(GameTooltip, "SetUnitDebuff", function(self, ...)
    showAuraId(UnitDebuff, self, ...)
end)

hooksecurefunc(NamePlateTooltip, "SetUnitAura", function(self, ...)
    showAuraId(UnitAura, self, ...)
end)

GameTooltip:HookScript("OnTooltipSetSpell", function()
    local _, spellId = GameTooltip:GetSpell()
    if spellId and not spellIdShown then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("ID: " .. HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(spellId))
        GameTooltip:Show()
        spellIdShown = true
    end
end)
GameTooltip:HookScript("OnTooltipCleared", function()
    spellIdShown = nil
end)
GameTooltip:HookScript("OnTooltipSetUnit", function()
    inspecting = nil
    inspectItemLevel = nil
    inspectSpec = nil
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
        line:SetTextColor(GetClassColor(select(2, UnitClass(unit))))
        index = index + 1
        local factionColor = GetFactionColor(UnitFactionGroup(unit))
        if factionColor then
            line = _G["GameTooltipTextLeft" .. index]
            line:SetTextColor(GetTableColor(factionColor))
        end
    end
end)

listener:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.5 then
        return
    end
    self.elapsed = 0

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
        local text
        if UnitIsUnit("mouseovertarget", "player") then
            text = RED_FONT_COLOR:WrapTextInColorCode(">>" .. YOU .. "<<")
        else
            local name = UnitName("mouseovertarget")
            if UnitIsPlayer("mouseovertarget") then
                text = GetClassColoredTextForUnit("mouseovertarget", name)
            else
                text = HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(name)
            end
        end
        if targetLabel then
            targetLabel:SetText(TARGET .. ": " .. text)
        else
            GameTooltip:AddLine(TARGET .. ": " .. text)
        end
        GameTooltip:Show()
    elseif targetLabel then
        targetLabel:SetText("")
        GameTooltip:Show()
    end

    if (not inspectItemLevel or not inspectSpec) and not inspecting and IsControlKeyDown() and UnitExists("mouseover")
            and CanInspect("mouseover") then
        NotifyInspect("mouseover")
        listener:RegisterEvent("INSPECT_READY")
        local inspectLabel
        for i = 4, GameTooltip:NumLines() do
            ---@type FontString
            local label = _G["GameTooltipTextLeft" .. i]
            local text = label:GetText()
            if text and strmatch(text, STAT_AVERAGE_ITEM_LEVEL) then
                inspectLabel = true
                break
            end
        end
        if not inspectLabel then
            GameTooltip:AddDoubleLine(STAT_AVERAGE_ITEM_LEVEL .. ": "
                    .. HIGHLIGHT_FONT_COLOR:WrapTextInColorCode("..."), "...", nil, nil, nil, 1, 1, 1)
            GameTooltip:Show()
        end
    end
end)
listener:SetScript("OnEvent", function(_, event, ...)
    if event == "INSPECT_READY" then
        listener:UnregisterEvent(event)
        inspecting = true
        if UnitExists("mouseover") and UnitGUID("mouseover") == ... then
            local itemLevel = getInspectItemLevel()
            local spec = getInspectSpec()
            if itemLevel or spec then
                for i = 4, GameTooltip:NumLines() do
                    ---@type FontString
                    local label = _G["GameTooltipTextLeft" .. i]
                    local text = label:GetText()
                    if text and strmatch(text, STAT_AVERAGE_ITEM_LEVEL) then
                        if itemLevel then
                            label:SetText(itemLevel)
                        end
                        if spec then
                            label = _G["GameTooltipTextRight" .. i]
                            label:SetText(spec)
                        end
                        GameTooltip:Show()
                        break
                    end
                end
            end
            inspectItemLevel = itemLevel
            inspectSpec = spec
        end
        inspecting = false
    end
end)
