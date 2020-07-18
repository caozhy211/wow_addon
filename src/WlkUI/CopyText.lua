---@type Frame
local copyFrame = CreateFrame("Frame", "WLK_CopyFrame", UIParent, "DialogBoxFrame")
--- DialogBoxButton 底部相对 DialogBoxFrame 底部偏移 16px，DialogBoxButton 的高度是 32px，ScrollBar 左边相对 ScrollFrame 右
--- 边偏移 6px，ScrollBar 的宽度是 16px
copyFrame:SetSize(350 + 16 * 2 + 6 + 16, 200 + 16 * 2 + 5 + 32)
copyFrame:SetPoint("CENTER")
copyFrame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/PVPFrame/UI-Character-PVP-Highlight",
    edgeSize = 16,
    insets = { left = 8, right = 8, top = 8, bottom = 8, },
})
local _, class = UnitClass("player")
local r, g, b = GetClassColor(class)
copyFrame:SetBackdropBorderColor(r, g, b, 0.8)

---@type ScrollFrame
local scrollFrame = CreateFrame("ScrollFrame", nil, copyFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 16, -16)
scrollFrame:SetPoint("BOTTOMRIGHT", -(16 + 6 + 16), 5 + 32 + 16)

---@type EditBox
local editBox = CreateFrame("EditBox", nil, scrollFrame)
editBox:SetSize(scrollFrame:GetSize())
editBox:SetFontObject("ChatFontNormal")
editBox:SetMultiLine(true)
editBox:SetAutoFocus(false)
editBox:SetScript("OnEscapePressed", editBox.ClearFocus)

scrollFrame:SetScrollChild(editBox)

--- 显示复制窗口
---@param contents string
local function ShowCopyFrame(contents)
    copyFrame:Show()
    editBox:SetText(contents)
    editBox:HighlightText()
    editBox:SetFocus()
end

--- 使用快捷键显示 fstack 选中的对象名称
tinsert(FrameStackTooltip.commandKeys, KeyCommand_Create(function()
    ---@type UIObject
    local object = FrameStackTooltip.highlightFrame
    if object then
        local name = object:GetDebugName()
        ShowCopyFrame(name)
    end
end, KeyCommand.RUN_ON_DOWN, KeyCommand_CreateKey("F5")))

local enumsText
--- 显示枚举值和部分数字常量
SlashCmdList["ENUMS"] = function()
    -- enumsText 是 nil 则需要遍历
    if enumsText == nil then
        local textTable = {}
        local version, build = GetBuildInfo()
        tinsert(textTable, "--- version: " .. version .. "." .. build .. "\n\nEnum = {\n")

        for name, value in pairs(Enum) do
            tinsert(textTable, "    " .. name .. " = {\n")
            for n, v in pairs(value) do
                tinsert(textTable, "        " .. n .. " = " .. v .. ",\n")
            end
            tinsert(textTable, "    },\n")
        end
        tinsert(textTable, "}\n\n")

        for name, value in pairs(_G) do
            if strfind(name, "^LE_") or strfind(name, ".+_LE_") then
                tinsert(textTable, name .. " = " .. value .. "\n")
            end
        end

        enumsText = table.concat(textTable)
    end

    ShowCopyFrame(enumsText)
end
SLASH_ENUMS1 = "/enums"

--- SimC 种族名
local races = {
    ["NightElf"] = "night_elf",
    ["Scourge"] = "undead",
    ["BloodElf"] = "blood_elf",
    ["VoidElf"] = "void_elf",
    ["LightforgedDraenei"] = "lightforged_draenei",
    ["DarkIronDwarf"] = "dark_iron_dwarf",
    ["HighmountainTauren"] = "highmountain_tauren",
    ["MagharOrc"] = "maghar_orc",
    ["ZandalariTroll"] = "zandalari_troll",
}

--- 赞达拉洛阿增益
local zandalariLoaBuffs = {
    [292359] = "akunda",
    [292360] = "bwonsamdi",
    [292362] = "gonk",
    [292363] = "kimbul",
    [292364] = "kragwa",
    [292361] = "paku",
}

--- 获取赞达拉洛阿增益
local function GetZandalariLoa()
    local zandalariLoa
    for index = 1, BUFF_MAX_DISPLAY do
        local _, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", index)
        if spellId == nil then
            break
        end
        if zandalariLoaBuffs[spellId] then
            zandalariLoa = zandalariLoaBuffs[spellId]
            break
        end
    end
    return zandalariLoa
end

