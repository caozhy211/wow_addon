local size1 = 27
local borderSize = size1 + 2
local spacing1 = 3
local offset1 = size1 + spacing1
local size2 = 29
local spacing2 = 1
local offset2 = size2 + spacing2
local numBuffsPerRow = 15
local numDebuffsPerRow = 8
local size3 = 40
local numberOfAuras = 8
local width = size3 * 4
local height = size3 * 2
local addonName = ...
local auras = { cooldowns = {}, expirationTimes = {}, }
local spec

---@type Frame
local buffFrame = CreateFrame("Frame", "WlkBuffFrame", UIParent)
---@type Frame
local debuffFrame = CreateFrame("Frame", "WlkDebuffFrame", UIParent)
---@type Frame
local listener = CreateFrame("Frame")

SLASH_ADD_BUFF1 = "/ab"
SLASH_ADD_DEBUFF1 = "/ad"
SLASH_ADD_COOLDOWN1 = "/ac"
SLASH_DELETE_COOLDOWN1 = "/dc"

SlashCmdList["ADD_BUFF"] = function(arg)
    local index, buffId, type, id = strsplit(" ", arg, 4)
    index = tonumber(index)
    buffId = tonumber(buffId)
    type = type or "spell"
    id = type ~= "spell" and (tonumber(id) or buffId)
    ---@type WlkAuraButton
    local button = _G["WlkBuff" .. index]
    if button then
        if buffId then
            auras[spec].buffs[index][buffId] = { type = type, id = id, }
        else
            wipe(auras[spec].buffs[index])
        end
        if type == "spell" or (type == "talent" and IsSpellKnown(id)) or (type == "item" and IsEquippedItem(id)) then
            button.icon:SetTexture(GetSpellTexture(buffId))
        end
    end
end

SlashCmdList["ADD_DEBUFF"] = function(arg)
    local index, debuffId, type, id = strsplit(" ", arg, 4)
    index = tonumber(index)
    debuffId = tonumber(debuffId)
    type = type or "spell"
    id = type ~= "spell" and (tonumber(id) or debuffId)
    ---@type WlkAuraButton
    local button = _G["WlkDebuff" .. index]
    if button then
        if debuffId then
            auras[spec].debuffs[index][debuffId] = { type = type, id = id, }
        else
            wipe(auras[spec].debuffs[index])
        end
        if type == "spell" or (type == "talent" and IsSpellKnown(id)) or (type == "item" and IsEquippedItem(id)) then
            button.icon:SetTexture(GetSpellTexture(debuffId))
        end
    end
end

SlashCmdList["ADD_COOLDOWN"] = function(arg)
    local auraId, type, value = strsplit(" ", arg, 3)
    auraId = tonumber(auraId)
    type = type or "spell"
    value = type == "spell" and auraId or tonumber(value)
    auras.cooldowns[auraId] = { type = type, value = value, }
    for i = 1, numberOfAuras do
        ---@type WlkAuraButton
        local button = _G["WlkBuff" .. i]
        local id
        for buffId, v in pairs(auras[spec].buffs[i]) do
            if v.type == "spell" or (v.type == "talent" and IsSpellKnown(v.id))
                    or (v.type == "item" and IsEquippedItem(v.id)) then
                id = buffId
            end
            if id and auras.cooldowns[id] and not button.show then
                local cooldownType = auras.cooldowns[id].type
                local cooldownValue = auras.cooldowns[id].value
                if cooldownType == "internal" then
                    local duration = cooldownValue
                    local expirationTime = auras.expirationTimes[id]
                    local currentTime = GetTime()
                    if duration and expirationTime and currentTime >= expirationTime - duration
                            and currentTime <= expirationTime then
                        CooldownFrame_Set(button.cooldown, expirationTime - duration, duration, duration > 0, true)
                    end
                elseif cooldownType == "item" then
                    CooldownFrame_Set(button.cooldown, GetInventoryItemCooldown("player", cooldownValue))
                elseif cooldownType == "spell" then
                    CooldownFrame_Set(button.cooldown, GetSpellCooldown(cooldownValue))
                end
                break
            end
        end
    end
    for i = 1, numberOfAuras do
        ---@type WlkAuraButton
        local button = _G["WlkDebuff" .. i]
        local id
        for debuffId, v in pairs(auras[spec].debuffs[i]) do
            if v.type == "spell" or (v.type == "talent" and IsSpellKnown(v.id))
                    or (v.type == "item" and IsEquippedItem(v.id)) then
                id = debuffId
            end
            if id and auras.cooldowns[id] and not button.show then
                local cooldownType = auras.cooldowns[id].type
                local cooldownValue = auras.cooldowns[id].value
                if cooldownType == "internal" then
                    local duration = cooldownValue
                    local expirationTime = auras.expirationTimes[id]
                    local currentTime = GetTime()
                    if duration and expirationTime and currentTime >= expirationTime - duration
                            and currentTime <= expirationTime then
                        CooldownFrame_Set(button.cooldown, expirationTime - duration, duration, duration > 0, true)
                    end
                elseif cooldownType == "item" then
                    CooldownFrame_Set(button.cooldown, GetInventoryItemCooldown("player", cooldownValue))
                elseif cooldownType == "spell" then
                    CooldownFrame_Set(button.cooldown, GetSpellCooldown(cooldownValue))
                end
                break
            end
        end
    end
