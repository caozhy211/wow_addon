-- CVar值全部重置：/console cvar_default
-- 設置CVar值：/run SetCVar("scriptErrors", 1)或/console scriptErrors 1
-- 查看CVar值：/dump GetCVar("scriptErrors")
-- 查看CVar默認值：/dump GetCVarDefault("scriptErrors")
-- 恢復CVar默認值：/run SetCVar("scriptErrors", GetCVarDefault("scriptErrors"))
SetCVar("scriptErrors", 1) -- 顯示LUA錯誤
SetCVar("alwaysCompareItems", 1) -- 總是對比裝備
SetCVar("cameraDistanceMaxZoomFactor", 2.6) -- 最大視距
SetCVar("floatingCombatTextFloatMode", 3) -- 戰鬥文字捲動顯示方式爲弧型
SetCVar("floatingCombatTextCombatHealing", 0) -- 隱藏目標戰鬥文字捲動的治療數字
SetCVar("floatingCombatTextReactives", 0) -- 隱藏戰鬥文字捲動的法術警示
SetCVar("floatingCombatTextCombatState", 1) -- 啟用進入/離開戰鬥提示
SetCVar("taintLog", 1) -- 啟用插件汙染日誌
SetCVar("rawMouseEnable", 1) -- 啟用魔獸世界滑鼠，防止視角晃動過大
SetCVar("ffxDeath", 0) -- 關閉死亡效果
SetCVar("lockActionBars", 0) -- 不鎖定快捷列
SetCVar("enableFloatingCombatText", 1) -- 啟用自己的戰鬥文字捲動
SetCVar("Sound_SFXVolume", 0.8) -- 音效音量
SetCVar("Sound_MusicVolume", 0.8) -- 音樂音量
SetCVar("Sound_AmbienceVolume", 1) -- 環境音量
SetCVar("Sound_DialogVolume", 1) -- 對話音量
------------------------------------------------------------------------------------------------------------------ 00.00
-- 隱藏製造者
ITEM_CREATED_BY = ""
--------------------------------------------------------------------------------------------------------- +00.00 = 00.00
-- 團隊框架滑塊值
CompactUnitFrameProfilesGeneralOptionsFrameHeightSlider:SetMinMaxValues(22, 33)
CompactUnitFrameProfilesGeneralOptionsFrameWidthSlider:SetMinMaxValues(70, 114)
--------------------------------------------------------------------------------------------------------- +00.00 = 00.00
-- 隱藏拾取框
LootFrame:SetAlpha(0)
--------------------------------------------------------------------------------------------------------- +00.00 = 00.00
-- 隱藏主快捷列兩邊的材質
MainMenuBarArtFrame.LeftEndCap:Hide()
MainMenuBarArtFrame.RightEndCap:Hide()
-- 隱藏載具快捷列兩邊的材質
OverrideActionBarEndCapL:Hide()
OverrideActionBarEndCapR:Hide()
--------------------------------------------------------------------------------------------------------- +00.00 = 00.00
-- 聊天框
for i = 1, NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame" .. i]
    -- 離左、右、上、下邊界的距離，正數向左和下移動，負數向右和上移動
    chatFrame:SetClampRectInsets(-35, 38, 38, -117)
    -- 設置聊天框的最小尺寸和最大尺寸
    chatFrame:SetMinResize(476, 181)
    chatFrame:SetMaxResize(476, 181)

    -- 隱藏輸入框的邊框
    _G["ChatFrame" .. i .. "EditBoxLeft"]:Hide()
    _G["ChatFrame" .. i .. "EditBoxMid"]:Hide()
    _G["ChatFrame" .. i .. "EditBoxRight"]:Hide()
    -- 設置輸入框位置
    local editBox = chatFrame.editBox
    editBox:ClearAllPoints()
    editBox:SetPoint("BottomLeft", ChatFrame1, "TopLeft", 155, -2)
    editBox:SetPoint("BottomRight", ChatFrame1, "TopRight", 5, -2)

    editBox:SetAltArrowKeyMode(false)
