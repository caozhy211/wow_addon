--- ScrollBar 和 ScrollFrame 的水平间距
local SPACING1 = 6
--- ScrollBar 的宽度
local WIDTH1 = 16
--- DialogBoxButton 和 DialogBox 的垂直间距
local SPACING2 = 16
--- DialogBoxButton 的高度
local HEIGHT1 = 32

--- DialogBoxButton 和 ScrollFrame 的垂直间距
local spacing = 5
local padding = SPACING2
local width = 500
local height = 300

---@type Frame
local exportFrame = CreateFrame("Frame", "WlkExportFrame", UIParent, "DialogBoxFrame")
exportFrame:SetSize(width + SPACING1 + WIDTH1 + padding * 2, height + SPACING2 + HEIGHT1 + spacing + padding * 2)
exportFrame:SetPoint("CENTER")

---@type ScrollFrame
local scrollFrame = CreateFrame("ScrollFrame", "WlkExportFrameTextContainer", exportFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", padding, -padding)
scrollFrame:SetPoint("BOTTOMRIGHT", -padding - SPACING1 - WIDTH1, SPACING2 + HEIGHT1 + spacing)

---@type EditBox
local editBox = CreateFrame("EditBox", "WlkExportFrameEditBox", scrollFrame)
editBox:SetMultiLine(true)
editBox:SetAutoFocus(false)
editBox:SetSize(width, height)
ScrollingEdit_OnLoad(editBox)
editBox:SetScript("OnUpdate", function(self, elapsed)
    ScrollingEdit_OnUpdate(self, elapsed, scrollFrame)
end)
---@param self EditBox
editBox:SetScript("OnEditFocusGained", function(self)
    self:HighlightText(0)
end)
editBox:SetScript("OnEscapePressed", EditBox_ClearFocus)
editBox:SetFontObject("GameFontHighlight")

scrollFrame:SetScrollChild(editBox)

local function ShowExportFrame(text)
    editBox:SetText(text)
    exportFrame:Show()
    editBox:SetFocus()
end

SLASH_EXPORT_FRAME_NAME1 = "/efn"

---@type UIObject
local object

SlashCmdList["EXPORT_FRAME_NAME"] = function()
    UIParentLoadAddOn("Blizzard_DebugTools")
    object = FrameStackTooltip.highlightFrame
    if object then
        ShowExportFrame(object:GetDebugName())
    end
end
