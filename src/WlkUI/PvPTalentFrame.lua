local NUM_PVP_TALENTS = 3
local buttonSize = 27
local spacing = 5
local frameWidth = (buttonSize + spacing) * NUM_PVP_TALENTS - spacing
local frameHeight = buttonSize
local classR, classG, classB = GetClassColor(select(2, UnitClass("player")))
local backdrop = { edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 2, }
local bindKeys = { "F1", "F2", "F3", }
---@type ActionButtonTemplate[]
local buttons = {}

---@type Frame
local pvpTalentFrame = CreateFrame("Frame", "WlkPvPTalentFrame", BuffFrame)

---@param self WlkPvPTalentButton
local function buttonOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.2 then
        return
    end
    self.elapsed = 0

    local r, g, b
    local spellId = self:GetAttribute("spell")
    if spellId then
        if IsPassiveSpell(spellId) then
            r, g, b = 0.77, 0.64, 0.0
        else
            local spellName = GetSpellInfo(spellId)
            local hasRange = SpellHasRange(spellName)
            local inRange = IsSpellInRange(spellName, "target")
            if not hasRange or (hasRange and inRange ~= false) then
                local isUsable, notEnoughMana = IsUsableSpell(spellId)
                if isUsable then
                    r, g, b = 1, 1, 1
                elseif notEnoughMana then
                    r, g, b = 0.5, 0.5, 1
                else
                    r, g, b = 0.4, 0.4, 0.4
                end
            else
                r, g, b = 1, 0, 0
            end
        end
        self.icon:SetVertexColor(r, g, b)
    end
end

---@param self WlkPvPTalentButton
local function buttonOnEnter(self)
    local spellId = self:GetAttribute("spell")
    if spellId then
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetSpellByID(spellId)
        self.UpdateTooltip = buttonOnEnter
    end
end

local function buttonOnLeave(self)
    GameTooltip:Hide()
    self.UpdateTooltip = nil
end

local function showButtons()
    pvpTalentFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    for i = 1, NUM_PVP_TALENTS do
        local button = buttons[i]
        button:SetScript("OnUpdate", buttonOnUpdate)
        button:SetScript("OnEnter", buttonOnEnter)
        button:SetScript("OnLeave", buttonOnLeave)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetAlpha(1)
    end
end

local function hideButtons()
    pvpTalentFrame:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
    for i = 1, NUM_PVP_TALENTS do
        local button = buttons[i]
        button:SetScript("OnUpdate", nil)
        button:SetScript("OnEnter", nil)
        button:SetScript("OnLeave", nil)
        button:RegisterForClicks()
        button:SetAlpha(0)
    end
end

local function updateButtonsVisibility(warModeButton)
    local warModeEnabled
    if warModeButton then
        warModeEnabled = not C_PvP.IsWarModeDesired()
    else
        warModeEnabled = C_PvP.IsWarModeDesired()
    end
    local _, instanceType = IsInInstance()
    local pvpType = GetZonePVPInfo()
    if instanceType == "pvp" or instanceType == "arena" or pvpType == "combat" or pvpType == "arena"
            or (warModeEnabled and instanceType == "none") then
        showButtons()
    else
        hideButtons()
    end
end

for i = 1, NUM_PVP_TALENTS do
    ---@class WlkPvPTalentButton:ActionButtonTemplate
    local button = CreateFrame("Button", "WlkPvPTalentButton" .. i, pvpTalentFrame,
            "ActionButtonTemplate, SecureActionButtonTemplate, BackdropTemplate")

    button:SetSize(buttonSize, buttonSize)
    button:SetPoint("LEFT", (i - 1) * (buttonSize + spacing), 0)
    button:SetBackdrop(backdrop)
    button:SetBackdropBorderColor(classR, classG, classB)
    button:SetAttribute("type", "spell")
    button:SetAttribute("checkfocuscast", true)
    button:SetAttribute("unit2", "player")

    button.NormalTexture:SetTexture(nil)

    button.HotKey:SetPoint("TOPRIGHT", 3, 0)
    button.HotKey:SetText(bindKeys[i])

    button.cooldown:SetSwipeColor(0, 0, 0)

    buttons[i] = button
end

pvpTalentFrame:SetSize(frameWidth, frameHeight)
pvpTalentFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", -147, 208)
pvpTalentFrame:RegisterEvent("PLAYER_LOGIN")
pvpTalentFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
pvpTalentFrame:RegisterEvent("PLAYER_PVP_TALENT_UPDATE")
pvpTalentFrame:RegisterEvent("ADDON_LOADED")
pvpTalentFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        for i = 1, NUM_PVP_TALENTS do
            SetBindingClick(bindKeys[i], buttons[i]:GetName())
        end
        updateButtonsVisibility()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        updateButtonsVisibility()
    elseif event == "ADDON_LOADED" and ... == "Blizzard_TalentUI" then
        pvpTalentFrame:UnregisterEvent(event)
        PlayerTalentFrameTalents.PvpTalentFrame.InvisibleWarmodeButton:HookScript("OnClick", updateButtonsVisibility)
    elseif event == "PLAYER_PVP_TALENT_UPDATE" then
        if not InCombatLockdown() then
            for i = 1, NUM_PVP_TALENTS do
                local slotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(i)
                local talentId = slotInfo and slotInfo.selectedTalentID
                local button = buttons[i]
                if talentId then
                    local _, _, texture, _, _, spellId = GetPvpTalentInfoByID(talentId)
                    button.icon:SetTexture(texture)
                    button:SetAttribute("spell", spellId)
                else
                    button.icon:SetTexture(nil)
                    button:SetAttribute("spell", nil)
                end
            end
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        for i = 1, NUM_PVP_TALENTS do
            local spellId = buttons[i]:GetAttribute("spell")
            if spellId then
                CooldownFrame_Set(buttons[i].cooldown, GetSpellCooldown(spellId))
            end
        end
    end
end)