end

SlashCmdList["DELETE_COOLDOWN"] = function(arg)
    local auraId = strsplit(" ", arg)
    auraId = tonumber(auraId)
    if auraId and auras.cooldowns[auraId] then
        auras.cooldowns[auraId] = nil
    end
end

buffFrame:SetSize(width, height)
buffFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -122, 484)
buffFrame:RegisterEvent("PLAYER_LOGIN")
buffFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
buffFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
buffFrame:RegisterEvent("UNIT_AURA")
buffFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        spec = GetSpecialization()
        if not auras[spec] then
            auras[spec] = {
                buffs = { {}, {}, {}, {}, {}, {}, {}, {}, },
                debuffs = { {}, {}, {}, {}, {}, {}, {}, {}, },
            }
        end
        for i = 1, numberOfAuras do
            ---@type WlkAuraButton
            local button = _G["WlkBuff" .. i]
            local id
            for buffId, v in pairs(auras[spec].buffs[i]) do
                if v.type == "spell" or (v.type == "talent" and IsSpellKnown(v.id))
                        or (v.type == "item" and IsEquippedItem(v.id)) then
                    id = buffId
                    button.icon:SetTexture(GetSpellTexture(id))
                end
                if id and auras.cooldowns[id] and not button.show then
                    local cooldownType = auras.cooldowns[id].type
                    local cooldownValue = auras.cooldowns[id].value
                    if cooldownType == "internal" then
                        local duration = cooldownValue
                        local expirationTime = auras.expirationTimes[id]
                        local currentTime = GetTime()
                        if duration and expirationTime and currentTime >= expirationTime - duration
                                and currentTime <= expirationTime then
                            CooldownFrame_Set(button.cooldown, expirationTime - duration, duration, duration > 0, true)
                        end
                    elseif cooldownType == "item" then
                        CooldownFrame_Set(button.cooldown, GetInventoryItemCooldown("player", cooldownValue))
                    elseif cooldownType == "spell" then
                        CooldownFrame_Set(button.cooldown, GetSpellCooldown(cooldownValue))
                    end
                    break
                end
            end
            if not id then
                button.icon:SetTexture(nil)
            end
        end
    elseif event == "UNIT_AURA" then
        for i = 1, numberOfAuras do
            _G["WlkBuff" .. i].show = nil
        end
        local index = 0
        AuraUtil.ForEachAura("player", "HELPFUL", BUFF_MAX_DISPLAY, function(...)
            local _, icon, count, _, duration, expirationTime, _, _, _, id = ...
            if id then
                index = index + 1
                for i = 1, numberOfAuras do
                    ---@type WlkAuraButton
                    local button = _G["WlkBuff" .. i]
                    if auras[spec].buffs[i][id] then
                        button.icon:SetTexture(icon)
                        if count > 1 then
                            button.Count:SetText(count)
                            button.Count:Show()
                        else
                            button.Count:Hide()
                        end
                        CooldownFrame_Set(button.cooldown, expirationTime - duration, duration, duration > 0, true)
                        if auras.cooldowns[id] then
                            local cooldownType = auras.cooldowns[id].type
                            local cooldownValue = auras.cooldowns[id].value
                            if cooldownType == "internal" and abs(button:GetAlpha() - 0.5) < 0.005 then
                                auras.expirationTimes[id] = expirationTime - duration + cooldownValue
                            end
                        end
                        button:SetAlpha(1)
                        button.show = true
                    end
                end
            end
            return index >= BUFF_MAX_DISPLAY
        end)
        for i = 1, numberOfAuras do
            ---@type WlkAuraButton
            local button = _G["WlkBuff" .. i]
            if not button.show then
                button:SetAlpha(0.5)
                button.Count:Hide()
                local id, cooling
                for buffId, v in pairs(auras[spec].buffs[i]) do
                    if v.type == "spell" or (v.type == "talent" and IsSpellKnown(v.id))
                            or (v.type == "item" and IsEquippedItem(v.id)) then
                        id = buffId
                    end
                    if id and auras.cooldowns[id] then
                        cooling = true
                        local cooldownType = auras.cooldowns[id].type
                        local cooldownValue = auras.cooldowns[id].value
                        if cooldownType == "internal" then
                            local duration = cooldownValue
                            local expirationTime = auras.expirationTimes[id]
                            local currentTime = GetTime()
                            if expirationTime and currentTime >= expirationTime - duration
                                    and currentTime <= expirationTime then
                                CooldownFrame_Set(button.cooldown, expirationTime - duration, duration, duration > 0,
                                        true)
                            else
                                CooldownFrame_Clear(button.cooldown)
                            end
                        elseif cooldownType == "item" then
                            CooldownFrame_Set(button.cooldown, GetInventoryItemCooldown("player", cooldownValue))
                        elseif cooldownType == "spell" then
                            CooldownFrame_Set(button.cooldown, GetSpellCooldown(cooldownValue))
                        end
                        break
                    end
                end
                if not cooling then
                    CooldownFrame_Clear(button.cooldown)
                end
            end
        end
    end
