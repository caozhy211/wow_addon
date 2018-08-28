-- 簡化重置命令
SlashCmdList["RELOAD"] = function()
    ReloadUI()
end
SLASH_RELOAD1 = "/rl"

-- 簡化ROLL點命令
SlashCmdList["ROLL"] = function()
    RandomRoll(1, 100)
end
SLASH_ROLL1 = "/ro"

-- 聊天框清屏
SlashCmdList["CLEAR"] = function()
    SELECTED_CHAT_FRAME:Clear()
end
SLASH_CLEAR1 = "/cl"

-- 加入/離開組隊頻道
SlashCmdList["ZUDUI"] = function()
    local _, channelName, _ = GetChannelName("組隊頻道")
    if channelName == nil then
        JoinPermanentChannel("組隊頻道", nil, 1, 1)
        ChatFrame_AddChannel(SELECTED_CHAT_FRAME, "組隊頻道")
        print("|cff00d200已加入組隊頻道|r")
    else
        LeaveChannelByName("組隊頻道")
        print("|cffd20000已离开組隊頻道|r")
    end
end
SLASH_ZUDUI1 = "/zd"