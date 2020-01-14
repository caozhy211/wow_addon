--- 设置鼠标提示位置跟随鼠标
---@param tooltip GameTooltip
hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    tooltip:SetOwner(parent, "ANCHOR_CURSOR_RIGHT", 30, -30)
end)

--- 格式化数字
local function FormatNumber(number)
    if number >= 1e8 then
        return format("%.2f" .. SECOND_NUMBER_CAP, number / 1e8)
    elseif number >= 1e4 then
        return format("%.1f" .. SECOND_NUMBER, number / 1e4)
    end
    return number
end

---@type StatusBar
local gameTooltipStatusBar = GameTooltipStatusBar

---@type FontString
local gameTooltipStatusBarLabel = gameTooltipStatusBar:CreateFontString(nil, "ARTWORK", "Game11Font_o1")
gameTooltipStatusBarLabel:SetPoint("CENTER")

--- 鼠标提示的血条显示数值
---@param self StatusBar
gameTooltipStatusBar:HookScript("OnValueChanged", function(self, value)
    local _, maxValue = self:GetMinMaxValues()
    if maxValue > 0 then
        gameTooltipStatusBarLabel:SetFormattedText("(%d%%) %s/%s", value / maxValue * 100, FormatNumber(value),
                FormatNumber(maxValue))
    else
        gameTooltipStatusBarLabel:SetText("")
    end
end)

---@type GameTooltip
local scannerTooltip = CreateFrame("GameTooltip", "WLK_Tooltip", UIParent, "GameTooltipTemplate")

local inspectUnit, inspectGUID

--- 获取当前查看单位的装等
local function GetUnitAverageItemLevel()
    local totalItemLevel = 0
    local waiting
    local mEquipSlot, oEquipSlot
    local mLevel, oLevel = 0, 0
    for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_OFFHAND do
        -- 不计算衬衫的等级
        if i ~= INVSLOT_BODY then
            scannerTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            scannerTooltip:SetInventoryItem(inspectUnit, i)
            local link = GetInventoryItemLink(inspectUnit, i) or select(2, scannerTooltip:GetItem())
            if link then
                local name, _, quality, _, _, _, _, _, equipLoc = GetItemInfo(link)
                if not waiting and not name then
                    -- 服务器未返回数据
                    waiting = true
                else
                    local level
                    if quality ~= LE_ITEM_QUALITY_HEIRLOOM then
                        -- 非传家宝直接使用 GetDetailedItemLevelInfo 获取物品等级
                        level = GetDetailedItemLevelInfo(link)
                    else
                        -- 传家宝使用鼠标提示获取物品等级
                        for j = 2, 3 do
                            ---@type FontString
                            local line = _G[scannerTooltip:GetName() .. "TextLeft" .. j]
                            if line then
                                local text = line:GetText()
                                if not level and text then
                                    level = strmatch(text, gsub(ITEM_LEVEL, "%%d", "(%%d+)"))
                                    if level then
                                        level = tonumber(level)
                                        break
                                    end
                                end
                            end
                        end
                    end
                    level = level or 0
                    if i == INVSLOT_MAINHAND then
                        mLevel = level
                        mEquipSlot = equipLoc
                    elseif i == INVSLOT_OFFHAND then
                        oLevel = level
                        oEquipSlot = equipLoc
                    else
                        totalItemLevel = totalItemLevel + level
                    end
                end
            end
        end
    end
    if not waiting then
        if mEquipSlot == "INVTYPE_RANGED" or mEquipSlot == "INVTYPE_RANGEDRIGHT"
                or mEquipSlot == "INVTYPE_2HWEAPON" or oEquipSlot == "INVTYPE_2HWEAPON" then
            totalItemLevel = totalItemLevel + max(mLevel, oLevel) * 2
        else
            totalItemLevel = totalItemLevel + mLevel + oLevel
        end
        return floor(totalItemLevel / 16 + 0.5)
    end
    return "..."
end

