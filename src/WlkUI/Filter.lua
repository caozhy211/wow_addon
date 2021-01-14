local BN_TOAST_TYPE_CLUB_INVITATION = 6
local addonName = ...
local keywords = {
    "|Hachievement.-|h.-|h.-免费",
    "|Hachievement.-|h.-|h.-没要求",
    "|Hspell.-|h.-|h.-免费",
    "|Hspell.-|h.-|h.-没要求",
}
local chatFilterEvents = {
    "CHAT_MSG_CHANNEL", "CHAT_MSG_SAY", "CHAT_MSG_WHISPER", "CHAT_MSG_YELL", "CHAT_MSG_TEXT_EMOTE",
}

---@type Frame
local listener = CreateFrame("Frame")

local originalShowToast = BNToastFrame.ShowToast

local function matchKeywords(...)
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        for _, keyword in ipairs(keywords) do
            if strmatch(arg, keyword) then
                return true
            end
        end
    end
end

local function filterChatMessage(_, _, message, ...)
    return matchKeywords(message), message, ...
end

SLASH_ADD_KEYWORD1 = "/ak"

SlashCmdList["ADD_KEYWORD"] = function(keyword)
    tinsert(keywords, keyword)
    ChatFrame1:AddMessage("添加成功", 1, 1, 0)
end

BNToastFrame.ShowToast = function()
    local toast = BNToastFrame.BNToasts[1]
    if toast.toastType == BN_TOAST_TYPE_CLUB_INVITATION then
        local clubName = toast.toastData.club.name
        local description = toast.toastData.club.description
        if matchKeywords(clubName, description) then
            tremove(BNToastFrame.BNToasts, 1)
            return
        end
    end
    return originalShowToast(BNToastFrame)
end

for _, event in ipairs(chatFilterEvents) do
    ChatFrame_AddMessageEventFilter(event, filterChatMessage)
end

listener:RegisterEvent("ADDON_LOADED")
listener:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        listener:UnregisterEvent(event)
        if not WlkFilterKeywords then
            WlkFilterKeywords = keywords
        else
            keywords = WlkFilterKeywords
        end
    end
end)
