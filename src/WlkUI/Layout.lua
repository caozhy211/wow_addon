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

local framesToBeUpdate = {}
local spacing = 2
local rows = 4

---@param frame Frame
local function UpdateCompactRaidGroupLayout(frame)
    local name = frame:GetName()
    local totalHeight = frame.title:GetHeight()
    local totalWidth = 0
    ---@type Button
    local frame1 = _G[frame:GetName() .. "Member1"]
    frame1:ClearAllPoints()

    if CUF_HORIZONTAL_GROUPS then
        frame1:SetPoint("TOPLEFT", 0, -totalHeight - spacing)
        for i = 2, MEMBERS_PER_RAID_GROUP do
            ---@type Button
            local unitFrame = _G[name .. "Member" .. i]
            unitFrame:ClearAllPoints()
            unitFrame:SetPoint("LEFT", _G[name .. "Member" .. (i - 1)], "RIGHT", spacing, 0)
        end
        totalHeight = totalHeight + spacing + frame1:GetHeight()
        totalWidth = totalWidth + MEMBERS_PER_RAID_GROUP * frame1:GetWidth() + (MEMBERS_PER_RAID_GROUP - 1) * spacing
    else
        local id = frame:GetID()
        if id > 0 and (id % rows ~= 1) then
            frame.title:ClearAllPoints()
            frame.title:SetPoint("TOP", 0, -spacing)
            totalHeight = totalHeight + spacing
        end
        frame1:SetPoint("TOPRIGHT", 0, -totalHeight - spacing)
        for i = 2, MEMBERS_PER_RAID_GROUP do
            ---@type Button
            local unitFrame = _G[name .. "Member" .. i]
            unitFrame:ClearAllPoints()
            unitFrame:SetPoint("TOP", _G[name .. "Member" .. (i - 1)], "BOTTOM", 0, -spacing)
        end
        totalHeight = totalHeight + (frame1:GetHeight() + spacing) * MEMBERS_PER_RAID_GROUP
        totalWidth = totalWidth + frame1:GetWidth() + spacing
    end

    if frame.borderFrame:IsShown() then
        totalWidth = totalWidth + 12
        totalHeight = totalHeight + 4
    end
    frame:SetSize(totalWidth, totalHeight)
end

ObjectiveTrackerFrame:SetMovable(true)
ObjectiveTrackerFrame:SetUserPlaced(true)

---@type Frame
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(_, event)
    eventFrame:UnregisterEvent(event)
    if event == "PLAYER_LOGIN" then
        ObjectiveTrackerFrame:ClearAllPoints()
        ObjectiveTrackerFrame:SetPoint("TOPLEFT", GetScreenWidth() + OFFSET_X1 + WIDTH2, OFFSET_Y1)
        ObjectiveTrackerFrame:SetPoint("BOTTOMRIGHT", OFFSET_X1 + WIDTH1 + WIDTH2, OFFSET_Y2)
        ObjectiveTrackerFrame:SetMovable(false)
    elseif event == "PLAYER_REGEN_ENABLED" then
        for _, frame in ipairs(framesToBeUpdate) do
            UpdateCompactRaidGroupLayout(frame)
        end
        wipe(framesToBeUpdate)
    end
end)

--- LossOfControlFrame.RedLineBottom 的高度
local HEIGHT1 = 27
local scale = 0.75
LossOfControlFrame:SetScale(scale)
LossOfControlFrame:ClearAllPoints()
LossOfControlFrame:SetPoint("BOTTOM", 0, (142 + HEIGHT1 * scale) / scale)
LossOfControlFrame.SetPoint = nop

--- WlkTargetFrameSpellBar.borderTop 顶部相对 UIParent 底部的偏移值
local offsetY1 = 316

TalkingHeadFrame:ClearAllPoints()
TalkingHeadFrame:SetPoint("BOTTOMRIGHT", OFFSET_X1, offsetY1)
TalkingHeadFrame.SetPoint = nop

--- WlkPetFrame 顶部相对 UIParent 底部的偏移值
local offsetY2 = 142

ArcheologyDigsiteProgressBar:ClearAllPoints()
ArcheologyDigsiteProgressBar:SetPoint("BOTTOM", 0, offsetY2)
ArcheologyDigsiteProgressBar.SetPoint = nop

hooksecurefunc("CompactRaidGroup_UpdateLayout", function(frame)
    if InCombatLockdown() then
        framesToBeUpdate[#framesToBeUpdate + 1] = frame
        eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        UpdateCompactRaidGroupLayout(frame)
    end
end)

---@param frame Frame
local function HideFrame(frame)
    frame:Hide()
    frame:UnregisterAllEvents()
end

for i = 1, MAX_BOSS_FRAMES do
    HideFrame(_G["Boss" .. i .. "TargetFrame"])
end

HideFrame(LootFrame)
HideFrame(AlertFrame)
HideFrame(TargetFrame)
HideFrame(FocusFrame)

PlayerFrame:Hide()
