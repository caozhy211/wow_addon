---@type Frame
local eventListener = CreateFrame("Frame")

eventListener:RegisterEvent("ADDON_LOADED")

local addonName = ...
local keywords

---@param self Frame
eventListener:SetScript("OnEvent", function(self, event, ...)
    if ... == addonName then
        if not WLK_AdFilter then
            WLK_AdFilter = {}
        end
        keywords = WLK_AdFilter
        self:UnregisterEvent(event)
    end
end)

local chatInfoEvents = {
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_WHISPER_INFORM",
}

for i = 1, #chatInfoEvents do
    ChatFrame_AddMessageEventFilter(chatInfoEvents[i], function(_, _, text, ...)
        for j = 1, #keywords do
            if strmatch(text, keywords[j]) then
                return true
            end
        end
        return false, text, ...
    end)
end

SLASH_AK1 = "/ak"
SlashCmdList["AK"] = function(word)
    tinsert(keywords, word)
end
