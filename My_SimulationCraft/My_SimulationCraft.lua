local simulation = CreateFrame("Frame", "SimulationCraftFrame", UIParent, "DialogBoxFrame")
simulation:SetSize(700, 450)
simulation:SetPoint("Center")
simulation:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })

local scroll = CreateFrame("ScrollFrame", nil, simulation, "UIPanelScrollFrameTemplate")
scroll:SetSize(650, 420)
scroll:SetPoint("Top", 0, -30)
scroll:SetPoint("Bottom", SimulationCraftFrameButton, "Top", 0, 5)

local editBox = CreateFrame("EditBox", nil, scroll)
editBox:SetSize(630, 380)
editBox:SetAllPoints()
editBox:SetMaxLetters(99999)
editBox:SetMultiLine(true)
editBox:SetAutoFocus(true)
editBox:EnableMouse(true)
editBox:SetFontObject(ChatFontNormal)

scroll:SetScrollChild(editBox)

local tooltip = CreateFrame("GameTooltip", "SimulationTooltip", UIParent, "GameTooltipTemplate")
local profiles = ""
local simRaces = {
    ["BloodElf"] = "blood_elf",
    ["NightElf"] = "night_elf",
    ["MagharOrc"] = "maghar_orc",
    ["DarkIronDwarf"] = "dark_iron_dwarf",
    ["Scourge"] = "undead",
}
local simSpecs = {
    -- Death Knight
    [250] = "blood",
    [251] = "frost",
    [252] = "unholy",
    -- Demon Hunter
    [577] = "havoc",
    [581] = "vengeance",
    -- Druid 
    [102] = "balance",
    [103] = "feral",
    [104] = "guardian",
    [105] = "restoration",
    -- Hunter 
    [253] = "beast mastery",
    [254] = "marksmanship",
    [255] = "survival",
    -- Mage 
    [62] = "arcane",
    [63] = "fire",
    [64] = "frost",
    -- Monk 
    [268] = "brewmaster",
    [269] = "windwalker",
    [270] = "mistweaver",
    -- Paladin 
    [65] = "joly",
    [66] = "protection",
    [70] = "retribution",
    -- Priest 
    [256] = "discipline",
    [257] = "holy",
    [258] = "shadow",
    -- Rogue 
    [259] = "assassination",
    [260] = "outlaw",
    [261] = "subtlety",
    -- Shaman 
    [262] = "elemental",
    [263] = "enhancement",
    [264] = "restoration",
    -- Warlock 
    [265] = "affliction",
    [266] = "demonology",
    [267] = "destruction",
    -- Warrior 
    [71] = "arms",
    [72] = "fury",
    [73] = "protection"
}
local slots = { "head", "neck", "shoulder", nil, "chest", "waist", "legs", "feet", "wrist", "hands", "finger1",
                "finger2", "trinket1", "trinket2", "back", "main_hand", "off_hand" }

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

local function GetGemId(link, index)
    local _, gemLink = GetItemGem(link, index)
    if gemLink then
        local gemString = gemLink:match("item:(%d+)")
        if gemString then
            return tonumber(gemString)
        end
    end
end

local function GetItem(link)
    local text = ""
    local itemString = link:match("item:([%-?%d:]+)")
    local stringTable = { strsplit(":", itemString) }

    local id = stringTable[1]
    text = ",id=" .. id

    local enchant = stringTable[2]
    if enchant ~= "" then
        text = text .. ",enchant_id=", enchant
    end

    local gems = {}
    for i = 3, 6 do
        local gem = stringTable[i]
        if gem ~= "" then
            local gemId = GetGemId(link, i - 2)
            if gemId then
                gems[i - 2] = gemId
            end
        end
    end
    if #gems > 0 then
        text = text .. ",gem_id=" .. table.concat(gems, "/")
    end

    if stringTable[13] ~= "" then
        local bonuses = {}
        local numBonuses = tonumber(stringTable[13])
        for i = 14, 14 + numBonuses do
            local bonus = stringTable[i]
            if bonus ~= "" then
                bonuses[i - 13] = bonus
            end
        end
        if #bonuses > 0 then
            text = text .. ",bonus_id=" .. table.concat(bonuses, "/")
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
                text = text .. slots[i] .. "=" .. GetItem(link) .. "\n"
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
                local _, bank, bags, void, slot, bag = EquipmentManager_UnpackLocation(bitString)
                local itemLocation
                if ItemLocation then
                    if bag then
                        itemLocation = ItemLocation:CreateFromBagAndSlot(bag, slot)
                    else
                        itemLocation = ItemLocation:CreateFromEquipmentSlot(slot)
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
                                local line = _G["SimulationTooltipTextLeft" .. j]:GetText() or ""
                                level = line:match(gsub(ITEM_LEVEL, "%%d", "(%%d+)"))
                                if level then
                                    level = tonumber(level)
                                    break
                                end
                            end

                            text = text .. "# " .. name .. " (" .. level .. ")\n"
                            text = text .. "# " .. slots[i] .. "=" .. GetItem(link) .. "\n#\n"
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
    profiles = string.lower(class) .. '="' .. name .. '"\n'

    local level = UnitLevel("player")
    profiles = profiles .. "level=" .. level .. "\n"

    local _, race = UnitRace("player")
    race = simRaces[race] and simRaces[race] or race
    profiles = profiles .. "race=" .. string.lower(race) .. "\n"

    local specId = GetSpecialization()
    local globalSpecId = GetSpecializationInfo(specId)
    local spec = simSpecs[globalSpecId]
    profiles = profiles .. "spec=" .. spec .. "\n"

    local talents = GetTalents()
    profiles = profiles .. "talents=" .. talents .. "\n\n"

    profiles = profiles .. GetEquippedItems() .. "\n"

    profiles = profiles .. GetBagItems()
end

SlashCmdList["SIM"] = function()
    GetProfiles()
    editBox:SetText(profiles)
    simulation:Show()
end

SLASH_SIM1 = "/sim"