---@type Button
local defaultButton = CreateFrame("Button", "WlkDefaultSettingsButton", UIParent, "UIPanelButtonTemplate")
defaultButton:SetSize(60, 22)
defaultButton:SetPoint("RIGHT", 0, 255)
defaultButton:SetText("BLZ")
defaultButton:SetAlpha(0)

---@type Button
local customButton = CreateFrame("Button", "WlkCustomSettingsButton", UIParent, "UIPanelButtonTemplate")
customButton:SetSize(60, 22)
customButton:SetPoint("RIGHT", 0, 225)
customButton:SetText("WLK")
customButton:SetAlpha(0)

local function ShowButtons()
    defaultButton:SetAlpha(1)
    customButton:SetAlpha(1)
end

local function HideButtons()
    defaultButton:SetAlpha(0)
    customButton:SetAlpha(0)
end

local function DisableButtons()
    defaultButton:Disable()
    customButton:Disable()
end

defaultButton:SetScript("OnEnter", ShowButtons)
defaultButton:SetScript("OnLeave", HideButtons)
customButton:SetScript("OnEnter", ShowButtons)
customButton:SetScript("OnLeave", HideButtons)

local function IsInCombat()
    if InCombatLockdown() then
        UIErrorsFrame:AddExternalErrorMessage(ERR_NOT_IN_COMBAT)
        return true
    end
    return false
end

local TRACKING = {
    -- 飞行管理员
    [136456] = true,
    -- 焦点目标
    [524051] = true,
    -- 任务目标追踪区域
    [535616] = true,
    -- 追踪挖掘场
    [535615] = true,
}

local otherCVars = {
    -- 显示脚本错误
    scriptErrors = 1,
    -- 记录插件污染日志
    taintLog = 1,
    -- 启用原始滑鼠，避免滑鼠重置到屏幕中间
    rawMouseEnable = 1,
    -- 关闭死亡效果
    ffxDeath = 0,
    -- 显示名条的最远距离
    nameplateMaxDistance = 40,
    -- 启用总是比较物品
    alwaysCompareItems = 1,
    -- 设置视距为最大值
    cameraDistanceMaxZoomFactor = 2.6,
    -- 使用弧型的战斗文字卷动
    floatingCombatTextFloatMode = 3,
    -- 不显示战斗文字的治疗信息
    floatingCombatTextCombatHealing = 0,
    -- 显示进入/离开战斗
    floatingCombatTextCombatState = 1,
    -- 隐藏竞技场单位框架
    showArenaEnemyFrames = 0,
    -- 世界地图不显示战宠训练师
    showTamers = 0,
    -- 游戏文字使用繁体中文
    textLocale = "zhTW",
    -- 游戏语音使用英语
    audioLocale = "enUS",
    -- 反和谐
    overrideArchive = 0,
}

