local bar = CreateFrame("Frame", "MyPVPTalentBar", UIParent)
bar:SetSize(150, 30)
bar:SetPoint("BottomLeft", 390, 300)

local buttons = {}
local bindKeys = { "F1", "F2", "F3", "F4" }
local trinketButtonIndex = 1
local generalPVPSpell = 195710

local function SetTrinketButton()
    if UnitLevel("player") >= SHOW_PVP_LEVEL then
        if InCombatLockdown() then
            bar:RegisterEvent("PLAYER_REGEN_ENABLED")
            return
        end
        bar:UnregisterEvent("PLAYER_REGEN_ENABLED")
        bar:UnregisterEvent("PLAYER_LEVEL_CHANGED")

        local trinketButton = buttons[trinketButtonIndex]
        trinketButton:SetAttribute("spell", generalPVPSpell)
        local _, _, texture = GetSpellInfo(generalPVPSpell)
        trinketButton.icon:SetTexture(texture)
    end
end

local function GetTrinketButtonSpellID()
    local trinketTalentID = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()[trinketButtonIndex]
    if trinketTalentID then
        local _, _, _, _, _, spellID = GetPvpTalentInfoByID(trinketTalentID)
        return spellID
    end
end

local function GetButtonSpellID(id)
    return id == trinketButtonIndex and GetTrinketButtonSpellID() or buttons[id]:GetAttribute("spell")
end

local function CheckUsable(button, spellID)
    local isUsable, notEnoughMana = IsUsableSpell(spellID)
    if isUsable then
        button.icon:SetVertexColor(1, 1, 1)
    elseif notEnoughMana then
        button.icon:SetVertexColor(0.5, 0.5, 1)
    else
        button.icon:SetVertexColor(0.4, 0.4, 0.4)
    end
end

local function CheckRange(button, spellID)
    local spellName = GetSpellInfo(spellID)
    local hasRange = SpellHasRange(spellName)
    local inRange = IsSpellInRange(spellName, "target")
    if not hasRange or (hasRange and (inRange == nil or inRange == 1)) then
        CheckUsable(button, spellID)
    else
        button.icon:SetVertexColor(1, 0, 0)
    end
end

local function UpdateIcon(button, spellID)
    local isPassive = IsPassiveSpell(spellID)
    if isPassive then
        button.icon:SetVertexColor(0, 1, 0)
    else
        CheckRange(button, spellID)
    end
end

local function OnEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_CURSOR_RIGHT", 30, -12)
    local spell = GetButtonSpellID(button.id)
    if spell then
        GameTooltip:SetSpellByID(spell)
        button:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            if self.elapsed < TOOLTIP_UPDATE_TIME then
                return
            end
            self.elapsed = 0

            GameTooltip:SetSpellByID(spell)
        end)
    end
end

local function CreatePVPTalentButton(id)
    local button = CreateFrame("Button", "MyPVPTalentButton" .. id, bar, "SecureActionButtonTemplate, ActionButtonTemplate")
    button.id = id
    buttons[id] = button
    button:SetSize(30, 30)
    button:SetPoint("Left", (id - 1) * (30 + 10), 0)

    button:SetAttribute("type*", "spell")
    if id == trinketButtonIndex then
        SetTrinketButton()
    end
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button.NormalTexture:SetTexture(nil)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    button.HotKey:SetText(bindKeys[id])

    C_Timer.NewTicker(TOOLTIP_UPDATE_TIME, function()
        if bar:GetAlpha() == 1 then
            local spell = GetButtonSpellID(id)
            if spell then
                UpdateIcon(button, spell)
            end
        end
    end)

    button:SetScript("OnEnter", OnEnter)

    button:SetScript("OnLeave", function(self)
        self:SetScript("OnUpdate", nil)
        GameTooltip:Hide()
    end)
end

local function SetBindingKey()
    for i = 1, #buttons do
        SetBindingClick(bindKeys[i], buttons[i]:GetName())
    end
end

local function UpdateCooldown()
    for i = 1, #buttons do
        local button = buttons[i]
        local spell = GetButtonSpellID(i)
        if spell then
            CooldownFrame_Set(button.cooldown, GetSpellCooldown(spell))
        end
    end
end

local function UpdatePVPTalentButtons()
    local selectedTalentIDs = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()
    for i = 1, #buttons do
        local button = buttons[i]
        local spellID, texture, _
        local talentID = selectedTalentIDs[i]
        if talentID then
            _, _, texture, _, _, spellID = GetPvpTalentInfoByID(talentID)
        end
        button.icon:SetTexture(texture)
        if i ~= trinketButtonIndex then
            button:SetAttribute("spell", spellID)
        end
    end
end

local function ShowBar()
    bar:SetAlpha(1)
    for i = 1, #buttons do
        local button = buttons[i]
        button:SetAlpha(1)
        button:SetScript("OnEnter", OnEnter)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end
end

local function HideBar()
    bar:SetAlpha(0)
    for i = 1, #buttons do
        local button = buttons[i]
        button:SetAlpha(0)
        button:SetScript("OnEnter", nil)
        button:RegisterForClicks()
    end
end

local function TogglePVPTalentBar()
    if IsUsableSpell(generalPVPSpell) and bar:GetAlpha() == 0 then
        ShowBar()
    elseif not IsUsableSpell(generalPVPSpell) and bar:GetAlpha() == 1 then
        HideBar()
    end
end

bar:RegisterEvent("PLAYER_LOGIN")
bar:RegisterEvent("PLAYER_PVP_TALENT_UPDATE")
bar:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
bar:RegisterEvent("SPELLS_CHANGED")
bar:RegisterEvent("PLAYER_LEVEL_CHANGED")

bar:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        SetBindingKey()
        TogglePVPTalentBar()
    elseif event == "PLAYER_LEVEL_CHANGED" or event == "PLAYER_REGEN_ENABLE" then
        SetTrinketButton()
    elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
        if bar:GetAlpha() == 1 then
            UpdateCooldown()
        end
    elseif event == "PLAYER_PVP_TALENT_UPDATE" then
        UpdatePVPTalentButtons()
    else
        TogglePVPTalentBar()
    end
end)

for i = 1, 4 do
    CreatePVPTalentButton(i)
end