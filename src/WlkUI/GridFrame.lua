local WIDTH = GetScreenWidth()
local HEIGHT = GetScreenHeight()
local lineSize = 2
local alpha = 0.6
local horizontalLines = {}
local verticalLines = {}

---@type Frame
local gridFrame = CreateFrame("Frame", "WlkGridFrame", UIParent)

---@param lines Texture[]
local function showLines(numBlocks, lines)
    local isHorizontal = lines == horizontalLines
    local width = isHorizontal and WIDTH or lineSize
    local height = isHorizontal and lineSize or HEIGHT
    local relativePoint = isHorizontal and "BOTTOM" or "LEFT"
    local offset = isHorizontal and (HEIGHT / numBlocks) or (WIDTH / numBlocks)
    for i = 1, numBlocks + 1 do
        local line = lines[i]
        if line then
            line:Show()
        else
            line = gridFrame:CreateTexture(nil, "BACKGROUND")
            line:SetSize(width, height)
            line:SetAlpha(alpha)
            tinsert(lines, line)
        end
        local xOffset = isHorizontal and 0 or ((i - 1) * offset)
        local yOffset = isHorizontal and ((i - 1) * offset) or 0
        line:SetPoint("CENTER", gridFrame, relativePoint, xOffset, yOffset)
        if i == numBlocks / 2 + 1 then
            line:SetColorTexture(1, 0, 0)
        else
            line:SetColorTexture(0, 0, 0)
        end
    end
    for i = numBlocks + 2, #lines do
        lines[i]:Hide()
    end
end

SLASH_TOGGLE_GRID1 = "/tg"

SlashCmdList["TOGGLE_GRID"] = function(arg)
    if gridFrame:IsShown() then
        gridFrame:Hide()
    else
        local numBlocksHorizontal, numBlocksVertical = strsplit(" ", arg)
        numBlocksHorizontal = tonumber(numBlocksHorizontal) or 64
        numBlocksVertical = tonumber(numBlocksVertical) or 36

        showLines(numBlocksVertical, horizontalLines)
        showLines(numBlocksHorizontal, verticalLines)
        gridFrame:Show()
    end
end

gridFrame:Hide()
gridFrame:SetAllPoints()
