local xOffset = 540
local yOffset = 116
local rows = 4
local columns = 3
local size = yOffset / rows
local WORLD = { zhTW = "大腳世界頻道", zhCN = "大脚世界频道", }
local locale = GetLocale()
local index = 0
local config = {
    { "說", "/s ", GetClassColor("PRIEST"), },
    { "喊", "/y ", GetClassColor("DEATHKNIGHT"), },
    { "隊", "/p ", GetClassColor("WARLOCK"), },
    { "會", "/g ", GetClassColor("MONK"), },
    { "團", "/raid ", GetClassColor("DRUID"), },
    { "副", "/i ", GetClassColor("WARRIOR"), },
    { "綜", GENERAL, GetClassColor("PALADIN"), },
    { "世", WORLD[locale], GetClassColor("SHAMAN"), },
    { "骰", "_RANDOM", GetClassColor("ROGUE"), },
    { "清", "_CLEAR_CHAT", GetClassColor("DEMONHUNTER"), },
    { "複", "_EXPORT_CHAT", GetClassColor("HUNTER"), },
    { "重", "_RELOAD", GetClassColor("MAGE"), },
}
local channelR, channelG, channelB = 1, 0.75, 0.75

---@type Frame
local chatMenuFrame = CreateFrame("Frame", "WlkChatMenuFrame", UIParent, "BackdropTemplate")

local function getChannelIndex(channelName, ...)
    for i = 2, select("#", ...), 3 do
        if select(i, ...) == channelName then
            return select(i - 1, ...)
        end
    end
end

local function chatMenuButtonOnClick(self, button)
    local command = self.command
    if strmatch(command, "^/") then
        ChatFrame_OpenChat(command .. SELECTED_CHAT_FRAME.editBox:GetText(), SELECTED_CHAT_FRAME)
    elseif strmatch(command, "^_") then
        SlashCmdList[strsub(command, 2)]("")
    else
        local channelName = command
        local channelIndex = getChannelIndex(channelName, GetChannelList())
        local text
        if button == "LeftButton" then
            if channelIndex then
                text = format("/%d %s", channelIndex, SELECTED_CHAT_FRAME.editBox:GetText())
                ChatFrame_OpenChat(text, SELECTED_CHAT_FRAME)
            else
                text = format(CHAT_NOT_MEMBER_NOTICE, "「" .. channelName .. "」")
                ChatFrame1:AddMessage(text, channelR, channelG, channelB)
            end
        else
            if channelIndex then
                LeaveChannelByName(channelName)
                text = format(CHAT_YOU_LEFT_NOTICE, channelIndex, channelIndex .. ". " .. channelName)
            else
                JoinPermanentChannel(channelName)
                channelIndex = ChatFrame_AddChannel(ChatFrame1, channelName)
                text = format(CHAT_YOU_JOINED_NOTICE, channelIndex, channelIndex .. ". " .. channelName)
            end
            ChatFrame1:AddMessage(text, channelR, channelG, channelB)
        end
    end
end

SLASH_CLEAR_CHAT1 = "/cc"
SLASH_RELOAD_UI1 = "/ru"

SlashCmdList["CLEAR_CHAT"] = function()
    SELECTED_CHAT_FRAME:Clear()
end
SlashCmdList["RELOAD_UI"] = ReloadUI

chatMenuFrame:SetFrameStrata("HIGH")
chatMenuFrame:SetSize(size * columns, size * rows)
chatMenuFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", xOffset, 0)
chatMenuFrame:SetBackdrop({ bgFile = "Interface/ChatFrame/CHATFRAMEBACKGROUND", })
chatMenuFrame:SetBackdropColor(DEFAULT_CHATFRAME_COLOR.r, DEFAULT_CHATFRAME_COLOR.g, DEFAULT_CHATFRAME_COLOR.b,
        DEFAULT_CHATFRAME_ALPHA)

for i = 1, rows do
    for j = 1, columns do
        index = index + 1
        local text, command, r, g, b = unpack(config[index])
        ---@class WlkChatMenuButton:Button
        local button = CreateFrame("Button", "WlkChatMenuButton" .. index, chatMenuFrame)
        local label = button:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med1")

        button:SetSize(size, size)
        button:SetPoint("TOPLEFT", (j - 1) * size, (1 - i) * size)
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", chatMenuButtonOnClick)

        label:SetPoint("CENTER")
        label:SetText(text)
        label:SetTextColor(r, g, b)

        button.command = command
        button.label = label
    end
end
