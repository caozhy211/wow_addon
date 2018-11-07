local buttons = {
    { text = "說", color = "PRIEST", arg = "/s " },
    { text = "喊", color = "DEATHKNIGHT", arg = "/y " },
    { text = "隊", color = "WARLOCK", arg = "/p " },
    { text = "會", color = "MONK", arg = "/g " },
    { text = "團", color = "DRUID", arg = "/raid " },
    { text = "副", color = "PALADIN", arg = "/i " },
    { text = "綜", color = "WARRIOR", arg = "綜合" },
    { text = "尋", color = "DEMONHUNTER", arg = "尋求組隊" },
    { text = "組", color = "SHAMAN", arg = "組隊頻道" },
    { text = "骰", color = "ROGUE", arg = "/roll" },
    { text = "清", color = "HUNTER", arg = "/clear" },
    { text = "重", color = "MAGE", arg = "/reload" },
}
local box = CreateFrame("Frame", "MyChannelBox", UIParent)
box:SetFrameStrata("Dialog")
box:SetSize(72, 116)
box:SetPoint("TopRight", ChatFrame1ResizeButton, "BottomRight")
box:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
box:SetBackdropColor(0, 0, 0, 0.2)
local rows = 4
local columns = 3
local buttonWidth = box:GetWidth() / columns
local buttonHeight = box:GetHeight() / rows

local function Click(arg, mouse)
    if arg == "/roll" then
        RandomRoll(1, 100)
    elseif arg == "/clear" then
        SELECTED_DOCK_FRAME:Clear()
    elseif arg == "/reload" then
        ReloadUI()
    elseif strfind(arg, "/") then
        ChatFrame_OpenChat(arg .. SELECTED_DOCK_FRAME.editBox:GetText(), SELECTED_DOCK_FRAME)
    else
        local channelIndex
        local channelList = { GetChannelList() }
        for i = 1, #channelList do
            if channelList[i] == arg then
                channelIndex = channelList[i - 1]
                break
            end
        end

        if mouse == "RightButton" then
            if channelIndex then
                LeaveChannelByName(arg)
                print("|cffffff00已離開" .. arg .. "|r")
            else
                JoinPermanentChannel(arg, nil, 1, 1)
                print("|cff00ff00已加入" .. arg .. "|r")
            end
        else
            if channelIndex then
                ChatFrame_OpenChat("/" .. channelIndex .. " " .. SELECTED_DOCK_FRAME.editBox:GetText(), SELECTED_DOCK_FRAME)
            else
                print("|cffff0000未加入" .. arg .. "|r")
            end
        end
    end
end

local function CreateChannelButton(row, column)
    local button = CreateFrame("Button", nil, box)
    button:SetSize(buttonWidth, buttonHeight)
    button:SetPoint("TopLeft", (column - 1) * buttonWidth, (1 - row) * buttonHeight)

    local index = column + (row - 1) * columns
    local text = button:CreateFontString()
    text:SetFont(GameFontNormal:GetFont(), 16, "Outline")
    text:SetPoint("Center")
    text:SetText(buttons[index].text)
    text:SetTextColor(RAID_CLASS_COLORS[buttons[index].color]:GetRGB())

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button:SetScript("OnClick", function(_, mouse)
        Click(buttons[index].arg, mouse)
    end)
end

for i = 1, rows do
    for j = 1, columns do
        CreateChannelButton(i, j)
    end
end