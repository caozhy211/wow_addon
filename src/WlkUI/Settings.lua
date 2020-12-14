--- VehicleSeatIndicator 右边相对 UIParent 右边的偏移
local OFFSET_X1 = -62
--- CompactRaidFrameContainer 左边相对 UIParent 左边的偏移
local OFFSET_X2 = 22
--- VehicleSeatIndicator 底部相对 UIParent 顶部的偏移
local OFFSET_Y1 = -320
--- DurabilityFrame 底部相对 UIParent 顶部的偏移
local OFFSET_Y2 = -267
--- OrderHallCommandBar 底部相对 UIParent 顶部的偏移
local OFFSET_Y3 = -25
--- CompactRaidGroup.title 的高度
local HEIGHT = 14
local buttonWidth = -OFFSET_X1
local buttonHeight = 22
local buttonSpacing = (OFFSET_Y2 - OFFSET_Y1 - buttonHeight * 2) / 3
local frameSpacing = 3
local rows = 4
local columns = ceil(MAX_RAID_GROUPS / rows)
local maxRight = 298
local maxBottom = 330
local maxHeight = 1080 + OFFSET_Y3 - maxBottom
local unitFrameWidth = (maxRight - OFFSET_X2 - frameSpacing * (columns - 1)) / columns
local unitFrameHeight = (maxHeight - HEIGHT * rows - frameSpacing * (MEMBERS_PER_RAID_GROUP * rows + rows - 1))
        / (MEMBERS_PER_RAID_GROUP * rows)
