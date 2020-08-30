local NUM_PVP_TALENT = 4
local size = 27
local spacing = 5
---@type Frame
local pvpTalentFrame = CreateFrame("Frame", "WlkPVPTalentFrame", UIParent)
pvpTalentFrame:SetSize((size + spacing) * NUM_PVP_TALENT - spacing, size)
pvpTalentFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", -180, 142 + 81 + 3)

---@param self Button
local function PvpTalentButtonOnEnter(self)
    local spellId = self:GetAttribute("spell")
    if spellId then
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetSpellByID(spellId)
        self.UpdateTooltip = PvpTalentButtonOnEnter
    end
end

local function PvpTalentButtonOnLeave(self)
    GameTooltip:Hide()
    self.UpdateTooltip = nil
end

---@param self Button
local function PvpTalentButtonOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < TOOLTIP_UPDATE_TIME then
        return
    end
    self.elapsed = 0

    local r, g, b
    local spellId = self:GetAttribute("spell")
    if IsPassiveSpell(spellId) then
        r, g, b = GetTableColor(PASSIVE_SPELL_FONT_COLOR)
    else
        local spellName = GetSpellInfo(spellId)
        local hasRange = SpellHasRange(spellName)
        local inRange = IsSpellInRange(spellName, "target")
        if not hasRange or (hasRange and (inRange == nil or inRange == 1)) then
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

local _, class = UnitClass("player")
local r, g, b = GetClassColor(class)
local backdrop = { edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 2, }
local bindKeys = { "F1", "F2", "F3", "F4", }
---@type Button[]
local buttons = {}

for i = 1, NUM_PVP_TALENT do
    ---@type Button|ActionButtonTemplate
    local button = CreateFrame("Button", "WlkPVPTalentButton" .. i, pvpTalentFrame,
            "ActionButtonTemplate, SecureActionButtonTemplate")
    buttons[#buttons + 1] = button
    button:SetSize(size, size)
    button:SetPoint("LEFT", (i - 1) * (size + spacing), 0)
    button:SetBackdrop(backdrop)
    button:SetBackdropBorderColor(r, g, b)

    button.NormalTexture:SetTexture(nil)
    button.HotKey:SetPoint("TOPRIGHT", 3, 0)
    button.HotKey:SetText(bindKeys[i])
    button.cooldown:SetSwipeColor(0, 0, 0)

    button:SetAttribute("type", "spell")
    button:SetAttribute("checkfocuscast", true)
    button:SetAttribute("unit2", "player")

    button:SetScript("OnEnter", PvpTalentButtonOnEnter)
    button:SetScript("OnLeave", PvpTalentButtonOnLeave)
end

local TRINKET_INDEX = 1
local HONOR_MEDAL_ID = 195710

pvpTalentFrame:RegisterEvent("PLAYER_LOGIN")
pvpTalentFrame:RegisterEvent("SPELLS_CHANGED")
pvpTalentFrame:RegisterEvent("PLAYER_PVP_TALENT_UPDATE")
pvpTalentFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")

pvpTalentFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        pvpTalentFrame:UnregisterEvent(event)
        for i = 1, NUM_PVP_TALENT do
            SetBindingClick(bindKeys[i], buttons[i]:GetName())
        end
    elseif event == "SPELLS_CHANGED" then
        if IsUsableSpell(HONOR_MEDAL_ID) and not pvpTalentFrame:IsShown() then
            pvpTalentFrame:Show()
            for i = 1, NUM_PVP_TALENT do
                buttons[i]:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            end
        elseif not IsUsableSpell(HONOR_MEDAL_ID) and pvpTalentFrame:IsShown() then
            pvpTalentFrame:Hide()
            for i = 1, NUM_PVP_TALENT do
                buttons[i]:RegisterForClicks()
            end
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        for i = 1, NUM_PVP_TALENT do
            local button = buttons[i]
            local spellId = button:GetAttribute("spell")
            if spellId then
                CooldownFrame_Set(button.cooldown, GetSpellCooldown(spellId))
            end
        end
    elseif event == "PLAYER_PVP_TALENT_UPDATE" then
        local selectedPvpTalents = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()
        for i = 1, NUM_PVP_TALENT do
            local button = buttons[i]
            local talentId = selectedPvpTalents[i]
            if talentId then
                local _, _, texture, _, _, spellId = GetPvpTalentInfoByID(talentId)
                button.icon:SetTexture(texture)
                button:SetAttribute("spell", i == TRINKET_INDEX and HONOR_MEDAL_ID or spellId)
                button:SetScript("OnUpdate", PvpTalentButtonOnUpdate)
            else
                button.icon:SetTexture(nil)
                button:SetAttribute("spell", nil)
                button:SetScript("OnUpdate", nil)
            end
        end
    end
end)
