local lineSize = 1
local squareSize = 30
local grid = CreateFrame("Frame", "MyGridFrame", UIParent)
local numHorizontal, numVertical

grid:Hide()
grid:SetAllPoints()
numHorizontal = floor(grid:GetHeight() / squareSize + 0.5)
numVertical = floor(grid:GetWidth() / squareSize + 0.5)

for i = 0, numHorizontal do
    local line = grid:CreateTexture(nil, "Background")
    line:SetSize(grid:GetWidth(), lineSize)
    line:SetPoint("Bottom", 0, squareSize * i)
    line:SetColorTexture(i == numHorizontal / 2 and 1 or 0, 0, 0, 0.5)
end

for i = 0, numVertical do
    local line = grid:CreateTexture(nil, "Background")
    line:SetSize(lineSize, grid:GetHeight())
    line:SetPoint("Left", squareSize * i, 0)
    line:SetColorTexture(i == numVertical / 2 and 1 or 0, 0, 0, 0.5)
end

SLASH_GRID1 = "/grid"
SlashCmdList["GRID"] = function()
    if grid:IsShown() then
        grid:Hide()
    else
        grid:Show()
    end
end