local groupFrameWidth = unitFrameWidth
local groupFrameHeight = HEIGHT + MEMBERS_PER_RAID_GROUP * (unitFrameHeight + frameSpacing)
local framesToUpdate = {}
local useUiScaleValue = GetScreenHeight() - 1080 < -0.005 and "1" or ""
local uiScaleValue = useUiScaleValue == "1" and GetScreenHeight() / 1080 or ""
local cVars = {
    -- 锁定目标
    deselectOnClick = "",
    -- 自动解除飞行中坐骑
    autoDismountFlying = "",
    -- 自动清除离开标签
    autoClearAFK = "",
    -- 自动拾取
    autoLootDefault = "1",
    -- 左键进行互动
    interactOnLeftClick = "",
    -- 在滑鼠位置开启拾取视窗
    lootUnderMouse = "",
    -- 目标的目标
    showTargetOfTarget = "",
    -- 低生命力时不要闪动萤幕
    doNotFlashLowHealthWarning = "",
    -- 丧失控制警告
    lossOfControl = "",
    -- 自己的战斗文字卷动
    enableFloatingCombatText = "1",
    -- 法术警告透明度(0 ~ 1.0)
    spellActivationOverlayOpacity = "",
    -- 自动自我施法
    autoSelfCast = "",
    -- 显著标示[停用: 0; 仅限任务目标: 1; 仅限任务目标和滑鼠指向目标: 2(预设); 任务目标、滑鼠指向目标与选择的目标: 3]
    Outline = "",
    -- 团队醒目标示[圆圈: 0(预设); 轮廓: 1; 圆圈和外框: 2; 关闭: -1] 
    findYourselfMode = "",
    -- 状态文字[数值: NUMERIC,1; 百分比: PERCENT,1; 两者: BOTH,1; 无: NONE,0(预设)]
    statusTextDisplay = "BOTH",
    statusText = "1",
    -- 对话泡泡[全部: 1,1(预设); 无: 0,0; 不包含队伍对话: 1,0]
    chatBubbles = "",
    chatBubblesParty = "",
    -- 旋转小地图
    rotateMinimap = "",
    -- 隐藏冒险指南提示
    hideAdventureJournalAlerts = "",
    -- 游戏内导航
    showInGameNavigation = "",
    -- 教学说明
    showTutorials = "0",
    -- 不当言词过滤器
    profanityFilter = "",
    -- 滥发讯息过滤器
    spamFilter = "",
    -- 公会成员提示
    guildMemberNotify = "",
    -- 阻止交易
    blockTrades = "",
    -- 封锁对话频道邀请
    blockChannelInvites = "",
    -- 聊天方式[以即时通讯方式: im(预设); 以传统方式: classic]
    chatStyle = "",
    -- 对话时间标记[无: none(预设); 03:27: %I:%M; 03:27:32: %I:%M:%S; 03:27 PM: %I:%M %p; 03:27:32 PM: %I:%M:%S %p;
    -- 15:27: %H:%M; 15:27:32: %H:%M:%S]
    showTimestamps = "",
    -- 新的密语[新的栏页: popout; 内嵌: inline(预设); 都显示: popout_and_inline]
    whisperMode = "",
    -- 线上好友
    showToastOnline = "",
    -- 离线好友
    showToastOffline = "",
    -- 公告更新
    showToastBroadcast = "1",
    -- 自动接受快速加入要求
    autoAcceptQuickJoinRequests = "",
    -- Real ID 及 BattleTag 好友邀请
    showToastFriendRequest = "",
    -- 显示通知视窗
    showToastWindow = "",
    -- 以垂直方式堆叠右方快捷列
    multiBarRightVerticalLayout = "",
    -- 锁定快捷列
    lockActionBars = "0",
    -- 总是显示快捷列
    alwaysShowActionBars = "1",
    -- 显示冷却时间
    countdownForCooldowns = "",
    -- 我的名称
    UnitNameOwn = "",
    -- 小动物与小宠物
    UnitNameNonCombatCreatureName = "",
    -- 友方玩家
    UnitNameFriendlyPlayerName = "",
    -- 友方玩家-仆从
    UnitNameFriendlyMinionName = "",
    -- NPC 名称[任务 NPC: 1,0,0,0,0; 敌对与任务 NPC: 1,1,0,0,1; 敌对, 任务与可互动的 NPC: 1,1,1,0,1(预设); 
    -- 所有 NPC: 0,0,0,1,1; 无: 0,0,0,0,1]
    UnitNameFriendlySpecialNPCName = "",
    UnitNameHostleNPC = "",
    UnitNameInteractiveNPC = "",
    UnitNameNPC = "",
    ShowQuestUnitCircles = "",
    -- 敌方玩家
    UnitNameEnemyPlayerName = "",
    -- 敌方玩家-仆从
    UnitNameEnemyMinionName = "",
    -- 显示个人资源
    nameplateShowSelf = "0",
    -- 显示个人资源-显示目标的特殊资源
    nameplateResourceOnTarget = "",
    -- 大型名条
    NamePlateHorizontalScale = "1.4",
    NamePlateVerticalScale = "2.7",
    NamePlateClassificationScale = "1.25",
    -- 警示目标转移
    ShowNamePlateLoseAggroFlash = "",
    -- 名条排列类型[重叠名条: 0(预设); 堆叠名条: 1]
    nameplateMotion = "1",
    -- 总是显示名条
    nameplateShowAll = "1",
    -- 敌方单位(V)
    nameplateShowEnemies = "",
    -- 敌方单位(V)-仆从
    nameplateShowEnemyMinions = "1",
    -- 敌方单位(V)-次要
    nameplateShowEnemyMinus = "",
    -- 友方玩家(SHIFT-V)
    nameplateShowFriends = "",
    -- 友方玩家(SHIFT-V)-仆从
    nameplateShowFriendlyMinions = "",
    -- 水体碰撞
    cameraWaterCollision = "1",
    -- 自动跟随速度(90 ~ 270)
    cameraYawSmoothSpeed = "",
    -- 镜头跟随模式[移动时只调整水平位面: 1; 只有移动时: 4(预设); 总是调整镜头: 2; 永不调整镜头: 0]
    cameraSmoothStyle = "0",
    -- 反转滑鼠
    mouseInvertPitch = "",
    -- 滑鼠观察速度(90 ~ 270)
    cameraYawMoveSpeed = "",
    -- 点击移动
    autointeract = "",
    -- 点击移动镜头模式[移动时只调整水平位面: 1; 只有移动时: 4(预设); 总是调整镜头: 2; 永不调整镜头: 0]
    cameraSmoothTrackingStyle = "",
    -- 开启滑鼠灵敏度
    enableMouseSpeed = "",
    -- 滑鼠灵敏度(0.5 ~ 1.5)
    mouseSpeed = "",
    -- 将游标锁定在视窗内
    ClipCursor = "",
    -- 显示移动面板
    enableMovePad = "",
    -- 动画字幕
    movieSubtitle = "",
    -- 替换全萤幕效果
    overrideScreenFlash = "",
    -- 画面眩晕[让角色保持置中: 1,0(预设); 减少镜头动作: 0,1; 让角色保持置中并减少镜头动作: 1,1; 允许动态镜头移动: 0,0]
    cameraKeepCharacterCentered = "",
    cameraReduceUnexpectedMovement = "",
    -- 画面震动[无: 0,0; 较弱: 0.25,0.25; 完整: 1,1(预设)]
    shakeStrengthCamera = "",
    shakeStrengthUI = "",
    -- 启动色盲模式界面
    colorblindMode = "",
    -- 色盲模式设定[无: 0(预设); 1. 红绿色盲: 1; 2. 绿色盲: 2; 3. 蓝色盲: 3]
    colorblindSimulator = "",
    -- 调整校正程度(0.05 ~ 1.0)
    colorblindWeaknessFactor = "",
    -- 使用团队风格的队伍框架
    useCompactPartyFrames = "1",
    -- 使用者界面缩放
    useUiScale = useUiScaleValue,
    uiScale = uiScaleValue,
    -- 文字
    textLocale = "zhTW",
    -- 语音
    audioLocale = "enUS",

    xpBarText = "1",
    scriptErrors = "1",
    taintLog = "1",
    rawMouseEnable = "1",
    ffxDeath = "0",
    nameplateMaxDistance = "40",
    alwaysCompareItems = "1",
    cameraDistanceMaxZoomFactor = "2.6",
    floatingCombatTextFloatMode = "3",
    floatingCombatTextCombatState = "1",
    overrideArchive = "0",
}
local defaultTracking = {
    [MINIMAP_TRACKING_BARBER] = true,
    [MINIMAP_TRACKING_DIGSITES] = true,
    [MINIMAP_TRACKING_FLIGHTMASTER] = true,
    [MINIMAP_TRACKING_FOCUS] = true,
    [MINIMAP_TRACKING_QUEST_POIS] = true,
}
local customTracking = {
    [MINIMAP_TRACKING_INNKEEPER] = true,
    [MINIMAP_TRACKING_TARGET] = true,
}
local unbindKeys = {
    {
        "MOVEANDSTEER", "REPLY2", "TARGETSELF", "TARGETPARTYMEMBER1", "TARGETPARTYMEMBER2", "TARGETPARTYMEMBER3",
        "TARGETPARTYMEMBER4", "TARGETPET", "TARGETPARTYPET1", "TARGETPARTYPET2", "TARGETPARTYPET3", "TARGETPARTYPET4",
    },
    { "MOVEFORWARD", "MOVEBACKWARD", "TURNLEFT", "TURNRIGHT", "JUMP", "TOGGLEAUTORUN", "TOGGLEBACKPACK", },
}
local bindKeys = {
    MOVEFORWARD = "E", MOVEBACKWARD = "D", STRAFELEFT = "S", STRAFERIGHT = "F", SITORSTAND = ".", TOGGLESHEATH = ",",
    TOGGLEAUTORUN = ";", FOLLOWTARGET = "'", ACTIONBUTTON1 = "1", ACTIONBUTTON2 = "2", ACTIONBUTTON3 = "3",
    ACTIONBUTTON4 = "4", ACTIONBUTTON5 = "Z", ACTIONBUTTON6 = "X", ACTIONBUTTON7 = "Q", ACTIONBUTTON8 = "W",
    ACTIONBUTTON9 = "R", ACTIONBUTTON10 = "T", ACTIONBUTTON11 = "A", ACTIONBUTTON12 = "G", EXTRAACTIONBUTTON1 = "F4",
    MULTIACTIONBAR1BUTTON1 = "CTRL-1", MULTIACTIONBAR1BUTTON2 = "CTRL-2", MULTIACTIONBAR1BUTTON3 = "CTRL-3",
    MULTIACTIONBAR1BUTTON4 = "CTRL-4", MULTIACTIONBAR1BUTTON5 = "CTRL-Z", MULTIACTIONBAR1BUTTON6 = "CTRL-X",
    MULTIACTIONBAR1BUTTON7 = "CTRL-Q", MULTIACTIONBAR1BUTTON8 = "CTRL-W", MULTIACTIONBAR1BUTTON9 = "CTRL-R",
    MULTIACTIONBAR1BUTTON10 = "CTRL-T", MULTIACTIONBAR1BUTTON11 = "CTRL-A", MULTIACTIONBAR1BUTTON12 = "CTRL-G",
    MULTIACTIONBAR2BUTTON1 = "ALT-E", MULTIACTIONBAR2BUTTON2 = "ALT-D", MULTIACTIONBAR2BUTTON3 = "ALT-S",
    MULTIACTIONBAR2BUTTON4 = "ALT-F", MULTIACTIONBAR2BUTTON5 = "SHIFT-E", MULTIACTIONBAR2BUTTON6 = "SHIFT-D",
    MULTIACTIONBAR2BUTTON7 = "CTRL-E", MULTIACTIONBAR2BUTTON8 = "CTRL-D", MULTIACTIONBAR2BUTTON9 = "CTRL-S",
    MULTIACTIONBAR2BUTTON10 = "CTRL-F", MULTIACTIONBAR2BUTTON11 = "SHIFT-S", MULTIACTIONBAR2BUTTON12 = "SHIFT-F",
    PETATTACK = "`",
}
local bagFilters = {
    LE_BAG_FILTER_FLAG_TRADE_GOODS,
    LE_BAG_FILTER_FLAG_TRADE_GOODS,
    LE_BAG_FILTER_FLAG_CONSUMABLES,
    LE_BAG_FILTER_FLAG_EQUIPMENT,
}