end)

debuffFrame:SetSize(width, height)
debuffFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", 122, 484)
debuffFrame:RegisterEvent("PLAYER_LOGIN")
debuffFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
debuffFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
debuffFrame:RegisterEvent("UNIT_AURA")
debuffFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
debuffFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_EQUIPMENT_CHANGED" then
        for i = 1, numberOfAuras do
            ---@type WlkAuraButton
            local button = _G["WlkDebuff" .. i]
            local id
            for debuffId, v in pairs(auras[spec].debuffs[i]) do
                if v.type == "spell" or (v.type == "talent" and IsSpellKnown(v.id))
                        or (v.type == "item" and IsEquippedItem(v.id)) then
                    id = debuffId
                    button.icon:SetTexture(GetSpellTexture(id))
                end
                if id and auras.cooldowns[id] and not button.show then
                    local cooldownType = auras.cooldowns[id].type
                    local cooldownValue = auras.cooldowns[id].value
                    if cooldownType == "internal" then
                        local duration = cooldownValue
                        local expirationTime = auras.expirationTimes[id]
                        local currentTime = GetTime()
                        if duration and expirationTime and currentTime >= expirationTime - duration
                                and currentTime <= expirationTime then
                            CooldownFrame_Set(button.cooldown, expirationTime - duration, duration, duration > 0, true)
                        end
                    elseif cooldownType == "item" then
                        CooldownFrame_Set(button.cooldown, GetInventoryItemCooldown("player", cooldownValue))
                    elseif cooldownType == "spell" then
                        CooldownFrame_Set(button.cooldown, GetSpellCooldown(cooldownValue))
                    end
                    break
                end
            end
            if not id then
                button.icon:SetTexture(nil)
            end
        end
    elseif event == "UNIT_AURA" or event == "PLAYER_TARGET_CHANGED" then
        for i = 1, numberOfAuras do
            _G["WlkDebuff" .. i].show = nil
        end
        local index = 0
        AuraUtil.ForEachAura("target", "HARMFUL|INCLUDE_NAME_PLATE_ONLY", DEBUFF_MAX_DISPLAY, function(...)
            local _, icon, count, _, duration, expirationTime, caster, _, _, id, _, _, casterIsPlayer, showAll = ...
            if id and TargetFrame_ShouldShowDebuffs("target", caster, showAll, casterIsPlayer) then
                index = index + 1
                for i = 1, numberOfAuras do
                    ---@type WlkAuraButton
                    local button = _G["WlkDebuff" .. i]
                    if auras[spec].debuffs[i][id] then
                        button.icon:SetTexture(icon)
                        if count > 1 then
                            button.Count:SetText(count)
                            button.Count:Show()
                        else
                            button.Count:Hide()
                        end
                        CooldownFrame_Set(button.cooldown, expirationTime - duration, duration, duration > 0, true)
                        if auras.cooldowns[id] then
                            local cooldownType = auras.cooldowns[id].type
                            local cooldownValue = auras.cooldowns[id].value
                            if cooldownType == "internal" and abs(button:GetAlpha() - 0.5) < 0.005 then
                                auras.expirationTimes[id] = expirationTime - duration + cooldownValue
                            end
                        end
                        button:SetAlpha(1)
                        button.show = true
                    end
                end
            end
            return index >= DEBUFF_MAX_DISPLAY
        end)
        for i = 1, numberOfAuras do
            ---@type WlkAuraButton
            local button = _G["WlkDebuff" .. i]
            if not button.show then
                button:SetAlpha(0.5)
                button.Count:Hide()
                local id, cooling
                for debuffId, v in pairs(auras[spec].debuffs[i]) do
                    if v.type == "spell" or (v.type == "talent" and IsSpellKnown(v.id))
                            or (v.type == "item" and IsEquippedItem(v.id)) then
                        id = debuffId
                    end
                    if id and auras.cooldowns[id] then
                        cooling = true
                        local cooldownType = auras.cooldowns[id].type
                        local cooldownValue = auras.cooldowns[id].value
                        if cooldownType == "internal" then
                            local duration = cooldownValue
                            local expirationTime = auras.expirationTimes[id]
                            local currentTime = GetTime()
                            if expirationTime and currentTime >= expirationTime - duration
                                    and currentTime <= expirationTime then
                                CooldownFrame_Set(button.cooldown, expirationTime - duration, duration, duration > 0,
                                        true)
                            else
                                CooldownFrame_Clear(button.cooldown)
                            end
                        elseif cooldownType == "item" then
                            CooldownFrame_Set(button.cooldown, GetInventoryItemCooldown("player", cooldownValue))
                        elseif cooldownType == "spell" then
                            CooldownFrame_Set(button.cooldown, GetSpellCooldown(cooldownValue))
                        end
                        break
                    end
                end
                if not cooling then
                    CooldownFrame_Clear(button.cooldown)
                end
            end
        end
    end
