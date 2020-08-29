---@type Frame
local gridFrame = CreateFrame("Frame", "WlkGridFrame", UIParent)
gridFrame:Hide()
gridFrame:SetAllPoints()

local WIDTH = GetScreenWidth()
local HEIGHT = GetScreenHeight()

local thickness = 2
local alpha = 0.6
local horizLines = {}
local vertLines = {}
local redR, redG, redB = GetTableColor(RED_FONT_COLOR)
local blackR, blackG, blackB = GetTableColor(BLACK_FONT_COLOR)

---@param lines Texture[]
local function ShowLines(numSegments, lines)
    local isHoriz = lines == horizLines
    local width = isHoriz and WIDTH or thickness
    local height = isHoriz and thickness or HEIGHT
    local relativePoint = isHoriz and "BOTTOM" or "LEFT"
    local offset = isHoriz and (HEIGHT / numSegments) or (WIDTH / numSegments)
    for i = 1, numSegments + 1 do
        local line = lines[i]
        if line then
            line:Show()
        else
            line = gridFrame:CreateTexture(nil, "BACKGROUND")
            lines[#lines + 1] = line
            line:SetSize(width, height)
            line:SetAlpha(alpha)
        end
        local offsetX = isHoriz and 0 or ((i - 1) * offset)
        local offsetY = isHoriz and ((i - 1) * offset) or 0
        line:SetPoint("CENTER", gridFrame, relativePoint, offsetX, offsetY)
        if i == numSegments / 2 + 1 then
            line:SetColorTexture(redR, redG, redB)
        else
            line:SetColorTexture(blackR, blackG, blackB)
        end
    end
    for i = numSegments + 2, #lines do
        lines[i]:Hide()
    end
end

SLASH_TOGGLE_GRID1 = "/tg"

SlashCmdList["TOGGLE_GRID"] = function(arg)
    if gridFrame:IsShown() then
        gridFrame:Hide()
    else
        local numHorizSegment, numVertSegment = strsplit(" ", arg)
        numHorizSegment = tonumber(numHorizSegment) or 64
        numVertSegment = tonumber(numVertSegment) or 36

        ShowLines(numVertSegment, horizLines)
        ShowLines(numHorizSegment, vertLines)
        gridFrame:Show()
    end
end
