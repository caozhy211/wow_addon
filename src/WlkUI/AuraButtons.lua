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

SlashCmdList["ADD_BUFF"] = function(arg)
    local index, id = strsplit(" ", arg, 2)
    index = tonumber(index)
    id = tonumber(id)
    ---@type WlkAuraButton
    local button = _G["WlkBuff" .. index]
    if button then
        if id then
            tinsert(auras[spec].buffs[index], id)
        else
            wipe(auras[spec].buffs[index])
        end
        button.icon:SetTexture(GetSpellTexture(id))
    end
end

SlashCmdList["ADD_DEBUFF"] = function(arg)
    local index, id = strsplit(" ", arg, 2)
    index = tonumber(index)
    id = tonumber(id)
    ---@type WlkAuraButton
    local button = _G["WlkDebuff" .. index]
    if button then
        if id then
            tinsert(auras[spec].debuffs[index], id)
        else
            wipe(auras[spec].debuffs[index])
        end
        button.icon:SetTexture(GetSpellTexture(id))
    end
end

SlashCmdList["ADD_COOLDOWN"] = function(arg)
    local id, cooldown = strsplit(" ", arg, 2)
    id = tonumber(id)
    cooldown = tonumber(cooldown)
    auras.cooldowns[id] = cooldown
end

buffFrame:SetSize(width, height)
buffFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -122, 484)
buffFrame:RegisterEvent("PLAYER_LOGIN")
buffFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
buffFrame:RegisterEvent("UNIT_AURA")
buffFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_SPECIALIZATION_CHANGED" then
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
            button.icon:SetTexture(GetSpellTexture(auras[spec].buffs[i][1]))
            for _, id in ipairs(auras[spec].buffs[i]) do
                local cooldown = auras.cooldowns[id]
                local expirationTime = auras.expirationTimes[id]
                if cooldown and expirationTime and GetTime() <= expirationTime then
                    CooldownFrame_Set(button.cooldown, expirationTime - cooldown, cooldown, cooldown > 0, true)
                    break
                end
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
                    if tContains(auras[spec].buffs[i], id) then
                        button.icon:SetTexture(icon)
                        if count > 1 then
                            button.Count:SetText(count)
                            button.Count:Show()
                        else
                            button.Count:Hide()
                        end
                        CooldownFrame_Set(button.cooldown, expirationTime - duration, duration, duration > 0, true)
                        if auras.cooldowns[id] and abs(button:GetAlpha() - 0.5) < 0.005 then
                            auras.expirationTimes[id] = expirationTime - duration + auras.cooldowns[id]
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
                local cooling
                for _, id in ipairs(auras[spec].buffs[i]) do
                    local cooldown = auras.cooldowns[id]
                    local expirationTime = auras.expirationTimes[id]
                    if cooldown and expirationTime and GetTime() <= expirationTime then
                        CooldownFrame_Set(button.cooldown, expirationTime - cooldown, cooldown, cooldown > 0, true)
                        cooling = true
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
debuffFrame:RegisterEvent("UNIT_AURA")
debuffFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        for i = 1, numberOfAuras do
            ---@type WlkAuraButton
            local button = _G["WlkDebuff" .. i]
            button.icon:SetTexture(GetSpellTexture(auras[spec].debuffs[i][1]))
            for _, id in ipairs(auras[spec].debuffs[i]) do
                local cooldown = auras.cooldowns[id]
                local expirationTime = auras.expirationTimes[id]
                if cooldown and expirationTime and GetTime() <= expirationTime then
                    CooldownFrame_Set(button.cooldown, expirationTime - cooldown, cooldown, cooldown > 0, true)
                    break
                end
            end
        end
    elseif event == "UNIT_AURA" then
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
                    if tContains(auras[spec].debuffs[i], id) then
                        button.icon:SetTexture(icon)
                        if count > 1 then
                            button.Count:SetText(count)
                            button.Count:Show()
                        else
                            button.Count:Hide()
                        end
                        CooldownFrame_Set(button.cooldown, expirationTime - duration, duration, duration > 0, true)
                        if auras.cooldowns[id] and abs(button:GetAlpha() - 0.5) < 0.005 then
                            auras.expirationTimes[id] = expirationTime - duration + auras.cooldowns[id]
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
                local cooling
                for _, id in ipairs(auras[spec].debuffs[i]) do
                    local cooldown = auras.cooldowns[id]
                    local expirationTime = auras.expirationTimes[id]
                    if cooldown and expirationTime and GetTime() <= expirationTime then
                        CooldownFrame_Set(button.cooldown, expirationTime - cooldown, cooldown, cooldown > 0, true)
                        cooling = true
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
