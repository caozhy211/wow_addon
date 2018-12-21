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

    return button
end

bar:RegisterEvent("PLAYER_LOGIN")
bar:SetScript("OnEvent", function()
    for i = 1, #summonSpells do
        local button = CreateSummonButton(i)
        SetBindingClick(bindKeys[i], button:GetName())
    end
end)