---@type Button
local defaultsButton = CreateFrame("Button", "WlkDefaultsButton", UIParent, "UIPanelButtonTemplate")
---@type Button
local customsButton = CreateFrame("Button", "WlkCustomsButton", UIParent, "UIPanelButtonTemplate")
---@type CheckButton
local focusButton = CreateFrame("CheckButton", "WlkFocusButton", UIParent, "SecureActionButtonTemplate")

local function showButtons()
    defaultsButton:SetAlpha(1)
    customsButton:SetAlpha(1)
end

local function hideButtons()
    defaultsButton:SetAlpha(0)
    customsButton:SetAlpha(0)
end

local function disableButtons()
    defaultsButton:Disable()
    customsButton:Disable()
end

local function isInCombatLockdown()
    if InCombatLockdown() then
        UIErrorsFrame:AddExternalErrorMessage(ERR_NOT_IN_COMBAT)
        return true
    end
end

---@param frame Frame
local function updateCompactRaidGroupLayout(frame)
    if InCombatLockdown() then
        tinsert(framesToUpdate, frame)
        customsButton:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    for i = 1, MEMBERS_PER_RAID_GROUP do
        ---@type Button
        local unitFrame = _G[frame:GetName() .. "Member" .. i]
        unitFrame:ClearAllPoints()
        unitFrame:SetPoint("TOP", 0, (1 - i) * unitFrameHeight - i * frameSpacing - HEIGHT)
    end
    frame:SetSize(groupFrameWidth, groupFrameHeight)
