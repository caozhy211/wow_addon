local listener = CreateFrame("Frame")
local tooltip = CreateFrame("GameTooltip", "MyTooltip", UIParent, "GameTooltipTemplate")
local iLevelCaches = {}
local specCaches = {}
local currentUnit, currentGUID
local statusBarText = GameTooltipStatusBar:CreateFontString()
statusBarText:SetFont(GameFontNormal:GetFont(), 11, "Outline")
statusBarText:SetPoint("Center")

local function FormatNumber(number)
    if number >= 1e8 then
        return format("%.2f億", number / 1e8)
    elseif number >= 1e4 then
        return format("%.2f萬", number / 1e4)
    end
    return number
end

GameTooltipStatusBar:HookScript("OnValueChanged", function(self, value)
    local _, maxValue = self:GetMinMaxValues()
    if maxValue > 0 then
        local percent = floor(value / maxValue * 100 + 0.5)
        statusBarText:SetText("(" .. percent .. "%) " .. FormatNumber(value) .. " / " .. FormatNumber(maxValue))
    else
        statusBarText:SetText("")
    end
end)

local function AddToGameTooltip(iLevel, spec)
    local _, unit = GameTooltip:GetUnit()
    if not unit or UnitGUID(unit) ~= currentGUID then
        return
    end

    local index
    for i = 2, GameTooltip:NumLines() do
        local line = _G["GameTooltipTextLeft" .. i]
        local text = line:GetText() or ""
        if strfind(text, STAT_AVERAGE_ITEM_LEVEL .. ": ") then
            index = i
            break
        end
    end
    local iLevelText = STAT_AVERAGE_ITEM_LEVEL .. ": " .. iLevel
    if index then
        _G["GameTooltipTextLeft" .. index]:SetText(iLevelText)
        _G["GameTooltipTextRight" .. index]:SetText(spec)
    else
        GameTooltip:AddDoubleLine(iLevelText, spec)
        GameTooltip:Show()
    end
end

local function ScanUnit(unit)
    if not unit or UnitGUID(unit) ~= currentGUID then
        return
    end
    local iLevel = iLevelCaches[currentGUID] or "..."
    local spec = specCaches[currentGUID] or "..."
    AddToGameTooltip(iLevel, spec)
    listener:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.2 then
            return
        end
        self.elapsed = 0

        ClearInspectPlayer()
        if currentUnit and UnitGUID(currentUnit) == currentGUID then
            NotifyInspect(currentUnit)
            self:RegisterEvent("INSPECT_READY")
        end
        self:SetScript("OnUpdate", nil)
    end)
end

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    local _, unit = self:GetUnit()
    if not unit or not CanInspect(unit) then
        return
    end
    currentUnit = unit
    currentGUID = UnitGUID(unit)
    ScanUnit(unit)
end)

local function GetUnitItemLevel(unit)
    if not unit or UnitGUID(unit) ~= currentGUID then
        return
    end
    local iLevel, delay
    local total, mLevel, oLevel = 0, 0, 0
    local mQuality, mSlot, oQuality, oSlot
    for i = 1, 17 do
        if i ~= 4 then
            tooltip:SetOwner(UIParent, "ANCHOR_NONE")
            tooltip:SetInventoryItem(unit, i)
            local link = GetInventoryItemLink(unit, i) or select(2, tooltip:GetItem())
            if link then
                local level
                local _, _, quality, _, _, _, _, _, slot = GetItemInfo(link)
                if not quality then
                    delay = true
                else
                    for j = 2, 5 do
                        local text = _G["MyTooltipTextLeft" .. j]:GetText() or ""
                        level = strmatch(text, gsub(ITEM_LEVEL, "%%d", "(%%d+)"))
                        if level then
                            level = tonumber(level)
                            break
                        end
                    end
                    if i == 16 then
                        mLevel = level or 0
                        mQuality = quality
                        mSlot = slot
                    elseif i == 17 then
                        oLevel = level or 0
                        oQuality = quality
                        oSlot = slot
                    else
                        total = total + (level or 0)
                    end
                end
            end
        end
    end
    if not delay then
        if mQuality == 6 or oQuality == 6 then
            total = total + max(mLevel, oLevel) * 2
        elseif oSlot == "INVTYPE_2HWEAPON" or mSlot == "INVTYPE_2HWEAPON" or mSlot == "INVTYPE_RANGED" or mSlot == "INVTYPE_RANGEDRIGHT" then
            total = total + max(mLevel, oLevel) * 2
        else
            total = total + mLevel + oLevel
        end

        iLevel = floor(total / 16)
    end
    return iLevel
