local abbrevs = {
    ["綜合"] = "綜合",
    ["交易"] = "交易",
    ["本地防務"] = "防務",
    ["尋求組隊"] = "尋組",
    ["組隊頻道"] = "組隊",
}

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

for i = 1, NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame" .. i]
    chatFrame:SetClampRectInsets(-35, 38, 38, -122)
    chatFrame:SetMinResize(480, 150)
    chatFrame:SetMaxResize(480, 150)

    _G["ChatFrame" .. i .. "EditBoxLeft"]:Hide()
    _G["ChatFrame" .. i .. "EditBoxMid"]:Hide()
    _G["ChatFrame" .. i .. "EditBoxRight"]:Hide()

    local editBox = chatFrame.editBox
    editBox:ClearAllPoints()
    editBox:SetPoint("BottomLeft", ChatFrame1, "TopLeft", 155, -2)
    editBox:SetPoint("BottomRight", ChatFrame1, "TopRight", 5, -2)

    editBox:SetAltArrowKeyMode(false)
end