end
--------------------------------------------------------------------------------------------------------- +00.00 = 00.00
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("MERCHANT_SHOW")
f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if Skada then
            -- 使用中文單位簡化數字
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

            -- 設置Skada框架大小和位置
            if Skada:GetWindows()[1] ~= nil then
                Skada:GetWindows()[1].bargroup:ClearAllPoints()
                Skada:GetWindows()[1].bargroup:SetPoint("BottomLeft", UIParent, "BottomLeft", 0, 0)
                Skada:GetWindows()[1].db.barwidth = 535
                Skada:GetWindows()[1].db.background.height = 90
            end
        end
        ------------------------------------------------------------------------------------------------- +01.58 = 01.58
        if ShadowUF then
            -- 使用中文單位簡化數字
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
        end
        ------------------------------------------------------------------------------------------------- +00.77 = 02.35
        -- 設置特殊能量條位置
        PlayerPowerBarAlt:SetMovable(true)
        PlayerPowerBarAlt:SetUserPlaced(true)
        PlayerPowerBarAlt:ClearAllPoints()
        PlayerPowerBarAlt:SetPoint("Center", UIParent, "Center", 0, 420)
        ------------------------------------------------------------------------------------------------- +00.27 = 02.62
        local bars = {
            "MainMenuBarArtFrame",
            "MultiBarBottomLeft",
            "MultiBarBottomRight",
            "MultiBarRight",
            "MultiBarLeft",
            "PossessBarFrame",
            "Action",
        }

        for i = 1, #bars do
            -- 隱藏快捷列巨集名稱
            if _G[bars[i] .. "Button1Name"] ~= nil then
                for j = 1, 12 do
                    _G[bars[i] .. "Button" .. j .. "Name"]:SetAlpha(0)
                end
            end
            -- 快捷列右鍵自我施法
            local bar = _G[bars[i]]
            if bar ~= nil then
                bar:SetAttribute("unit2", "player")
            end
        end
        ------------------------------------------------------------------------------------------------- +00.96 = 03.58
    else
        -- 自動出售灰色物品
        local totalPrice = 0
        for myBags = 0, 4 do
            for bagSlots = 1, GetContainerNumSlots(myBags) do
                local CurrentItemLink = GetContainerItemLink(myBags, bagSlots)
                if CurrentItemLink then
                    local _, _, itemRarity, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(CurrentItemLink)
                    local _, itemCount = GetContainerItemInfo(myBags, bagSlots)
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
        ------------------------------------------------------------------------------------------------- +01.23 = 04.81
        -- 自動修理
        if (CanMerchantRepair()) then
            local repairAllCost, canRepair = GetRepairAllCost()
            if (canRepair and repairAllCost > 0) then
                -- 使用公會修理
                local guildRepairedItems = false
                if (IsInGuild() and CanGuildBankRepair()) then
                    -- 檢查公會是否有足夠的錢
                    local amount = GetGuildBankWithdrawMoney()
                    local guildBankMoney = GetGuildBankMoney()
                    amount = amount == -1 and guildBankMoney or min(amount, guildBankMoney)
                    if (amount >= repairAllCost) then
                        RepairAllItems(true)
                        guildRepairedItems = true
                        DEFAULT_CHAT_FRAME:AddMessage("装备已使用公修修理", 255, 255, 255)
                    end
                end

                -- 使用自己的錢修理
                if (repairAllCost <= GetMoney() and not guildRepairedItems) then
                    RepairAllItems(false)
                    DEFAULT_CHAT_FRAME:AddMessage("修理装备花费: -" .. GetCoinTextureString(repairAllCost), 255, 255, 255)
                end
            end
        end
        ------------------------------------------------------------------------------------------------- +01.03 = 05.84
    end
    ----------------------------------------------------------------------------------------------------- +00.07 = 05.91
end)
--------------------------------------------------------------------------------------------------------- +00.26 = 06.17
-- 設置Immersion框架位置
if LoadAddOn("Immersion") then
    ImmersionFrame.TalkBox:ClearAllPoints()
    ImmersionFrame.TalkBox:SetPoint("Bottom", UIParent, "Center", 0, -190)
    ImmersionFrame.TalkBox.SetPoint = function()
    end

    ImmersionFrame.TalkBox.Elements:ClearAllPoints()
    ImmersionFrame.TalkBox.Elements:SetPoint("BottomLeft", ImmersionFrame.TalkBox, "BottomRight", 0, 0)
