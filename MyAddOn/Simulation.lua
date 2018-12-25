local simRaces = {
    ["BloodElf"] = "blood_elf",
    ["NightElf"] = "night_elf",
    ["MagharOrc"] = "maghar_orc",
    ["DarkIronDwarf"] = "dark_iron_dwarf",
    ["Scourge"] = "undead",
}
local simSpecs = {
    [250] = "blood",
    [251] = "frost",
    [252] = "unholy",

    [577] = "havoc",
    [581] = "vengeance",

    [102] = "balance",
    [103] = "feral",
    [104] = "guardian",
    [105] = "restoration",

    [253] = "beast mastery",
    [254] = "marksmanship",
    [255] = "survival",

    [62] = "arcane",
    [63] = "fire",
    [64] = "frost",

    [268] = "brewmaster",
    [269] = "windwalker",
    [270] = "mistweaver",

    [65] = "joly",
    [66] = "protection",
    [70] = "retribution",

    [256] = "discipline",
    [257] = "holy",
    [258] = "shadow",

    [259] = "assassination",
    [260] = "outlaw",
    [261] = "subtlety",

    [262] = "elemental",
    [263] = "enhancement",
    [264] = "restoration",

    [265] = "affliction",
    [266] = "demonology",
    [267] = "destruction",

    [71] = "arms",
    [72] = "fury",
    [73] = "protection"
}
local simSlots = { "head", "neck", "shoulder", nil, "chest", "waist", "legs", "feet", "wrist", "hands", "finger1",
                   "finger2", "trinket1", "trinket2", "back", "main_hand", "off_hand" }
local profile = ""
local tooltip = CreateFrame("GameTooltip", "MySimulationTooltip", UIParent, "GameTooltipTemplate")
local simulation = CreateFrame("Frame", "MySimulationFrame", UIParent, "DialogBoxFrame")
local scroll = CreateFrame("ScrollFrame", nil, simulation, "UIPanelScrollFrameTemplate")
local editBox = CreateFrame("EditBox", nil, scroll)

simulation:SetSize(700, 450)
simulation:SetPoint("Center")
simulation:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })

scroll:SetSize(650, 420)
scroll:SetPoint("Top", 0, -30)
scroll:SetPoint("Bottom", MySimulationFrameButton, "Top", 0, 5)

editBox:SetSize(630, 380)
editBox:SetAllPoints()
editBox:SetMaxLetters(99999)
editBox:SetMultiLine(true)
editBox:SetAutoFocus(true)
editBox:EnableMouse(true)
editBox:SetFontObject(ChatFontNormal)

scroll:SetScrollChild(editBox)

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

local function GetGemID(link, index)
    local _, gemLink = GetItemGem(link, index)
    if gemLink then
        local gemString = strmatch(gemLink, "item:(%d+)")
        if gemString then
            return tonumber(gemString)
        end
    end
end

local function GetItem(link, itemLoc)
    local text = ""
    local itemString = strmatch(link, "item:([%-?%d:]+)")
    local itemStringTable = { strsplit(":", itemString) }

    local id = itemStringTable[1]
    text = ",id=" .. id

    local enchant = itemStringTable[2]
    if enchant ~= "" then
        text = text .. ",enchant_id=", enchant
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

local function GetEquippedItems()
    local text = ""
    for i = 1, 17 do
        if i ~= 4 then
            local link = GetInventoryItemLink("player", i)
            if link then
                local itemLoc = ItemLocation and ItemLocation:CreateFromEquipmentSlot(i)
                text = text .. simSlots[i] .. "=" .. GetItem(link, itemLoc) .. "\n"
            end
        end
    end
    return text
end

local function GetBagItems()
    local text = ""
    for i = 1, 17 do
        if i ~= 4 and i ~= 12 and i ~= 14 then
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
                        slot = slot - 47
                    end

                    local _, _, _, _, _, _, itemLink = GetContainerItemInfo(container, slot)
                    if itemLink then
                        local name, link, quality = GetItemInfo(itemLink)
                        if IsEquippableItem(itemLink) and quality ~= 6 then
                            local level
                            tooltip:SetOwner(UIParent, "ANCHOR_NONE")
                            tooltip:SetBagItem(container, slot)
                            for j = 2, 5 do
                                local lineText = _G[tooltip:GetName() .. "TextLeft" .. j]:GetText() or ""
                                level = strmatch(lineText, gsub(ITEM_LEVEL, "%%d", "(%%d+)"))
                                if level then
                                    level = tonumber(level)
                                    break
                                end
                            end

                            text = text .. "# " .. name .. " (" .. (level or 0) .. ")" .. "\n"
                            text = text .. "# " .. simSlots[i] .. "=" .. GetItem(link, itemLoc) .. "\n#\n"
                        end
                    end
                end
            end
        end
    end
    return text
end

local function GetProfiles()
    local _, class = UnitClass("player")
    local name = UnitName("player")
    profile = strlower(class) .. '="' .. name .. '"\n'

    local level = UnitLevel("player")
    profile = profile .. "level=" .. level .. "\n"

    local _, race = UnitRace("player")
    race = simRaces[race] and simRaces[race] or race
    profile = profile .. "race=" .. strlower(race) .. "\n"

    local specID = GetSpecialization()
    local globalSpecID = GetSpecializationInfo(specID)
    local spec = simSpecs[globalSpecID]
    profile = profile .. "spec=" .. spec .. "\n"

    local talents = GetTalents()
    profile = profile .. "talents=" .. talents .. "\n\n"

    profile = profile .. GetEquippedItems() .. "\n"

    profile = profile .. GetBagItems()
end

SLASH_SIM1 = "/sim"
SlashCmdList["SIM"] = function()
    GetProfiles()
    editBox:SetText(profile)
    editBox:HighlightText()
    simulation:Show()
end