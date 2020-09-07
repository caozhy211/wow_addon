local numMarker = NUM_WORLD_RAID_MARKERS + 1
local height = 322 - 88
local size = height / numMarker

---@type Frame
local markerFrame = CreateFrame("Frame", "WlkMarkerFrame", UIParent)

markerFrame:SetSize(size, height)
markerFrame:SetPoint("BOTTOMRIGHT", 0, 88)
markerFrame:SetAlpha(0)

---@param self Button
local function HookMarkerButtonOnClick(self, button)
    local id = self:GetID()
    if button == "LeftButton" then
        if not IsModifierKeyDown() then
            SetRaidTarget("target", id)
        elseif IsShiftKeyDown() then
            SetRaidTarget("focus", id)
        elseif IsAltKeyDown() then
            SetRaidTarget("player", id)
        end
    end
end

local function MarkerButtonOnEnter()
    markerFrame:SetAlpha(1)
end

local function MarkerButtonOnLeaver()
    markerFrame:SetAlpha(0)
end

for i = 0, NUM_WORLD_RAID_MARKERS do
    ---@type Button
    local button = CreateFrame("Button", "WlkMarkerButton" .. i, markerFrame, "SecureActionButtonTemplate")

    button:SetID(i)
    button:SetSize(size, size)
    button:SetPoint("BOTTOM", 0, size * i)
    if i == 0 then
        button:SetNormalTexture("Interface/Buttons/UI-GroupLoot-Pass-Up")
        button:SetAttribute("marker", 0)
    else
        button:SetNormalTexture("Interface/TargetingFrame/UI-RaidTargetingIcon_" .. i)
        button:SetAttribute("marker", WORLD_RAID_MARKER_ORDER[#WORLD_RAID_MARKER_ORDER + 1 - i])
    end
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetAttribute("ctrl-type1", "worldmarker")
    button:SetAttribute("action1", "set")
    button:SetAttribute("*type2", "worldmarker")
    button:SetAttribute("action2", "clear")
    button:HookScript("OnClick", HookMarkerButtonOnClick)
    button:SetScript("OnEnter", MarkerButtonOnEnter)
    button:SetScript("OnLeave", MarkerButtonOnLeaver)
end
