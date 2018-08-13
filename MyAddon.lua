-- CVar
-- 全部重置：/console cvar_default
-- 设置CVar值：/run SetCVar("scriptErrors", 1)或/console scriptErrors 1
-- 查看框体名称：/fstack
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 查看当前CVar值：/dump GetCVar("scriptErrors")
-- 查看当前CVar默认值：/dump GetCVarDefault("scriptErrors")
-- 单项恢复默认：/run SetCVar("scriptErrors",GetCVarDefault("scriptErrors"))
SetCVar("scriptErrors", 1) -- 显示LUA错误
SetCVar("alwaysCompareItems", 1) -- 总是对比装备
SetCVar("cameraDistanceMaxZoomFactor", 2.6) -- 最大视距
SetCVar("floatingCombatTextFloatMode", 3) -- 浮动战斗信息弧型显示
SetCVar("floatingCombatTextCombatHealing", 0) -- 关闭浮动战斗对目标治疗信息
SetCVar("floatingCombatTextReactives", 0) -- 关闭浮动战斗信息法术警示
SetCVar("floatingCombatTextCombatState", 1) -- 进入/离开战斗提示
SetCVar("taintLog", 1) -- 开启插件污染日志
SetCVar("rawMouseEnable", 1) -- 解决鼠标右键乱晃问题
SetCVar("ffxDeath", 0) -- 关闭死亡黑白效果
SetCVar("lockActionBars", 0) -- 快捷列不锁定，设置中有但有时候会重置成锁定
SetCVar("enableFloatingCombatText", 1) -- 启用自己的战斗文字卷动，设置中有但有时候会重置成不启用
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 缩写重置命令
SlashCmdList['RELOAD'] = function()
    ReloadUI()
end
SLASH_RELOAD1 = '/rl'
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 不显示由谁制造
ITEM_CREATED_BY = ""
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 自动填写delete
hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"], "OnShow", function(s)
    s.editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- shift设置焦点
local modifier = "shift" -- shift, alt or ctrl 
local mouseButton = "1" -- 1 = left, 2 = right, 3 = middle, 4 and 5 = thumb buttons if there are any 

local function SetFocusHotkey(frame)
    frame:SetAttribute(modifier .. "-type" .. mouseButton, "focus")
end

local function CreateFrame_Hook(type, name, parent, template)
    if template == "SecureUnitButtonTemplate" then
        SetFocusHotkey(_G[name])
    end
end

hooksecurefunc("CreateFrame", CreateFrame_Hook)

-- Keybinding override so that models can be shift/alt/ctrl+clicked 
local focusFrame = CreateFrame("CheckButton", "FocuserButton", UIParent, "SecureActionButtonTemplate")
focusFrame:SetAttribute("type1", "macro")
focusFrame:SetAttribute("macrotext", "/focus mouseover")
SetOverrideBindingClick(FocuserButton, true, modifier .. "-BUTTON" .. mouseButton, "FocuserButton")

