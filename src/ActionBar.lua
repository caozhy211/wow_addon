---@type Texture
local mainMenuBarArtFrameBackground = MainMenuBarArtFrameBackground
mainMenuBarArtFrameBackground:Hide()
---@type Texture
local mainMenuBarArtFrameLeftEndCap = MainMenuBarArtFrame.LeftEndCap
mainMenuBarArtFrameLeftEndCap:Hide()
---@type Texture
local mainMenuBarArtFrameRightEndCap = MainMenuBarArtFrame.RightEndCap
mainMenuBarArtFrameRightEndCap:Hide()
---@type Texture
local overrideActionBarEndCapL = OverrideActionBarEndCapL
overrideActionBarEndCapL:Hide()
---@type Texture
local overrideActionBarEndCapR = OverrideActionBarEndCapR
overrideActionBarEndCapR:Hide()
---@type Texture
local slidingActionBarTexture0 = SlidingActionBarTexture0
slidingActionBarTexture0:SetTexture(nil)
---@type Texture
local slidingActionBarTexture1 = SlidingActionBarTexture1
slidingActionBarTexture1:SetTexture(nil)
---@type Texture
local possessBackground1 = PossessBackground1
possessBackground1:SetTexture(nil)
---@type Texture
local possessBackground2 = PossessBackground2
possessBackground2:SetTexture(nil)
---@type Texture
local possessButton1NormalTexture = PossessButton1NormalTexture
possessButton1NormalTexture:SetTexture(nil)
---@type Texture
local possessButton2NormalTexture = PossessButton2NormalTexture
possessButton2NormalTexture:SetTexture(nil)

---@type Frame
local possessBarFrame = PossessBarFrame
possessBarFrame:ClearAllPoints()
--- PossessButton 的大小是（30px，30px），PossessButton1 左边相对 PossessBarFrame 左边偏移 10px，PossessButton2 左边相对
--- PossessButton1 右边偏移 8px；上边界相对屏幕底部偏移 185 - 2 - 3 - 30 - 3 - 1 = 146px，MultiBarBottomLeftButton 顶部最大
--- 值是 108px，边框纹理是 4px，即下边界相对屏幕底部偏移 108 + 4 = 112px，PossessButton 底部相对 PossessBarFrame 底部偏移 3px
possessBarFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", -(30 + 10 + 8 / 2), 112 + (146 - 112) / 2 - 30 / 2 - 3)
possessBarFrame.SetPoint = nop

---@type Frame
local petActionBarFrame = CreateFrame("Frame", "WLK_PetActionBarFrame", UIParent)
--- PetActionButton 的大小是（30px，30px），PetActionButton 之间的水平间距是 8px
petActionBarFrame:SetSize(30 * NUM_PET_ACTION_SLOTS + 8 * (NUM_PET_ACTION_SLOTS - 1), 30)
petActionBarFrame:SetPoint("CENTER", UIParent, "BOTTOM", 0, 112 + (146 - 112) / 2)
for i = 1, NUM_PET_ACTION_SLOTS do
    ---@type Button
    local petActionButton = _G["PetActionButton" .. i]
    petActionButton:ClearAllPoints()
    petActionButton:SetPoint("LEFT", petActionBarFrame, (i - 1) * (30 + 8), 0)
end

---@type Button
local leftButton = MultiBarBottomLeftButton12
local left = leftButton:GetRight()
---@type Button
local rightButton = MultiBarBottomRightButton7
local right = rightButton:GetLeft();
local xOffset = (right - left) / 2
---@type Button
local vehicleLeaveButton = MainMenuBarVehicleLeaveButton

--- 设置 MainMenuBarVehicleLeaveButton 位置
hooksecurefunc("MainMenuBarVehicleLeaveButton_Update", function()
    vehicleLeaveButton:ClearAllPoints()
    vehicleLeaveButton:SetPoint("CENTER", leftButton, "RIGHT", xOffset, 0)
end)

---@type Frame
local playerPowerBarAlt = PlayerPowerBarAlt
playerPowerBarAlt:SetMovable(true)
playerPowerBarAlt:SetUserPlaced(true)

---@type Frame
local iconIntroTracker = IconIntroTracker
--- 阻止学会新技能时技能图标自动添加到动作条
iconIntroTracker.RegisterEvent = nop
iconIntroTracker:UnregisterEvent("SPELL_PUSHED_TO_ACTIONBAR")

---@type Frame
local eventListener = CreateFrame("Frame")

eventListener:RegisterEvent("PLAYER_LOGIN")
eventListener:RegisterEvent("SPELL_PUSHED_TO_ACTIONBAR")

---@param self Frame
eventListener:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- 设置 PlayerPowerBarAlt 位置
        playerPowerBarAlt:ClearAllPoints()
        -- 左边界相对屏幕左边偏移 1080px，右边界相对屏幕左边偏移 1350px，下边界相对屏幕底部偏移 314 + 1 = 315px
        playerPowerBarAlt:SetPoint("BOTTOM", 1080 - GetScreenWidth() / 2 + (1350 - 1080) / 2, 315)
        self:UnregisterEvent(event)
    elseif event == "SPELL_PUSHED_TO_ACTIONBAR" then
        -- 阻止在不是第一页动作条学会新技能时技能图标自动添加到第一页动作条
        local _, slot = ...
        if not InCombatLockdown() then
            ClearCursor()
            PickupAction(slot)
            ClearCursor()
        end
    end
end)