local interfaceOptionCVars = {
    -- 锁定目标
    deselectOnClick = "",
    -- 自动解除飞行
    autoDismountFlying = "",
    -- 自动清除离开标签
    autoClearAFK = "",
    -- 自动拾取
    autoLootDefault = 1,
    -- 左键进行互动
    interactOnLeftClick = "",
    -- 在滑鼠位置开启拾取视窗
    lootUnderMouse = "",
    -- 目标的目标
    showTargetOfTarget = "",
    -- 低生命力时不要闪烁萤幕
    doNotFlashLowHealthWarning = "",
    -- 自动自我施法
    autoSelfCast = "",
    -- 丧失控制警告
    lossOfControl = "",
    -- 自己的战斗文字卷动
    enableFloatingCombatText = 1,
    -- 法术警告透明度
    spellActivationOverlayOpacity = "",
    -- 旋转小地图
    rotateMinimap = "",
    -- 隐藏冒险指南提示
    hideAdventureJournalAlerts = "",
    -- 教学说明
    showTutorials = 0,
    -- 不当言词过滤器
    profanityFilter = "",
    -- 滥发信息过滤器
    spamFilter = "",
    -- 公会成员提示
    guildMemberNotify = "",
    -- 阻止交易
    blockTrades = "",
    -- 封锁对话频道邀请
    blockChannelInvites = "",
    -- 线上好友
    showToastOnline = "",
    -- 离线好友
    showToastOffline = "",
    -- 公告更新
    showToastBroadcast = "",
    -- 自动接受快速加入要求
    autoAcceptQuickJoinRequests = "",
    -- Real ID 及 BattleTag 好友邀请
    showToastFriendRequest = "",
    -- 显示通知视窗
    showToastWindow = "",
    -- 以垂直方式堆叠右方快捷列
    multiBarRightVerticalLayout = "",
    -- 锁定快捷列
    lockActionBars = 0,
    -- 总是显示快捷列
    alwaysShowActionBars = 1,
    -- 显示冷却时间
    countdownForCooldowns = "",
    -- 我的名称
    UnitNameOwn = "",
    -- 小动物与小宠物名称
    UnitNameNonCombatCreatureName = "",
    -- 友方玩家名称
    UnitNameFriendlyPlayerName = "",
    -- 友方玩家仆从名称
    UnitNameFriendlyMinionName = "",
    -- 敌方玩家名称
    UnitNameEnemyPlayerName = "",
    -- 敌方玩家仆从名称
    UnitNameEnemyMinionName = "",
    -- 显示个人资源
    nameplateShowSelf = 0,
    -- 显示目标的特殊资源
    nameplateResourceOnTarget = "",
    -- 警示目标转移
    ShowNamePlateLoseAggroFlash = "",
    -- 总是显示名条
    nameplateShowAll = 1,
    -- 敌方单位名条
    nameplateShowEnemies = "",
    -- 敌方仆从单位名条
    nameplateShowEnemyMinions = 1,
    -- 敌方次要单位名条
    nameplateShowEnemyMinus = "",
    -- 友方玩家名条
    nameplateShowFriends = "",
    -- 友方玩家仆从名条
    nameplateShowFriendlyMinions = "",
    -- 水体碰撞
    cameraWaterCollision = 1,
    -- 自动跟随速度
    cameraYawSmoothSpeed = "",
    cameraPitchSmoothSpeed = "",
    -- 反转滑鼠
    mouseInvertPitch = "",
    -- 滑鼠观察速度
    cameraYawMoveSpeed = "",
    cameraPitchMoveSpeed = "",
    -- 开启滑鼠灵敏度
    enableMouseSpeed = "",
    -- 滑鼠灵敏度
    mouseSpeed = "",
    -- 将游标锁定在视窗内
    ClipCursor = "",
    -- 点击移动
    autointeract = "",
    -- 显示移动面板
    enableMovePad = "",
    -- 动画字幕
    movieSubtitle = 1,
    -- 启动色盲模式界面
    colorblindMode = "",
    -- 调整校正程度
    colorblindWeaknessFactor = "",
    -- 色盲模式设定
    colorblindSimulator = "",
    -- 聊天方式
    chatStyle = "",
    -- 大型名条
    NamePlateHorizontalScale = 1.4,
    NamePlateVerticalScale = 2.7,
    NamePlateClassificationScale = 1.25,
    -- NPC 名称
    UnitNameFriendlySpecialNPCName = "",
    UnitNameNPC = "",
    UnitNameHostleNPC = "",
    UnitNameInteractiveNPC = "",
    ShowQuestUnitCircles = "",
    -- 名条排列类型
    nameplateMotion = 1,
    -- 对话泡泡
    chatBubbles = 0,
    chatBubblesParty = 0,
    -- 状态文字
    statusTextDisplay = "BOTH",
    statusText = 1,
    -- 显著标示
    Outline = "",
    -- 团队醒目标示
    findYourselfMode = "",
    -- 对话时间标记
    showTimestamps = "",
    -- 新的密语
    whisperMode = "",
    -- 镜头跟随模式
    cameraSmoothStyle = 0,
    -- 点击移动镜头模式
    cameraSmoothTrackingStyle = "",
    -- 使用团队风格的队伍框架
    useCompactPartyFrames = 1,
}

defaultButton:SetScript("OnClick", function()
    if IsInCombat() then
        return
    end
    DisableButtons()

    for name in pairs(otherCVars) do
        SetCVar(name, (name == "textLocale" or name == "audioLocale") and GetAvailableLocales() or GetCVarDefault(name))
    end

    -- 界面设置 CVar 恢复预设值
    for name in pairs(interfaceOptionCVars) do
        SetCVar(name, GetCVarDefault(name))
    end
    -- 阻止公会邀请恢复预设值
    SetAutoDeclineGuildInvites(false)
    -- 快捷列显示恢复预设值
    SetActionBarToggles()
    -- 团队档案恢复预设值
    CompactUnitFrameProfiles_ResetToDefaults()

    -- 按键设定恢复预设值
    C_VoiceChat.SetPushToTalkBinding({ "`", })
    KeyBindingFrame_LoadUI()
    KeyBindingFrame_ResetBindingsToDefault()
    SaveBindings(ACCOUNT_BINDINGS)

    -- 对话视窗恢复预设值
    FCF_ResetChatWindows()
    ChatConfig_ResetChatSettings()

    -- 小地图追踪恢复预设值
    for i = 1, GetNumTrackingTypes() do
        local _, texture = GetTrackingInfo(i)
        SetTracking(i, TRACKING[texture])
    end
    UIDropDownMenu_Refresh(MiniMapTrackingDropDown)

    -- 背包设定恢复预设值
    if GetBackpackAutosortDisabled() then
        SetBackpackAutosortDisabled(false)
    end
    for i = 1, NUM_BAG_SLOTS do
        for j = LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, LE_BAG_FILTER_FLAG_TRADE_GOODS do
            if GetBagSlotFlag(i, j) then
                SetBagSlotFlag(i, j, false)
            end
        end
    end

    StaticPopup_Show("APPLY_SETTINGS")
end)

