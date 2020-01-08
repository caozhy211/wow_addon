---@type Frame
local grid = CreateFrame("Frame", "WLK_GridFrame", UIParent)
grid:SetAllPoints()
grid:Hide()

local height = grid:GetHeight()
local width = grid:GetWidth()
--- 方格的大小
local size = 30
--- 水平线个数，四舍五入取整
local numHorizontal = floor(height / size + 0.5)
--- 垂直线个数，四舍五入取整
local numVertical = floor(width / size + 0.5)
local lineSize = 2

for i = 0, numHorizontal do
    ---@type Texture
    local line = grid:CreateTexture(nil, "BACKGROUND")
    line:SetSize(width, lineSize)
    line:SetPoint("BOTTOM", 0, size * i - lineSize / 2)
    line:SetAlpha(0.6)
    line:SetColorTexture(GetTableColor(i == numHorizontal / 2 and RED_FONT_COLOR or BLACK_FONT_COLOR))
end

for i = 0, numVertical do
    ---@type Texture
    local line = grid:CreateTexture(nil, "BACKGROUND")
    line:SetSize(lineSize, height)
    line:SetPoint("LEFT", size * i - lineSize / 2, 0)
    line:SetAlpha(0.6)
    line:SetColorTexture(GetTableColor(i == numVertical / 2 and RED_FONT_COLOR or BLACK_FONT_COLOR))
end

SlashCmdList["GRID"] = function()
    if grid:IsShown() then
        grid:Hide()
    else
        grid:Show()
    end
end
SLASH_GRID1 = "/grid"
