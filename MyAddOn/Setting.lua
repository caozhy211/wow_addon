local defaultMiniMapTracking = {
    ["136456"] = true,
    ["524051"] = true,
    ["535616"] = true,
    ["535615"] = true,
}
local isPetTrainer = IsSpellKnown(125439) and C_PetJournal.IsJournalUnlocked()
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
local myBagFilter = {
    LE_BAG_FILTER_FLAG_TRADE_GOODS,
    LE_BAG_FILTER_FLAG_TRADE_GOODS,
    LE_BAG_FILTER_FLAG_CONSUMABLES,
    LE_BAG_FILTER_FLAG_EQUIPMENT,
}
local unbinds = {
    MOVEANDSTEER = 1,
    MOVEFORWARD = 2,
    MOVEBACKWARD = 2,
    TURNLEFT = 1,
    TURNRIGHT = 1,
    JUMP = 2,
    TOGGLEAUTORUN = 2,

    REPLY2 = 1,

    BONUSACTIONBUTTON2 = 1,
    BONUSACTIONBUTTON3 = 1,
    BONUSACTIONBUTTON4 = 1,
    BONUSACTIONBUTTON5 = 1,
    BONUSACTIONBUTTON6 = 1,
    BONUSACTIONBUTTON7 = 1,
    BONUSACTIONBUTTON8 = 1,
    BONUSACTIONBUTTON9 = 1,
    BONUSACTIONBUTTON10 = 1,
    ACTIONPAGE1 = 1,
    ACTIONPAGE2 = 1,
    ACTIONPAGE3 = 1,
    ACTIONPAGE4 = 1,
    ACTIONPAGE5 = 1,
    ACTIONPAGE6 = 1,
    PREVIOUSACTIONPAGE = 1,
    NEXTACTIONPAGE = 1,

    TARGETSELF = 1,
    TARGETPARTYMEMBER1 = 1,
    TARGETPARTYMEMBER2 = 1,
    TARGETPARTYMEMBER3 = 1,
    TARGETPARTYMEMBER4 = 1,
    TARGETPET = 1,
    TARGETPARTYPET1 = 1,
    TARGETPARTYPET2 = 1,
    TARGETPARTYPET3 = 1,
    TARGETPARTYPET4 = 1,

    TOGGLEBACKPACK = 2,
}
local binds = {
    MOVEFORWARD = "E",
    MOVEBACKWARD = "D",
    STRAFELEFT = "S",
    STRAFERIGHT = "F",
    SITORSTAND = ".",
    TOGGLESHEATH = ",",
    TOGGLEAUTORUN = ";",
    FOLLOWTARGET = "'",

    ACTIONBUTTON1 = "Q",
    ACTIONBUTTON2 = "W",
    ACTIONBUTTON3 = "R",
    ACTIONBUTTON4 = "T",
    ACTIONBUTTON5 = "A",
    ACTIONBUTTON6 = "G",
    ACTIONBUTTON7 = "1",
    ACTIONBUTTON8 = "2",
    ACTIONBUTTON9 = "3",
    ACTIONBUTTON10 = "4",
    ACTIONBUTTON11 = "Z",
    ACTIONBUTTON12 = "X",
    EXTRAACTIONBUTTON1 = "`",
    BONUSACTIONBUTTON1 = "CTRL-`",

    MULTIACTIONBAR1BUTTON1 = "CTRL-Q",
    MULTIACTIONBAR1BUTTON2 = "CTRL-W",
    MULTIACTIONBAR1BUTTON3 = "CTRL-R",
    MULTIACTIONBAR1BUTTON4 = "CTRL-T",
    MULTIACTIONBAR1BUTTON5 = "CTRL-A",
    MULTIACTIONBAR1BUTTON6 = "CTRL-G",
    MULTIACTIONBAR1BUTTON7 = "CTRL-1",
    MULTIACTIONBAR1BUTTON8 = "CTRL-2",
    MULTIACTIONBAR1BUTTON9 = "CTRL-3",
    MULTIACTIONBAR1BUTTON10 = "CTRL-4",
    MULTIACTIONBAR1BUTTON11 = "CTRL-Z",
    MULTIACTIONBAR1BUTTON12 = "CTRL-X",
    MULTIACTIONBAR2BUTTON1 = "CTRL-E",
    MULTIACTIONBAR2BUTTON2 = "CTRL-D",
    MULTIACTIONBAR2BUTTON3 = "CTRL-S",
    MULTIACTIONBAR2BUTTON4 = "CTRL-F",
    MULTIACTIONBAR2BUTTON5 = "SHIFT-E",
    MULTIACTIONBAR2BUTTON6 = "SHIFT-D",
    MULTIACTIONBAR2BUTTON7 = "SHIFT-S",
    MULTIACTIONBAR2BUTTON8 = "SHIFT-F",
    MULTIACTIONBAR2BUTTON9 = "ALT-E",
    MULTIACTIONBAR2BUTTON10 = "ALT-D",
    MULTIACTIONBAR2BUTTON11 = "ALT-S",
    MULTIACTIONBAR2BUTTON12 = "ALT-F",
}

local default = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
default:SetSize(60, 22)
default:SetPoint("Right", 0, 225)
default:SetText("BLZ")
default:SetAlpha(0)

local my = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
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
end

local function SetDefaultMiniMapTracking()
    for i = 1, GetNumTrackingTypes() do
        local _, texture = GetTrackingInfo(i)
        SetTracking(i, defaultMiniMapTracking[tostring(texture)])
    end
