local defaultMiniMapTracking = {
    ["飛行管理員"] = true,
    ["專注目標"] = true,
    ["任務目標區域追蹤"] = true,
    ["追蹤挖掘場"] = true,
}
local hiddenCVars = {
    scriptErrors = 1,
    taintLog = 1,
    rawMouseEnable = 1,
    ffxDeath = 0,
    nameplateMaxDistance = 40,
    alwaysCompareItems = 1,
    cameraDistanceMaxZoomFactor = 2.6,
    floatingCombatTextFloatMode = 3,
    floatingCombatTextCombatHealing = 0,
    floatingCombatTextReactives = 0,
    floatingCombatTextCombatState = 1,
}
local voiceCVars = {
    Sound_SFXVolume = 0.7,
    Sound_MusicVolume = 0.5,
    Sound_AmbienceVolume = 1,
    Sound_DialogVolume = 1,
}
local interfaceCVars = {
    autoLootDefault = 1,
    enableFloatingCombatText = 1,
    statusTextDisplay = "BOTH",
    statusText = 1,
    showTutorials = 0,
    lockActionBars = 0,
    alwaysShowActionBars = 1,
    UnitNameFriendlySpecialNPCName = 1,
    UnitNameHostleNPC = 1,
    UnitNameInteractiveNPC = 1,
    nameplateShowSelf = 0,
    nameplateShowAll = 1,
    nameplateMotion = 1,
    cameraWaterCollision = 1,
    cameraSmoothStyle = 0,
    movieSubtitle = 1,
    useCompactPartyFrames = 1,
}
local worldMapTrackingCVars = {
    showTamers = 0,
}
local addonName = ...
local listener = CreateFrame("Frame")

local default = CreateFrame("Button", "MyBLZSettingsButton", UIParent, "UIPanelButtonTemplate")
default:SetSize(60, 22)
default:SetPoint("Right", 0, 225)
default:SetText("BLZ")
default:SetAlpha(0)

local my = CreateFrame("Button", "MySettingsButton", UIParent, "UIPanelButtonTemplate")
my:SetSize(60, 22)
my:SetPoint("Right", 0, 255)
my:SetText("MY")
my:SetAlpha(0)

StaticPopupDialogs["RELOAD_UI"] = {
    text = "重載介面以使設置生效",
    button1 = "重載介面",
    OnAccept = function()
        ReloadUI()
    end,
    OnCancel = function()
        ReloadUI()
    end,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1,
}

listener:RegisterEvent("ADDON_LOADED")
listener:RegisterEvent("PLAYER_LOGIN")

listener:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if ... == addonName then
            if not MySettings then
                MySettings = {
                    autoEnterDelete = false,
                }
            end
            self:UnregisterEvent(event)
        end
    elseif MySettings.autoEnterDelete then
        hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"], "OnShow", function(self)
            self.editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
        end)
    end
end)

local function OnEnter()
    default:SetAlpha(1)
    my:SetAlpha(1)
end

local function OnLeave()
    default:SetAlpha(0)
    my:SetAlpha(0)
end

default:SetScript("OnEnter", OnEnter)
default:SetScript("OnLeave", OnLeave)
my:SetScript("OnEnter", OnEnter)
my:SetScript("OnLeave", OnLeave)

local function SetCVars(cvars, toDefault)
    for cvar, value in pairs(cvars) do
        SetCVar(cvar, toDefault and GetCVarDefault(cvar) or value)
    end
end

local function ApplyDefaultSettings()
    MySettings.autoEnterDelete = false

    SetCVars(hiddenCVars, true)
    SetCVars(voiceCVars, true)

    InterfaceOptionsFrame_SetAllToDefaults()

    if LoadAddOn("Blizzard_BindingUI") then
        KeyBindingFrame_ResetBindingsToDefault()
        C_VoiceChat.SetPushToTalkBinding({ "`" })
        SaveBindings(ACCOUNT_BINDINGS)
    end

    FCF_ResetChatWindows()
    if ChatConfigFrame:IsShown() then
        ChatConfig_UpdateChatSettings()
    end

    for i = 1, GetNumTrackingTypes() do
        local name = GetTrackingInfo(i)
        SetTracking(i, defaultMiniMapTracking[name])
    end

    SetCVars(worldMapTrackingCVars, true)