--- 获取当前查看单位的专精
local function GetUnitSpecialization()
    if UnitIsUnit(inspectUnit, "player") then
        local specIndex = GetSpecialization()
        if not specIndex then
            -- 未学习专精
            return ""
        end
        local _, specName, _, icon = GetSpecializationInfo(specIndex)
        return "|T" .. icon .. ":0|t " .. specName
    end
    local specID = GetInspectSpecialization(inspectUnit)
    if not specID then
        -- 未学习专精
        return ""
    end
    if specID == 0 then
        -- 服务器未返回数据
        return "..."
    end
    local _, specName, _, icon = GetSpecializationInfoByID(specID)
    return "|T" .. icon .. ":0|t " .. specName
end

--- 鼠标提示显示装等和专精
local function GameTooltipShowItemLevelAndSpec(iLevel, specName)
    iLevel = HIGHLIGHT_FONT_COLOR_CODE .. iLevel .. FONT_COLOR_CODE_CLOSE
    ---@type FontString
    local index
    -- 在鼠标提示内容中找到装等专精标签在第几行
    for i = GameTooltip:NumLines(), 2, -1 do
        ---@type FontString
        local line = _G["GameTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text and strfind(text, "^" .. STAT_AVERAGE_ITEM_LEVEL .. "：") then
                index = i
                break
            end
        end
    end
    if index then
        -- 鼠标提示中已经有装等专精标签，更新标签内容
        ---@type FontString
        local levelLabel = _G["GameTooltipTextLeft" .. index]
        levelLabel:SetText(STAT_AVERAGE_ITEM_LEVEL .. "：" .. iLevel)
        ---@type FontString
        local specLabel = _G["GameTooltipTextRight" .. index]
        specLabel:SetText(specName)
    else
        -- 没有装等专精标签，则添加标签
        GameTooltip:AddDoubleLine(STAT_AVERAGE_ITEM_LEVEL .. "：" .. iLevel, specName)
        GameTooltip:Show()
    end
end

---@type Frame
local eventListener = CreateFrame("Frame")

eventListener:RegisterEvent("INSPECT_READY")

eventListener:SetScript("OnEvent", function(...)
    local _, _, guid = ...
    if guid == inspectGUID then
        -- 获取装等和专精并添加到鼠标提示
        local iLevel = GetUnitAverageItemLevel()
        local specName = GetUnitSpecialization()
        GameTooltipShowItemLevelAndSpec(iLevel, specName)
        if iLevel == "..." or specName == "..." then
            -- 如果装等或专精返回 “...”，表示服务器未返回数据，需要重新查看单位并获取数据
            ClearInspectPlayer()
            NotifyInspect(inspectUnit)
        end
    end
end)

--- 鼠标停留在单位上时，修改玩家单位鼠标提示文字颜色，并查看单位
---@param self GameTooltip
GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    local _, unit = self:GetUnit()
    if UnitIsPlayer(unit) then
        -- 修改公会颜色
        local guildInfo = GetGuildInfo(unit)
        if guildInfo then
            ---@type FontString
            local guildLine = _G["GameTooltipTextLeft2"]
            guildLine:SetTextColor(Chat_GetChannelColor(ChatTypeInfo["GUILD"]))
        end
        -- 修改职业颜色
        local classLineIndex = guildInfo and 3 or 2
        ---@type FontString
        local classLine = _G["GameTooltipTextLeft" .. classLineIndex]
        local _, class = UnitClass(unit)
        classLine:SetTextColor(GetClassColor(class))
        -- 修改阵营颜色
        ---@type FontString
        local factionLine = _G["GameTooltipTextLeft" .. (classLineIndex + 1)]
        factionLine:SetTextColor(GetTableColor(GetFactionColor(UnitFactionGroup(unit))))
    end

    -- 查看单位以获取装等和专精
    if CanInspect(unit) then
        inspectUnit = unit
        inspectGUID = UnitGUID(unit)
        ClearInspectPlayer()
        NotifyInspect(inspectUnit)
    end
end)

--- 显示物品 ID
---@param tooltip GameTooltip
local function ShowItemID(tooltip)
    local _, link = tooltip:GetItem()
    local id = GetItemInfoFromHyperlink(link)
    if id then
        tooltip:AddLine(" ")
        tooltip:AddLine(ITEMS .. ID .. "：" .. HIGHLIGHT_FONT_COLOR_CODE .. id .. FONT_COLOR_CODE_CLOSE)
        tooltip:Show()
    end
