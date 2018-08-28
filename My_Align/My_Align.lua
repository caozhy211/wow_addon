local align = CreateFrame("Frame", "AlignFrame", UIParent)
align:SetAllPoints(UIParent)
align.width = GetScreenWidth() / 64
align.height = GetScreenHeight() / 36
align:Hide()
SlashCmdList["ALIGN"] = function()
    if align:IsShown() then
        align:Hide()
    else
        -- 豎線
        for i = 0, 64 do
            local texture = align:CreateTexture(nil, "Background")
            if i == 32 then
                texture:SetColorTexture(1, 0, 0, 0.5)
            else
                texture:SetColorTexture(0, 0, 0, 0.5)
            end
            texture:SetPoint(
                    "TopLeft", align, "TopLeft", i * align.width - 1, 0)
            texture:SetPoint(
                    "BottomRight", align, "BottomLeft", i * align.width + 1, 0)
        end
        -- 橫線
        for i = 0, 36 do
            local texture = align:CreateTexture(nil, "Background")
            if i == 18 then
                texture:SetColorTexture(1, 0, 0, 0.5)
            else
                texture:SetColorTexture(0, 0, 0, 0.5)
            end
            texture:SetPoint(
                    "TopLeft", align, "TopLeft", 0, -(i * align.height - 1))
            texture:SetPoint(
                    "BottomRight", align, "TopRight", 0, -(i * align.height + 1))
        end
        align:Show()
    end
end
SLASH_ALIGN1 = "/al"