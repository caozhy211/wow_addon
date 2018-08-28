local matchTable = {
    ["綜合"] = "綜合",
    ["交易"] = "交易",
    ["本地防務"] = "防務",
    ["尋求組隊"] = "尋組",
    ["組隊頻道"] = "組隊",
}

-- 簡化輸入框的頻道名稱
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

            for key, value in pairs(matchTable) do
                if channelName:find(key) then
                    channelName = value
                end
            end

            header:SetFormattedText(CHAT_CHANNEL_SEND, channel, channelName)
        end
    end
    editBox:SetTextInsets(15 + header:GetWidth() + (headerSuffix:IsShown() and headerSuffix:GetWidth() or 0), 13, 0, 0)
end)

-- 簡化聊天框頻道名稱
for name, abbrev in pairs(matchTable) do
    for i = 1, NUM_CHAT_WINDOWS do
        if i ~= 2 then
            local chatFrame = _G["ChatFrame" .. i]
            local am = chatFrame.AddMessage
            chatFrame.AddMessage = function(frame, text, ...)
                return am(frame, text:gsub("|h%[(%d+)%. " .. name .. ".-%]|h", "|h%[%1%. " .. abbrev .. "%]|h"), ...)
            end
        end
    end
end