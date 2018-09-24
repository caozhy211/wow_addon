-- 顯示在光標右邊
hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    tooltip:SetOwner(parent, "ANCHOR_CURSOR_RIGHT", 30, -12)
end)

local function UnitClassColor(unit)
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        return GetClassColor(class)
    end
    return 1, 1, 1, "ffffffff"
end

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    local name = self:GetName()

    local _, unit = self:GetUnit()
    if UnitIsPlayer(unit) then
        -- 公會文字著色
        local guildInfo = GetGuildInfo(unit)
        if guildInfo then
            _G[name .. "TextLeft2"]:SetTextColor(1, 0, 1)
        end

        -- 等級職業文字著色
        local classLine = guildInfo and 3 or 2
        _G[name .. "TextLeft" .. classLine]:SetTextColor(UnitClassColor(unit))

        -- 陣營文字著色
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

-- 顯示目標
GameTooltip:HookScript("OnUpdate", function(self)
    if (not UnitExists("mouseover")) then
        return
    end

    local targetLine
    for i = 2, self:NumLines() do
        local line = _G[self:GetName() .. "TextLeft" .. i]
        local text = line:GetText() or ""
        if text:find("^選取目標: ") then
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

local function FormatNumber(number)
    if number >= 1e8 then
        return format("%.2f億", number / 1e8)
    elseif number >= 1e4 then
        return format("%.2f萬", number / 1e4)
    end
    return number
end

-- 顯示生命值
GameTooltipStatusBar.text = GameTooltipStatusBar:CreateFontString()
GameTooltipStatusBar.text:SetFont(GameFontNormal:GetFont(), 11, "Outline")
GameTooltipStatusBar.text:SetPoint("Center")
GameTooltipStatusBar:HookScript("OnValueChanged", function(self, value)
    local _, max = self:GetMinMaxValues();
    local percent = ceil(value / max * 100)
    GameTooltipStatusBar.text:SetText("(" .. percent .. "%) " .. FormatNumber(value) .. " / " .. FormatNumber(max))
end)

-- 顯示光環ID
hooksecurefunc(GameTooltip, "SetUnitAura", function(self, ...)
    local _, _, _, _, _, _, _, _, _, id = UnitAura(...)
    self:AddLine(" ")
    self:AddLine("|cff00ffccAura ID:|r " .. id)
    self:Show()
end)

