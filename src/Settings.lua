--- 删除物品时自动填写 “DELETE”
hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"], "OnShow", function(self)
    ---@type EditBox
    local editBox = self.editBox
    editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
end)

---@type Button
local defaultButton = CreateFrame("BUTTON", "WLK-DefaultSettings", UIParent, "UIPanelButtonTemplate")
defaultButton:SetSize(60, 22)
defaultButton:SetPoint("RIGHT", 0, 225)
defaultButton:SetText("BLZ")
defaultButton:SetAlpha(0)

---@type Button
local wlkButton = CreateFrame("BUTTON", "WLK-WlkSettings", UIParent, "UIPanelButtonTemplate")
wlkButton:SetSize(60, 22)
wlkButton:SetPoint("RIGHT", 0, 255)
wlkButton:SetText("WLK")
wlkButton:SetAlpha(0)

--- 显示设置按钮，战斗中使用 Show() 会造成插件污染
local function ShowButtons()
    defaultButton:SetAlpha(1)
    wlkButton:SetAlpha(1)
end

--- 隐藏设置按钮，战斗中使用 Hide() 会造成插件污染
local function HideButtons()
    defaultButton:SetAlpha(0)
    wlkButton:SetAlpha(0)
end

defaultButton:SetScript("OnEnter", ShowButtons)
defaultButton:SetScript("OnLeave", HideButtons)

wlkButton:SetScript("OnEnter", ShowButtons)
wlkButton:SetScript("OnLeave", HideButtons)

--- 检查是否在战斗中
local function InCombat()
    -- 战斗中时显示错误提示
    if InCombatLockdown() then
        ---@type MessageFrame
        local UIErrorsFrame = UIErrorsFrame
        UIErrorsFrame:AddMessage(ERR_NOT_IN_COMBAT, 1, 0.1, 0.1, 1)
        return true
    end
    return false
end

--- 使按钮无效
local function DisableButtons()
    defaultButton:SetEnabled(false)
    wlkButton:SetEnabled(false)
end

--- 隐藏的控制台变量
local hiddenCVars = {
    -- 显示脚本错误
    scriptErrors = 1,
    -- 记录插件污染日志
    taintLog = 1,
    -- 启用魔兽世界鼠标，防止鼠标有时候会回到屏幕中间的问题
    rawMouseEnable = 1,
    -- 关闭死亡效果
    ffxDeath = 0,
    -- 姓名板显示的最大距离
    nameplateMaxDistance = 40,
    -- 启用物品对比
    alwaysCompareItems = 1,
    -- 最远视距
    cameraDistanceMaxZoomFactor = 2.6,
    -- 弧型浮动战斗信息
    floatingCombatTextFloatMode = 3,
    -- 隐藏浮动战斗信息的治疗量
    floatingCombatTextCombatHealing = 0,
    -- 进入/离开战斗
    floatingCombatTextCombatState = 1,
}

--- 声音设置的控制台变量
local voiceCVars = {
    -- 音效音量
    Sound_SFXVolume = 0.7,
    -- 音乐音量
    Sound_MusicVolume = 0.5,
    -- 环境音量
    Sound_AmbienceVolume = 1,
    -- 对话音量
    Sound_DialogVolume = 1,
}

--- 设置控制台变量的值
---@param cvars table 存放控制台变量的表
---@param toDefault boolean 是否设置为默认值
local function SetCVars(cvars, toDefault)
    for name, value in pairs(cvars) do
        SetCVar(name, toDefault and GetCVarDefault(name) or value)
    end
end

--- 默认的小地图追踪类型
local defaultMinimapTracking = {
    -- 飞行管理员
    ["136456"] = true,
    -- 焦点目标
    ["524051"] = true,
    -- 任务目标区域追踪
    ["535616"] = true,
    -- 追踪挖掘场
    ["535615"] = true,
}

