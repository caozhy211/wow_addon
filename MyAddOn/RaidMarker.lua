local worldRaidMarkerColors = {
    { 1, 1, 1 },
    { 1, 0, 0 },
    { 0, 0, 1 },
    { 0.75, 0.75, 0.75 },
    { 0, 1, 0 },
    { 0.5, 0, 0.5 },
    { 1, 0.65, 0 },
    { 1, 1, 0 },
    { 0, 0, 0 },
}

local worldRaidMarkerMacroValues = {
    "/cwm 8\n/wm 8",
    "/cwm 4\n/wm 4",
    "/cwm 1\n/wm 1",
    "/cwm 7\n/wm 7",
    "/cwm 2\n/wm 2",
    "/cwm 3\n/wm 3",
    "/cwm 6\n/wm 6",
    "/cwm 5\n/wm 5",
    "/cwm 0",
}

local raidMarkers = CreateFrame("Frame", "MyRaidMarkers", UIParent)
raidMarkers:SetSize(240, 24)
raidMarkers:SetPoint("BottomLeft", 1380 + 1, 257 + 1)
raidMarkers:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
raidMarkers:SetBackdropColor(0, 0, 0, 0.2)
raidMarkers:SetAlpha(0)
raidMarkers:SetFrameStrata("High")

local worldRaidMarkers = CreateFrame("Frame", "MyWorldRaidMarkers", UIParent)
worldRaidMarkers:SetSize(240, 24)
worldRaidMarkers:SetPoint("BottomLeft", 1380 + 1, 257 + 1)
worldRaidMarkers:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
worldRaidMarkers:SetBackdropColor(0, 0, 0, 0.2)
worldRaidMarkers:SetAlpha(0)

raidMarkers:SetScript("OnEnter", function(self)
    self:SetAlpha(1)
end)

raidMarkers:SetScript("OnLeave", function(self)
    self:SetAlpha(0)
end)

raidMarkers:SetScript("OnMouseWheel", function(self)
    if not UnitInParty("player") and not UnitInRaid("player") then
        return
    end
    self:Hide()
    worldRaidMarkers:SetAlpha(1)
end)

worldRaidMarkers:SetScript("OnEnter", function(self)
    self:SetAlpha(1)
end)

worldRaidMarkers:SetScript("OnLeave", function(self)
    self:SetAlpha(0)
end)

worldRaidMarkers:SetScript("OnMouseWheel", function(self)
    self:SetAlpha(0)
    raidMarkers:Show()
end)

local function CreateRaidMarkerButton(id)
    local button = CreateFrame("Button", nil, raidMarkers)
    button:SetSize(24, 24)
    button:SetPoint("Left", (NUM_RAID_ICONS - id) * (24 + 3) + 1, 0)

    if id == 0 then
        button:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    else
        button:SetNormalTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        local left = mod((id - 1) / 4, 1)
        local right = left + 0.25
        local top = floor((id - 1) / 4) * 0.25
        local bottom = top + 0.25
        button:GetNormalTexture():SetTexCoord(left, right, top, bottom)
    end

    button:SetScript("OnEnter", function()
        raidMarkers:SetAlpha(1)
    end)

    button:SetScript("OnLeave", function()
        raidMarkers:SetAlpha(0)
    end)

    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", function()
        SetRaidTarget("target", id)
    end)

    return button
end

for i = 0, NUM_RAID_ICONS do
    CreateRaidMarkerButton(i)
end

local function CreateWorldRaidMarkerButton(id)
    local button = CreateFrame("Button", nil, worldRaidMarkers, "SecureActionButtonTemplate")
    button:SetSize(24, 24)
    button:SetPoint("Left", id * (24 + 3) + 1, 0)

    button:SetNormalTexture("Interface\\ChatFrame\\ChatFrameBackground")
    button:GetNormalTexture():SetColorTexture(unpack(worldRaidMarkerColors[id + 1]))

    button:SetAttribute("type1", "macro")
    button:SetAttribute("macrotext", worldRaidMarkerMacroValues[id + 1])

    button:SetScript("OnEnter", function()
        worldRaidMarkers:SetAlpha(1)
    end)

    button:SetScript("OnLeave", function()
        worldRaidMarkers:SetAlpha(0)
    end)
end

for i = 0, NUM_WORLD_RAID_MARKERS do
    CreateWorldRaidMarkerButton(i)
end
