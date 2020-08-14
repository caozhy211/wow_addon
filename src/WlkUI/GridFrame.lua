---@type Frame
local gridFrame = CreateFrame("Frame", "WlkGridFrame", UIParent)
gridFrame:Hide()
gridFrame:SetAllPoints()

local WIDTH = GetScreenWidth()
local HEIGHT = GetScreenHeight()

local thickness = 2
local alpha = 0.6
local numHorizSegment, numVertSegment, width, height, line
---@type Texture[]
local horizLines = {}
---@type Texture[]
local vertLines = {}

SLASH_TOGGLE_GRID1 = "/tg"

SlashCmdList["TOGGLE_GRID"] = function(arg)
    if gridFrame:IsShown() then
        gridFrame:Hide()
    else
        numHorizSegment, numVertSegment = strsplit(" ", arg)
        numHorizSegment = tonumber(numHorizSegment) or 64
        numVertSegment = tonumber(numVertSegment) or 36
        width = WIDTH / numHorizSegment
        height = HEIGHT / numVertSegment

        for i = 1, numVertSegment + 1 do
            line = horizLines[i]
            if line then
                line:Show()
            else
                line = gridFrame:CreateTexture("WlkGridFrameHorizLine" .. i, "BACKGROUND")
                tinsert(horizLines, line)
                line:SetSize(WIDTH, thickness)
                line:SetAlpha(alpha)
            end
            line:SetPoint("CENTER", gridFrame, "BOTTOM", 0, (i - 1) * height)
            line:SetColorTexture(GetTableColor(i == numVertSegment / 2 + 1 and RED_FONT_COLOR or BLACK_FONT_COLOR))
        end
        for i = numVertSegment + 2, #horizLines do
            horizLines[i]:Hide()
        end

        for i = 1, numHorizSegment + 1 do
            line = vertLines[i]
            if line then
                line:Show()
            else
                line = gridFrame:CreateTexture("WlkGridFrameVertLine" .. i, "BACKGROUND")
                tinsert(vertLines, line)
                line:SetSize(thickness, HEIGHT)
                line:SetAlpha(alpha)
            end
            line:SetPoint("CENTER", gridFrame, "LEFT", (i - 1) * width, 0)
            line:SetColorTexture(GetTableColor(i == numHorizSegment / 2 + 1 and RED_FONT_COLOR or BLACK_FONT_COLOR))
        end
        for i = numHorizSegment + 2, #vertLines do
            vertLines[i]:Hide()
        end

        gridFrame:Show()
    end
end
