local bar = CreateFrame("Frame", "MySummonBar", UIParent)
bar:SetSize(150, 30)
bar:SetPoint("BottomLeft", 390, 300)

local summonSpells = { 688, 697, 712, 691 }
local bindKeys = { "F1", "F2", "F3", "F4" }

local function CreateSummonButton(id)
    local button = CreateFrame("Button", "MySummonButton" .. id, bar, "SecureActionButtonTemplate, ActionButtonTemplate")
    button:SetSize(30, 30)
    button:SetPoint("Left", (id - 1) * (30 + 10), 0)

    local spell = summonSpells[id]

    button.NormalTexture:SetTexture(nil)
    local _, _, texture = GetSpellInfo(spell)
    button.icon:SetTexture(texture)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.HotKey:SetText(bindKeys[id])

    button:SetAttribute("type*", "spell")
    button:SetAttribute("spell", spell)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    C_Timer.NewTicker(TOOLTIP_UPDATE_TIME, function()
        local isUsable, notEnoughMana = IsUsableSpell(spell)
        if isUsable then
            button.icon:SetVertexColor(1, 1, 1)
        elseif notEnoughMana then
            button.icon:SetVertexColor(0.5, 0.5, 1)
        else
            button.icon:SetVertexColor(0.4, 0.4, 0.4)
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 30, -12)
        GameTooltip:SetSpellByID(spell)
        self:SetScript("OnUpdate", function(_, elapsed)
            self.elapsed = (self.elapsed or 0) + elapsed
            if self.elapsed < 0.01 then
                return
            end
            self.elapsed = 0

            GameTooltip:SetSpellByID(spell)
        end)
    end)

    button:SetScript("OnLeave", function(self)
        self:SetScript("OnUpdate", nil)
        GameTooltip:Hide()
    end)

    return button
end

bar:RegisterEvent("PLAYER_LOGIN")
bar:SetScript("OnEvent", function()
    for i = 1, #summonSpells do
        local button = CreateSummonButton(i)
        SetBindingClick(bindKeys[i], button:GetName())
    end
end)