-- Set the keybindings on the default unit frames since we won't get any CreateFrame notification about them 
local duf = {
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

for i, frame in pairs(duf) do
    SetFocusHotkey(frame)
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 自动出售垃圾和修理装备
local function OnEvent(self, event)
    -- Auto Sell Grey Items
    totalPrice = 0
    for myBags = 0, 4 do
        for bagSlots = 1, GetContainerNumSlots(myBags) do
            CurrentItemLink = GetContainerItemLink(myBags, bagSlots)
            if CurrentItemLink then
                _, _, itemRarity, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(CurrentItemLink)
                _, itemCount = GetContainerItemInfo(myBags, bagSlots)
                if itemRarity == 0 and itemSellPrice ~= 0 then
                    totalPrice = totalPrice + (itemSellPrice * itemCount)
                    UseContainerItem(myBags, bagSlots)
                end
            end
        end
    end
    if totalPrice ~= 0 then
        DEFAULT_CHAT_FRAME:AddMessage("出售物品获得: +" .. GetCoinTextureString(totalPrice), 255, 255, 255)
    end
    -- Auto Repair
    if (CanMerchantRepair()) then
        repairAllCost, canRepair = GetRepairAllCost()
        -- If merchant can repair and there is something to repair
        if (canRepair and repairAllCost > 0) then
            -- Use Guild Bank
            guildRepairedItems = false
            if (IsInGuild() and CanGuildBankRepair()) then
                -- Checks if guild has enough money
                local amount = GetGuildBankWithdrawMoney()
                local guildBankMoney = GetGuildBankMoney()
                amount = amount == -1 and guildBankMoney or min(amount, guildBankMoney)
                if (amount >= repairAllCost) then
                    RepairAllItems(true)
                    guildRepairedItems = true
                    DEFAULT_CHAT_FRAME:AddMessage("装备已使用公修修理", 255, 255, 255)
                end
            end

            -- Use own funds
            if (repairAllCost <= GetMoney() and not guildRepairedItems) then
                RepairAllItems(false)
                DEFAULT_CHAT_FRAME:AddMessage("修理装备花费: -" .. GetCoinTextureString(repairAllCost), 255, 255, 255)
            end
        end
    end
end

local sellAndRepair = CreateFrame("Frame")
sellAndRepair:SetScript("OnEvent", OnEvent)
sellAndRepair:RegisterEvent("MERCHANT_SHOW")
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 超出距离技能变红
hooksecurefunc("ActionButton_OnUpdate", function(self, elapsed)
    if (self.rangeTimer == TOOLTIP_UPDATE_TIME) then
        local valid = IsActionInRange(self.action)
        if (valid == false) then
            self.icon:SetVertexColor(0.8, 0.1, 0.1)
        else
            ActionButton_UpdateUsable(self)
        end
    end
end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 右键自我施法
local bars = {
    "MainMenuBarArtFrame",
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarRight",
    "MultiBarLeft",
    "PossessBarFrame",
}

local rightClickFrame = CreateFrame("frame", "RightClickSelfCast", UIParent)
rightClickFrame:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

function rightClickFrame:PLAYER_REGEN_ENABLED()
    self:PLAYER_LOGIN()
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self.PLAYER_REGEN_ENABLED = nil
end

function rightClickFrame:PLAYER_LOGIN()

    -- if we load/reload in combat don't try to set secure attributes or we get action_blocked errors
    if InCombatLockdown() or UnitAffectingCombat("player") then
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    -- Blizzard bars
    for i, v in ipairs(bars) do
        local bar = _G[v]
        if bar ~= nil then
            bar:SetAttribute("unit2", "player")
        end
    end

    self:UnregisterEvent("PLAYER_LOGIN")
    self.PLAYER_LOGIN = nil

end

if IsLoggedIn() then
    rightClickFrame:PLAYER_LOGIN()
else
    rightClickFrame:RegisterEvent("PLAYER_LOGIN")
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 设置团队框架的最大值和最小值
local n = "CompactUnitFrameProfilesGeneralOptionsFrame"
local h, w = _G[n .. "HeightSlider"], _G[n .. "WidthSlider"]

h:SetMinMaxValues(22, 33)
w:SetMinMaxValues(70, 114)

-- 设置团队框架默认位置
hooksecurefunc("CompactRaidFrameManager_UpdateContainerBounds", function()
    local manager = CompactRaidFrameManager

    manager.containerResizeFrame:SetMaxResize(manager.containerResizeFrame:GetWidth(), 390)

    if (manager.dynamicContainerPosition) then
        --Should be below the TargetFrameSpellBar at its lowest height..
        local top = GetScreenHeight()
        --Should be just above the FriendsFrameMicroButton.
        local bottom = 360

        local managerTop = manager:GetTop()

        manager.containerResizeFrame:ClearAllPoints()
        manager.containerResizeFrame:SetPoint("TOPLEFT", manager, "TOPRIGHT", 0, top - managerTop)
        manager.containerResizeFrame:SetHeight(min(390, top - bottom))

        CompactRaidFrameManager_ResizeFrame_UpdateContainerSize(manager)
    end
end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 技能栏隐藏宏名字
local actionBar = { "MultiBarBottomLeft", "MultiBarBottomRight", "Action", "MultiBarLeft", "MultiBarRight" }

for b = 1, #actionBar do
    for i = 1, 12 do
        _G[actionBar[b] .. "Button" .. i .. "Name"]:SetAlpha(0)
    end
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 隐藏拾取框
LootFrame:SetAlpha(0)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 隐藏技能栏狮鹫
MainMenuBarArtFrame.LeftEndCap:Hide()
MainMenuBarArtFrame.RightEndCap:Hide()

-- 隐藏载具动作条两边
OverrideActionBarEndCapL:Hide()
OverrideActionBarEndCapR:Hide()
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 隐藏浮动战斗信息自己的治疗
if LoadAddOn("Blizzard_CombatText") then
    COMBAT_TEXT_TYPE_INFO["HEAL"] = { var = nil, show = nil }
    COMBAT_TEXT_TYPE_INFO["HEAL_ABSORB"] = { var = nil, show = nil }
    COMBAT_TEXT_TYPE_INFO["HEAL_CRIT"] = { var = nil, show = nil }
    COMBAT_TEXT_TYPE_INFO["HEAL_CRIT_ABSORB"] = { var = nil, show = nil }
    COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL"] = { var = nil, show = nil }
    COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL_ABSORB"] = { var = nil, show = nil }
    COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL_CRIT"] = { var = nil, show = nil }
    COMBAT_TEXT_TYPE_INFO["ABSORB_ADDED"] = { var = nil, show = nil }
    hooksecurefunc("CombatText_UpdateDisplayedMessages", function()
    end)
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 隐藏区域技能键边框
ZoneAbilityFrame.SpellButton.Style:Hide()

-- 隐藏额外快捷键边框
ExtraActionButton1.style:Hide()
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 移动额外快捷键
ExtraActionBarFrame:ClearAllPoints()
ExtraActionBarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -210)
ExtraActionBarFrame.SetPoint = function()
end

-- 移动区域技能键
ZoneAbilityFrame:ClearAllPoints()
ZoneAbilityFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -270)
ZoneAbilityFrame.SetPoint = function()
end

-- 移动特殊能量条
local movePowerBarAltFrame = CreateFrame("frame")
movePowerBarAltFrame:RegisterEvent("PLAYER_LOGIN")
movePowerBarAltFrame:SetScript("OnEvent", function()
    PlayerPowerBarAlt:SetMovable(true)
    PlayerPowerBarAlt:SetUserPlaced(true)
    PlayerPowerBarAlt:ClearAllPoints()
    PlayerPowerBarAlt:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    PlayerPowerBarAlt.SetPoint = function()
    end
end)
hooksecurefunc("UnitPowerBarAltStatus_ToggleFrame", function(self)
    if self.enabled then
        self:Show();
        UnitPowerBarAltStatus_UpdateText(self);
    else
        self:Hide();
    end
end)

-- 解决上载具后宠物栏有时候不隐藏的问题
hooksecurefunc("MainMenuBarVehicleLeaveButton_Update", function()
    if (CanExitVehicle() and ActionBarController_GetCurrentActionBarState() == LE_ACTIONBAR_STATE_MAIN) then
        PetActionBarFrame:Hide()
    end
end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 移动背包
hooksecurefunc("UpdateContainerFrameAnchors", function()
    -- 修改这两个值移动
    local moveOffsetX = 0 -- 正数向左移动，负数向右移动
    local moveOffsetY = 60 -- 正数向上移动， 负数向下移动

    local frame, xOffset, yOffset, screenHeight, freeScreenHeight, leftMostPoint, column
    local screenWidth = GetScreenWidth()
    local containerScale = 1
    local leftLimit = 0
    if (BankFrame:IsShown()) then
        leftLimit = BankFrame:GetRight() - 25
    end

    while (containerScale > CONTAINER_SCALE) do
        screenHeight = GetScreenHeight() / containerScale
        -- Adjust the start anchor for bags depending on the multibars
        xOffset = (CONTAINER_OFFSET_X + moveOffsetX) / containerScale
        yOffset = (CONTAINER_OFFSET_Y + moveOffsetY) / containerScale
        -- freeScreenHeight determines when to start a new column of bags
        freeScreenHeight = screenHeight - yOffset
        leftMostPoint = screenWidth - xOffset
        column = 1
        local frameHeight
        for index, frameName in ipairs(ContainerFrame1.bags) do
            frameHeight = _G[frameName]:GetHeight()
            if (freeScreenHeight < frameHeight) then
                -- Start a new column
                column = column + 1
                leftMostPoint = screenWidth - (column * CONTAINER_WIDTH * containerScale) - xOffset
                freeScreenHeight = screenHeight - yOffset
            end
            freeScreenHeight = freeScreenHeight - frameHeight - VISIBLE_CONTAINER_SPACING
        end
        if (leftMostPoint < leftLimit) then
            containerScale = containerScale - 0.01
        else
            break
        end
    end

    if (containerScale < CONTAINER_SCALE) then
        containerScale = CONTAINER_SCALE
    end

    screenHeight = GetScreenHeight() / containerScale
    -- Adjust the start anchor for bags depending on the multibars
    xOffset = (CONTAINER_OFFSET_X + moveOffsetX) / containerScale
    yOffset = (CONTAINER_OFFSET_Y + moveOffsetY) / containerScale
    -- freeScreenHeight determines when to start a new column of bags
    freeScreenHeight = screenHeight - yOffset
    column = 0
    for index, frameName in ipairs(ContainerFrame1.bags) do
        frame = _G[frameName]
        frame:SetScale(containerScale)
        if (index == 1) then
            -- First bag
            frame:SetPoint("BOTTOMRIGHT", frame:GetParent(), "BOTTOMRIGHT", -xOffset, yOffset)
        elseif (freeScreenHeight < frame:GetHeight()) then
            -- Start a new column
            column = column + 1
            freeScreenHeight = screenHeight - yOffset
            frame:SetPoint("BOTTOMRIGHT", frame:GetParent(), "BOTTOMRIGHT", -(column * CONTAINER_WIDTH) - xOffset, yOffset)
        else
            -- Anchor to the previous bag
            frame:SetPoint("BOTTOMRIGHT", ContainerFrame1.bags[index - 1], "TOPRIGHT", 0, CONTAINER_SPACING)
        end
        freeScreenHeight = freeScreenHeight - frame:GetHeight() - VISIBLE_CONTAINER_SPACING
    end
end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 网格
SLASH_EA1 = "/al"
local alignFrame
SlashCmdList["EA"] = function()
    if alignFrame then
        alignFrame:Hide()
        alignFrame = nil
    else
        alignFrame = CreateFrame('Frame', nil, UIParent)
        alignFrame:SetAllPoints(UIParent)
        local width = GetScreenWidth() / 64
        local height = GetScreenHeight() / 36
        for i = 0, 64 do
            local t = alignFrame:CreateTexture(nil, 'BACKGROUND')
            if i == 32 then
                t:SetColorTexture(1, 0, 0, 0.5)
            else
                t:SetColorTexture(0, 0, 0, 0.5)
            end
            t:SetPoint('TOPLEFT', alignFrame, 'TOPLEFT', i * width - 1, 0)
            t:SetPoint('BOTTOMRIGHT', alignFrame, 'BOTTOMLEFT', i * width + 1, 0)
        end
        for i = 0, 36 do
            local t = alignFrame:CreateTexture(nil, 'BACKGROUND')
            if i == 18 then
                t:SetColorTexture(1, 0, 0, 0.5)
            else
                t:SetColorTexture(0, 0, 0, 0.5)
            end
            t:SetPoint('TOPLEFT', alignFrame, 'TOPLEFT', 0, -i * height + 1)
            t:SetPoint('BOTTOMRIGHT', alignFrame, 'TOPRIGHT', 0, -i * height - 1)
        end
    end
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 方形小地图
MinimapBorderTop:Hide()
MinimapBorder:Hide()
MiniMapWorldMapButton:Hide()
Minimap:SetMaskTexture([=[Interface\ChatFrame\ChatFrameBackground]=])
Minimap:SetBackdrop({ bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=], insets = { top = -1, left = -1, bottom = -1, right = -1 } })    --边框粗细
local color = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
Minimap:SetBackdropColor(color.r, color.g, color.b, 1)
function GetMinimapShape()
    return "SQUARE"
end

-- 滚轮缩放
MinimapZoomIn:Hide()
MinimapZoomOut:Hide()
Minimap:EnableMouseWheel(true)

Minimap:SetScript("OnMouseWheel", function(self, y)
    if y > 0 then
        MinimapZoomIn:Click()
    else
        MinimapZoomOut:Click()
    end
end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 大地图显示坐标
WorldMapFrame.playerPos = WorldMapFrame.BorderFrame:CreateFontString(nil, 'ARTWORK')
WorldMapFrame.playerPos:SetFont(GameFontNormal:GetFont(), 12, 'THINOUTLINE')
WorldMapFrame.playerPos:SetJustifyH('RIGHT')
WorldMapFrame.playerPos:SetPoint('RIGHT', WorldMapFrameCloseButton, 'LEFT', -40, 0)
WorldMapFrame.playerPos:SetTextColor(1, 0.82, 0.1)
WorldMapFrame.mousePos = WorldMapFrame.BorderFrame:CreateFontString(nil, 'ARTWORK')
WorldMapFrame.mousePos:SetFont(GameFontNormal:GetFont(), 12, 'THINOUTLINE')
WorldMapFrame.mousePos:SetJustifyH('RIGHT')
WorldMapFrame.mousePos:SetPoint('RIGHT', WorldMapFrameCloseButton, 'LEFT', -160, 0)

WorldMapFrame:HookScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if (self.elapsed < 0.2) then
        return
    end
    self.elapsed = 0
    --玩家坐标
    local position = C_Map.GetPlayerMapPosition(MapUtil.GetDisplayableMapForPlayer(), "player")
    if (position) then
        self.playerPos:SetText(format("玩家: %.1f, %.1f", position.x * 100, position.y * 100))
    else
        self.playerPos:SetText("")
    end
    --鼠标坐标
    local mapInfo = C_Map.GetMapInfo(self:GetMapID())
    if (mapInfo and mapInfo.mapType == 3) then
        local x, y = self.ScrollContainer:GetNormalizedCursorPosition()
        if (x and y and x > 0 and x < 1 and y > 0 and y < 1) then
            self.mousePos:SetText(format("當前: %.1f, %.1f", x * 100, y * 100))
        else
            self.mousePos:SetText("")
        end
    else
        self.mousePos:SetText("")
    end
end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 聊天框
-- Table to keep track of frames you already saw:
local frames = {}

-- Function to handle customzing a chat frame:
local function ProcessFrame(frame)
    if frames[frame] then
        return
    end
    frame:SetClampRectInsets(-35, 58, 58, -117) -- 离左、右、上、下边界的距离，+往左和下、-往右和上
    frame:SetMaxResize(476, 181)
    frame:SetMinResize(476, 181)

    local name = frame:GetName()
    _G[name .. "EditBoxLeft"]:Hide()
    _G[name .. "EditBoxMid"]:Hide()
    _G[name .. "EditBoxRight"]:Hide()
    local editbox = _G[name .. "EditBox"]
    editbox:ClearAllPoints()
    editbox:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", -3, 31)
    editbox:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 5, 31)
    editbox:SetAltArrowKeyMode(false)

    frames[frame] = true
end

-- Get all of the permanent chat windows and customize them:
for i = 1, NUM_CHAT_WINDOWS do
    ProcessFrame(_G["ChatFrame" .. i])
end

-- Set up a dirty hook to catch temporary windows and customize them when they are created:
local old_OpenTemporaryWindow = FCF_OpenTemporaryWindow

FCF_OpenTemporaryWindow = function(...)
    local frame = old_OpenTemporaryWindow(...)
    ProcessFrame(frame)
    return frame
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 频道选择条
-- 位置瞄点
local ChatBarOffsetX = 0 -- 相对于默认位置的X坐标
local ChatBarOffsetY = 0 -- 相对于默认位置的Y坐标
local chatFrame = SELECTED_DOCK_FRAME -- 聊天框架
local inputBox = chatFrame.editBox

-- 主框架初始化
local chat = CreateFrame("Frame", "chat", UIParent)
chat:SetWidth(300) -- 主框体宽度
chat:SetHeight(23) -- 主框体高度
chat:SetPoint("BOTTOMRIGHT", chatFrame, "TOPRIGHT", ChatBarOffsetX + 25, ChatBarOffsetY + 2)

local function ChannelSay_OnClick()
    ChatFrame_OpenChat("/s " .. inputBox:GetText(), chatFrame)
end

local function ChannelYell_OnClick()
    ChatFrame_OpenChat("/y " .. inputBox:GetText(), chatFrame)
end

local function ChannelParty_OnClick()
    ChatFrame_OpenChat("/p " .. inputBox:GetText(), chatFrame)
end

local function ChannelGuild_OnClick()
    ChatFrame_OpenChat("/g " .. inputBox:GetText(), chatFrame)
end

local function ChannelRaid_OnClick()
    ChatFrame_OpenChat("/raid " .. inputBox:GetText(), chatFrame)
end

local function ChannelBG_OnClick()
    ChatFrame_OpenChat("/bg " .. inputBox:GetText(), chatFrame)
end

local function Channel01_OnClick()
    ChatFrame_OpenChat("/1 " .. inputBox:GetText(), chatFrame)
end

local function Channel04_OnClick()
    ChatFrame_OpenChat("/4 " .. inputBox:GetText(), chatFrame)
end

local function ChannelTeam_OnClick(self, button)
    if button == "RightButton" then
        local _, channelName, _ = GetChannelName("組隊頻道")
        if channelName == nil then
            JoinPermanentChannel("組隊頻道", nil, 1, 1)
            ChatFrame_RemoveMessageGroup(chatFrame, "CHANNEL")
            ChatFrame_AddChannel(chatFrame, "組隊頻道")
            print("|cff00d200已加入組隊頻道|r")
        else
            LeaveChannelByName("組隊頻道")
            print("|cffd20000已离开組隊頻道|r")
        end
    else
        local channel, _, _ = GetChannelName("組隊頻道")
        ChatFrame_OpenChat("/" .. channel .. " " .. inputBox:GetText(), chatFrame)
    end
end

local function Roll_OnClick()
    RandomRoll(1, 100)
end

local function Mem_OnClick()
    local totalMem = 0
    local addonInfo = {}
    local count = 0

    for i = 1, GetNumAddOns() do
        if not addonInfo[i] and IsAddOnLoaded(i) then
            local name, _ = GetAddOnInfo(i)
            addonInfo[i] = { name = name, memory = GetAddOnMemoryUsage(i) }
            totalMem = totalMem + addonInfo[i].memory
            count = count + 1
        end
    end

    -- 根据内存降序排序
    table.sort(addonInfo, function(element1, element2)
        if element1 == nil then
            return false
        end
        if element2 == nil then
            return true
        end

        local mem1 = element1.memory
        local mem2 = element2.memory
        if mem1 ~= mem2 then
            return mem1 > mem2
        end
    end)

    if totalMem < 1000 then
        totalMem = format("%d KB", totalMem)
    else
        totalMem = format("%.2f MB", totalMem / 1000)
    end
    print("----------------------------------------")
    print("Total (" .. count .. "): " .. totalMem)
    print("----------------------------------------")
    for index, info in pairs(addonInfo) do
        local memory = info.memory
        if memory < 1000 then
            memory = format("%d KB", memory)
        else
            memory = format("%.2f MB", memory / 1000)
        end
        print(info.name .. ": " .. memory)
    end
    print("----------------------------------------")
end

local function Clear_OnClick()
    SELECTED_CHAT_FRAME:Clear()
end

local ChannelButtons = {
    { name = "say", text = "說", color = { 1.00, 1.00, 1.00 }, callback = ChannelSay_OnClick },
    { name = "yell", text = "喊", color = { 1.00, 0.25, 0.25 }, callback = ChannelYell_OnClick },
    { name = "party", text = "隊", color = { 0.66, 0.66, 1.00 }, callback = ChannelParty_OnClick },
    { name = "guild", text = "會", color = { 0.25, 1.00, 0.25 }, callback = ChannelGuild_OnClick },
    { name = "raid", text = "團", color = { 1.00, 0.50, 0.00 }, callback = ChannelRaid_OnClick },
    { name = "LFT", text = "副", color = { 1.00, 0.50, 0.00 }, callback = ChannelBG_OnClick },
    { name = "chn01", text = "綜", color = { 0.82, 0.70, 0.55 }, callback = Channel01_OnClick },
    { name = "chn04", text = "尋", color = { 0.25, 0.66, 0.70 }, callback = Channel04_OnClick },
    { name = "team", text = "組", color = { 0.70, 1.00, 0.55 }, callback = ChannelTeam_OnClick },
    { name = "roll", text = "骰", color = { 1.00, 1.00, 0.00 }, callback = Roll_OnClick },
    { name = "mem", text = "内", color = { 0.66, 1.00, 1.00 }, callback = Mem_OnClick },
    { name = "clear", text = "清", color = { 1.00, 0.75, 0.80 }, callback = Clear_OnClick },
}

local function CreateChannelButton(data, index)
    local frame = CreateFrame("Button", "frameName", chat)
    frame:SetWidth(23) -- 按钮宽度
    frame:SetHeight(23) -- 按钮高度
    frame:SetPoint("LEFT", chat, "LEFT", -17 + (index - 1) * 27, 0) -- 锚点
    frame:RegisterForClicks("AnyUp")
    frame:SetScript("OnClick", data.callback)
    frameText = frame:CreateFontString(data.name .. "Text", "OVERLAY")
    frameText:SetFont("fonts\\ARHei.ttf", 16, "OUTLINE") -- 字体设置
    frameText:SetJustifyH("CENTER")
    frameText:SetWidth(25)
    frameText:SetHeight(25)
    frameText:SetText(data.text) -- 显示的文字
    frameText:SetPoint("CENTER", 0, 0)
    frameText:SetTextColor(data.color[1], data.color[2], data.color[3]) -- 文字按钮的颜色
end

for i = 1, #ChannelButtons do
    -- 对非战斗记录聊天框的信息进行处理
    local button = ChannelButtons[i]
    CreateChannelButton(button, i)
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 聊天频道缩写
local matchTBL = {
    ["綜合"] = "綜合",
    ["交易"] = "交易",
    ["尋求組隊"] = "尋組",
    ["組隊頻道"] = "組隊",
    ["本地防務"] = "防務",
}

local function AbbreviatedChannelName(name, abbreviation)
    for i = 1, NUM_CHAT_WINDOWS do
        if (i ~= 2) then
            local f = _G["ChatFrame" .. i]
            local am = f.AddMessage
            f.AddMessage = function(frame, text, ...)
                return am(frame, text:gsub('|h%[(%d+)%. ' .. name .. '.-%]|h', '|h%[%1%. ' .. abbreviation .. '%]|h'), ...)
            end
        end
    end
end

for k, v in pairs(matchTBL) do
    AbbreviatedChannelName(k, v)
end

local function ShortName(name)
    for k, v in pairs(matchTBL) do
        if name:find(k) then
            return v
        end
    end
end

hooksecurefunc("ChatEdit_UpdateHeader", function(editBox)
    local type = editBox:GetAttribute("chatType")
    if not type then
        return
    end
    local info = ChatTypeInfo[type]
    local header = _G[editBox:GetName() .. "Header"]
    local headerSuffix = _G[editBox:GetName() .. "HeaderSuffix"]
    if not header then
        return
    end
    header:SetWidth(0)
    if type == "CHANNEL" then
        local channel, channelName, instanceID = GetChannelName(editBox:GetAttribute("channelTarget"))
        if channelName then
            if instanceID > 0 then
                channelName = channelName .. " " .. instanceID
            end
            info = ChatTypeInfo["CHANNEL" .. channel]
            editBox:SetAttribute("channelTarget", channel)
            header:SetFormattedText(CHAT_CHANNEL_SEND, channel, ShortName(channelName))
        end
    end
    editBox:SetTextInsets(15 + header:GetWidth() + (headerSuffix:IsShown() and headerSuffix:GetWidth() or 0), 13, 0, 0)
end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 冷却计时
local Timer = {}
local timers = {}
local font = GameTooltipTextLeft1:GetFont()
local minFontsize = 10

local ButtonType = {
    { value = "AutoCastable", type = "Pet" },
    { value = "HotKey", type = "Action" },
    { value = "Stock", type = "Item" },
}

local iCCDB = {
    Action = { config = true, min = 2, size = 20 },
    Pet = { config = true, min = 3, size = 18 },
    Item = { config = true, min = 3, size = 20 },
    Aura = { config = true, max = 7200, scale = 0.5 },
}

local function Timer_OnUpdate(self, elapsed)
    if not self.cd:IsVisible() then
        self:Hide()
    else
        if self.nextUpdate <= 0 then
            Timer.Update(self)
        else
            self.nextUpdate = self.nextUpdate - elapsed
        end
    end
end

local function Timer_Hide(self)
    self.nextUpdate = 0
    self.cd:SetAlpha(1)
end

local function GetButtonType(btn)
    local name = btn:GetName()
    while not name do
        btn = btn:GetParent()
        name = btn:GetName()
    end

    if name == "LossOfControlFrame" or string.find(name, "ThreatPlatesFrame") then
        return nil
    end

    if name == "ZoneAbilityFrame" or name == "ExtraActionButton1" then
        return "Action"
    end

    for _, index in ipairs(ButtonType) do
        if _G[name .. index.value] then
            return index.type
        end
    end
    return "Aura"
end

local function GetFormattedTime(t)
    if t < 5 then
        return floor(t), 1.2, 1, 0.12, 0.12, 0.2
    elseif t < 60 then
        return floor(t), 1, 1, 0.82, 0, t - floor(t)
    elseif t < 600 then
        return ceil(t / 60) .. "m", 0.85, 0.8, 0.6, 0, t - floor(t)
    elseif t < 3600 then
        return ceil(t / 60) .. "m", 0.85, 0.8, 0.6, 0, t % 60
    elseif t < 86400 then
        return ceil(t / 3600) .. "h", 0.7, 0.6, 0.4, 0, t % 3600
    else
        return ceil(t) .. "d", 0.6, 0.4, 0.4, 0.4, t % 86400
    end
end

function Timer.Start(cd, start, duration, enable, forceShowDrawEdge, modRate)
    cd.button = cd.button or cd:GetParent()
    if cd.button and cd.button:GetSize() >= 15 then
        cd.type = cd.type or GetButtonType(cd.button)
        if cd.type then
            if start > 0 and duration > (iCCDB[cd.type].min or 0) and iCCDB[cd.type].config then
                local timer = timers[cd] or Timer.Create(cd)
                if timer then
                    timer.start = start
                    timer.duration = duration
                    timer.nextUpdate = 0
                    timer:Show()
                end
            elseif timers[cd] then
                timers[cd]:Hide()
            end
        end
    end
end

function Timer.Create(cd)
    local timer = CreateFrame("Frame", nil, cd.button)
    timer:SetAllPoints(cd)
    timer.cd = cd
    timer.type = cd.type
    timer.button = cd.button
    timer:Hide()
    timer:SetScript("OnUpdate", Timer_OnUpdate)
    timer:SetScript("OnHide", Timer_Hide)

    local text = timer:CreateFontString(nil, "OVERLAY")
    if cd.type == "Aura" then
        text:SetPoint("TOPRIGHT", timer, "TOPRIGHT", 1, 1)
    else
        text:SetPoint("CENTER", timer, "CENTER", 0, 0)
    end
    timer.text = text

    timers[cd] = timer
    return timer
end

function Timer.Update(timer)
    local time = timer.start + timer.duration - GetTime()
    local max = iCCDB[timer.type].max
    if max then
        if time > max and max > 0 then
            if timer.text:IsVisible() then
                timer.text:Hide()
            end
            timer.cd:SetAlpha(1)
            return
        else
            if not timer.text:IsVisible() then
                timer.text:Show()
            end
            timer.cd:SetAlpha(0)
        end
    end

    if timer.text:IsVisible() then
        local text, scale, r, g, b, nextUpdate = GetFormattedTime(time)
        local size = iCCDB[timer.type].size or floor((iCCDB[timer.type].scale * timer.button:GetSize()) + 0.5)
        timer.text:SetFont(font, size, "OUTLINE")
        timer.text:SetText(size < minFontsize and "" or text)
        timer.text:SetTextColor(r, g, b)
        timer:SetScale(scale)
        timer.nextUpdate = nextUpdate
    end

    if time < 0.2 then
        timer:Hide()
        timer.cd:SetAlpha(1)
    end
end

local iCC = CreateFrame("Frame")
iCC:Hide()
iCC:RegisterEvent("PLAYER_ENTERING_WORLD")

iCC:SetScript("OnEvent", function()
    for cooldown, timer in pairs(timers) do
        Timer.Update(timer)
    end
end)
hooksecurefunc(getmetatable(CreateFrame("Cooldown", nil, nil, "CooldownFrameTemplate")).__index, "SetCooldown", Timer.Start)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 灵魂碎片
local AFFLICTION = 265
local DEMONOLOGY = 266
local DESTRUCTION = 267

local SPELL_POWER_SOUL_SHARDS = 7

local shards = {}

local soulShardFrame = CreateFrame("Frame", "SoulShard", UIParent)
soulShardFrame:SetClampedToScreen(true)

local events = CreateFrame("Frame", "SoulShardEventFrame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("UNIT_POWER_UPDATE")

local function ErrorPrint(err)
    print("|cffFF0000" .. err)
end

local function PlayerSpecialization()
    local spec = GetSpecialization()
    return spec and GetSpecializationInfo(spec) or nil
end

local function MaxPower()
    return UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)
end

local function DrawMainFrame()
    if soulShardFrame:GetHeight() == 0 then
        local numPower = MaxPower()
        local height = 36
        local width = height * numPower
        soulShardFrame:SetHeight(height)
        soulShardFrame:SetWidth(width)
        soulShardFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 195)
    end

    soulShardFrame:Show()
end

local function ShardUpdate()
    local available = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
    for i, shard in ipairs(shards) do
        local alpha = tonumber(i) > available and 0.15 or 1.0
        shard:SetAlpha(alpha)
    end
end

local function getIcon()
    return "Interface\\ICONS\\INV_Misc_Gem_Amethyst_02"
end

local function ShardTexture()
    local size = soulShardFrame:GetWidth() / MaxPower()
    local shard = soulShardFrame:CreateTexture(nil, "ARTWORK")
    shard:SetTexture(getIcon())
    shard:SetWidth(size)
    shard:SetHeight(size)
    return shard
end

local function DrawShards()
    if next(shards) == nil then
        for i = 0, MaxPower() - 1, 1 do
            local shard = ShardTexture()
            shard:SetPoint("LEFT", shard:GetWidth() * i, 0)
            shards[i + 1] = shard
        end
    else
        local icon = getIcon()
        for i, shard in ipairs(shards) do
            shard:SetTexture(icon)
        end
    end
    ShardUpdate()
end

local function SoulShardLoad()
    local spec = PlayerSpecialization()
    if spec == AFFLICTION or spec == DESTRUCTION or spec == DEMONOLOGY then
        DrawMainFrame()
        DrawShards()
    else
        soulShardFrame:Hide()
    end
end

local function EventHandler(self, event, unit, powerType, ...)
    if event == "UNIT_POWER_UPDATE" and unit == "player" then
        ShardUpdate()
    elseif event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        SoulShardLoad()
    elseif event == "ADDON_LOADED" and unit == "MyAddon" then
        if (soulShardFrame) then
            SoulShardLoad()
        else
            ErrorPrint("加载灵魂碎片失败！")
        end
        events:UnregisterEvent("ADDON_LOADED")
        events:RegisterEvent("PLAYER_TALENT_UPDATE")
        events:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    end
end

events:SetScript("OnEvent", EventHandler)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 显示fps和延迟
local fpsLag = CreateFrame("Frame", "FpsLagFrame", UIParent)
fpsLag:SetWidth(120)
fpsLag:SetHeight(30)
fpsLag:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -180, 40)

fpsLag.text = fpsLag:CreateFontString(nil, "OVERLAY")
fpsLag.text:SetFont("Fonts\\ARIALN.TTF", 14)
fpsLag.text:SetPoint("RIGHT", fpsLag, "RIGHT", 0, 5)

local updateInterval = 1
local timeSinceLastUpdate = 0

fpsLag:SetScript("OnUpdate", function(self, elapsed)
    if timeSinceLastUpdate > 0 then
        timeSinceLastUpdate = timeSinceLastUpdate - elapsed
    else
        timeSinceLastUpdate = updateInterval
        local fps = ceil(GetFramerate())
        local lagHome = GetColorText(select(3, GetNetStats()))
        local lagWorld = GetColorText(select(4, GetNetStats()))

        fpsLag.text:SetText(" " .. fps .. " | " .. lagHome .. " | " .. lagWorld .. " ")
    end
end)

function GetColorText(lag)
    if lag < 100 then
        return "|cff008000" .. lag .. "|r"
    elseif lag < 200 then
        return "|cffffff00" .. lag .. "|r"
    end
    return "|cffff0000" .. lag .. "|r"
end
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 修改skada和suf单位
local function Event(event, handler)
    if _G.event == nil then
        _G.event = CreateFrame("Frame")
        _G.event.handler = {}
        _G.event.OnEvent = function(frame, event, ...)
            for key, handler in pairs(_G.event.handler[event]) do
                handler(...)
            end
        end
        _G.event:SetScript("OnEvent", _G.event.OnEvent)
    end
    if _G.event.handler[event] == nil then
        _G.event.handler[event] = {}
        _G.event:RegisterEvent(event)
    end
    table.insert(_G.event.handler[event], handler)
end

local function HookFormatNumber()
    if Skada then
        Skada.FormatNumber = function(self, number)
            if number then
                if number >= 1e8 then
                    return ("%02.2f億"):format(number / 1e8)
                end
                if number >= 1e4 then
                    return ("%02.2f萬"):format(number / 1e4)
                end
                return math.floor(number)
            end
        end
    end

    if ShadowUF then
        ShadowUF.FormatLargeNumber = function(self, number)
            if number < 1e4 then
                return number
            end
            if number < 1e6 then
                return ("%02.1f萬"):format(number / 1e4)
            end
            if number < 1e8 then
                return ("%d萬"):format(number / 1e4)
            end
            return ("%02.2f億"):format(number / 1e8)
        end
        ShadowUF.SmartFormatNumber = function(self, number)
            if number < 1e4 then
                return number
            end
            if number < 1e6 then
                return ("%02.1f萬"):format(number / 1e4)
            end
            if number < 1e8 then
                return ("%d萬"):format(number / 1e4)
            end
            return ("%02.2f億"):format(number / 1e8)
        end
    end
end

Event("PLAYER_LOGIN", function()
    HookFormatNumber()
end)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------