end

local function updateCompactFrameContainerLayout()
    if InCombatLockdown() then
        customsButton:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    ---@type Frame
    local frame = CompactPartyFrame
    if frame then
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", maxRight, maxBottom)
    end
    for i = 1, NUM_RAID_GROUPS do
        frame = _G["CompactRaidGroup" .. i]
        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", maxRight - floor((i - 1) / rows)
                    * (groupFrameWidth + frameSpacing), maxBottom + (i - 1) % rows * (groupFrameHeight + frameSpacing))
        end
    end
end

StaticPopupDialogs["APPLY_SETTINGS"] = {
    text = "反和諧和語言設定需要重新啟動遊戲才能夠生效。",
    subText = "其他設定需要重新載入遊戲才能夠生效。",
    button1 = RELOADUI,
    button2 = "",
    OnAccept = ReloadUI,
    showAlert = 1,
    timeout = 0,
    whileDead = 1,
    notClosableByLogout = 1,
    ---@param self StaticPopupTemplate
    OnShow = function(self)
        local originalButton = self.button2
        ---@type Button @创建能够退出游戏的按钮覆盖 button2
        local button = CreateFrame("Button", "Wlk" .. originalButton:GetName(), self, "StaticPopupButtonTemplate, "
                .. "SecureActionButtonTemplate")
        button:SetAllPoints(originalButton)
        button:SetFrameLevel(originalButton:GetFrameLevel() + 1)
        button:SetText(EXIT_GAME)
        button:SetAttribute("type1", "macro")
        button:SetAttribute("macrotext", "/quit")
    end
}

