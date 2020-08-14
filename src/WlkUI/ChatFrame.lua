--- ChatFrame1EditBox 和输入框白边的边距
local PADDING1 = 8
--- ChatFrame1Tab 和 ChatFrame1Background 的垂直间距
local SPACING1 = 3
--- ChatFrame1TabText 相对 ChatFrame1Tab 垂直偏移
local OFFSET_Y = -5

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

---@param addChatFrame ScrollingMessageFrame
local function UpdateChatFrameEditBox(initialUpdate, addChatFrame)
    for i = 1, NUM_CHAT_WINDOWS do
        ---@type ScrollingMessageFrame
        local chatFrame = _G["ChatFrame" .. i]

        local rightmostTab = _G[dockedChatFrames[#dockedChatFrames]:GetName() .. "Tab"]
        chatFrame.editBox:ClearAllPoints()
        chatFrame.editBox:SetPoint("BOTTOMLEFT", rightmostTab, "BOTTOMRIGHT", -PADDING1, OFFSET_Y)
        chatFrame.editBox:SetPoint("BOTTOMRIGHT", ChatFrame1Background, "TOPRIGHT", PADDING1, OFFSET_Y - SPACING1)

        if initialUpdate then
            UpdateChatFrameEditBoxOptions(chatFrame.editBox)
        end
    end

    if addChatFrame then
        UpdateChatFrameEditBoxOptions(addChatFrame.editBox)
    end
end

UpdateChatFrameEditBox(true)

hooksecurefunc("FCFDock_AddChatFrame", function(_, addChatFrame)
    UpdateChatFrameEditBox(false, addChatFrame)
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

local CHANNEL_ABBREVIATIONS = {
    [GENERAL] = "綜合",
    [TRADE] = "交易",
    [DEFENSE[locale]] = "防務",
    [LOOK_FOR_GROUP] = "尋組",
    [WORLD[locale]] = "世界",
}

for channelName, channelAbbreviation in pairs(CHANNEL_ABBREVIATIONS) do
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        local originAddMessage = chatFrame.AddMessage
        function chatFrame.AddMessage(self, message, ...)
            local abbreviation = gsub(message, strconcat("|h%[(%d+)%. ", channelName, ".-%]|h"), strconcat("|h%[%1%. ",
                    channelAbbreviation, "%]|h"))
            return originAddMessage(self, abbreviation, ...)
        end
    end
end