end

local function GetUnitSpec(unit)
    if not unit or UnitGUID(unit) ~= currentGUID then
        return
    end

    if UnitLevel(unit) >= SHOW_SPEC_LEVEL then
        local specID, specName, _
        if unit == "player" then
            specID = GetSpecialization()
            _, specName = GetSpecializationInfo(specID)
        else
            specID = GetInspectSpecialization(unit)
            if specID and specID > 0 then
                _, specName = GetSpecializationInfoByID(specID)
            end
        end
        return specName
    end
    return ""
end

listener:SetScript("OnEvent", function(self, event, guid)
    self:UnregisterEvent(event)
    if guid ~= currentGUID then
        return
    end
    local iLevel = GetUnitItemLevel(currentUnit)
    local spec = GetUnitSpec(currentUnit)
    if not iLevel or not spec then
        ScanUnit(currentUnit)
    else
        AddToGameTooltip(iLevel, spec)
        iLevelCaches[guid] = iLevel
        specCaches[guid] = spec
    end
end)

hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    tooltip:SetOwner(parent, "ANCHOR_CURSOR_RIGHT", 30, -30)
end)

local function UnitClassColor(unit)
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        return GetClassColor(class)
    end
    return 1, 0, 1, "ffff00ff"
end

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    local name = self:GetName()

    local _, unit = self:GetUnit()
    if UnitIsPlayer(unit) then
        local guildInfo = GetGuildInfo(unit)
        if guildInfo then
            _G[name .. "TextLeft2"]:SetTextColor(0, 1, 0)
        end

        local classLine = guildInfo and 3 or 2
        _G[name .. "TextLeft" .. classLine]:SetTextColor(UnitClassColor(unit))

        local factionGroup = UnitFactionGroup(unit)
        local factionText = _G[name .. "TextLeft" .. (classLine + 1)]
        if factionGroup == "Alliance" then
            factionText:SetTextColor(0, 0.6, 1)
        elseif factionGroup == "Horde" then
            factionText:SetTextColor(1, 0.6, 0)
        else
            factionText:SetTextColor(0, 1, 0)
        end
    end
end)

GameTooltip:HookScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.01 then
        return
    end
    self.elapsed = 0

    if not UnitExists("mouseover") then
        return
    end

    local targetLine
    for i = 2, self:NumLines() do
        local line = _G[self:GetName() .. "TextLeft" .. i]
        local text = line:GetText() or ""
        if strfind(text, "^選取目標: ") then
            targetLine = line
        end
    end

    local text
    if UnitExists("mouseovertarget") then
        if UnitIsUnit("mouseovertarget", "player") then
            text = "|cffff0000>>你<<|r"
        else
            local _, _, _, hexColor = UnitClassColor("mouseovertarget")
            text = "|c" .. hexColor .. UnitName("mouseovertarget") .. "|r"
        end
    end

    if targetLine and not text then
        targetLine:SetText(nil)
        self:Show()
    elseif not targetLine and text then
        self:AddLine("選取目標: " .. text)
        self:Show()
    elseif targetLine then
        targetLine:SetText("選取目標: " .. text)
    end
end)

hooksecurefunc(GameTooltip, "SetUnitAura", function(self, ...)
    local _, _, _, _, _, _, _, _, _, id = UnitAura(...)
    if id then
        self:AddLine(" ")
        self:AddLine("|cff00ffccAura ID:|r " .. id)
        self:Show()
    end
end)

GameTooltip:HookScript("OnTooltipSetSpell", function(self)
    local _, id = self:GetSpell()
    if id then
        local find = false
        for i = 2, self:NumLines() do
            local text = _G[self:GetName() .. "TextLeft" .. i]:GetText() or ""
            if strfind(text, "Spell ID:") then
                find = true
                break
            end
        end
        if not find then
            self:AddLine(" ")
            self:AddLine("|cff00ffccSpell ID:|r " .. id)
            self:Show()
        end
    end
end)