end
--------------------------------------------------------------------------------------------------------- +00.19 = 06.36
-- 設置對話框架位置
if LoadAddOn("Blizzard_TalkingHeadUI") then
    TalkingHeadFrame.ignorePositionFrameManager = true
    TalkingHeadFrame:ClearAllPoints()
    TalkingHeadFrame:SetPoint("TopLeft", UIParent, "TopLeft", 0, 0)
    TalkingHeadFrame.SetPoint = function()
    end
end
--------------------------------------------------------------------------------------------------------- +00.24 = 06.61
-- 隱藏自己的戰鬥文字捲動的治療數字
if LoadAddOn("Blizzard_CombatText") then
    COMBAT_TEXT_TYPE_INFO["HEAL"] = nil
    COMBAT_TEXT_TYPE_INFO["HEAL_ABSORB"] = nil
    COMBAT_TEXT_TYPE_INFO["HEAL_CRIT"] = nil
    COMBAT_TEXT_TYPE_INFO["HEAL_CRIT_ABSORB"] = nil
    COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL"] = nil
    COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL_ABSORB"] = nil
    COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL_CRIT"] = nil
    COMBAT_TEXT_TYPE_INFO["ABSORB_ADDED"] = nil
end
--------------------------------------------------------------------------------------------------------- +00.38 = 06.99
-- 簡化重置命令
SlashCmdList["RELOAD"] = function()
    ReloadUI()
end
SLASH_RELOAD1 = "/rl"
--------------------------------------------------------------------------------------------------------- +00.26 = 07.25
-- 自動填寫DELETE
hooksecurefunc(StaticPopupDialogs["DELETE_GOOD_ITEM"], "OnShow", function(self)
    self.editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
end)
--------------------------------------------------------------------------------------------------------- +00.40 = 07.65
MinimapBorderTop:Hide() -- 隱藏地點邊框
MinimapBorder:Hide() -- 隱藏地圖邊框
MiniMapWorldMapButton:Hide() -- 隱藏世界地圖按鈕
MinimapZoomIn:Hide() -- 隱藏放大按鈕
MinimapZoomOut:Hide() -- 隱藏縮小按鈕

-- 方形小地圖
Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
Minimap:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                      insets = { top = -1, left = -1, bottom = -1, right = -1 } })
Minimap:SetBackdropColor(0.53, 0.53, 0.93, 1)

-- 滾輪縮放小地圖
Minimap:EnableMouseWheel(true)
Minimap:SetScript("OnMouseWheel", function(self, value)
    if value > 0 then
        MinimapZoomIn:Click()
    else
        MinimapZoomOut:Click()
    end
end)
--------------------------------------------------------------------------------------------------------- +00.38 = 08.03
-- 大地圖顯示坐標
WorldMapFrame.playerPos = WorldMapFrame.BorderFrame:CreateFontString(nil, "Artwork")
WorldMapFrame.playerPos:SetFont(GameFontNormal:GetFont(), 12, "ThinOutline")
WorldMapFrame.playerPos:SetJustifyH("Right")
WorldMapFrame.playerPos:SetPoint("Right", WorldMapFrameCloseButton, "Left", -40, 0)
WorldMapFrame.playerPos:SetTextColor(1, 0.82, 0.1)
WorldMapFrame.mousePos = WorldMapFrame.BorderFrame:CreateFontString(nil, "Artwork")
WorldMapFrame.mousePos:SetFont(GameFontNormal:GetFont(), 12, "ThinOutline")
WorldMapFrame.mousePos:SetJustifyH("Right")
WorldMapFrame.mousePos:SetPoint("Right", WorldMapFrameCloseButton, "Left", -160, 0)

WorldMapFrame:HookScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if (self.elapsed < 0.2) then
        return
    end
    self.elapsed = 0
    -- 玩家坐標
    local position = C_Map.GetPlayerMapPosition(MapUtil.GetDisplayableMapForPlayer(), "player")
    if (position) then
        self.playerPos:SetText(format("玩家: %.1f, %.1f", position.x * 100, position.y * 100))
    else
        self.playerPos:SetText("")
    end
    -- 滑鼠坐標
    local mapInfo = C_Map.GetMapInfo(self:GetMapID())
    if (mapInfo and mapInfo.mapType == 3) then
        local x, y = self.ScrollContainer:GetNormalizedCursorPosition()
        if (x and y and x > 0 and x < 1 and y > 0 and y < 1) then
            self.mousePos:SetText(format("滑鼠: %.1f, %.1f", x * 100, y * 100))
        else
            self.mousePos:SetText("")
        end
    else
        self.mousePos:SetText("")
    end