--- 应用默认设置
local function ApplyDefaultSettings()
    -- 隐藏的控制台变量恢复为默认值
    SetCVars(hiddenCVars, true)
    -- 声音设置恢复为默认值
    SetCVars(voiceCVars, true)
    -- 界面设置恢复为默认值
    InterfaceOptionsFrame_SetAllToDefaults()

    -- 按键设置恢复为默认值
    KeyBindingFrame_ResetBindingsToDefault()
    -- 语音按键恢复为默认值
    C_VoiceChat.SetPushToTalkBinding({ "`" })
    -- 保存按键设置
    SaveBindings(ACCOUNT_BINDINGS)

    -- 重置聊天窗口
    FCF_ResetChatWindows()
    ---@type Frame
    local chatConfigFrame = ChatConfigFrame
    -- 聊天设置恢复为默认值
    if chatConfigFrame:IsShown() then
        ChatConfig_ResetChatSettings()
    end

    -- 设置小地图追踪类型
    for i = 1, GetNumTrackingTypes() do
        local _, texture = GetTrackingInfo(i)
        SetTracking(i, defaultMinimapTracking[tostring(texture)])
    end
end

--- 应用默认设置对话框
StaticPopupDialogs["APPLY_DEFAULT_SETTINGS"] = {
    text = "你必須重新載入才能使默认設置生效",
    button1 = RELOADUI,
    OnAccept = ReloadUI,
    OnCancel = ReloadUI,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1,
}

defaultButton:SetScript("OnClick", function()
    if InCombat() then
        return
    end
    DisableButtons()
    ApplyDefaultSettings()

    -- 关闭背包的 “忽视这个背包”
    if GetBackpackAutosortDisabled() then
        SetBackpackAutosortDisabled(false)
    end
    for i = 1, NUM_BAG_SLOTS do
        for j = LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, LE_BAG_FILTER_FLAG_TRADE_GOODS do
            -- 关闭袋子的 “忽视这个背包” 和取消分类
            if GetBagSlotFlag(i, j) then
                SetBagSlotFlag(i, j, false)
            end
        end
    end

    StaticPopup_Show("APPLY_DEFAULT_SETTINGS")
end)

--- 通过是否学会技能 “复活战宠” 及宠物日志是否解锁来判断玩家是不是宠物训练师
local isPetTrainer = IsSpellKnown(125439) and C_PetJournal.IsJournalUnlocked()

--- 袋子从右到左的分类依次是商品、商品、消耗品、装备
local wlkBagFilter = {
    LE_BAG_FILTER_FLAG_TRADE_GOODS,
    LE_BAG_FILTER_FLAG_TRADE_GOODS,
    LE_BAG_FILTER_FLAG_CONSUMABLES,
    LE_BAG_FILTER_FLAG_EQUIPMENT,
}

--- 界面设置的控制台变量
local interfaceCVars = {
    -- 启用自动拾取
    autoLootDefault = 1,
    -- 启用浮动战斗信息
    enableFloatingCombatText = 1,
    -- 启用状态文字，并显示数值和百分比
    statusText = 1,
    statusTextDisplay = "BOTH",
    -- 关闭教学说明
    showTutorials = 0,
    -- 取消锁定动作条
    lockActionBars = 0,
    -- 总是显示动作条
    alwaysShowActionBars = 1,
    -- NPC 名称显示为敌对、任务与可互动的 NPC
    UnitNameFriendlySpecialNPCName = 1,
    UnitNameHostleNPC = 1,
    UnitNameInteractiveNPC = 1,
    -- 不显示玩家姓名板
    nameplateShowSelf = 0,
    -- 启用大型姓名板
    NamePlateHorizontalScale = 1.4,
    NamePlateVerticalScale = 2.7,
    -- 堆叠姓名板
    nameplateMotion = 1,
    -- 永不调整镜头
    cameraWaterCollision = 1,
    -- 启用水体碰撞
    cameraSmoothStyle = 0,
    -- 显示动画字幕
    movieSubtitle = 1,
    -- 使用团队风格的队伍框架
    useCompactPartyFrames = 1,
}

