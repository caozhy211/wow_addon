--- 首领框架底部相对屏幕底部偏移 315px，焦点减益框架顶部相对屏幕底部偏移 289px
local size = 315 - 1 - 289 - 1

---@type Frame
local markerFrame = CreateFrame("Frame", "WLK_MarkerFrame", UIParent)
--- 目标框架右边相对屏幕右边偏移 -540px，MicroButtonAndBagsBar 左边相对屏幕右边偏移 -298px，
markerFrame:SetSize(540 - 298 - 2, size)
markerFrame:SetPoint("BOTTOMRIGHT", -298 - 1, 289 + 1)
markerFrame:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark", })
markerFrame:SetAlpha(0)

---@param self Frame
markerFrame:SetScript("OnEnter", function(self)
    self:SetAlpha(1)
end)

---@param self Frame
markerFrame:SetScript("OnLeave", function(self)
    self:SetAlpha(0)
end)

local spacing = (markerFrame:GetWidth() - (NUM_WORLD_RAID_MARKERS + 1) * size) / (NUM_WORLD_RAID_MARKERS + 1 - 1)

--- 创建标记按钮
local function CreateMarkerButton(index)
    ---@type Button
    local btn = CreateFrame("Button", nil, markerFrame, "SecureActionButtonTemplate")
    btn:SetSize(size, size)
    btn:SetPoint("RIGHT", (size + spacing) * -index, 0)

    if index == 0 then
        btn:SetNormalTexture("Interface/Buttons/UI-GroupLoot-Pass-Up")
        btn:SetAttribute("marker", 0)
    else
        btn:SetNormalTexture("Interface/TargetingFrame/UI-RaidTargetingIcon_" .. index)
        btn:SetAttribute("marker", WORLD_RAID_MARKER_ORDER[#WORLD_RAID_MARKER_ORDER + 1 - index])
    end

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    -- “Ctrl + 鼠标左键” 放置世界标记，点击移除按钮无效
    btn:SetAttribute("ctrl-type1", "worldmarker")
    btn:SetAttribute("action1", "set")
    -- 鼠标右键清除世界标记，点击移除按钮清除全部世界标记
    btn:SetAttribute("*type2", "worldmarker")
    btn:SetAttribute("action2", "clear")
    -- 使用 SetScript 方法会使设置的点击属性失效
    btn:HookScript("OnClick", function(_, button)
        if button == "LeftButton" then
            if not IsModifierKeyDown() then
                -- 鼠标左键标记目标
                SetRaidTarget("target", index)
            elseif IsShiftKeyDown() then
                -- “Shift + 鼠标左键” 标记焦点
                SetRaidTarget("focus", index)
            elseif IsAltKeyDown() then
                -- “Alt + 鼠标左键” 标记自己
                SetRaidTarget("player", index)
            end
        end
    end)

    btn:SetScript("OnEnter", function()
        markerFrame:SetAlpha(1)
    end)

    btn:SetScript("OnLeave", function()
        markerFrame:SetAlpha(0)
    end)
end

for i = 0, NUM_WORLD_RAID_MARKERS do
    CreateMarkerButton(i)
end
