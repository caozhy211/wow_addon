local align = CreateFrame("Frame", "AlignFrame", UIParent)

align:SetAllPoints()
align:Hide()

local width = GetScreenWidth() / 64
local height = GetScreenHeight() / 36

-- 橫線
for i = 0, 64 do
    local texture = align:CreateTexture(nil, "Background")
    texture:SetColorTexture(i == 32 and 1 or 0, 0, 0, 0.5)
    texture:SetPoint("TopLeft", i * width - 1, 0)
    texture:SetPoint("BottomRight", align, "BottomLeft", i * width + 1, 0)
end

-- 豎線
for i = 0, 36 do
    local texture = align:CreateTexture(nil, "Background")
    texture:SetColorTexture(i == 18 and 1 or 0, 0, 0, 0.5)
    texture:SetPoint("TopLeft", 0, -(i * height - 1))
    texture:SetPoint("BottomRight", align, "TopRight", 0, -(i * height + 1))
end

SlashCmdList["ALIGN"] = function()
    if align:IsShown() then
        align:Hide()
    else
        align:Show()
    end
end

SLASH_ALIGN1 = "/al"