--- 显示左下方动作条、右下方动作条和右方动作条
local function ShowMultiActionBar()
    InterfaceOptionsActionBarsPanelBottomLeft.value = "1"
    InterfaceOptionsActionBarsPanelBottomRight.value = "1"
    InterfaceOptionsActionBarsPanelRight.value = "1"
    SHOW_MULTI_ACTIONBAR_1 = true
    SHOW_MULTI_ACTIONBAR_2 = true
    SHOW_MULTI_ACTIONBAR_3 = true
    InterfaceOptions_UpdateMultiActionBars()
end

--- 获取团队框架单位的大小
local function GetCompactUnitFrameProfilesSize()
    local resizeVerticalOutsets = 7
    -- 队伍标题高度
    local titleHeight = 14
    -- 单位之间的间隔
    local spacing = 2
    -- 队伍的行数
    local rows = 2
    -- 队伍的列数
    local columns = ceil(MAX_RAID_GROUPS / rows)

    -- containerResizeFrame 顶部应该最多在 TargetFrameSpellBar 的底部，即 135px；底部最多在 FriendsFrameMicroButton 的顶部，
    -- 即 330px
    local containerResizeFrameHeight = GetScreenHeight() - 135 - 330
    -- container 的最大高度
    local containerMaxHeight = containerResizeFrameHeight - resizeVerticalOutsets * 2
    local height
    local arg = 1
    while arg >= 1 do
        height = floor(containerMaxHeight / (MEMBERS_PER_RAID_GROUP * rows + ceil(arg)))
        arg = (titleHeight * rows + spacing * (MEMBERS_PER_RAID_GROUP * rows + rows - 1)) / (height * ceil(arg))
    end

    -- 最右边界
    local maxRight = 570
    -- CompactRaidFrameManager 的宽度是 200px，左边相对屏幕左边偏移 -182px，containerResizeFrame 左边相对
    -- CompactRaidFrameManager 右边偏移 0px，container 左边相对 containerResizeFrame 左边偏移 4px
    local left = 200 - 182 + 4
    local width = floor((maxRight - left - spacing * (columns - 1)) / columns)

    return height, width
end

--- 团队框架设置
local function SetRaidOptions(profile)
    -- 保持小队连在一起
    SetRaidProfileOption(profile, "keepGroupsTogether", true)
    -- 显示职业颜色
    SetRaidProfileOption(profile, "useClassColors", true)
    -- 不显示边框
    SetRaidProfileOption(profile, "displayBorder", false)
    -- 设置团队框架单位的大小
    local height, width = GetCompactUnitFrameProfilesSize()
    SetRaidProfileOption(profile, "frameHeight", height, height)
    SetRaidProfileOption(profile, "frameWidth", width, width)
end

--- 自定义界面设置
local function SetWlkInterfaceOptions()
    SetCVars(interfaceCVars)
    ShowMultiActionBar()
    SetRaidOptions(CompactUnitFrameProfiles.selectedProfile)
    -- 自动拾取键设置为 “无”
    SetModifiedClick("AUTOLOOTTOGGLE", "None")
    -- 焦点施法键设置为 “Shift”
    SetModifiedClick("FOCUSCAST", "Shift")
    -- 自我施法键设置为 “无”
    SetModifiedClick("SELFCAST", "None")
    -- 阻止公会邀请
    SetAutoDeclineGuildInvites(true)
end

