local modifier = "Shift" -- Shift、Ctrl、Alt
local mouseButton = 1 -- 1：左鍵，2：右鍵，3：中鍵，4：前進鍵，5：後退鍵

local focus = CreateFrame("CheckButton", "FocuserFrame", UIParent, "SecureActionButtonTemplate")
focus:SetAttribute("type1", "macro")
focus:SetAttribute("macrotext", "/focus mouseover")
SetOverrideBindingClick(FocuserFrame, true, modifier .. "-button" .. mouseButton, "FocuserFrame")

local function SetFocus(frame)
    frame:SetAttribute(modifier .. "-type" .. mouseButton, "focus")
end

hooksecurefunc("CreateFrame", function(type, name, parent, template)
    if template == "SecureUnitButtonTemplate" then
        SetFocus(_G[name])
    end
end)

-- 在默認單位框架上設置按鍵綁定，因爲不會獲得有關它們創建框架的通知
local defaultUnitFrames = {
    PlayerFrame,
    PetFrame,
    PartyMemberFrame1,
    PartyMemberFrame2,
    PartyMemberFrame3,
    PartyMemberFrame4,
    PartyMemberFrame1PetFrame,
    PartyMemberFrame2PetFrame,
    PartyMemberFrame3PetFrame,
    PartyMemberFrame4PetFrame,
    TargetFrame,
    TargetofTargetFrame,
}

for i = 1, #defaultUnitFrames do
    SetFocus(defaultUnitFrames[i])
end