local CLIENT_RESTART_ALERT = "反和諧和系統文字語言設定需要重新啟動遊戲才能夠生效。"
local CLIENT_RELOAD_ALERT = "其他設定需要重新載入遊戲才能夠生效。"

--- CompactRaidFrameContainer 和 UIParent 的左边边距
local PADDING1 = 22
--- CompactRaidFrameContainer 和 UIParent 的顶部边距
local PADDING2 = 142
--- CompactRaidFrameContainer 和 UIParent 的底部边距
local PADDING3 = 337
--- CompactUnitFrameTitle 的高度
local HEIGHT1 = 14

--- CompactUnitFrame 的间距
local spacing = 2
local rows = 4
local columns = ceil(MAX_RAID_GROUPS / rows)
local right = 298

local width = floor((right - PADDING1 - spacing * columns) / columns)
local maxHeight = GetScreenHeight() - PADDING2 - PADDING3
local height = ceil((maxHeight - HEIGHT1 * rows - spacing * (MEMBERS_PER_RAID_GROUP * rows + rows - 1))
        / (MEMBERS_PER_RAID_GROUP * rows)) - 1

local unbindKeys = {
    -- 解绑键位设定 1
    {
        -- 移动按键
        "MOVEANDSTEER",
        -- 对话
        "REPLY2",
        -- 选择目标
        "TARGETSELF", "TARGETPARTYMEMBER1", "TARGETPARTYMEMBER2", "TARGETPARTYMEMBER3", "TARGETPARTYMEMBER4",
        "TARGETPET", "TARGETPARTYPET1", "TARGETPARTYPET2", "TARGETPARTYPET3", "TARGETPARTYPET4",
    },
    -- 解绑键位设定 2
    {
        -- 移动按键
        "MOVEFORWARD", "MOVEBACKWARD", "TURNLEFT", "TURNRIGHT", "JUMP", "TOGGLEAUTORUN",
        -- 界面面板
        "TOGGLEBACKPACK",
    },
}

local bindKeys = {
    -- 移动按键
    MOVEFORWARD = "E", MOVEBACKWARD = "D", STRAFELEFT = "S", STRAFERIGHT = "F", SITORSTAND = ".", TOGGLESHEATH = ",",
    TOGGLEAUTORUN = ";", FOLLOWTARGET = "'",
    -- 快捷列
    ACTIONBUTTON1 = "1", ACTIONBUTTON2 = "2", ACTIONBUTTON3 = "3", ACTIONBUTTON4 = "4", ACTIONBUTTON5 = "Z",
    ACTIONBUTTON6 = "X", ACTIONBUTTON7 = "Q", ACTIONBUTTON8 = "W", ACTIONBUTTON9 = "R", ACTIONBUTTON10 = "T",
    ACTIONBUTTON11 = "A", ACTIONBUTTON12 = "G", EXTRAACTIONBUTTON1 = "`",
    -- 复合式快捷列
    MULTIACTIONBAR1BUTTON1 = "CTRL-1", MULTIACTIONBAR1BUTTON2 = "CTRL-2", MULTIACTIONBAR1BUTTON3 = "CTRL-3",
    MULTIACTIONBAR1BUTTON4 = "CTRL-4", MULTIACTIONBAR1BUTTON5 = "CTRL-Z", MULTIACTIONBAR1BUTTON6 = "CTRL-X",
    MULTIACTIONBAR1BUTTON7 = "CTRL-Q", MULTIACTIONBAR1BUTTON8 = "CTRL-W", MULTIACTIONBAR1BUTTON9 = "CTRL-R",
    MULTIACTIONBAR1BUTTON10 = "CTRL-T", MULTIACTIONBAR1BUTTON11 = "CTRL-A", MULTIACTIONBAR1BUTTON12 = "CTRL-G",
    MULTIACTIONBAR2BUTTON1 = "CTRL-E", MULTIACTIONBAR2BUTTON2 = "CTRL-D", MULTIACTIONBAR2BUTTON3 = "CTRL-S",
    MULTIACTIONBAR2BUTTON4 = "CTRL-F", MULTIACTIONBAR2BUTTON5 = "SHIFT-E", MULTIACTIONBAR2BUTTON6 = "SHIFT-D",
    MULTIACTIONBAR2BUTTON7 = "SHIFT-S", MULTIACTIONBAR2BUTTON8 = "SHIFT-F", MULTIACTIONBAR2BUTTON9 = "ALT-E",
    MULTIACTIONBAR2BUTTON10 = "ALT-D", MULTIACTIONBAR2BUTTON11 = "ALT-S", MULTIACTIONBAR2BUTTON12 = "ALT-F",
    -- 选择目标
    PETATTACK = "CTRL-`"
}

