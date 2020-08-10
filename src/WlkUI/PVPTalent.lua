local size = 30

---@type Frame
local pvpTalentFrame = CreateFrame("Frame", "WLK_PVPTalentFrame", UIParent)
pvpTalentFrame:SetSize(150, size)
pvpTalentFrame:SetPoint("BOTTOMLEFT", 390, 300)
pvpTalentFrame:Hide()

---@type GameTooltip
local tooltip = CreateFrame("GameTooltip", "WLK_PVPTalentTooltip", UIParent, "GameTooltipTemplate")

---@param self GameTooltip
tooltip:HookScript("OnTooltipSetSpell", function(self)
    local _, id = self:GetSpell()
    if id then
        self:AddLine(" ")
        self:AddLine(SPELLS .. ID .. ": " .. HIGHLIGHT_FONT_COLOR_CODE .. id .. FONT_COLOR_CODE_CLOSE)
        self:Show()
    end
end)

---@type table<number, Button>
local pvpTalentButtons = {}
local numPVPTalentButtons = 4
local trinketButtonIndex = 1
--- 荣誉勋章 SpellID
local trinketSpellID = 195710
local spacing = (pvpTalentFrame:GetWidth() - size * numPVPTalentButtons) / (numPVPTalentButtons - 1)

--- 创建按钮
local function CreatePVPTalentButton(index)
    ---@type Button
    local button = CreateFrame("Button", "WLK_PVPTalentButton" .. index, pvpTalentFrame,
            "SecureActionButtonTemplate, ActionButtonTemplate")
    button:SetSize(size, size)
    button:SetPoint("LEFT", (size + spacing) * (index - 1), 0)
    button:Hide()
    button:SetAttribute("type*", "spell")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    ---@type Texture
    local texture = button.NormalTexture
    texture:SetTexture(nil)
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button:SetScript("OnEnter", function(self)
        local spellID = self.spellID
        tooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 30, 10)
        tooltip:SetSpellByID(spellID)
        self.ticker = C_Timer.NewTicker(TOOLTIP_UPDATE_TIME, function()
            tooltip:SetSpellByID(spellID)
        end)
    end)

    button:SetScript("OnLeave", function(self)
        ---@type TickerPrototype
        local ticker = self.ticker
        ticker:Cancel()
        ticker = nil
        tooltip:Hide()
    end)

    ---@param self Button
    button:SetScript("OnUpdate", function(self)
        local spellID = self.spellID
        local color
        if IsPassiveSpell(spellID) then
            color = PASSIVE_SPELL_FONT_COLOR
        else
            local spellName = GetSpellInfo(spellID)
            local hasRange = SpellHasRange(spellName)
            local inRange = IsSpellInRange(spellName, "target")
            if not hasRange or (hasRange and (inRange == nil or inRange == 1)) then
                local isUsable, noMana = IsUsableSpell(spellID)
                if isUsable then
                    color = WHITE_FONT_COLOR
                elseif noMana then
                    color = LIGHTBLUE_FONT_COLOR
                else
                    color = DISABLED_FONT_COLOR
                end
            else
                color = DIM_RED_FONT_COLOR
            end
        end
        ---@type Texture
        local icon = self.icon
        icon:SetVertexColor(GetTableColor(color))
    end)

    pvpTalentButtons[index] = button
end

for i = 1, numPVPTalentButtons do
    CreatePVPTalentButton(i)
end

local bindingKeys = { "F1", "F2", "F3", "F4", }

--- 绑定快捷键
local function SetBindingKey()
    for i = 1, numPVPTalentButtons do
        local button = pvpTalentButtons[i]
        local bindingKey = bindingKeys[i]
        SetBindingClick(bindingKey, button:GetName())
        ---@type FontString
        local keyLabel = button.HotKey
        keyLabel:SetText(bindingKey)
    end
end

--- 更新技能冷却
local function UpdateCooldown()
    for i = 1, numPVPTalentButtons do
        local button = pvpTalentButtons[i]
        if button:IsShown() then
            CooldownFrame_Set(button.cooldown, GetSpellCooldown(button.spellID))
        end
    end
end

--- 更新按钮
local function UpdatePVPTalentButtons()
    local selectedPVPTalentIDs = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()
    for i = 1, numPVPTalentButtons do
        local button = pvpTalentButtons[i]
        local talentID = selectedPVPTalentIDs[i]
        if talentID then
            local _, _, texture, _, _, spellID = GetPvpTalentInfoByID(talentID)
            ---@type Texture
            local icon = button.icon
            icon:SetTexture(texture)
            button:SetAttribute("spell", i == trinketButtonIndex and trinketSpellID or spellID)
            button.spellID = spellID
            button:Show()
            UpdateCooldown()
        else
            button:SetAttribute("spell", nil)
            button:Hide()
        end
    end
end

pvpTalentFrame:RegisterEvent("PLAYER_LOGIN")
pvpTalentFrame:RegisterEvent("PLAYER_PVP_TALENT_UPDATE")
pvpTalentFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
pvpTalentFrame:RegisterEvent("SPELLS_CHANGED")

---@param self Frame
pvpTalentFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        SetBindingKey()
        self:UnregisterEvent(event)
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        UpdateCooldown()
    elseif event == "PLAYER_PVP_TALENT_UPDATE" then
        if not InCombatLockdown() then
            UpdatePVPTalentButtons()
        end
    elseif event == "SPELLS_CHANGED" then
        if IsUsableSpell(trinketSpellID) and not self:IsShown() then
            if InCombatLockdown() then
                self:RegisterEvent("PLAYER_REGEN_ENABLED")
                self.show = true
            else
                self:Show()
            end
        elseif not IsUsableSpell(trinketSpellID) and self:IsShown() then
            if InCombatLockdown() then
                self:RegisterEvent("PLAYER_REGEN_ENABLED")
                self.show = false
            else
                self:Hide()
            end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if self.show then
            self:Show()
        else
            self:Hide()
        end
        self:UnregisterEvent(event)
    end
end)