end

GameTooltip:HookScript("OnTooltipSetItem", ShowItemID)
---@type GameTooltip
local itemRefTooltip = ItemRefTooltip
itemRefTooltip:HookScript("OnTooltipSetItem", ShowItemID)
---@type GameTooltip
local shoppingTooltip1 = ShoppingTooltip1
shoppingTooltip1:HookScript("OnTooltipSetItem", ShowItemID)
---@type GameTooltip
local shoppingTooltip2 = ShoppingTooltip2
shoppingTooltip2:HookScript("OnTooltipSetItem", ShowItemID)
---@type GameTooltip
local itemRefShoppingTooltip1 = ItemRefShoppingTooltip1
itemRefShoppingTooltip1:HookScript("OnTooltipSetItem", ShowItemID)
---@type GameTooltip
local itemRefShoppingTooltip2 = ItemRefShoppingTooltip2
itemRefShoppingTooltip2:HookScript("OnTooltipSetItem", ShowItemID)

--- 检查法术 ID 是否已经显示
---@param tooltip GameTooltip
local function SpellIDIsShown(tooltip)
    for i = 1, tooltip:NumLines() do
        ---@type FontString
        local line = _G[tooltip:GetName() .. "TextLeft" .. i]
        if line then
            local text = line:GetText()
            if strfind(text, SPELLS .. ID .. "：") then
                return true
            end
        end
    end
end

--- 显示法术 ID
---@param self GameTooltip
GameTooltip:HookScript("OnTooltipSetSpell", function(self)
    local _, id = self:GetSpell()
    -- 防止天赋技能显示两次 SpellID
    if id and not SpellIDIsShown(self) then
        self:AddLine(" ")
        self:AddLine(SPELLS .. ID .. "：" .. HIGHLIGHT_FONT_COLOR_CODE .. id .. FONT_COLOR_CODE_CLOSE)
        self:Show()
    end
end)

--- 显示光环 ID
---@param self GameTooltip
hooksecurefunc(GameTooltip, "SetUnitAura", function(self, ...)
    local id = select(10, UnitAura(...))
    if id then
        self:AddLine(" ")
        self:AddLine(AURAS .. ID .. "：" .. HIGHLIGHT_FONT_COLOR_CODE .. id .. FONT_COLOR_CODE_CLOSE)
        self:Show()
    end
end)

--- 显示鼠标悬停单位的目标
---@param self GameTooltip
GameTooltip:HookScript("OnUpdate", function(self, elapsed)
    local unit = "mouseovertarget"
    if not UnitExists(unit) then
        return
    end

    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < TOOLTIP_UPDATE_TIME then
        return
    end
    self.elapsed = 0

    ---@type FontString
    local targetLine
    -- 获取目标行标签
    for i = self:NumLines(), 2, -1 do
        ---@type FontString
        local line = _G["GameTooltipTextLeft" .. i]
        if strfind(line:GetText() or "", "^" .. TARGET .. "：") then
            targetLine = line
            break
        end
    end
    local target
    if UnitIsUnit(unit, "player") then
        -- 目标是你
        target = RED_FONT_COLOR_CODE .. ">>" .. YOU .. "<<" .. FONT_COLOR_CODE_CLOSE
    else
        target = UnitName(unit)
        if UnitIsPlayer(unit) then
            -- 目标是玩家，则使用职业颜色着色
            local _, class = UnitClass(unit)
            target = WrapTextInColorCode(target, select(4, GetClassColor(class)))
        else
            target = HIGHLIGHT_FONT_COLOR_CODE .. target .. FONT_COLOR_CODE_CLOSE
        end
    end

    if targetLine then
        -- 目标行标签已存在，则更新
        targetLine:SetText(TARGET .. "：" .. target)
    else
        -- 目标行标签不存在，则添加目标行标签
        self:AddLine(TARGET .. "：" .. target)
        self:Show()
    end
end)