end

default:SetScript("OnClick", function(self)
    self:SetScript("OnClick", nil)
    my:SetScript("OnClick", nil)

    ApplyDefaultSettings()
    StaticPopup_Show("RELOAD_UI")
end)

local function SetMyInterfaceOptions()
    SetCVars(interfaceCVars)
    SetModifiedClick("AUTOLOOTTOGGLE", "None")
    SetModifiedClick("FOCUSCAST", "Shift")
    SetModifiedClick("SELFCAST", "None")
    SetAutoDeclineGuildInvites(true)
end

local function UnbindButton(action, buttonID)
    local key1, key2 = GetBindingKey(action, 1)
    if key1 then
        SetBinding(key1, nil, 1)
    end
    if key2 then
        SetBinding(key2, nil, 1)
    end
    if key1 and buttonID == 1 then
        KeyBindingFrame_SetBinding(key1, nil, 1, key1)
        if key2 then
            KeyBindingFrame_SetBinding(key2, action, 1, key2)
        end
    else
        if key1 then
            KeyBindingFrame_SetBinding(key1, action, 1)
        end
        if key2 then
            KeyBindingFrame_SetBinding(key2, nil, 1, key2)
        end
    end
end

local function BindButton(key, action, buttonID)
    KeyBindingFrame_AttemptKeybind(KeyBindingFrame, key, action, 1, buttonID or 1, true)
end

local function SetMyBindings()
    UnbindButton("MOVEFORWARD", 2)
    UnbindButton("MOVEBACKWARD", 2)
    UnbindButton("TURNLEFT", 2)
    UnbindButton("TURNRIGHT", 2)
    UnbindButton("JUMP", 2)
    UnbindButton("TOGGLEAUTORUN", 2)
    UnbindButton("PREVIOUSACTIONPAGE", 2)
    UnbindButton("NEXTACTIONPAGE", 2)
    UnbindButton("TOGGLEBACKPACK", 2)

    UnbindButton("MOVEANDSTEER", 1)
    UnbindButton("TURNRIGHT", 1)
    UnbindButton("TURNRIGHT", 1)
    BindButton("E", "MOVEFORWARD")
    BindButton("D", "MOVEBACKWARD")
    BindButton("S", "STRAFELEFT")
    BindButton("F", "STRAFERIGHT")
    BindButton(".", "SITORSTAND")
    BindButton(",", "TOGGLESHEATH")
    BindButton(";", "TOGGLEAUTORUN")
    BindButton("'", "FOLLOWTARGET")

    UnbindButton("REPLY2", 1)
    C_VoiceChat.SetPushToTalkBinding({ "BUTTON3" })

    BindButton("Q", "ACTIONBUTTON1")
    BindButton("W", "ACTIONBUTTON2")
    BindButton("A", "ACTIONBUTTON3")
    BindButton("R", "ACTIONBUTTON4")
    BindButton("T", "ACTIONBUTTON5")
    BindButton("G", "ACTIONBUTTON6")
    BindButton("1", "ACTIONBUTTON7")
    BindButton("2", "ACTIONBUTTON8")
    BindButton("3", "ACTIONBUTTON9")
    BindButton("4", "ACTIONBUTTON10")
    BindButton("Z", "ACTIONBUTTON11")
    BindButton("X", "ACTIONBUTTON12")
    BindButton("`", "EXTRAACTIONBUTTON1")
    BindButton("CTRL-`", "BONUSACTIONBUTTON1")
    UnbindButton("BONUSACTIONBUTTON2", 1)
    UnbindButton("BONUSACTIONBUTTON3", 1)
    UnbindButton("BONUSACTIONBUTTON4", 1)
    UnbindButton("BONUSACTIONBUTTON5", 1)
    UnbindButton("BONUSACTIONBUTTON6", 1)
    UnbindButton("BONUSACTIONBUTTON7", 1)
    UnbindButton("BONUSACTIONBUTTON8", 1)
    UnbindButton("BONUSACTIONBUTTON9", 1)
    UnbindButton("BONUSACTIONBUTTON10", 1)
    UnbindButton("ACTIONPAGE1", 1)
    UnbindButton("ACTIONPAGE2", 1)
    UnbindButton("ACTIONPAGE3", 1)
    UnbindButton("ACTIONPAGE4", 1)
    UnbindButton("ACTIONPAGE5", 1)
    UnbindButton("ACTIONPAGE6", 1)
    UnbindButton("PREVIOUSACTIONPAGE", 1)
    UnbindButton("NEXTACTIONPAGE", 1)

    BindButton("CTRL-Q", "MULTIACTIONBAR1BUTTON1")
    BindButton("CTRL-W", "MULTIACTIONBAR1BUTTON2")
    BindButton("CTRL-A", "MULTIACTIONBAR1BUTTON3")
    BindButton("CTRL-R", "MULTIACTIONBAR1BUTTON4")
    BindButton("CTRL-T", "MULTIACTIONBAR1BUTTON5")
    BindButton("CTRL-G", "MULTIACTIONBAR1BUTTON6")
    BindButton("CTRL-1", "MULTIACTIONBAR1BUTTON7")
    BindButton("CTRL-2", "MULTIACTIONBAR1BUTTON8")
    BindButton("CTRL-3", "MULTIACTIONBAR1BUTTON9")
    BindButton("CTRL-4", "MULTIACTIONBAR1BUTTON10")
    BindButton("CTRL-Z", "MULTIACTIONBAR1BUTTON11")
    BindButton("CTRL-X", "MULTIACTIONBAR1BUTTON12")
    BindButton("CTRL-E", "MULTIACTIONBAR2BUTTON1")
    BindButton("CTRL-D", "MULTIACTIONBAR2BUTTON2")
    BindButton("CTRL-S", "MULTIACTIONBAR2BUTTON3")
    BindButton("CTRL-F", "MULTIACTIONBAR2BUTTON4")
    BindButton("SHIFT-E", "MULTIACTIONBAR2BUTTON5")
    BindButton("SHIFT-D", "MULTIACTIONBAR2BUTTON6")
    BindButton("SHIFT-S", "MULTIACTIONBAR2BUTTON7")
    BindButton("SHIFT-F", "MULTIACTIONBAR2BUTTON8")
    BindButton("ALT-E", "MULTIACTIONBAR2BUTTON9")
    BindButton("ALT-D", "MULTIACTIONBAR2BUTTON10")
    BindButton("ALT-S", "MULTIACTIONBAR2BUTTON11")
    BindButton("ALT-F", "MULTIACTIONBAR2BUTTON12")

    SaveBindings(ACCOUNT_BINDINGS)
    KeyBindingFrame.outputText:SetText("")