end

local function SetDefaultOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 1 then
        return
    end
    self.elapsed = 0

    SetDefaultMiniMapTracking()

    local flag = false
    if GetBackpackAutosortDisabled() then
        flag = true
        SetBackpackAutosortDisabled(false)
    end
    for i = 1, NUM_BAG_SLOTS do
        for j = LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, LE_BAG_FILTER_FLAG_TRADE_GOODS do
            if GetBagSlotFlag(i, j) then
                flag = true
                SetBagSlotFlag(i, j, false)
            end
        end
    end

    if not flag then
        self:SetScript("OnUpdate", nil)
    end
end

default:SetScript("OnClick", function(self)
    self:SetScript("OnClick", nil)
    my:SetScript("OnClick", nil)

    self:SetScript("OnUpdate", SetDefaultOnUpdate)

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

local function UnbindButton(action, isButton2)
    local key1, key2 = GetBindingKey(action, 1)
    if key1 then
        SetBinding(key1, nil, 1)
        if isButton2 then
            KeyBindingFrame_SetBinding(key1, action, 1)
        else
            KeyBindingFrame_SetBinding(key1, nil, 1, key1)
        end
    end
    if key2 then
        SetBinding(key2, nil, 1)
        KeyBindingFrame_SetBinding(key2, nil, 1, key2)
    end
end

local function UnbindButtons(unbindKeys)
    for action, id in pairs(unbindKeys) do
        UnbindButton(action, id == 2)
    end
end

local function BindButtons(bindKeys)
    for action, key in pairs(bindKeys) do
        KeyBindingFrame_AttemptKeybind(KeyBindingFrame, key, action, 1, 1, true)
    end
end

local function SetMyBindings()
    UnbindButtons(unbinds)
    BindButtons(binds)
    C_VoiceChat.SetPushToTalkBinding({ "BUTTON3" })
    SaveBindings(ACCOUNT_BINDINGS)
    KeyBindingFrame.outputText:SetText("")
end

local function ApplyMySettings()
    SetCVars(hiddenCVars)
    SetCVars(voiceCVars)

    SetMyInterfaceOptions()

    if LoadAddOn("Blizzard_BindingUI") then
        SetMyBindings()
    end

    local list = ChatFrame1.messageTypeList
    for i = 1, #list do
        if list[i] == "CHANNEL" then
            tremove(list, i)
            ChatFrame_RemoveMessageGroup(ChatFrame1, "CHANNEL")
            break
        end
    end
    ChatFrame_AddChannel(ChatFrame1, "尋求組隊")
end

local function SetMyMiniMapTracking()
    for i = 1, GetNumTrackingTypes() do
        local _, texture = GetTrackingInfo(i)
        if texture == 136458 or (isPetTrainer and (texture == 613074 or texture == 136466)) then
            SetTracking(i, true)
        end
    end
end

local function SetMyOnUpdate(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 1 then
        return
    end
    self.elapsed = 0

    SetMyMiniMapTracking()

    local flag = false
    if GetBackpackAutosortDisabled() then
        flag = true
        SetBackpackAutosortDisabled(false)
    end
    for i = 1, NUM_BAG_SLOTS do
        if GetBagSlotFlag(i, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP) then
            flag = true
            SetBagSlotFlag(i, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, false)
        end
        if not GetBagSlotFlag(i, myBagFilter[i]) then
            flag = true
            SetBagSlotFlag(i, myBagFilter[i], true)
        end
    end

    if not flag then
        self:SetScript("OnUpdate", nil)
    end
end

local function GetCompactUnitFrameProfilesSize()
    local resizeVerticalOutsets = 7
    local titleHeight = 14

    local spacing = 2
    local rows = 2
    local columns = ceil(MAX_RAID_GROUPS / rows)

    local containerResizeFrameHeight = GetScreenHeight() - 135 - 330
    local containerMaxHeight = containerResizeFrameHeight - resizeVerticalOutsets * 2
    local height
    local arg = 1
    while arg >= 1 do
        height = floor(containerMaxHeight / (MEMBERS_PER_RAID_GROUP * rows + ceil(arg)))
        arg = (titleHeight * rows + spacing * (MEMBERS_PER_RAID_GROUP * rows + rows - 1)) / (height * ceil(arg))
    end

    local maxRight = 570
    local left = 22
    local width = floor((maxRight - spacing * columns - left) / columns)

    return height, width
end

my:SetScript("OnClick", function(self)
    self:SetScript("OnClick", nil)
    default:SetScript("OnClick", nil)

    self:SetScript("OnUpdate", SetMyOnUpdate)

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

    local height, width = GetCompactUnitFrameProfilesSize()
    SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "keepGroupsTogether", true)
    SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "useClassColors", true)
    SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "displayBorder", false)
    SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "frameHeight", height, height)
    SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "frameWidth", width, width)

    StaticPopup_Show("RELOAD_UI")
end)

if not isPetTrainer then
    my:RegisterEvent("SPELLS_CHANGED")

    my:SetScript("OnEvent", function(self, event)
        if isPetTrainer then
            for i = 1, GetNumTrackingTypes() do
                local _, texture = GetTrackingInfo(i)
                if texture == 613074 or texture == 136466 then
                    SetTracking(i, true)
                end
            end
            self:UnregisterEvent(event)
        end
    end)
end

hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"], "OnShow", function(self)
    self.editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
end)