local size1 = 27
local borderSize = size1 + 2
local spacing1 = 3
local offset1 = size1 + spacing1
local size2 = 29
local spacing2 = 1
local offset2 = size2 + spacing2
local numBuffsPerRow = 15
local numDebuffsPerRow = 8

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
    if BuffFrame.BuffButton then
        for i = 1, BUFF_MAX_DISPLAY do
            ---@type WlkPlayerAuraButton
            local button = BuffFrame.BuffButton[i]
            if button then
                button:ClearAllPoints()
                button:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -122 - (i - 1) % numBuffsPerRow * offset1,
                        301 + floor((i - 1) / numBuffsPerRow) * offset1)
            end
        end
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