end

local function ApplyMySettings()
    MySettings.autoEnterDelete = true

    SetCVars(hiddenCVars)
    SetCVars(voiceCVars)

    SetMyInterfaceOptions()

    if LoadAddOn("Blizzard_BindingUI") then
        SetMyBindings()
    end

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

    for i = 1, GetNumTrackingTypes() do
        local name = GetTrackingInfo(i)
        if name == "旅店老闆" then
            SetTracking(i, true)
            break
        end
    end

    SetCVars(worldMapTrackingCVars)
end

my:SetScript("OnClick", function(self)
    self:SetScript("OnClick", nil)
    default:SetScript("OnClick", nil)

    ApplyDefaultSettings()
    ApplyMySettings()

    InterfaceOptionsActionBarsPanelBottomLeft.value = "1"
    InterfaceOptionsActionBarsPanelBottomRight.value = "1"
    InterfaceOptionsActionBarsPanelRight.value = "1"
    SHOW_MULTI_ACTIONBAR_1 = true
    SHOW_MULTI_ACTIONBAR_2 = true
    SHOW_MULTI_ACTIONBAR_3 = true
    InterfaceOptions_UpdateMultiActionBars()

    InterfaceOptionsNamesPanelUnitNameplatesMakeLarger.setFunc("1")

    SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "keepGroupsTogether", true)
    SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "useClassColors", true)
    SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "displayBorder", false)
    SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "frameHeight", 54, 54)
    SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "frameWidth", 137, 137)

    StaticPopup_Show("RELOAD_UI")
end)