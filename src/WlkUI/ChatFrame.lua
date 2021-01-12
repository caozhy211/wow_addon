---@type ScrollingMessageFrame[]
local GENERAL_DOCKED_CHAT_FRAMES = GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES

--- ChatFrameEditBox 边框和输入边框的水平边距
local PADDING = 8
--- ChatFrame1 左边相对 ChatFrame1ButtonFrameBackground 左边的偏移
local OFFSET_X1 = 36
--- ChatFrame1 右边相对 ChatFrame1Background 右边的偏移
local OFFSET_X2 = -24
--- ChatFrameTabText 中心相对 ChatFrameTab 中心 的垂直偏移
local OFFSET_Y1 = -5
--- ChatFrame1 顶部相对 QuickJoinToastButton 顶部的偏移
local OFFSET_Y2 = -59
--- ChatFrame1 底部相对 ChatFrame1Background 底部的偏移
local OFFSET_Y3 = 6
local xOffset1 = OFFSET_X1
local xOffset2 = 540 + OFFSET_X2
local yOffset1 = 330 + OFFSET_Y2
local yOffset2 = 116 + OFFSET_Y3
local DEFENSE = { zhTW = "本地防務", zhCN = "本地防务", }
local WORLD = { zhTW = "大腳世界頻道", zhCN = "大脚世界频道", }
local locale = GetLocale()
local shortnames = {
    [GENERAL .. " - .-"] = "綜合",
    [TRADE .. " - .-"] = "交易",
    [DEFENSE[locale] .. " - .-"] = "防務",
    [WORLD[locale]] = "世界",
}

local function updateChatFrameEditBoxPosition()
    local frame = GENERAL_DOCKED_CHAT_FRAMES[#GENERAL_DOCKED_CHAT_FRAMES]
    local rightmostTab = _G[frame:GetName() .. "Tab"]
    for _, chatFrame in ipairs(GENERAL_DOCKED_CHAT_FRAMES) do
        ---@type EditBox
        local editBox = _G[chatFrame:GetName() .. "EditBox"]
        editBox:ClearAllPoints()
        editBox:SetPoint("LEFT", rightmostTab, "RIGHT", -PADDING, OFFSET_Y1)
        editBox:SetPoint("RIGHT", ChatFrame1.Background, PADDING, 0)
    end
end

---@param editBox EditBox
local function setChatFrameEditBox(editBox)
    local name = editBox:GetName()
    ---@type Texture
    local texture = _G[name .. "Left"]
    texture:Hide()
    texture = _G[name .. "Mid"]
    texture:Hide()
    texture = _G[name .. "Right"]
    texture:Hide()
    editBox:SetAltArrowKeyMode(false)
end

local function abbreviateChannelName(chatFrame, name, shortname)
    local originalAddMessage = chatFrame.AddMessage
    chatFrame.AddMessage = function(self, message, ...)
        local msg = gsub(message, "(|h%[%d+%. )" .. name .. "(%]|h)", "%1" .. shortname .. "%2")
        return originalAddMessage(self, msg, ...)
    end
end

updateChatFrameEditBoxPosition()

for i = 1, NUM_CHAT_WINDOWS do
    setChatFrameEditBox(_G["ChatFrame" .. i .. "EditBox"])
    for name, shortname in pairs(shortnames) do
        abbreviateChannelName(_G["ChatFrame" .. i], name, shortname)
    end
end

hooksecurefunc("FCFDock_AddChatFrame", function(_, chatFrame)
    updateChatFrameEditBoxPosition()
    setChatFrameEditBox(chatFrame.editBox)
end)

hooksecurefunc("FCFDock_RemoveChatFrame", function()
    updateChatFrameEditBoxPosition()
end)

---@param editBox EditBox
hooksecurefunc("ChatEdit_ActivateChat", function(editBox)
    ---@type Button
    local button = _G[editBox:GetName() .. "Language"]
    button:Hide()
end)

---@param editBox ChatFrameEditBoxTemplate
hooksecurefunc("ChatEdit_UpdateHeader", function(editBox)
    local chatType = editBox:GetAttribute("chatType")
    if not chatType then
        return
    end
    local header = editBox.header
    local headerSuffix = editBox.headerSuffix
    if not header then
        return
    end
    if chatType == "CHANNEL" then
        local channelName = header:GetText()
        for name, shortname in pairs(shortnames) do
            if strmatch(channelName, name) then
                header:SetFormattedText(CHAT_CHANNEL_SEND, editBox:GetAttribute("channelTarget"), shortname)
                header:SetWidth(header:GetStringWidth())
                local headerWidth = header:GetWidth()
                local editBoxWidth = editBox:GetWidth()
                local headerSuffixWidth = 0
                if headerWidth > editBoxWidth / 2 then
                    header:SetWidth(editBoxWidth / 2)
                    headerSuffix:Show()
                    headerSuffixWidth = headerSuffix:GetWidth()
                else
                    headerSuffix:Hide()
                end
                editBox:SetTextInsets(15 + headerWidth + headerSuffixWidth, 13, 0, 0)
                break
            end
        end
    end
    if not editBox:HasFocus() and headerSuffix:IsShown() then
        headerSuffix:Hide()
    end
end)

hooksecurefunc("UIParent_ManageFramePosition", function(index)
    if _G[index] == ChatFrame1 then
        ChatFrame1:ClearAllPoints()
        ChatFrame1:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", xOffset1, yOffset1)
        ChatFrame1:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", xOffset2, yOffset2)
    end
end)