--- CollectionsJournal 右边相对屏幕左边偏移 719px，右边界相对屏幕左边偏移 1080px，ExtraActionBarFrame（包括纹理）的宽度是 256px
local scale = (1080 - 719 - 1) / 2 / 256
--- 保留两位小数
scale = scale - scale % 0.01
---@type Frame
local extraActionBarFrame = ExtraActionBarFrame
extraActionBarFrame:SetScale(scale)
extraActionBarFrame:ClearAllPoints()
--- ExtraActionBarFrame（包括纹理）的高度是 128px，ExtraActionBarFrame 纹理中心相对 ExtraActionBarFrame 中心水平偏移 -2px
extraActionBarFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", (719 + 1 + ceil(256 * scale) / 2 + 2) / scale,
        (315 + ceil(128 * scale) / 2) / scale)
extraActionBarFrame.SetPoint = nop

---@type Frame
local zoneAbilityFrame = ZoneAbilityFrame
zoneAbilityFrame:SetScale(scale)
zoneAbilityFrame:ClearAllPoints()
--- 同 ExtraActionBarFrame
zoneAbilityFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", (1080 - ceil(256 * scale) / 2 + 2) / scale,
        (315 + ceil(128 * scale) / 2) / scale)
zoneAbilityFrame.SetPoint = nop

--- 显示 UnitPowerBarAlt 的数值
---@param self StatusBar
hooksecurefunc("UnitPowerBarAltStatus_ToggleFrame", function(self)
    if self.enabled then
        self:Show()
        UnitPowerBarAltStatus_UpdateText(self)
    end
end)

--- 设置右方动作条的滑入滑出动画时间为主动作条的滑入滑出动画时间
---@type AnimationGroup
local mainMenuBarSlideOut = MainMenuBar.slideOut
---@type Animation
local mainMenuBarSlideOutAnimation = mainMenuBarSlideOut:GetAnimations()
local duration = mainMenuBarSlideOutAnimation:GetDuration()
---@type AnimationGroup
local multiBarLeftSlideOut = MultiBarLeft.slideOut
---@type Animation
local multiBarLeftSlideOutAnimation = multiBarLeftSlideOut:GetAnimations()
multiBarLeftSlideOutAnimation:SetDuration(duration)
---@type AnimationGroup
local multiBarRightSlideOut = MultiBarRight.slideOut
---@type Animation
local multiBarRightSlideOutAnimation = multiBarRightSlideOut:GetAnimations()
multiBarRightSlideOutAnimation:SetDuration(duration)

---@type table<number, Frame>
local actionBars = {
    MainMenuBarArtFrame,
    MultiBarBottomLeft,
    MultiBarBottomRight,
    MultiBarLeft,
    MultiBarRight,
    PossessBarFrame,
}
for i = 1, #actionBars do
    -- 右键点击动作条按钮自我施法
    actionBars[i]:SetAttribute("unit2", "player")
end

local actionButtons = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarLeftButton",
    "MultiBarRightButton",
}
for i = 1, #actionButtons do
    for j = 1, NUM_ACTIONBAR_BUTTONS do
        -- 隐藏动作条按钮上的文字
        ---@type FontString
        local buttonText = _G[actionButtons[i] .. j .. "Name"]
        buttonText:Hide()
    end
end

--- 目标不在动作条按钮的技能范围内时，按钮变红色
hooksecurefunc("ActionButton_OnUpdate", function(self)
    if self.rangeTimer == TOOLTIP_UPDATE_TIME then
        local valid = IsActionInRange(self.action)
        if valid == false then
            ---@type Texture
            local icon = self.icon
            icon:SetVertexColor(GetTableColor(DIM_RED_FONT_COLOR))
        else
            ActionButton_UpdateUsable(self)
        end
    end
end)

local numDivs = 10
local width = 380
---@type Texture
local xpMid = OverrideActionBar.xpBar.XpMid
---@type Texture
local xpBar = OverrideActionBar.xpBar

--- 设置 OverrideActionBar.xpBar
hooksecurefunc("OverrideActionBar_CalcSize", function()
    xpMid:SetWidth(width - 16)
    xpBar:SetWidth(width)
    for i = 1, 19 do
        ---@type Texture
        local texture = OverrideActionBar.xpBar["XpDiv" .. i]
        if i < numDivs then
            texture:SetPoint("CENTER", xpMid, "LEFT", floor(width / numDivs * i), 1)
        else
            texture:Hide()
        end
    end
end)

--- MicroButtonAndBagsBar 左边相对屏幕右边偏移 -298px，ObjectiveTrackerBlocksFrame 的宽度是 235px，MultiBarRightButton 右边
--- 相对屏幕右边偏移 -2px，PoiButton 的大小是（20px，20px），PoiButton.Icon 的大小是（24px，24px），PoiButton.Icon 中心相对
--- PoiButton 中心水平偏移 -1px，PoiButton 右边相对 ObjectiveTrackerBlocksFrame 左边偏移 -6px
local size = 298 - 235 - 2 - ((24 - 20) / 2 + 1 + 20 + 6)
local buttonNamePrefix = "MultiBarRightButton"
for i = 1, NUM_ACTIONBAR_BUTTONS do
    ---@type Button
    local button = _G[buttonNamePrefix .. i]
    -- 设置 MultiBarRightButton 大小
    button:SetSize(size, size)
    -- 隐藏 MultiBarRightButton 纹理
    ---@type Texture
    local texture = _G[buttonNamePrefix .. i .. "NormalTexture"]
    texture:SetTexture(nil)
    ---@type Texture
    local bg = _G[buttonNamePrefix .. i .. "FloatingBG"]
    bg:Hide()
end
