local abbrevs = {
    ["綜合"] = "綜合",
    ["交易"] = "交易",
    ["本地防務"] = "防務",
    ["尋求組隊"] = "尋組",
    ["組隊頻道"] = "組隊",
}
local dockedChatFrames = GeneralDockManager.DOCKED_CHAT_FRAMES
local numActiveFrames = FCF_GetNumActiveChatFrames()

ChatFrame1:ClearAllPoints()
ChatFrame1:SetPoint("TopLeft", UIParent, "BottomLeft", 2 + 29 + 3 + 2, 330 - 32 - 24 - 3)
ChatFrame1:SetPoint("BottomRight", UIParent, "BottomLeft", 540 - 24, 116 + 6)
ChatFrame1.SetPoint = nop

hooksecurefunc("ChatEdit_UpdateHeader", function(editBox)
    local type = editBox:GetAttribute("chatType")
    if not type then
        return
    end

    local header = _G[editBox:GetName() .. "Header"]
    local headerSuffix = _G[editBox:GetName() .. "HeaderSuffix"]
    if not header then
        return
    end

    header:SetWidth(0)
    if type == "CHANNEL" then
        local channel, channelName, instanceID = GetChannelName(editBox:GetAttribute("channelTarget"))
        if channelName then
            if instanceID > 0 then
                channelName = channelName .. " " .. instanceID
            end
            editBox:SetAttribute("channelTarget", channel)

            for key, value in pairs(abbrevs) do
                if strfind(channelName, key) then
                    channelName = value
                end
            end

            header:SetFormattedText(CHAT_CHANNEL_SEND, channel, channelName)
        end
    end

    editBox:SetTextInsets(15 + header:GetWidth() + (headerSuffix:IsShown() and headerSuffix:GetWidth() or 0), 13, 0, 0)
end)

for name, abbrev in pairs(abbrevs) do
    for i = 1, NUM_CHAT_WINDOWS do
        if i ~= 2 then
            local chatFrame = _G["ChatFrame" .. i]
            local addMessage = chatFrame.AddMessage
            function chatFrame:AddMessage(text, ...)
                local abbrevText = gsub(text, "|h%[(%d+)%. " .. name .. ".-%]|h", "|h%[%1%. " .. abbrev .. "%]|h")
                return addMessage(self, abbrevText, ...)
            end
        end
    end
end

local function IsNewChatFrame()
    local count = FCF_GetNumActiveChatFrames()
    return count > numActiveFrames
end

local function PositionEditBox()
    local index = #dockedChatFrames
    local rightTab = _G[dockedChatFrames[index]:GetName() .. "Tab"]
    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame" .. i].editBox
        editBox:ClearAllPoints()
        editBox:SetPoint("BottomLeft", rightTab, "BottomRight")
        editBox:SetPoint("BottomRight", ChatFrame1, "TopRight", 5, 3)
    end
end

local function HandleNewChatFrame(chatFrame)
    local name = chatFrame:GetName()
    _G[name .. "EditBoxLeft"]:Hide()
    _G[name .. "EditBoxMid"]:Hide()
    _G[name .. "EditBoxRight"]:Hide()

    local editBox = chatFrame.editBox
    editBox:SetAltArrowKeyMode(false)
end

for i = 1, NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame" .. i]
    HandleNewChatFrame(chatFrame)
end
PositionEditBox()

hooksecurefunc("FCFDock_AddChatFrame", function(_, chatFrame)
    if IsNewChatFrame() then
        HandleNewChatFrame(chatFrame)
        numActiveFrames = numActiveFrames + 1
    end
    PositionEditBox()
end)

hooksecurefunc("FCFDock_RemoveChatFrame", function()
    numActiveFrames = numActiveFrames - 1
    PositionEditBox()
end)