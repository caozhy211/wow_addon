---@type MessageFrame
local chatFrame1 = ChatFrame1
chatFrame1:ClearAllPoints()
--- ChatFrame1ButtonFrame 左边相对屏幕左边偏移 2px，ChatFrame1ButtonFrame 的宽度是 29px，ChatFrame1Background 左边相对
--- ChatFrame1ButtonFrame 右边偏移 3px，ChatFrame1 左边相对 ChatFrame1Background 左边偏移 2px；
--- QuickJoinToastButton 顶部相对屏幕底部偏移 330px，QuickJoinToastButton 的高度是 32px，ChatFrame1Background 顶部相
--- 对 QuickJoinToastButton 底部偏移 -24px，ChatFrame1 顶部相对 ChatFrame1Background 顶部偏移 -3px
chatFrame1:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 2 + 29 + 3 + 2, 330 - 32 - 24 - 3)
--- ChatFrame1Background 右边相对屏幕左边偏移 540px，ChatFrame1 右边相对 ChatFrame1Background 右边偏移 -24px，
--- ChatFrame1Background 底部相对屏幕底部偏移 116px，ChatFrame1 底部相对 ChatFrame1Background 底部偏移 6px
chatFrame1:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", 540 - 24, 116 + 6)
chatFrame1.SetPoint = nop

local abbrevs = {
    [COMMUNITIES_DEFAULT_CHANNEL_NAME] = "綜合",
    [TRADE] = "交易",
    ["本地防務"] = "防務",
    [LOOK_FOR_GROUP] = "尋組",
    ["組隊頻道"] = "組隊",
}

--- 聊天窗口内容的频道名使用简称
---@param chatFrame MessageFrame 聊天窗口
---@param name string 本名
---@param shortName string 简称
local function AbbreviateChannelName(chatFrame, name, shortName)
    local addMessage = chatFrame.AddMessage
    function chatFrame:AddMessage(text, ...)
        local abbrevText = gsub(text, "|h%[(%d+)%. " .. name .. ".-%]|h", "|h%[%1%. " .. shortName .. "%]|h")
        return addMessage(self, abbrevText, ...)
    end
end

for name, abbrev in pairs(abbrevs) do
    for i = 1, NUM_CHAT_WINDOWS do
        -- 第二个聊天窗口是战斗记录
        if i ~= 2 then
            AbbreviateChannelName(_G["ChatFrame" .. i], name, abbrev)
        end
    end
end

--- 聊天输入框的频道名使用简称
---@param editBox EditBox
hooksecurefunc("ChatEdit_UpdateHeader", function(editBox)
    local type = editBox:GetAttribute("chatType")
    if not type then
        return
    end

    ---@type FontString
    local header = _G[editBox:GetName() .. "Header"]
    local headerSuffix = _G[editBox:GetName() .. "HeaderSuffix"]
    if not header then
        return
    end

    header:SetWidth(0)
    if type == "CHANNEL" then
        local localID, channelName, instanceID = GetChannelName(ChatEdit_GetChannelTarget(editBox))
        if channelName then
            if instanceID > 0 then
                channelName = channelName .. " " .. instanceID
            end
            -- 替换频道名
            for name, shortName in pairs(abbrevs) do
                if strfind(channelName, name) then
                    channelName = shortName
                    break
                end
            end
            header:SetFormattedText(CHAT_CHANNEL_SEND, localID, channelName)
        end
    end

    editBox:SetTextInsets(15 + header:GetWidth() + (headerSuffix:IsShown() and headerSuffix:GetWidth() or 0), 13, 0, 0)
end)

--- 已嵌入的聊天窗口
local dockedChatFrames = GeneralDockManager.DOCKED_CHAT_FRAMES
local dockedIDs = {}

--- 设置聊天输入框
---@param editBox EditBox
local function SetEditBox(editBox)
    local name = editBox:GetName()
    -- 隐藏边框
    ---@type Texture
    local left = _G[name .. "Left"]
    left:Hide()
    ---@type Texture
    local mid = _G[name .. "Mid"]
    mid:Hide()
    ---@type Texture
    local right = _G[name .. "Right"]
    right:Hide()

    -- 設置移动光标不需要按住 Alt 键
    editBox:SetAltArrowKeyMode(false)
end

for i = 1, #dockedChatFrames do
    ---@type MessageFrame
    local chatFrame = dockedChatFrames[i]
    tinsert(dockedIDs, chatFrame:GetID())
    SetEditBox(chatFrame.editBox)
end

--- 移动聊天输入框
local function MoveEditBox()
    ---@type MessageFrame
    local rightmostChatFrame = dockedChatFrames[#dockedChatFrames]
    local rightmostTab = _G[rightmostChatFrame:GetName() .. "Tab"]
    for i = 1, #dockedIDs do
        ---@type EditBox
        local editBox = _G["ChatFrame" .. dockedIDs[i] .. "EditBox"]
        editBox:ClearAllPoints()
        editBox:SetPoint("BOTTOMLEFT", rightmostTab, "BOTTOMRIGHT", 0, -3)
        editBox:SetPoint("BOTTOMRIGHT", chatFrame1, "TOPRIGHT", 5, 0)
    end
end

MoveEditBox()

--- 新嵌入聊天窗口后，设置聊天输入框
---@param chatFrame MessageFrame
hooksecurefunc("FCFDock_AddChatFrame", function(_, chatFrame)
    tinsert(dockedIDs, chatFrame:GetID())
    SetEditBox(chatFrame.editBox)
    MoveEditBox()
end)

--- 移除已嵌入的聊天窗口后，移动聊天输入框
hooksecurefunc("FCFDock_RemoveChatFrame", MoveEditBox)