end)

RegisterStateDriver(buffFrame, "visibility", "[petbattle] hide; show")
RegisterStateDriver(debuffFrame, "visibility", "[petbattle] hide; show")

for i = 1, numberOfAuras do
    ---@type ActionButtonTemplate
    local button = CreateFrame("Button", "WlkBuff" .. i, buffFrame, "ActionButtonTemplate")
    button:SetSize(size3, size3)
    if i < 5 then
        button:SetPoint("BOTTOMRIGHT", -size3 * (i - 1), 0)
    else
        button:SetPoint("TOPRIGHT", -size3 * (i - 5), 0)
    end
    button:SetAlpha(0.5)
    button:EnableMouse(false)
    button.cooldown:SetSwipeColor(0, 0, 0)
    button.cooldown:SetReverse(true)
    button.NormalTexture:SetTexture(nil)
end

for i = 1, numberOfAuras do
    ---@type ActionButtonTemplate
    local button = CreateFrame("Button", "WlkDebuff" .. i, debuffFrame, "ActionButtonTemplate")
    button:SetSize(size3, size3)
    if i < 5 then
        button:SetPoint("BOTTOMLEFT", size3 * (i - 1), 0)
    else
        button:SetPoint("TOPLEFT", size3 * (i - 5), 0)
    end
    button:SetAlpha(0.5)
    button:EnableMouse(false)
    button.cooldown:SetSwipeColor(0, 0, 0)
    button.cooldown:SetReverse(true)
    button.NormalTexture:SetTexture(nil)
