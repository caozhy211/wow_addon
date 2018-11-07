local function MovePossessBar()
    PossessBarFrame:ClearAllPoints()
    PossessBarFrame:SetPoint("BottomLeft", UIParent, "Bottom", -30 - 10 - (8 / 2), 143 - 30 - 3)
    PossessBarFrame.SetPoint = nop
end

local function MoveExtraActionBar()
    local scale = 0.75
    ExtraActionBarFrame:SetScale(scale)
    ExtraActionBarFrame:ClearAllPoints()
    ExtraActionBarFrame:SetPoint("Center", UIParent, -150 / scale, -180 / scale)
    ExtraActionBarFrame.SetPoint = nop
end

local function HideLayers()
    MainMenuBarArtFrameBackground:Hide()

    MainMenuBarArtFrame.LeftEndCap:Hide()
    MainMenuBarArtFrame.RightEndCap:Hide()

    OverrideActionBarEndCapL:Hide()
    OverrideActionBarEndCapR:Hide()

    SlidingActionBarTexture0:SetTexture(nil)
    SlidingActionBarTexture1:SetTexture(nil)

    PossessBackground1:SetTexture(nil)
    PossessBackground2:SetTexture(nil)

    PossessButton1NormalTexture:SetTexture(nil)
    PossessButton2NormalTexture:SetTexture(nil)
end

local function MovePetActionButtons()
    local bar = CreateFrame("Frame", "MyPetActionBar", UIParent)
    bar:SetSize(30 * NUM_PET_ACTION_SLOTS + 8 * (NUM_PET_ACTION_SLOTS - 1), 30)
    bar:SetPoint("Bottom", 0, 143 - 30)

    for i = 1, NUM_PET_ACTION_SLOTS do
        local button = _G["PetActionButton" .. i]
        button:ClearAllPoints()
        button:SetPoint("Left", bar, (30 + 8) * (i - 1), 0)
    end

    bar:RegisterEvent("PET_BATTLE_OPENING_START")
    bar:RegisterEvent("PET_BATTLE_OPENING_DONE")
    bar:RegisterEvent("PET_BATTLE_CLOSE")

    bar:SetScript("OnEvent", function(self, event)
        if event == "PET_BATTLE_CLOSE" then
            self:Show()
        else
            self:Hide()
        end
    end)
end

local function SetSlideOutDuration()
    local duration = MainMenuBar.slideOut:GetAnimations():GetDuration()
    MultiBarLeft.slideOut:GetAnimations():SetDuration(duration)
    MultiBarRight.slideOut:GetAnimations():SetDuration(duration)
end

local function RightClickSelfCast()
    local bars = {
        MainMenuBarArtFrame,
        MultiBarBottomLeft,
        MultiBarBottomRight,
        MultiBarLeft,
        MultiBarRight,
        PossessBarFrame,
    }
    for i = 1, #bars do
        bars[i]:SetAttribute("unit2", "player")
    end
end

local function HideMacroName()
    local buttons = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarLeftButton",
        "MultiBarRightButton",
    }
    for i = 1, #buttons do
        for j = 1, NUM_ACTIONBAR_BUTTONS do
            _G[buttons[i] .. j .. "Name"]:Hide()
        end
    end
end

local function ResizeMultiBarRightButton()
    local size = 298 - 235 - 27
    for i = 1, NUM_ACTIONBAR_BUTTONS do
        _G["MultiBarRightButton" .. i]:SetSize(size, size)
        _G["MultiBarRightButton" .. i .. "NormalTexture"]:SetTexture(nil)
        _G["MultiBarRightButton" .. i .. "FloatingBG"]:Hide()
    end
end

local function MoveVehicleLeaveButton()
    local left = MultiBarBottomLeftButton12:GetRight()
    local right = MultiBarBottomRightButton7:GetLeft()
    local xOffset = (right - left) / 2
    hooksecurefunc("MainMenuBarVehicleLeaveButton_Update", function()
        MainMenuBarVehicleLeaveButton:ClearAllPoints()
        MainMenuBarVehicleLeaveButton:SetPoint("Center", MultiBarBottomLeftButton12, "Right", xOffset, 0)
    end)
end

local function ResizeOverrideExpBar()
    local width = 360
    hooksecurefunc("OverrideActionBar_CalcSize", function()
        OverrideActionBar.xpBar.XpMid:SetWidth(width - 16)
        OverrideActionBar.xpBar:SetWidth(width)
        for i = 1, 19 do
            local texture = OverrideActionBar.xpBar["XpDiv" .. i]
            if i <= 9 then
                texture:SetPoint("Left", floor(width / 10 * i - 7 / 2), 1)
            else
                texture:Hide()
            end
        end
    end)
end

hooksecurefunc("ActionButton_OnUpdate", function(self)
    if self.rangeTimer == TOOLTIP_UPDATE_TIME then
        local valid = IsActionInRange(self.action)
        if valid == false then
            self.icon:SetVertexColor(1, 0, 0)
        else
            ActionButton_UpdateUsable(self)
        end
    end
end)

SetSlideOutDuration()
ResizeMultiBarRightButton()
ResizeOverrideExpBar()
MovePossessBar()
MovePetActionButtons()
MoveExtraActionBar()
MoveVehicleLeaveButton()
RightClickSelfCast()
HideMacroName()
HideLayers()