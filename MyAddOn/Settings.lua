SetCVar("Sound_SFXVolume", 0.7)
SetCVar("Sound_MusicVolume", 0.5)
SetCVar("Sound_AmbienceVolume", 1)
SetCVar("Sound_DialogVolume", 1)

local listener = CreateFrame("Frame")
listener:RegisterEvent("PLAYER_LOGIN")
listener:SetScript("OnEvent", function()
    SetTracking(8, true)

    for i = 1, NUM_CHAT_WINDOWS do
        local list = _G["ChatFrame" .. i].messageTypeList
        for j = 1, #list do
            if list[j] == "CHANNEL" then
                tremove(list, j)
                ChatFrame_RemoveMessageGroup(_G["ChatFrame" .. i], "CHANNEL")
                break
            end
        end
    end

    SetCVar("scriptErrors", 0)
    SetCVar("cameraDistanceMaxZoomFactor", 2.6)
    SetCVar("floatingCombatTextFloatMode", 3)
    SetCVar("floatingCombatTextCombatHealing", 0)
    SetCVar("floatingCombatTextReactives", 0)
    SetCVar("floatingCombatTextCombatState", 1)
    SetCVar("taintLog", 1)
    SetCVar("rawMouseEnable", 1)
    SetCVar("ffxDeath", 0)
    SetCVar("nameplateMaxDistance", 40)

    SetCVar("autoLootDefault", 1)
    SetModifiedClick("AUTOLOOTTOGGLE", "None")

    SetCVar("enableFloatingCombatText", 1)
    SetModifiedClick("FOCUSCAST", "Shift")
    SetModifiedClick("SELFCAST", "None")

    SetCVar("statusTextDisplay", "BOTH")
    SetCVar("statusText", 1)
    SetCVar("showTutorials", 0)

    SetAutoDeclineGuildInvites(true)

    SetCVar("lockActionBars", 0)
    SetCVar("alwaysShowActionBars", 1)

    SetCVar("nameplateShowSelf", 0)
    SetCVar("NamePlateHorizontalScale", 1.4)
    SetCVar("NamePlateVerticalScale", 2.7)
    NamePlateDriverFrame:UpdateNamePlateOptions()
    SetCVar("nameplateShowAll", 1)
    SetCVar("nameplateMotion", 1)

    SetCVar("cameraWaterCollision", 1)
    SetCVar("cameraSmoothStyle", 0)

    SetCVar("movieSubtitle", 1)

    SetCVar("useCompactPartyFrames", 1)

    C_Timer.After(1, function()
        SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "keepGroupsTogether", true)
        SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "useClassColors", true)
        SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "displayBorder", false)
        SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "frameHeight", 54, 54)
        SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "frameWidth", 37, 37)
        CompactUnitFrameProfiles_ApplyCurrentSettings()
    end)
end)

hooksecurefunc("InterfaceOptions_UpdateMultiActionBars", function()
    SHOW_MULTI_ACTIONBAR_1 = true
    SHOW_MULTI_ACTIONBAR_2 = true
    SHOW_MULTI_ACTIONBAR_3 = true
    InterfaceOptionsActionBarsPanelBottomLeft.value = SHOW_MULTI_ACTIONBAR_1 and "1" or "0"
    InterfaceOptionsActionBarsPanelBottomRight.value = SHOW_MULTI_ACTIONBAR_2 and "1" or "0"
    InterfaceOptionsActionBarsPanelRight.value = SHOW_MULTI_ACTIONBAR_3 and "1" or "0"
end)

hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"], "OnShow", function(self)
    self.editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
end)