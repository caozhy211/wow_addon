--- VehicleSeatIndicator 底部相对 UIParent 顶部的偏移值
local OFFSET_Y1 = -320
--- MicroButtonAndBagsBar 左边相对 UIParent 右边的偏移值
local OFFSET_X1 = -298
--- MicroButtonAndBagsBar 顶部相对 UIParent 底部的偏移值
local OFFSET_Y2 = 88
--- ObjectiveTrackerFrame 的宽度
local WIDTH1 = 235
--- QuestPOIButtonNormalTexture 的宽度
local WIDTH2 = 32

ObjectiveTrackerFrame:SetMovable(true)
ObjectiveTrackerFrame:SetUserPlaced(true)

---@type Frame
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(_, event)
    eventFrame:UnregisterEvent(event)
    ObjectiveTrackerFrame:ClearAllPoints()
    ObjectiveTrackerFrame:SetPoint("TOPLEFT", GetScreenWidth() + OFFSET_X1 + WIDTH2, OFFSET_Y1)
    ObjectiveTrackerFrame:SetPoint("BOTTOMRIGHT", OFFSET_X1 + WIDTH1 + WIDTH2, OFFSET_Y2)
    ObjectiveTrackerFrame:SetMovable(false)
end)

--- LossOfControlFrame.RedLineBottom 的高度
local HEIGHT1 = 27
local scale = 0.75
LossOfControlFrame:SetScale(scale)
LossOfControlFrame:ClearAllPoints()
LossOfControlFrame:SetPoint("BOTTOM", 0, (142 + HEIGHT1 * scale) / scale)
LossOfControlFrame.SetPoint = nop

TalkingHeadFrame:ClearAllPoints()
TalkingHeadFrame:SetPoint("TOPLEFT")
TalkingHeadFrame.SetPoint = nop

---@param frame Frame
local function HideFrame(frame)
    frame:Hide()
    frame:UnregisterAllEvents()
end

for i = 1, MAX_BOSS_FRAMES do
    HideFrame(_G[strconcat("Boss", i, "TargetFrame")])
end
