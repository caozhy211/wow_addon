--- ChatFrame1EditBox 和输入框白边的边距
local PADDING1 = 8
--- ChatFrame1Tab 和 ChatFrame1Background 的垂直间距
local SPACING1 = 3
--- ChatFrame1TabText 相对 ChatFrame1Tab 垂直偏移
local OFFSET_Y = -5

---@type ScrollingMessageFrame[]
local dockedChatFrames = GeneralDockManager.DOCKED_CHAT_FRAMES
local rightmostTab
---@type ScrollingMessageFrame
local chatFrame
---@type Texture
local editBoxTexture

---@param editBox EditBox
local function UpdateChatFrameEditBoxOptions(editBox)
    editBoxTexture = _G[editBox:GetName() .. "Left"]
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
        chatFrame = _G["ChatFrame" .. i]

        rightmostTab = _G[dockedChatFrames[#dockedChatFrames]:GetName() .. "Tab"]
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

---@type Button
local languageButton

---@param editBox EditBox
hooksecurefunc("ChatEdit_ActivateChat", function(editBox)
    languageButton = _G[editBox:GetName() .. "Language"]
    languageButton:Hide()
end)
