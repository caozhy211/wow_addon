local addonName = ...
local filter

---@type Frame
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" and addonName == ... then
        eventFrame:UnregisterEvent(event)
        if not WlkChatFilter then
            WlkChatFilter = {}
        end
        filter = WlkChatFilter
    end
end)

local chatFilterEvents = {
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_SAY",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_YELL",
}

local function tMatch(tbl, ...)
    for i = 1, select("#", ...) do
        local str = select(i, ...)
        for _, value in ipairs(tbl) do
            if strmatch(str, value) then
                return true
            end
        end
    end
    return false
end

local function FilterChatMessage(_, _, message, ...)
    return tMatch(filter, message), message, ...
end

for _, event in ipairs(chatFilterEvents) do
    ChatFrame_AddMessageEventFilter(event, FilterChatMessage)
end

local KEYWORD_LIST = "過濾關鍵字列表："
local DELETE_SUCCESS = "刪除成功！"
local ADD_SUCCESS = "添加成功！"
local HELP = "輸入 '\/cf option' 管理過濾關鍵字\n-list：顯示關鍵字列表\n-add keyword：添加關鍵字\n-delete index：刪除關鍵字"
local systemR, systemG, systemB = 1, 1, 0

SLASH_CHAT_FILTER1 = "/cf"

SlashCmdList["CHAT_FILTER"] = function(arg)
    local option, value = strsplit(" ", arg)
    if option == "list" then
        ChatFrame1:AddMessage(KEYWORD_LIST, systemR, systemG, systemB)
        for i, keyword in ipairs(filter) do
            local text = format(i .. ": " .. keyword)
            ChatFrame1:AddMessage(text)
        end
    elseif option == "delete" then
        local index = tonumber(value)
        if index and tremove(filter, index) then
            ChatFrame1:AddMessage(DELETE_SUCCESS, systemR, systemG, systemB)
        end
    elseif option == "add" then
        filter[#filter + 1] = value
        ChatFrame1:AddMessage(ADD_SUCCESS, systemR, systemG, systemB)
    else
        ChatFrame1:AddMessage(HELP, systemR, systemG, systemB)
    end
end

local BN_TOAST_TYPE_CLUB_INVITATION = 6;

local rawShowToast = BNToastFrame.ShowToast
BNToastFrame.ShowToast = function()
    local toast = BNToastFrame.BNToasts[1]
    if toast.toastType == BN_TOAST_TYPE_CLUB_INVITATION then
        local clubName = toast.toastData.club.name
        local description = toast.toastData.club.description
        if tMatch(filter, clubName, description) then
            return tremove(BNToastFrame.BNToasts, 1)
        end
    end
    return rawShowToast(BNToastFrame)
end