--- 需要解绑的按键
local unbindKeys = {
    -- 移动按键
    MOVEANDSTEER = 1, MOVEFORWARD = 2, MOVEBACKWARD = 2, TURNLEFT = 2, TURNRIGHT = 2, JUMP = 2, TOGGLEAUTORUN = 2,
    -- 动作条
    BONUSACTIONBUTTON2 = 1, BONUSACTIONBUTTON3 = 1, BONUSACTIONBUTTON4 = 1, BONUSACTIONBUTTON5 = 1,
    BONUSACTIONBUTTON6 = 1, BONUSACTIONBUTTON7 = 1, BONUSACTIONBUTTON8 = 1, BONUSACTIONBUTTON9 = 1,
    BONUSACTIONBUTTON10 = 1, ACTIONPAGE1 = 1, ACTIONPAGE2 = 1, ACTIONPAGE3 = 1, ACTIONPAGE4 = 1, ACTIONPAGE5 = 1,
    ACTIONPAGE6 = 1, PREVIOUSACTIONPAGE = 1, NEXTACTIONPAGE = 1,
    -- 选择目标
    TARGETSELF = 1, TARGETPARTYMEMBER1 = 1, TARGETPARTYMEMBER2 = 1, TARGETPARTYMEMBER3 = 1, TARGETPARTYMEMBER4 = 1,
    TARGETPET = 1, TARGETPARTYPET1 = 1, TARGETPARTYPET2 = 1, TARGETPARTYPET3 = 1, TARGETPARTYPET4 = 1,
    -- 界面面板
    TOGGLEBACKPACK = 2,
}

--- 要绑定的按键
local bindKeys = {
    -- 移动按键
    MOVEFORWARD = "E", MOVEBACKWARD = "D", STRAFELEFT = "S", STRAFERIGHT = "F", SITORSTAND = ".", TOGGLESHEATH = ",",
    TOGGLEAUTORUN = ";", FOLLOWTARGET = "'",
    -- 动作条
    ACTIONBUTTON1 = "Q", ACTIONBUTTON2 = "W", ACTIONBUTTON3 = "R", ACTIONBUTTON4 = "T", ACTIONBUTTON5 = "A",
    ACTIONBUTTON6 = "G", ACTIONBUTTON7 = "1", ACTIONBUTTON8 = "2", ACTIONBUTTON9 = "3", ACTIONBUTTON10 = "4",
    ACTIONBUTTON11 = "Z", ACTIONBUTTON12 = "X", EXTRAACTIONBUTTON1 = "`", BONUSACTIONBUTTON1 = "CTRL-`",
    -- 复合式动作条
    MULTIACTIONBAR1BUTTON1 = "CTRL-Q", MULTIACTIONBAR1BUTTON2 = "CTRL-W", MULTIACTIONBAR1BUTTON3 = "CTRL-R",
    MULTIACTIONBAR1BUTTON4 = "CTRL-T", MULTIACTIONBAR1BUTTON5 = "CTRL-A", MULTIACTIONBAR1BUTTON6 = "CTRL-G",
    MULTIACTIONBAR1BUTTON7 = "CTRL-1", MULTIACTIONBAR1BUTTON8 = "CTRL-2", MULTIACTIONBAR1BUTTON9 = "CTRL-3",
    MULTIACTIONBAR1BUTTON10 = "CTRL-4", MULTIACTIONBAR1BUTTON11 = "CTRL-Z", MULTIACTIONBAR1BUTTON12 = "CTRL-X",
    MULTIACTIONBAR2BUTTON1 = "CTRL-E", MULTIACTIONBAR2BUTTON2 = "CTRL-D", MULTIACTIONBAR2BUTTON3 = "CTRL-S",
    MULTIACTIONBAR2BUTTON4 = "CTRL-F", MULTIACTIONBAR2BUTTON5 = "SHIFT-E", MULTIACTIONBAR2BUTTON6 = "SHIFT-D",
    MULTIACTIONBAR2BUTTON7 = "SHIFT-S", MULTIACTIONBAR2BUTTON8 = "SHIFT-F", MULTIACTIONBAR2BUTTON9 = "ALT-E",
    MULTIACTIONBAR2BUTTON10 = "ALT-D", MULTIACTIONBAR2BUTTON11 = "ALT-S", MULTIACTIONBAR2BUTTON12 = "ALT-F",
}

