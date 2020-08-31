--- ChatFrame1EditBox 和输入框白边的边距
local PADDING1 = 8
--- ChatFrame1Tab 和 ChatFrame1Background 的垂直间距
local SPACING1 = 3
--- ChatFrame1TabText 中心相对 ChatFrame1Tab 中心的垂直偏移值
local OFFSET_Y1 = -5

---@type ScrollingMessageFrame[]
local dockedChatFrames = GeneralDockManager.DOCKED_CHAT_FRAMES

---@param editBox EditBox
local function UpdateChatFrameEditBoxOptions(editBox)
    local name = editBox:GetName()
    ---@type Texture
    local editBoxTexture = _G[name .. "Left"]
    editBoxTexture:Hide()
    editBoxTexture = _G[name .. "Right"]
    editBoxTexture:Hide()
    editBoxTexture = _G[name .. "Mid"]
    editBoxTexture:Hide()

    editBox:SetAltArrowKeyMode(false)
end

---@param chatFrame ScrollingMessageFrame
local function UpdateChatFrameEditBox(firstUpdate, chatFrame)
    for i = 1, NUM_CHAT_WINDOWS do
        ---@type EditBox
        local editBox = _G["ChatFrame" .. i .. "EditBox"]

        local rightmostTab = _G[dockedChatFrames[#dockedChatFrames]:GetName() .. "Tab"]
        editBox:ClearAllPoints()
        editBox:SetPoint("BOTTOMLEFT", rightmostTab, "BOTTOMRIGHT", -PADDING1, OFFSET_Y1)
        editBox:SetPoint("BOTTOMRIGHT", ChatFrame1Background, "TOPRIGHT", PADDING1, OFFSET_Y1 - SPACING1)

        if firstUpdate then
            UpdateChatFrameEditBoxOptions(editBox)
        end
    end

    if chatFrame then
        UpdateChatFrameEditBoxOptions(chatFrame.editBox)
    end
end

UpdateChatFrameEditBox(true)

hooksecurefunc("FCFDock_AddChatFrame", function(_, chatFrame)
    UpdateChatFrameEditBox(false, chatFrame)
end)

hooksecurefunc("FCFDock_RemoveChatFrame", function()
    UpdateChatFrameEditBox()
end)

---@param editBox EditBox
hooksecurefunc("ChatEdit_ActivateChat", function(editBox)
    ---@type Button
    local languageButton = _G[editBox:GetName() .. "Language"]
    languageButton:Hide()
end)

local DEFENSE = { zhTW = "本地防務", zhCN = "本地防务", }
local WORLD = { zhTW = "大腳世界頻道", zhCN = "大脚世界频道", }

local locale = GetLocale()

local CHANNEL_SHORTNAMES = {
    [GENERAL] = "綜合",
    [TRADE] = "交易",
    [DEFENSE[locale]] = "防務",
    [LOOK_FOR_GROUP] = "尋組",
    [WORLD[locale]] = "世界",
}

---@param chatFrame ScrollingMessageFrameMixin
local function AbbreviateChatFrameChannelName(chatFrame, name, shortname)
    local rawAddMessage = chatFrame.AddMessage
    chatFrame.AddMessage = function(self, message, ...)
        local text = gsub(message, "(|h%[%d+%. )" .. name .. ".-(%]|h)", "%1" .. shortname .. "%2")
        return rawAddMessage(self, text, ...)
    end
end

for i = 1, NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame" .. i]
    for name, shortname in pairs(CHANNEL_SHORTNAMES) do
        AbbreviateChatFrameChannelName(chatFrame, name, shortname)
    end
end

---@param editBox EditBox|ChatFrameEditBoxTemplate
hooksecurefunc("ChatEdit_UpdateHeader", function(editBox)
    local type = editBox:GetAttribute("chatType")
    if not type then
        return
    end
    local header = editBox.header
    local headerSuffix = editBox.headerSuffix
    if not header then
        return
    end
    if type == "CHANNEL" then
        local channelName = header:GetText()
        for name, abbreviation in pairs(CHANNEL_SHORTNAMES) do
            if strmatch(channelName, name) then
                header:SetFormattedText(CHAT_CHANNEL_SEND, GetChannelName(ChatEdit_GetChannelTarget(editBox)),
                        abbreviation)
                local headerWidth = (header:GetRight() or 0) - (header:GetLeft() or 0)
                local editBoxWidth = (editBox:GetRight() or 0) - (editBox:GetLeft() or 0)
                if headerWidth > editBoxWidth / 2 then
                    header:SetWidth(editBoxWidth / 2)
                    headerSuffix:Show()
                else
                    headerSuffix:Hide()
                end
                editBox:SetTextInsets(15 + header:GetWidth() + (headerSuffix:IsShown() and headerSuffix:GetWidth()
                        or 0), 13, 0, 0)
                break
            end
        end
    end
end)

--- ChatFrame1 左边相对 ChatFrame1ButtonFrameBackground 左边的偏移值
local OFFSET_Y2 = 36
--- CompactRaidFrameManagerContainerResizeFrame 底部相对 UIParent 底部的偏移值
local OFFSET_Y3 = 330
--- QuickJoinToastButton 顶部相对 ChatFrame1 顶部的偏移值
local OFFSET_Y4 = 59
--- ChatFrame1 底部相对 ChatFrame1Background 底部的偏移值
local OFFSET_Y5 = 6
--- ChatFrame1Background 右边相对 ChatFrame1 右边的偏移值
local OFFSET_X1 = 24

--- ChatFrame1Background 右边相对 UIParent 左边的偏移值
local offsetX = 540
--- ChatFrame1Background 底部相对 UIParent 底部的偏移值
local offsetY = 116

hooksecurefunc("UIParent_ManageFramePosition", function(index)
    if _G[index] == ChatFrame1 then
        ChatFrame1:ClearAllPoints()
        ChatFrame1:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", OFFSET_Y2, OFFSET_Y3 - OFFSET_Y4)
        ChatFrame1:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", offsetX - OFFSET_X1, offsetY + OFFSET_Y5)
    end
end)
