local frames = {
    PlayerFrame, PetFrame, TargetFrame, TargetFrameToT, PartyMemberFrame1, PartyMemberFrame2, PartyMemberFrame3,
    PartyMemberFrame4, PartyMemberFrame1PetFrame, PartyMemberFrame2PetFrame, PartyMemberFrame3PetFrame,
    PartyMemberFrame4PetFrame,
}
local modifier = "Shift"
local button = 1
local focus = CreateFrame("CheckButton", "MyFocus", UIParent, "SecureActionButtonTemplate")

focus:SetAttribute("type1", "macro")
focus:SetAttribute("macrotext", "/focus mouseover")
SetOverrideBindingClick(focus, true, modifier .. "-button" .. button, focus:GetName())

local function SetFocus(frame)
    frame:SetAttribute(modifier .. "-type" .. button, "focus")
end

for i = 1, #frames do
    SetFocus(frames[i])
end

hooksecurefunc("CreateFrame", function(_, name, _, template)
    if template == "SecureUnitButtonTemplate" then
        SetFocus(_G[name])
    end
end)