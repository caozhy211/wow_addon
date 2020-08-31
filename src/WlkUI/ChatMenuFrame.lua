--- ChatFrame1Background 底部相对 UIParent 底部的偏移值
local OFFSET_Y1 = 116

local numRows = 4
local numCols = 3
local height = OFFSET_Y1 / numRows
local width = height

---@type Frame
local chatMenuFrame = CreateFrame("Frame", "WlkChatMenuFrame", UIParent)
chatMenuFrame:SetFrameStrata("HIGH")
chatMenuFrame:SetSize(width * numCols, height * numRows)
chatMenuFrame:SetPoint("TOPRIGHT", ChatFrame1Background, "BOTTOMRIGHT")
chatMenuFrame:SetBackdrop({ bgFile = "Interface/ChatFrame/CHATFRAMEBACKGROUND", })
local r, g, b = GetTableColor(DEFAULT_CHATFRAME_COLOR)
chatMenuFrame:SetBackdropColor(r, g, b, DEFAULT_CHATFRAME_ALPHA)

local WORLD = { zhTW = "大腳世界頻道", zhCN = "大脚世界频道", }

local locale = GetLocale()

local menuButtons = {
    { text = "說", color = "PRIEST", command = "/s ", },
    { text = "喊", color = "DEATHKNIGHT", command = "/y ", },
    { text = "隊", color = "WARLOCK", command = "/p ", },
    { text = "會", color = "MONK", command = "/g ", },
    { text = "團", color = "DRUID", command = "/raid ", },
    { text = "副", color = "PALADIN", command = "/i ", },
    { text = "綜", color = "WARRIOR", command = GENERAL, },
    { text = "尋", color = "DEMONHUNTER", command = LOOK_FOR_GROUP, },
    { text = "世", color = "SHAMAN", command = WORLD[locale], },
    { text = "清", color = "HUNTER", command = "/clear", },
    { text = "骰", color = "ROGUE", command = "/roll", },
    { text = "重", color = "MAGE", command = "/reload", },
}

local function GetChannelIndex(channelName, ...)
    for i = 2, select("#", ...), 3 do
        if select(i, ...) == channelName then
            return select(i - 1, ...)
        end
    end
end

local channelR, channelG, channelB = 1, 0.75, 0.75

---@param self Button
local function ChatMenuButtonOnClick(self, button)
    local command = menuButtons[self:GetID()].command
    if command == "/roll" then
        RandomRoll(1, 100)
    elseif command == "/clear" then
        SELECTED_CHAT_FRAME:Clear()
    elseif command == "/reload" then
        ReloadUI()
    elseif strmatch(command, "/") then
        ChatFrame_OpenChat(command .. SELECTED_CHAT_FRAME.editBox:GetText(), SELECTED_CHAT_FRAME)
    else
        local channelName = command
        local channelIndex = GetChannelIndex(channelName, GetChannelList())
        local text
        if button == "RightButton" then
            if channelIndex then
                LeaveChannelByName(channelName)
                text = format(CHAT_YOU_LEFT_NOTICE, channelIndex, channelName)
            else
                JoinPermanentChannel(channelName)
                channelIndex = ChatFrame_AddChannel(ChatFrame1, channelName)
                text = format(CHAT_YOU_JOINED_NOTICE, channelIndex, channelName)
            end
            ChatFrame1:AddMessage(text, channelR, channelG, channelB)
        else
            if channelIndex then
                text = format("%s%d %s", KEY_SLASH, channelIndex, SELECTED_CHAT_FRAME.editBox:GetText())
                ChatFrame_OpenChat(text, SELECTED_CHAT_FRAME)
            else
                text = format(CHAT_NOT_MEMBER_NOTICE, " [" .. channelName .. "]")
                ChatFrame1:AddMessage(text, channelR, channelG, channelB)
            end
        end
    end
end

for i = 1, numRows do
    for j = 1, numCols do
        local id = (i - 1) * numCols + j
        ---@type Button
        local button = CreateFrame("Button", "WlkChatMenuButton" .. id, chatMenuFrame)
        button:SetID(id)
        button:SetSize(width, height)
        button:SetPoint("TOPLEFT", (j - 1) * width, (1 - i) * height)

        ---@type FontString
        local label = button:CreateFontString(button:GetName() .. "Label", "ARTWORK", "GameFontHighlight")
        label:SetPoint("CENTER")
        label:SetText(menuButtons[id].text)
        label:SetTextColor(GetClassColor(menuButtons[id].color))

        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", ChatMenuButtonOnClick)
    end
end

SLASH_RL1 = "/rl"

SlashCmdList["RL"] = ReloadUI

SLASH_CLEAR_CHAT1 = "/cl"

SlashCmdList["CLEAR_CHAT"] = function()
    SELECTED_CHAT_FRAME:Clear()
end

