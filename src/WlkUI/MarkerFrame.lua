local numMarkers = NUM_WORLD_RAID_MARKERS + 1
local size = 25
local frameWidth = size
local frameHeight = numMarkers * size

---@type Frame
local markerFrame = CreateFrame("Frame", "WlkMarkerFrame", UIParent)

---@param self Button
local function buttonOnClick(self, button)
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

local function buttonOnEnter()
    markerFrame:SetAlpha(1)
end

local function buttonOnLeave()
    markerFrame:SetAlpha(0)
end

markerFrame:SetSize(frameWidth, frameHeight)
markerFrame:SetPoint("BOTTOMRIGHT", 0, 88)
markerFrame:SetAlpha(0)

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
    button:SetAttribute("*type2", "worldmarker")
    button:SetAttribute("action1", "set")
    button:SetAttribute("action2", "clear")
    button:SetScript("OnEnter", buttonOnEnter)
    button:SetScript("OnLeave", buttonOnLeave)
    button:HookScript("OnClick", buttonOnClick)
end
