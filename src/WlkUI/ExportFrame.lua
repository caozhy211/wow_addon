--- ScrollBar 和 ScrollFrame 的水平间距
local SPACING = 6
--- DialogBoxButton 底部相对 DialogBox 底部的偏移
local OFFSET_Y = 16
--- ScrollBar 的宽度
local WIDTH = 16
--- DialogBoxButton 的高度
local HEIGHT = 32
local width = 500
local height = 300
local frameWidth = width + SPACING + WIDTH + OFFSET_Y * 2
local frameHeight = height + SPACING + HEIGHT + OFFSET_Y * 2
local xOffset1 = OFFSET_Y
local yOffset1 = -OFFSET_Y
local xOffset2 = -OFFSET_Y - SPACING - WIDTH
local yOffset2 = OFFSET_Y + HEIGHT + SPACING
local ncText
local ncTbl = {}
local chatMessages = {}

---@type Frame
local exportFrame = CreateFrame("Frame", "WlkExportFrame", UIParent, "DialogBoxFrame")
---@type ScrollFrame
local scrollFrame = CreateFrame("ScrollFrame", "WlkExportScrollFrame", exportFrame, "UIPanelScrollFrameTemplate")
---@type EditBox
local editBox = CreateFrame("EditBox", "WlkExportEditBox", scrollFrame)
---@type Button
local exportButton = CreateFrame("Button", "WlkExportButton")

local function showExportFrame(text)
    exportFrame:Show()
    editBox:SetText(text)
    editBox:SetFocus()
    editBox:SetCursorPosition(0)
end

local function canChangeMessage(arg, id)
    if id and arg == "" then
        return id
    end
end

local function isProtectedMessage(message)
    return message and (message ~= gsub(message, "(:?|?)|K(.-)|k", canChangeMessage))
end

SLASH_NUMERIC_CONSTANTS1 = "/nc"
SLASH_EXPORT_CHAT1 = "/ec"

SlashCmdList["NUMERIC_CONSTANTS"] = function()
    if ncText == nil then
        wipe(ncTbl)
        local _, build = GetBuildInfo()
        tinsert(ncTbl, "--- version: " .. build .. "\n\nEnum = {")

        for name, tbl in pairs(Enum) do
            if not strmatch(name, "Meta$") then
                tinsert(ncTbl, "    " .. name .. " = {")
                for key, value in pairs(tbl) do
                    tinsert(ncTbl, format("        %s = %s,", key, value))
                end
                tinsert(ncTbl, "    },")
            end
        end
        tinsert(ncTbl, "}\n")

        for key, value in pairs(_G) do
            if (strmatch(key, "^LE_") or strmatch(key, "_LE_")) and not strmatch(key, "_ERR_") then
                tinsert(ncTbl, key .. " = " .. value)
            end
        end

        ncText = table.concat(ncTbl, "\n")
    end
    showExportFrame(ncText)
end
SlashCmdList["EXPORT_CHAT"] = function()
    wipe(chatMessages)
    for i = 1, SELECTED_CHAT_FRAME:GetNumMessages() do
        local message = SELECTED_CHAT_FRAME:GetMessageInfo(i)
        if not isProtectedMessage(message) then
            tinsert(chatMessages, message)
        end
    end
    showExportFrame(table.concat(chatMessages, "\n"))
end

exportFrame:SetSize(frameWidth, frameHeight)
exportFrame:SetPoint("CENTER")

scrollFrame:SetPoint("TOPLEFT", xOffset1, yOffset1)
scrollFrame:SetPoint("BOTTOMRIGHT", xOffset2, yOffset2)
scrollFrame:SetScrollChild(editBox)

editBox:SetFontObject("SystemFont_Shadow_Med1")
editBox:SetMultiLine(true)
editBox:SetAutoFocus(false)
editBox:SetSize(width, height)
editBox:SetScript("OnCursorChanged", ScrollingEdit_OnCursorChanged)
editBox:SetScript("OnUpdate", function(self, elapsed)
    ScrollingEdit_OnUpdate(self, elapsed, scrollFrame)
end)
editBox:SetScript("OnEditFocusGained", EditBox_HighlightText)
editBox:SetScript("OnEscapePressed", function()
    exportFrame:Hide()
end)

exportButton:RegisterForClicks("LeftButtonUp")
exportButton:SetScript("OnClick", function()
    ---@type UIObject
    local obj = FrameStackTooltip.highlightFrame
    if obj then
        showExportFrame(obj:GetDebugName())
        FrameStackTooltip_Hide(FrameStackTooltip)
    end
end)
exportButton:RegisterEvent("PLAYER_LOGIN")
exportButton:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        SetBindingClick("F5", "WlkExportButton")
    end
end)