end)
--------------------------------------------------------------------------------------------------------- +01.76 = 09.79
-- 隱藏區域技能鍵材質
ZoneAbilityFrame.SpellButton.Style:Hide()
-- 設置區域技能鍵位置
ZoneAbilityFrame:ClearAllPoints()
ZoneAbilityFrame:SetPoint("Center", UIParent, "Center", 0, -270)
ZoneAbilityFrame.SetPoint = function()
end
--------------------------------------------------------------------------------------------------------- +00.19 = 09.98
-- 隱藏額外快捷鍵材質
ExtraActionButton1.style:Hide()
-- 設置額外快捷鍵位置
ExtraActionBarFrame:ClearAllPoints()
ExtraActionBarFrame:SetPoint("Center", UIParent, "Center", 0, -210)
ExtraActionBarFrame.SetPoint = function()
end
--------------------------------------------------------------------------------------------------------- +00.19 = 10.17
-- 技能范圍外時快捷列按鈕著色
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
--------------------------------------------------------------------------------------------------------- +00.72 = 10.89
-- 特殊能量條始終顯示數值
hooksecurefunc("UnitPowerBarAltStatus_ToggleFrame", function(self)
    if self.enabled then
        self:Show();
        UnitPowerBarAltStatus_UpdateText(self);
    end
end)
--------------------------------------------------------------------------------------------------------- +00.43 = 11.32
-- 上載具後隱藏寵物快捷列
hooksecurefunc("MainMenuBarVehicleLeaveButton_Update", function()
    if (CanExitVehicle() and ActionBarController_GetCurrentActionBarState() == LE_ACTIONBAR_STATE_MAIN) then
        PetActionBarFrame:Hide()
    end
end)
--------------------------------------------------------------------------------------------------------- +00.50 = 11.82
-- 移動背包
hooksecurefunc("UpdateContainerFrameAnchors", function()
    -- 修改這兩個值移動
    local moveOffsetX = 0 -- 正數向左移動，負數向右移動
    local moveOffsetY = 60 -- 正數向上移動， 負數向下移動

    local frame, xOffset, yOffset, screenHeight, freeScreenHeight, leftMostPoint, column
    local screenWidth = GetScreenWidth()
    local containerScale = 1
    local leftLimit = 0
    if (BankFrame:IsShown()) then
        leftLimit = BankFrame:GetRight() - 25
    end

    while (containerScale > CONTAINER_SCALE) do
        screenHeight = GetScreenHeight() / containerScale
        -- 根據快捷列調整背包的起始錨點
        xOffset = (CONTAINER_OFFSET_X + moveOffsetX) / containerScale
        yOffset = (CONTAINER_OFFSET_Y + moveOffsetY) / containerScale
        -- freeScreenHeight決定什麼時候開始新的一列
        freeScreenHeight = screenHeight - yOffset
        leftMostPoint = screenWidth - xOffset
        column = 1
        local frameHeight
        for index = 1, #ContainerFrame1.bags do
            frameHeight = _G[ContainerFrame1.bags[index]]:GetHeight()
            if (freeScreenHeight < frameHeight) then
                -- 開始新的一列
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
    -- 根據快捷列調整背包的起始錨點
    xOffset = (CONTAINER_OFFSET_X + moveOffsetX) / containerScale
    yOffset = (CONTAINER_OFFSET_Y + moveOffsetY) / containerScale
    -- freeScreenHeight決定什麼時候開始新的一列
    freeScreenHeight = screenHeight - yOffset
    column = 0
    for index = 1, #ContainerFrame1.bags do
        frame = _G[ContainerFrame1.bags[index]]
        frame:SetScale(containerScale)
        if (index == 1) then
            -- 第一個背包
            frame:SetPoint("BottomRight", frame:GetParent(), "BottomRight", -xOffset, yOffset)
        elseif (freeScreenHeight < frame:GetHeight()) then
            -- 開始新的一列
            column = column + 1
            freeScreenHeight = screenHeight - yOffset
            frame:SetPoint(
                    "BottomRight", frame:GetParent(), "BottomRight", -(column * CONTAINER_WIDTH) - xOffset, yOffset)
        else
            -- 以上一個背包作爲錨點
            frame:SetPoint("BottomRight", ContainerFrame1.bags[index - 1], "TopRight", 0, CONTAINER_SPACING)
        end
        freeScreenHeight = freeScreenHeight - frame:GetHeight() - VISIBLE_CONTAINER_SPACING
    end
end)
--------------------------------------------------------------------------------------------------------- +02.18 = 14.20
-- 快速設置專注目標
-- 覆蓋按鍵綁定以使模型支持Shift/Alt/Ctrl+點擊
local focus = CreateFrame(
        "CheckButton", "FocuserFrame", UIParent, "SecureActionButtonTemplate")
