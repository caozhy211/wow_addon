local worldRaidMarkerMacroValues = {
    "/cwm 0",
    "/cwm 5\n/wm 5",
    "/cwm 6\n/wm 6",
    "/cwm 3\n/wm 3",
    "/cwm 2\n/wm 2",
    "/cwm 7\n/wm 7",
    "/cwm 1\n/wm 1",
    "/cwm 4\n/wm 4",
    "/cwm 8\n/wm 8",
}

local raidMarkers = CreateFrame("Frame", "MyRaidMarkerFrame", UIParent)
raidMarkers:SetSize(240, 24)
raidMarkers:SetPoint("BottomLeft", 1380 + 1, 257 + 1)
raidMarkers:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
raidMarkers:SetBackdropColor(0, 0, 0, 0.2)
raidMarkers:SetAlpha(0)

raidMarkers:SetScript("OnEnter", function(self)
    self:SetAlpha(1)
end)

raidMarkers:SetScript("OnLeave", function(self)
    self:SetAlpha(0)
end)

local function CreateRaidMarkerButton(id)
    local button = CreateFrame("Button", nil, raidMarkers, "SecureActionButtonTemplate")
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

    button:SetAttribute("type2", "macro")
    button:SetAttribute("macrotext", worldRaidMarkerMacroValues[id + 1])

    button:SetScript("OnEnter", function()
        raidMarkers:SetAlpha(1)
    end)

    button:SetScript("OnLeave", function()
        raidMarkers:SetAlpha(0)
    end)

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button:HookScript("OnClick", function(_, mouse)
        if mouse == "LeftButton" then
            SetRaidTarget("target", id)
        end
    end)

    return button
end

for i = 0, NUM_RAID_ICONS do
    CreateRaidMarkerButton(i)
end