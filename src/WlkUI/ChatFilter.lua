local addonName = ...
local filter

---@type Frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
---@param self Frame
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if addonName == ... then
        if not WlkChatFilter then
            WlkChatFilter = {}
        end
        filter = WlkChatFilter
        self:UnregisterEvent(event)
    end
end)

local chatInfoEvents = {
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_WHISPER",
}

local function filterChat(_, _, message, ...)
    for _, keyword in ipairs(filter) do
        if strmatch(message, keyword) then
            return true
        end
    end
    return false, message, ...
end

for _, event in ipairs(chatInfoEvents) do
    ChatFrame_AddMessageEventFilter(event, filterChat)
end

local KEYWORD_LIST = "過濾關鍵字列表："
local DELETE_SUCCESS = "刪除成功！"
local ADD_SUCCESS = "添加成功！"
local HELP = "輸入 '\/cf option' 管理過濾關鍵字\n-list：顯示關鍵字列表\n-add keyword：添加關鍵字\n-delete index：刪除關鍵字"

SLASH_CHAT_FILTER1 = "/cf"

SlashCmdList["CHAT_FILTER"] = function(arg)
    local option, value = strsplit(" ", arg)
    local info = ChatTypeInfo["SYSTEM"]
    if option == "list" then
        ChatFrame1:AddMessage(KEYWORD_LIST, info.r, info.g, info.b, info.id)
        info = ChatTypeInfo["SAY"]
        for i, keyword in ipairs(filter) do
            local text = format("%d: %s", i, keyword)
            ChatFrame1:AddMessage(text, info.r, info.g, info.b, info.id)
        end
    elseif option == "delete" then
        local index = tonumber(value)
        if index and tremove(filter, index) then
            ChatFrame1:AddMessage(DELETE_SUCCESS, info.r, info.g, info.b, info.id)
        end
    elseif option == "add" then
        tinsert(filter, value)
        ChatFrame1:AddMessage(ADD_SUCCESS, info.r, info.g, info.b, info.id)
    else
        ChatFrame1:AddMessage(HELP, info.r, info.g, info.b, info.id)
    end
end