focus:SetAttribute("type1", "macro")
focus:SetAttribute("macrotext", "/focus mouseover")
-- key參數可以是shift/alt/ctrl-button1/2/3/4/5
SetOverrideBindingClick(FocuserFrame, true, "shift-button1", "FocuserFrame")

hooksecurefunc("CreateFrame", function(type, name, parent, template)
    if template == "SecureUnitButtonTemplate" then
        -- key參數可以是shift/alt/ctrl-type1/2/3/4/5
        _G[name]:SetAttribute("shift-type1", "focus")
    end
end)

-- 在默認單位框架上設置按鍵綁定，因爲我們不會獲得有關它們創建框架的通知
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
    -- key參數可以是shift/alt/ctrl-type1/2/3/4/5
    defaultUnitFrames[i]:SetAttribute("shift-type1", "focus")
end
--------------------------------------------------------------------------------------------------------- +00.72 = 14.92
-- 顯示FPS和延遲
local info = CreateFrame("Frame", "InfoFrame", UIParent)
info:SetWidth(120)
info:SetHeight(30)
info:SetPoint("BottomRight", UIParent, "BottomRight", -180, 40)

local infoText = info:CreateFontString(nil, "Overlay")
infoText:SetFont("Fonts\\ARHei.ttf", 14)
infoText:SetPoint("Right", info, "Right", 0, 5)

function infoText:SetColor(latency)
    if latency < 100 then
        return "|cff00ff00" .. latency .. "|r"
    elseif latency < 200 then
        return "|cffffff00" .. latency .. "|r"
    end
    return "|cffff0000" .. latency .. "|r"
end

info:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 1 then
        return
    end
    self.elapsed = 0

    local fps = format("%.0f", GetFramerate())
    local latencyHome = infoText:SetColor(select(3, GetNetStats()))
    local latencyWorld = infoText:SetColor(select(4, GetNetStats()))

    infoText:SetText(" " .. fps .. " | " .. latencyHome .. " | " .. latencyWorld .. " ")
end)
--------------------------------------------------------------------------------------------------------- +01.62 = 16.54
local matchTable = {
    ["綜合"] = "綜合",
    ["交易"] = "交易",
    ["本地防務"] = "防務",
    ["尋求組隊"] = "尋組",
    ["組隊頻道"] = "組隊",
}

-- 簡化輸入框的頻道名稱
hooksecurefunc("ChatEdit_UpdateHeader", function(editBox)
    local type = editBox:GetAttribute("chatType")
    if not type then
        return
    end
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
            editBox:SetAttribute("channelTarget", channel)

            for key, value in pairs(matchTable) do
                if channelName:find(key) then
                    channelName = value
                end
            end

            header:SetFormattedText(CHAT_CHANNEL_SEND, channel, channelName)
        end
    end
    editBox:SetTextInsets(15 + header:GetWidth() + (headerSuffix:IsShown() and headerSuffix:GetWidth() or 0), 13, 0, 0)
end)
--------------------------------------------------------------------------------------------------------- +02.39 = 18.93
-- 簡化聊天框頻道名稱
for name, abbrev in pairs(matchTable) do
    for i = 1, NUM_CHAT_WINDOWS do
        if i ~= 2 then
            local chatFrame = _G["ChatFrame" .. i]
            local am = chatFrame.AddMessage
            chatFrame.AddMessage = function(frame, text, ...)
                return am(frame, text:gsub("|h%[(%d+)%. " .. name .. ".-%]|h", "|h%[%1%. " .. abbrev .. "%]|h"), ...)
            end
        end
    end