defaultsButton:SetSize(buttonWidth, buttonHeight)
defaultsButton:SetPoint("TOPRIGHT", 0, OFFSET_Y2 - buttonSpacing)
defaultsButton:SetText("BLZ")
defaultsButton:SetScript("OnEnter", showButtons)
defaultsButton:SetScript("OnLeave", hideButtons)
defaultsButton:SetScript("OnClick", function()
    if isInCombatLockdown() then
        return
    end
    disableButtons()

    for name in pairs(cVars) do
        SetCVar(name, (name == "textLocale" or name == "audioLocale") and GetAvailableLocales() or GetCVarDefault(name))
    end
    SetAutoDeclineGuildInvites(false)
    SetActionBarToggles()
    CompactUnitFrameProfiles_ResetToDefaults()
    CompactRaidFrameManager_ResetContainerPosition()

    FCF_ResetChatWindows()
    ChatConfig_ResetChatSettings()

    C_VoiceChat.SetPushToTalkBinding({ "`", })
    KeyBindingFrame:ResetBindingsToDefault()
    SaveBindings(ACCOUNT_BINDINGS)

    for i = 1, GetNumTrackingTypes() do
        SetTracking(i, defaultTracking[GetTrackingInfo(i)])
    end

    if GetBackpackAutosortDisabled() then
        SetBackpackAutosortDisabled(false)
    end
    for i = 1, NUM_BAG_SLOTS do
        for j = LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, LE_BAG_FILTER_FLAG_TRADE_GOODS do
            if GetBagSlotFlag(i, j) then
                SetBagSlotFlag(i, j, false)
                break
            end
        end
    end

    StaticPopup_Show("APPLY_SETTINGS")
end)