--- SimC 专精名
local specs = {
    -- 死亡骑士
    [250] = "blood", -- 鲜血
    [251] = "frost", -- 冰霜
    [252] = "unholy", -- 邪恶
    -- 恶魔猎手
    [577] = "havoc", -- 浩劫
    [581] = "vengeance", -- 复仇
    -- 德鲁伊
    [102] = "balance", -- 平衡
    [103] = "feral", -- 野性
    [104] = "guardian", -- 守护
    [105] = "restoration", -- 恢复
    -- 猎人
    [253] = "beast mastery", -- 野兽控制
    [254] = "marksmanship", -- 射击
    [255] = "survival", -- 生存
    -- 法师
    [62] = "arcane", -- 奥术
    [63] = "fire", -- 火焰
    [64] = "frost", -- 冰霜
    -- 武僧
    [268] = "brewmaster", -- 酒仙
    [269] = "windwalker", -- 织雾
    [270] = "mistweaver", -- 踏风
    -- 圣骑士
    [65] = "joly", -- 神圣
    [66] = "protection", -- 防护
    [70] = "retribution", -- 惩戒
    -- 牧师
    [256] = "discipline", -- 戒律
    [257] = "holy", -- 神圣
    [258] = "shadow", -- 暗影
    -- 潜行者
    [259] = "assassination", -- 奇袭
    [260] = "outlaw", -- 狂徒
    [261] = "subtlety", -- 敏锐
    -- 萨满祭司
    [262] = "elemental", -- 元素
    [263] = "enhancement", -- 增强
    [264] = "restoration", -- 恢复
    -- 术士
    [265] = "affliction", -- 痛苦
    [266] = "demonology", -- 恶魔
    [267] = "destruction", -- 毁灭
    -- 战士
    [71] = "arms", -- 武器
    [72] = "fury", -- 狂怒
    [73] = "protection", -- 防护
}

--- 获取天赋
local function GetTalents()
    local talents = ""
    local rows = 7
    local columns = 3
    for i = 1, rows do
        local getSelected
        for j = 1, columns do
            local _, _, _, selected = GetTalentInfo(i, j, GetActiveSpecGroup())
            if selected then
                talents = talents .. j
                getSelected = true
                break
            end
        end

        if not getSelected then
            talents = talents .. 0
        end
    end
    return talents
end

--- SimC 装备槽名
local slots = {
    "head", "neck", "shoulder", nil, "chest", "waist", "legs", "feet", "wrist", "hands", "finger1", "finger2",
    "trinket1", "trinket2", "back", "main_hand", "off_hand",
}

--- 获取宝石 ID
local function GetGemID(link, index)
    local _, gemLink = GetItemGem(link, index)
    if gemLink then
        return GetItemInfoFromHyperlink(gemLink)
    end
end

