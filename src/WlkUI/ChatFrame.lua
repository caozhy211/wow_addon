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
    ---@type Texture
    local editBoxTexture = _G[editBox:GetName() .. "Left"]
    editBoxTexture:Hide()
    editBoxTexture = _G[editBox:GetName() .. "Right"]
    editBoxTexture:Hide()
    editBoxTexture = _G[editBox:GetName() .. "Mid"]
    editBoxTexture:Hide()

    editBox:SetAltArrowKeyMode(false)
end

---@param chatFrame ScrollingMessageFrame
local function UpdateChatFrameEditBox(initialUpdate, chatFrame)
    for i = 1, NUM_CHAT_WINDOWS do
        ---@type EditBox
        local editBox = _G["ChatFrame" .. i .. "EditBox"]

        local rightmostTab = _G[dockedChatFrames[#dockedChatFrames]:GetName() .. "Tab"]
        editBox:ClearAllPoints()
        editBox:SetPoint("BOTTOMLEFT", rightmostTab, "BOTTOMRIGHT", -PADDING1, OFFSET_Y1)
        editBox:SetPoint("BOTTOMRIGHT", ChatFrame1Background, "TOPRIGHT", PADDING1, OFFSET_Y1 - SPACING1)

        if initialUpdate then
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

for name, shortname in pairs(CHANNEL_SHORTNAMES) do
    for i = 1, NUM_CHAT_WINDOWS do
        ---@type ScrollingMessageFrameMixin
        local chatFrame = _G["ChatFrame" .. i]
        local rawAddMessage = chatFrame.AddMessage
        chatFrame.AddMessage = function(self, message, ...)
            local text = gsub(message, strconcat("|h%[(%d+)%. ", name, ".-%]|h"),
                    strconcat("|h%[%1%. ", shortname, "%]|h"))
            return rawAddMessage(self, text, ...)
        end
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

--- ChatFrame1ButtonFrameBackground 和 ChatFrame1 的水平间距
local SPACING2 = 3
--- ChatFrame1ButtonFrameBackground 的宽度
local WIDTH1 = 33
--- QuickJoinToastButton 和 ChatFrame1 的垂直间距
local SPACING3 = 27
--- QuickJoinToastButton 的高度
local HEIGHT1 = 32
--- CompactRaidFrameManagerContainerResizeFrame 和 UIParent 的底部边距
local PADDING2 = 330
--- ChatFrame1 和 ChatFrame1Background 的底部差距
local MARGIN1 = 6
--- ChatFrame1 和 ChatFrame1Background 的右边差距
local MARGIN2 = 24

--- ChatFrame1Background 右下角的横坐标
local x = 540
--- ChatFrame1Background 右下角的纵坐标
local y = 116

hooksecurefunc("UIParent_ManageFramePosition", function(index)
    if _G[index] == ChatFrame1 then
        ChatFrame1:ClearAllPoints()
        ChatFrame1:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", SPACING2 + WIDTH1, PADDING2 - HEIGHT1 - SPACING3)
        ChatFrame1:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", x - MARGIN2, y + MARGIN1)
    end
end)
