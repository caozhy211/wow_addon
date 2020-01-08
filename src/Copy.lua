---@type Frame
local copyFrame = CreateFrame("Frame", "WLK-CopyFrame", UIParent, "DialogBoxFrame")
--- DialogBoxButton 底部相对 DialogBoxFrame 底部偏移 16px，DialogBoxButton 的高度是 32px，ScrollBar 左边相对 ScrollFrame 右
--- 边偏移 6px，ScrollBar 的宽度是 16px
copyFrame:SetSize(350 + 16 * 2 + 6 + 16, 200 + 16 * 2 + 5 + 32)
copyFrame:SetPoint("CENTER")
copyFrame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/PVPFrame/UI-Character-PVP-Highlight",
    edgeSize = 16,
    insets = { left = 8, right = 8, top = 8, bottom = 8, },
})
local _, class = UnitClass("player")
local r, g, b = GetClassColor(class)
copyFrame:SetBackdropBorderColor(r, g, b, 0.8)

---@type ScrollFrame
local scrollFrame = CreateFrame("ScrollFrame", nil, copyFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 16, -16)
scrollFrame:SetPoint("BOTTOMRIGHT", -(16 + 6 + 16), 5 + 32 + 16)

---@type EditBox
local editBox = CreateFrame("EditBox", nil, scrollFrame)
editBox:SetSize(scrollFrame:GetSize())
editBox:SetFontObject("ChatFontNormal")
editBox:SetMultiLine(true)
editBox:SetAutoFocus(false)
editBox:SetScript("OnEscapePressed", editBox.ClearFocus)

scrollFrame:SetScrollChild(editBox)

--- 显示复制窗口
---@param contents string
local function ShowCopyFrame(contents)
    copyFrame:Show()
    editBox:SetText(contents)
    editBox:HighlightText()
    editBox:SetFocus()
end

--- 使用快捷键显示 fstack 选中的对象名称
tinsert(FrameStackTooltip.commandKeys, KeyCommand_Create(function()
    ---@type Object
    local object = FrameStackTooltip.highlightFrame
    if object then
        local name = object:GetDebugName()
        ShowCopyFrame(name)
    end
end, KeyCommand.RUN_ON_DOWN, KeyCommand_CreateKey("F5")))

local text
--- 显示枚举值
SlashCmdList["ENUMS"] = function()
    -- text 是 nil 则需要遍历
    if text == nil then
        local textTable = {}
        local version, build = GetBuildInfo()
        tinsert(textTable, "--- version: " .. version .. "." .. build .. "\n\nEnum = {\n")

        for name, value in pairs(Enum) do
            tinsert(textTable, "    " .. name .. " = {\n")
            for n, v in pairs(value) do
                tinsert(textTable, "        " .. n .. " = " .. v .. ",\n")
            end
            tinsert(textTable, "    },\n")
        end
        tinsert(textTable, "}\n")

        text = table.concat(textTable)
    end

    ShowCopyFrame(text)
end
SLASH_ENUMS1 = "/enums"
