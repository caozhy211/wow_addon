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

SlashCmdList["EXPORT_FRAME_NAME"] = function()
    ---@type UIObject
    local object = FrameStackTooltip.highlightFrame
    if object then
        ShowExportFrame(object:GetDebugName())
    end
end

SLASH_EXPORT_SYSTEM_API1 = "/esa"

local apiText
local events = {}
local EVENT_FUNCTION_FORMAT = strconcat("---@alias EventType string |%s\n\n",
        "---@param event EventType\nfunction Frame:RegisterEvent(event) end\n\n",
        "---@param event EventType\nfunction Frame:RegisterUnitEvent(event, ...) end\n\n",
        "---@param event EventType\nfunction Frame:UnregisterEvent(event) end\n\n",
        "---@param event EventType\nfunction Frame:IsEventRegistered(event) end")
local enums = {}
local numericConstants = {}
local _, build = GetBuildInfo()

SlashCmdList["EXPORT_SYSTEM_API"] = function()
    if apiText == nil then
        for _, apiInfo in ipairs(APIDocumentation.systems) do
            for _, eventInfo in ipairs(apiInfo.Events) do
                tinsert(events, format("'\"%s\"'", eventInfo.LiteralName))
            end

            for _, tableInfo in ipairs(apiInfo.Tables) do
                if tableInfo.Type == "Enumeration" then
                    tinsert(enums, format("    %s = {", tableInfo.Name))
                    for _, fieldInfo in ipairs(tableInfo.Fields) do
                        tinsert(enums, format("        %s = %s,", fieldInfo.Name, fieldInfo.EnumValue))
                    end
                    tinsert(enums, "    },")
                end
            end
        end

        tinsert(enums, 1, "Enum = {")
        tinsert(enums, "}")

        for name, value in pairs(_G) do
            if (strmatch(name, "^LE_") or strmatch(name, "_LE_")) and not strmatch(name, "GAME_ERR") then
                tinsert(numericConstants, format("%s = %s", name, value))
            end
        end

        apiText = format("--- version: %s\n\n%s\n\n%s\n\n%s", build, format(EVENT_FUNCTION_FORMAT,
                table.concat(events, "|")), table.concat(enums, "\n"), table.concat(numericConstants, "\n"))
    end
    ShowExportFrame(apiText)
end

SLASH_EXPORT_CHAT1 = "/ec"

local allMessages = {}

SlashCmdList["EXPORT_CHAT"] = function()
    local message
    ---@param line FontString
    for _, line in ipairs({ SELECTED_CHAT_FRAME.FontStringContainer:GetRegions() }) do
        message = line:GetText()
        if message and MouseIsOver(line) and line:IsVisible() then
            return ShowExportFrame(message)
        end
    end

    wipe(allMessages)
    for i = 1, SELECTED_CHAT_FRAME:GetNumMessages() do
        message = SELECTED_CHAT_FRAME:GetMessageInfo(i)
        tinsert(allMessages, message)
    end
    ShowExportFrame(table.concat(allMessages, "\n"))
end