local customTracking = {
    -- 旅店老板
    [136458] = true,
    -- 目标
    [524052] = true,
}

local bagFilters = {
    LE_BAG_FILTER_FLAG_TRADE_GOODS,
    LE_BAG_FILTER_FLAG_TRADE_GOODS,
    LE_BAG_FILTER_FLAG_CONSUMABLES,
    LE_BAG_FILTER_FLAG_EQUIPMENT,
}

customButton:SetScript("OnClick", function()
    if IsInCombat() then
        return
    end
    DisableButtons()

    for name, value in pairs(otherCVars) do
        SetCVar(name, value)
    end

    -- 界面设置 CVar
    for name, value in pairs(interfaceOptionCVars) do
        SetCVar(name, value == "" and GetCVarDefault(name) or value)
    end
    -- 阻止公会邀请
    SetAutoDeclineGuildInvites(true)
    -- 显示左下方、右下方和右方快捷列
    SetActionBarToggles(true, true, true)
    -- 设置团队档案
    -- 恢复预设值
    CompactUnitFrameProfiles_ResetToDefaults()
    local profile = GetActiveRaidProfile()
    -- 让各队伍连在一起
    SetRaidProfileOption(profile, "keepGroupsTogether", true)
    -- 显示职业颜色
    SetRaidProfileOption(profile, "useClassColors", true)
    -- 不显示边框
    SetRaidProfileOption(profile, "displayBorder", false)
    -- 不显示主坦克与主助攻
    SetRaidProfileOption(profile, "displayMainTankAndAssist", false)
    -- 设置团队框架高度和宽度
    SetRaidProfileOption(profile, "frameHeight", height, height)
    SetRaidProfileOption(profile, "frameWidth", width, width)

    -- 按键设定
    C_VoiceChat.SetPushToTalkBinding({ "", })
    KeyBindingFrame_LoadUI()
    -- 恢复预设值
    KeyBindingFrame_ResetBindingsToDefault()
    -- 界面设置的按键设定
    SetModifiedClick("AUTOLOOTTOGGLE", "NONE")
    SetModifiedClick("FOCUSCAST", "SHIFT")
    SetModifiedClick("SELFCAST", "NONE")
    -- 解绑键位设定
    for i, actions in ipairs(unbindKeys) do
        for _, action in ipairs(actions) do
            local key = select(i, GetBindingKey(action))
            if key then
                SetBinding(key)
            end
        end
    end
    -- 绑定键位设定
    for action, key in pairs(bindKeys) do
        KeyBindingFrame_AttemptKeybind(KeyBindingFrame, key, action, KeyBindingFrame.mode, 1, true)
    end
    SaveBindings(ACCOUNT_BINDINGS)
    KeyBindingFrame.outputText:SetText("")

    -- 设置对话视窗
    -- 恢复预设值
    FCF_ResetChatWindows()
    ChatConfig_ResetChatSettings()
    -- 显示所有频道对话消息
    local channelList = { GetChannelList() }
    for i = 2, #channelList, 3 do
        ChatFrame_AddChannel(ChatFrame1, channelList[i])
    end
    -- 显示经验值消息
    ChatFrame_AddMessageGroup(ChatFrame1, "COMBAT_XP_GAIN")
    -- 不显示频道切换消息
    ChatFrame_RemoveMessageGroup(ChatFrame1, "CHANNEL")

    -- 设置小地图追踪
    for i = 1, GetNumTrackingTypes() do
        local _, texture = GetTrackingInfo(i)
        SetTracking(i, customTracking[texture] or TRACKING[texture])
    end
    UIDropDownMenu_Refresh(MiniMapTrackingDropDown)

    -- 设置背包设定
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

StaticPopupDialogs["APPLY_SETTINGS"] = {
    text = CLIENT_RESTART_ALERT,
    subText = CLIENT_RELOAD_ALERT,
    button1 = RELOADUI,
    button2 = "",
    OnAccept = ReloadUI,
    showAlert = 1,
    timeout = 0,
    whileDead = 1,
    notClosableByLogout = 1,
    ---@param self Frame|StaticPopupTemplate
    OnShow = function(self)
        -- 创建能够退出游戏的按钮覆盖 button2
        ---@type Button
        local button = CreateFrame("Button", self:GetName() .. "Button0", self,
                "StaticPopupButtonTemplate, SecureActionButtonTemplate")
        button:SetAllPoints(self.button2)
        button:SetFrameLevel(self.button2:GetFrameLevel() + 1)
        button:SetText(EXIT_GAME)
        button:SetAttribute("type1", "macro")
        button:SetAttribute("macrotext", "/quit")
    end
}