end
--------------------------------------------------------------------------------------------------------- +07.69 = 26.62
-- 靈魂裂片
local ss = CreateFrame("Frame", "SoulShard", UIParent)
ss:SetClampedToScreen(true)
ss:RegisterEvent("PLAYER_LOGIN")
ss:RegisterEvent("UNIT_POWER_UPDATE")

ss.shards = {}

function ss:Update()
    -- 7：靈魂裂片
    local available = UnitPower("player", 7)
    for i = 1, #ss.shards do
        local alpha = i > available and 0.15 or 1
        ss.shards[i]:SetAlpha(alpha)
    end
end

ss:SetScript("OnEvent", function(self, event, unit, ...)
    if event == "UNIT_POWER_UPDATE" and unit == "player" then
        ss:Update()
    elseif event == "PLAYER_LOGIN" then
        local spec = GetSpecialization()
        spec = spec and GetSpecializationInfo(spec) or nil
        -- 265:痛苦，266：惡魔，267：毀滅
        if spec == 265 or spec == 266 or spec == 267 then
            -- 7：靈魂裂片
            local numPower = UnitPowerMax("player", 7)
            local size = 36

            if ss:GetHeight() == 0 then
                ss:SetHeight(size)
                ss:SetWidth(size * numPower)
                ss:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 195)
            end
            ss:Show()

            if next(ss.shards) == nil then
                for i = 1, numPower do
                    local shard = ss:CreateTexture(nil, "Artwork")
                    shard:SetTexture("Interface\\ICONS\\INV_Misc_Gem_Amethyst_02")
                    shard:SetWidth(size)
                    shard:SetHeight(size)
                    shard:SetPoint("Left", size * (i - 1), 0)
                    ss.shards[i] = shard
                end
            end
            ss:Update()
        else
            ss:Hide()
        end
    end
end)
--------------------------------------------------------------------------------------------------------- +03.10 = 29.72
-- 冷卻時間
local timers = {}

local function GetTimeText(seconds)
    if seconds < 5 then
        return floor(seconds), 1, 0, 0, 0.2
    elseif seconds < 100 then
        return floor(seconds), 1, 1, 0, seconds - floor(seconds)
    elseif seconds < 3600 then
        local text = ceil(seconds / 60) .. "m"
        local nextUpdate
        if seconds < 120 then
            nextUpdate = seconds - 100
        else
            nextUpdate = seconds % 60
        end
        return text, 1, 1, 1, nextUpdate
    elseif seconds < 86400 then
        return ceil(seconds / 3600) .. "h", 1, 1, 1, seconds % 3600
    end
    return ceil(seconds / 86400) .. "d", 1, 1, 1, seconds % 86400
end

local function CreateTimer(cd)
    local parent = cd:GetParent()
    local size = parent:GetSize()
    if size >= 20 then
        local frame = parent
        local name = frame:GetName()
        while not name do
            frame = frame:GetParent()
            name = frame:GetName()
        end

        if not name:find("ThreatPlatesFrame") and not name:find("LossOfControlFrame") then
            local type = name:find("SUF") and "Aura" or "Action"
            local timer = CreateFrame("Frame", nil, parent)
            timer:SetAllPoints(parent)

            timer.cd = cd
            timer.nextUpdate = 0

            timer.text = timer:CreateFontString(nil, "Overlay")
            local fontSize = floor(0.5 * size)
            if fontSize > 15 then
                fontSize = 15
            end
            timer.text:SetFont("Fonts\\ARHei.ttf", fontSize, "Outline")
            if type == "Aura" then
                timer.text:SetPoint("TopRight", timer, "TopRight", 0, 0)
            else
                timer.text:SetPoint("Center", timer, "Center", 0, 0)
            end
            timers[cd] = timer

            timer:SetScript("OnUpdate", function(self, elapsed)
                if not self.cd:IsShown() then
                    self:Hide()
                end

                self.elapsed = (self.elapsed or 0) + elapsed
                if self.elapsed < self.nextUpdate then
                    return
                end
                self.elapsed = 0

                local remain = self.start + self.duration - GetTime()
                if remain > 864000 then
                    if self.text:IsShown() then
                        self.nextUpdate = remain % 864000
                        self.text:Hide()
                    end
                else
                    if not self.text:IsShown() then
                        self.text:Show()
                    end
                end

                if self.text:IsShown() then
                    local text, r, g, b, nextUpdate = GetTimeText(remain)
                    self.text:SetText(text)
                    self.text:SetTextColor(r, g, b)
                    self.nextUpdate = nextUpdate
                end

                if remain < 0.2 then
                    self:Hide()
                end
            end)

            timer:SetScript("OnHide", function(self)
                self.nextUpdate = 0
            end)

            timer:SetScript("OnShow", function(self)
                self.nextUpdate = 0
            end)

            return timer
        end
    end