customsButton:SetSize(buttonWidth, buttonHeight)
customsButton:SetPoint("TOP", defaultsButton, "BOTTOM", 0, -buttonSpacing)
customsButton:SetText("WLK")
customsButton:SetScript("OnEnter", showButtons)
customsButton:SetScript("OnLeave", hideButtons)
customsButton:SetScript("OnClick", function()
    if isInCombatLockdown() then
        return
    end
    disableButtons()

    for name, value in pairs(cVars) do
        SetCVar(name, value == "" and GetCVarDefault(name) or value)
    end
    -- 阻止公会邀请
    SetAutoDeclineGuildInvites(true)
    -- 左下方快捷列, 右下方快捷列, 右方快捷列, 右方快捷列 2
    SetActionBarToggles(true, true, true)
    -- 团队档案
    CompactUnitFrameProfiles_ResetToDefaults()
    local profile = GetActiveRaidProfile()
    -- 让各队伍连在一起
    SetRaidProfileOption(profile, "keepGroupsTogether", true)
    -- 显示边框
    SetRaidProfileOption(profile, "displayBorder", false)
    -- 团队框架高度
    SetRaidProfileOption(profile, "frameHeight", unitFrameHeight, unitFrameHeight)
    -- 团队框架宽度
    SetRaidProfileOption(profile, "frameWidth", unitFrameWidth, unitFrameWidth)

    -- 对话视窗
    FCF_ResetChatWindows()
    ChatConfig_ResetChatSettings()
    -- 频道-频道
    local channelList = { GetChannelList() }
    for i = 2, #channelList, 3 do
        ChatFrame_AddChannel(ChatFrame1, channelList[i])
    end
    -- 其他-战斗-经验值
    ChatFrame_AddMessageGroup(ChatFrame1, "COMBAT_XP_GAIN")
    -- 其他-其他-频道
    ChatFrame_RemoveMessageGroup(ChatFrame1, "CHANNEL")

    -- 按键设定
    -- 发话键
    C_VoiceChat.SetPushToTalkBinding({ "", })
    -- 恢复预设值
    KeyBindingFrame:ResetBindingsToDefault()
    -- 自动拾取键
    SetModifiedClick("AUTOLOOTTOGGLE", "CTRL")
    -- 专注施法键
    SetModifiedClick("FOCUSCAST", "SHIFT")
    -- 自我施法键
    SetModifiedClick("SELFCAST", "NONE")
    -- 取消设定
    for keyIndex, actions in ipairs(unbindKeys) do
        for _, action in ipairs(actions) do
            SetBinding(select(keyIndex, GetBindingKey(action)))
        end
    end
    for action, key in pairs(bindKeys) do
        KeyBindingFrame:AttemptKeybind(key, action, KeyBindingFrame.mode, 1, true)
    end
    SaveBindings(ACCOUNT_BINDINGS)
    KeyBindingFrame.outputText:SetText("")

    -- 小地图追踪
    for i = 1, GetNumTrackingTypes() do
        local name = GetTrackingInfo(i)
        SetTracking(i, customTracking[name] or defaultTracking[name])
    end

    -- 背包设定
    if GetBackpackAutosortDisabled() then
        SetBackpackAutosortDisabled(false)
    end
    for i = 1, NUM_BAG_SLOTS do
        if GetBagSlotFlag(i, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP) then
            SetBagSlotFlag(i, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, false)
        end

        if not GetBagSlotFlag(i, bagFilters[i]) then
            SetBagSlotFlag(i, bagFilters[i], true)
        end
    end

    StaticPopup_Show("APPLY_SETTINGS")
end)
customsButton:RegisterEvent("PLAYER_LOGIN")
customsButton:RegisterEvent("ADDON_LOADED")
customsButton:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" and ... == "Blizzard_TalkingHeadUI" then
        customsButton:UnregisterEvent(event)
        TalkingHeadFrame:ClearAllPoints()
        TalkingHeadFrame:SetPoint("BOTTOMLEFT", 0, 116)
    elseif event == "PLAYER_LOGIN" then
        ObjectiveTrackerFrame:ClearAllPoints()
        ObjectiveTrackerFrame:SetPoint("TOPLEFT", UIParent, "TOPRIGHT", -264, OFFSET_Y1)
        ObjectiveTrackerFrame:SetPoint("BOTTOMRIGHT", UIParent, -29, 88)
        ObjectiveTrackerFrame:SetMovable(false)

        if LoadAddOn("Skada") then
            Skada.FormatNumber = function(_, value)
                if value >= 1e8 then
                    return format("%.2f%s", value / 1e8, SECOND_NUMBER_CAP)
                elseif value >= 1e4 then
                    return format("%.2f%s", value / 1e4, FIRST_NUMBER_CAP)
                end
                return floor(value)
            end

            local window = Skada:GetWindows()[1]
            ---@type Frame
            local barGroup = window.bargroup
            ---@type Frame
            local title = barGroup.button
            local timer = title:CreateFontString(nil, "OVERLAY", "SystemFont_Shadow_Med3")
            local ticker
            local startTime

            barGroup:ClearAllPoints()
            barGroup:SetPoint("BOTTOMLEFT")

            window.db.barwidth = 453
            window.db.barheight = 19
            window.db.background.height = 96
            window.db.barslocked = true
            window.db.smoothing = true

            Skada.db.profile.reset.join = 1

            timer:SetPoint("CENTER")
            timer:SetText(Skada.char.sets[1] and SecondsToClock(Skada.char.sets[1].time) or "")
            hooksecurefunc(Skada, "StartCombat", function()
                startTime = Skada.current.starttime
                timer:SetText("")
                ---@type TickerPrototype
                ticker = C_Timer.NewTicker(1, function()
                    if Skada.current then
                        timer:SetText(SecondsToClock(time() - Skada.current.starttime))
                    end
                end)
            end)
            hooksecurefunc(Skada, "EndSegment", function()
                if ticker then
                    ticker:Cancel()
                    ticker = nil
                end
                timer:SetText(startTime and SecondsToClock(time() - startTime) or "")
            end)
            hooksecurefunc(window, "UpdateDisplay", function()
                if window.selectedset == "current" and window.selectedmode then
                    timer:Show()
                else
                    timer:Hide()
                end
            end)
            hooksecurefunc(Skada, "Reset", function()
                timer:Hide()
            end)
        end

        if LoadAddOn("DBM-Core") and LoadAddOn("DBM-VPYike") then
            DBM_AllSavedOptions.Default.ChosenVoicePack = "Yike"
            DBM_AllSavedOptions.Default.CountdownVoice = "VP:Yike"
            DBM_AllSavedOptions.Default.CountdownVoice2 = "VP:Yike"
            DBM_AllSavedOptions.Default.CountdownVoice3 = "VP:Yike"
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        customsButton:UnregisterEvent(event)
        for _, frame in ipairs(framesToUpdate) do
            updateCompactRaidGroupLayout(frame)
        end
        wipe(framesToUpdate)
        updateCompactFrameContainerLayout()
    end