--- 绑定按键设置
local function SetWlkBindings()
    -- 解绑键位设定
    for action, keyButtonID in pairs(unbindKeys) do
        local key1, key2 = GetBindingKey(action, KeyBindingFrame.mode)
        if keyButtonID == 1 and key1 then
            SetBinding(key1, nil, KeyBindingFrame.mode);
        end
        if keyButtonID == 2 and key2 then
            SetBinding(key2, nil, KeyBindingFrame.mode);
        end
    end
    -- 解绑语音按键
    C_VoiceChat.SetPushToTalkBinding({ "" })
    -- 绑定按键
    for action, key in pairs(bindKeys) do
        KeyBindingFrame_AttemptKeybind(KeyBindingFrame, key, action, KeyBindingFrame.mode, 1, true)
    end
    -- 保存按键设置
    SaveBindings(ACCOUNT_BINDINGS)
    -- 隐藏按键设置框架输出消息
    ---@type FontString
    local output = KeyBindingFrame.outputText
    output:SetText("")
end

--- 应用自定义设置
local function ApplyWlkSettings()
    -- 隐藏的控制台变量设置
    SetCVars(hiddenCVars)
    -- 声音设置
    SetCVars(voiceCVars)
    -- 界面设置
    SetWlkInterfaceOptions()
    -- 按键设置
    SetWlkBindings()
    -- 加入 “寻求组队” 频道
    ChatFrame_AddChannel(ChatFrame1, LOOK_FOR_GROUP)
    -- 设置小地图追踪类型
    for i = 1, GetNumTrackingTypes() do
        local _, texture = GetTrackingInfo(i)
        -- 136458：旅店老板，613074：追踪宠物，136466：兽栏管理员
        if texture == 136458 or (isPetTrainer and (texture == 613074 or texture == 136466)) then
            SetTracking(i, true)
        end
    end
end

--- 因为调用 InterfaceOptionsFrame_SetAllToDefaults() 方法后设置 “nameplateShowAll” 会出现脚本错误，所以移至此处设置
local function ReloadForSettings()
    -- 总是显示姓名板
    SetCVar("nameplateShowAll", 1)
    ReloadUI()
end

--- 应用自定义设置对话框
StaticPopupDialogs["APPLY_WLK_SETTINGS"] = {
    text = "你必須重新載入才能使自定义設置生效",
    button1 = RELOADUI,
    OnAccept = ReloadForSettings,
    OnCancel = ReloadForSettings,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1,
}

wlkButton:SetScript("OnClick", function()
    if InCombat() then
        return
    end
    DisableButtons()
    -- 应用自定义设置前先应用一次默认设置，因为自定义设置是基于默认设置修改的
    ApplyDefaultSettings()
    ApplyWlkSettings()

    -- 关闭背包的 “忽视这个背包”
    if GetBackpackAutosortDisabled() then
        SetBackpackAutosortDisabled(false)
    end
    for i = 1, NUM_BAG_SLOTS do
        -- 关闭袋子的 “忽视这个背包”
        if GetBagSlotFlag(i, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP) then
            SetBagSlotFlag(i, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP, false)
        end
        -- 设置袋子分类
        if not GetBagSlotFlag(i, wlkBagFilter[i]) then
            SetBagSlotFlag(i, wlkBagFilter[i], true)
        end
    end

    StaticPopup_Show("APPLY_WLK_SETTINGS")
end)

if not isPetTrainer then
    -- 玩家不是宠物训练师时，注册 “SPELLS_CHANGED” 事件
    wlkButton:RegisterEvent("SPELLS_CHANGED")

    wlkButton:SetScript("OnEvent", function(_, event)
        -- 成为宠物训练师时，小地图追踪勾选 “宠物追踪” 和 “兽栏管理员”
        if isPetTrainer then
            for i = 1, GetNumTrackingTypes() do
                local _, texture = GetTrackingInfo(i)
                if texture == 613074 or texture == 136466 then
                    SetTracking(i, true)
                end
            end
            -- 取消注册 “SPELLS_CHANGED” 事件
            wlkButton:UnregisterEvent(event)
        end
    end)
end