end

local metatable = getmetatable(
        CreateFrame("Cooldown", nil, nil, "CooldownFrameTemplate")).__index
hooksecurefunc(metatable, "SetCooldown", function(cd, start, duration)
    -- 2：最小時間，公共冷卻時間不顯示
    if duration > 2 then
        local timer = timers[cd] or CreateTimer(cd)
        if timer then
            timer.start = start
            timer.duration = duration
            timer:Show()
        end
    end
end)
--------------------------------------------------------------------------------------------------------- +06.07 = 35.79
-- 對齊網格
local align = CreateFrame("Frame", "AlignFrame", UIParent)
align:SetAllPoints(UIParent)
align.width = GetScreenWidth() / 64
align.height = GetScreenHeight() / 36
align:Hide()
SlashCmdList["ALIGN"] = function()
    if align:IsShown() then
        align:Hide()
    else
        -- 豎線
        for i = 0, 64 do
            local texture = align:CreateTexture(nil, "Background")
            if i == 32 then
                texture:SetColorTexture(1, 0, 0, 0.5)
            else
                texture:SetColorTexture(0, 0, 0, 0.5)
            end
            texture:SetPoint(
                    "TopLeft", align, "TopLeft", i * align.width - 1, 0)
            texture:SetPoint(
                    "BottomRight", align, "BottomLeft", i * align.width + 1, 0)
        end
        -- 橫線
        for i = 0, 36 do
            local texture = align:CreateTexture(nil, "Background")
            if i == 18 then
                texture:SetColorTexture(1, 0, 0, 0.5)
            else
                texture:SetColorTexture(0, 0, 0, 0.5)
            end
            texture:SetPoint(
                    "TopLeft", align, "TopLeft", 0, -(i * align.height - 1))
            texture:SetPoint(
                    "BottomRight", align, "TopRight", 0, -(i * align.height + 1))
        end
        align:Show()
    end
end
SLASH_ALIGN1 = "/al"
--------------------------------------------------------------------------------------------------------- +01.85 = 37.64
-- 簡化ROLL點命令
SlashCmdList["ROLL"] = function()
    RandomRoll(1, 100)
end
SLASH_ROLL1 = "/rr"
--------------------------------------------------------------------------------------------------------- +00.44 = 38.08
-- 聊天框清屏
SlashCmdList["CLEAR"] = function()
    SELECTED_CHAT_FRAME:Clear()
end
SLASH_CLEAR1 = "/cl"
--------------------------------------------------------------------------------------------------------- +00.26 = 38.34
-- 加入/離開組隊頻道
SlashCmdList["ZUDUI"] = function()
    local _, channelName, _ = GetChannelName("組隊頻道")
    if channelName == nil then
        JoinPermanentChannel("組隊頻道", nil, 1, 1)
        ChatFrame_AddChannel(SELECTED_CHAT_FRAME, "組隊頻道")
        print("|cff00d200已加入組隊頻道|r")
    else
        LeaveChannelByName("組隊頻道")
        print("|cffd20000已离开組隊頻道|r")
    end
end
SLASH_ZUDUI1 = "/zd"
--------------------------------------------------------------------------------------------------------- +00.97 = 39.31