--- 获取物品信息
local function GetItem(link, itemLoc)
    local text = ""
    local itemString = strmatch(link, "item:([%-?%d:]+)")
    local itemStringTable = { strsplit(":", itemString) }

    local id = itemStringTable[1]
    text = ",id=" .. id

    local enchant = itemStringTable[2]
    if enchant ~= "" then
        text = text .. ",enchant_id=" .. enchant
    end

    local gems = {}
    for i = 3, 6 do
        local gem = itemStringTable[i]
        if gem ~= "" then
            local gemID = GetGemID(link, i - 2)
            if gemID then
                gems[i - 2] = gemID
            end
        end
    end
    if #gems > 0 then
        text = text .. ",gem_id=" .. table.concat(gems, "/")
    end

    local flag = itemStringTable[11] == "" and 0 or tonumber(itemStringTable[11])
    local offset = 14

    if itemStringTable[13] ~= "" then
        local bonuses = {}
        local numBonuses = tonumber(itemStringTable[13])
        for i = 14, 13 + numBonuses do
            local bonus = itemStringTable[i]
            if bonus ~= "" then
                bonuses[i - 13] = bonus
            end
        end
        if #bonuses > 0 then
            text = text .. ",bonus_id=" .. table.concat(bonuses, "/")
        end
        offset = offset + #bonuses
    end

    if bit.band(flag, 0x4) == 0x4 then
        offset = offset + 1
    end

    if bit.band(flag, 0x200) == 0x200 then
        text = text .. ",drop_level=" .. itemStringTable[offset]
    end

    if itemStringTable[12] ~= "" then
        text = text .. ",context=" .. itemStringTable[12]
    end

    if itemLoc and C_AzeriteEmpoweredItem then
        if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLoc) then
            local azeritePowers = {}
            local tierInfo = C_AzeriteEmpoweredItem.GetAllTierInfo(itemLoc)
            for i = 1, #tierInfo do
                local tier = tierInfo[i]
                for j = 1, #tier.azeritePowerIDs do
                    local powerID = tier.azeritePowerIDs[j]
                    if C_AzeriteEmpoweredItem.IsPowerSelected(itemLoc, powerID) then
                        azeritePowers[#azeritePowers + 1] = powerID
                    end
                end
            end
            text = text .. ",azerite_powers=" .. table.concat(azeritePowers, "/")
        end

        if C_AzeriteItem.IsAzeriteItem(itemLoc) then
            text = text .. ",azerite_level=" .. C_AzeriteItem.GetPowerLevel(itemLoc)
        end
    end

    return text
end

--- 获取已装备的物品
local function GetEquippedItems()
    local result = ""
    for i = 1, 17 do
        if i ~= 4 then
            local link = GetInventoryItemLink("player", i)
            if link then
                local itemLoc = ItemLocation and ItemLocation:CreateFromEquipmentSlot(i)
                result = result .. slots[i] .. "=" .. GetItem(link, itemLoc) .. "\n"
            end
        end
    end
    return result
end

---@type GameTooltip
local scanner = CreateFrame("GameTooltip", "WLK_BagScanner", UIParent, "GameTooltipTemplate")

--- 获取背包中的物品
local function GetBagItems()
    local text = ""
    for i = INVSLOT_HEAD, INVSLOT_OFFHAND do
        if i ~= INVSLOT_BODY and i ~= INVSLOT_FINGER2 and i ~= INVSLOT_TRINKET2 then
            local slotItems = {}
            GetInventoryItemsForSlot(i, slotItems)
            for bitString, _ in pairs(slotItems) do
                local _, bank, bags, _, slot, bag = EquipmentManager_UnpackLocation(bitString)

                local itemLoc
                if ItemLocation then
                    if bag == nil then
                        itemLoc = ItemLocation:CreateFromEquipmentSlot(slot)
                    else
                        itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
                    end
                end

                if bags or bank then
                    local container
                    if bags then
                        container = bag
                    elseif bank then
                        container = BANK_CONTAINER
                        slot = slot - 51
                    end

                    local _, _, _, _, _, _, itemLink = GetContainerItemInfo(container, slot)
                    if itemLink then
                        local name, link, quality = GetItemInfo(itemLink)
                        if IsEquippableItem(itemLink) and quality ~= LE_ITEM_QUALITY_ARTIFACT then
                            local level
                            scanner:SetOwner(UIParent, "ANCHOR_NONE")
                            scanner:SetBagItem(container, slot)
                            for j = 2, 5 do
                                local lineText = _G[scanner:GetName() .. "TextLeft" .. j]:GetText() or ""
                                level = strmatch(lineText, gsub(ITEM_LEVEL, "%%d", "%%d+%%((%%d+)%%)"))
                                        or strmatch(lineText, gsub(ITEM_LEVEL, "%%d", "(%%d+)"))
                                if level then
                                    level = tonumber(level)
                                    break
                                end
                            end

                            text = text .. "# " .. name .. " (" .. (level or 0) .. ")" .. "\n"
                            text = text .. "# " .. slots[i] .. "=" .. GetItem(link, itemLoc) .. "\n#\n"
                        end
                    end
                end
            end
        end
    end
    return text
end

--- 获取 SimC 文本
local function GetSimCText()
    local result
    local name = UnitName("player")
    result = strlower(class) .. '="' .. name .. '"\n'

    local level = UnitLevel("player")
    result = result .. "level=" .. level .. "\n"

    local _, race = UnitRace("player")
    race = races[race] or race
    result = result .. "race=" .. strlower(race) .. "\n"
    if race == "zandalari_troll" then
        local zandalariLoa = GetZandalariLoa()
        result = result .. "zandalari_loa=" .. zandalariLoa .. "\n"
    end

    local specIndex = GetSpecialization()
    local specID = GetSpecializationInfo(specIndex)
    local spec = specs[specID]
    result = result .. "spec=" .. spec .. "\n"

    local talents = GetTalents()
    result = result .. "talents=" .. talents .. "\n\n"

    local equippedItems = GetEquippedItems()
    result = result .. equippedItems .. "\n"

    local bagItems = GetBagItems()
    result = result .. bagItems

    return result
end

--- 显示 SimC 文本
SlashCmdList["SCT"] = function()
    ShowCopyFrame(GetSimCText())
end
SLASH_SCT1 = "/sct"