end

listener:RegisterEvent("ADDON_LOADED")
listener:RegisterEvent("PLAYER_LOGIN")
listener:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        listener:UnregisterEvent(event)
        if WlkAuras then
            auras = WlkAuras
        else
            WlkAuras = auras
        end
    end
end)

hooksecurefunc("CreateFrame", function(frameType, name, parent, template)
    if frameType == "Button" and name and parent == BuffFrame and (template == "BuffButtonTemplate"
            or template == "DebuffButtonTemplate") then
        ---@type AuraButtonTemplate|DebuffButtonTemplate
        local button = _G[name]
        ---@type Cooldown
        local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        ---@type WlkPlayerAuraButton
        local auraButton = _G[name]

        button:SetSize(size1, size1)

        cooldown:SetReverse(true)

        button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        button.count:ClearAllPoints()
        button.count:SetPoint("BOTTOMRIGHT", 3, 0)
        button.count:SetJustifyH("RIGHT")
        button.count:SetFontObject("Game12Font_o1")

        if button.Border then
            button.Border:SetSize(borderSize, borderSize)
        end

        auraButton.cooldown = cooldown
        auraButton.SetAlpha = nop
        auraButton.duration.Show = nop
    end
end)

hooksecurefunc("AuraButton_Update", function(buttonName, index, _, _, _, _, duration, expirationTime)
    local cooldown = _G[buttonName .. index].cooldown
    if cooldown then
        local startTime = expirationTime - duration
        CooldownFrame_Set(cooldown, startTime, duration, duration > 0, true)
    end
end)

hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", function()
    for i = 1, BUFF_ACTUAL_DISPLAY do
        ---@type WlkPlayerAuraButton
        local button = BuffFrame.BuffButton[i]
        button:ClearAllPoints()
        button:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -122 - (i - 1) % numBuffsPerRow * offset1,
                301 + floor((i - 1) / numBuffsPerRow) * offset1)
    end
end)

hooksecurefunc("DebuffButton_UpdateAnchors", function(buttonName, index)
    ---@type WlkPlayerAuraButton
    local button = BuffFrame[buttonName][index]
    button:ClearAllPoints()
    button:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -181 - (index - 1) % numDebuffsPerRow * offset1,
            211 + floor((index - 1) / numDebuffsPerRow) * offset1)
end)

for i = 1, NUM_TEMP_ENCHANT_FRAMES do
    ---@type TempEnchantButtonTemplate|AuraButtonTemplate
    local button = _G["TempEnchant" .. i]
    ---@type WlkTempEnchantButton
    local tempEnchantButton = _G["TempEnchant" .. i]

    button:SetSize(size1, size1)
    button:ClearAllPoints()
    button:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -183 - (i - 1) * offset1, 361)

    button.Border:SetSize(borderSize, borderSize)

    button.duration:ClearAllPoints()
    button.duration:SetPoint("TOPRIGHT", 3, -3)
    button.duration:SetFontObject("Game12Font_o1")

    button.count:ClearAllPoints()
    button.count:SetPoint("BOTTOMRIGHT", 3, 0)
    button.count:SetJustifyH("RIGHT")
    button.count:SetFontObject("Game12Font_o1")

    tempEnchantButton.SetAlpha = nop
end

TotemFrame:SetParent(BuffFrame)

for i = 1, MAX_TOTEMS do
    ---@type TotemButtonTemplate
    local button = _G["TotemFrameTotem" .. i]

    button:SetSize(size2, size2)
    button:ClearAllPoints()
    button:SetPoint("TOPRIGHT", UIParent, "BOTTOM", -122 - (i - 1) * offset2, 430)

    button.duration:SetFontObject("NumberFont_Shadow_Small")
    button.duration:SetPoint("TOP", button, "BOTTOM")
end

---@param button Button
hooksecurefunc("TotemButton_Update", function(button)
    ---@type Cooldown
    local cooldown = _G[button:GetName() .. "IconCooldown"]
    cooldown:Hide()
end)

---@class WlkPlayerAuraButton:Button
---@class WlkTempEnchantButton:Button
---@class WlkAuraButton:ActionButtonTemplate