end)

hideButtons()

hooksecurefunc("CompactRaidGroup_UpdateLayout", updateCompactRaidGroupLayout)

hooksecurefunc("CompactRaidFrameContainer_LayoutFrames", updateCompactFrameContainerLayout)

focusButton:SetAttribute("type1", "macro")
focusButton:SetAttribute("macrotext", "/focus mouseover")

SetOverrideBindingClick(focusButton, true, "SHIFT-BUTTON1", "WlkFocusButton")

hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"], "OnShow", function(self)
    ---@type EditBox
    local editBox = self.editBox
    editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
end)

hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"], "OnShow", function(self)
    ---@type EditBox
    local editBox = self.editBox
    editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
end)

hooksecurefunc(StaticPopupDialogs["CONFIRM_DESTROY_COMMUNITY"], "OnShow", function(self)
    ---@type EditBox
    local editBox = self.editBox
    editBox:SetText(COMMUNITIES_DELETE_CONFIRM_STRING)
end)

ObjectiveTrackerFrame:SetMovable(true)
ObjectiveTrackerFrame:SetUserPlaced(true)

hooksecurefunc("ObjectiveTracker_AddBlock", function(block)
    if block == ScenarioBlocksFrame then
        block:SetPoint("LEFT", ObjectiveTrackerFrame.BlocksFrame, -13, 0)
    end
end)
