local bar = CreateFrame("Frame", "ChatBarFrame", UIParent)

-- 設置框架層級比載具快捷列高
bar:SetFrameStrata("DIALOG")
bar:SetWidth(75)
bar:SetHeight(110)
bar:SetPoint("TopRight", ChatFrame1ResizeButton, "BottomRight")

local function OnClick(self, mouse, arg)
    if arg == "/roll" then
        RandomRoll(1, 100)
    elseif arg == "/clear" then
        SELECTED_DOCK_FRAME:Clear()
    elseif arg == "/reload" then
        ReloadUI()
    elseif arg:find("/") then
        ChatFrame_OpenChat(arg .. SELECTED_DOCK_FRAME.editBox:GetText(), SELECTED_DOCK_FRAME)
    else
        local channelNum
        local channelList = { GetChannelList() }
        for i = 1, #channelList do
            if channelList[i] == arg then
                channelNum = channelList[i - 1]
                break
            end
        end

        if mouse == "RightButton" then
            if channelNum then
                LeaveChannelByName(arg)
                print("|cff00d200已離開" .. arg .. "|r")
            else
                JoinPermanentChannel(arg, nil, 1, 1)
                print("|cff00d200已加入" .. arg .. "|r")
            end
        else
            if channelNum then
                ChatFrame_OpenChat("/" .. channelNum .. " " .. SELECTED_DOCK_FRAME.editBox:GetText(), SELECTED_DOCK_FRAME)
            else
                print("|cffd20000未加入" .. arg .. "|r")
            end
        end
    end
end

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

for i = 1, #buttons do
    local button = CreateFrame("Button", "ChatButton" .. i, bar)

    button:SetWidth(25)
    button:SetHeight(27.5)
    if i == 1 then
        button:SetPoint("TopLeft")
    elseif i % 3 == 1 then
        button:SetPoint("Top", _G["ChatButton" .. (i - 3)], "Bottom")
    else
        button:SetPoint("Left", _G["ChatButton" .. (i - 1)], "Right")
    end

    button:RegisterForClicks("AnyUp")
    button:SetScript("OnClick", function(self, mouse)
        OnClick(self, mouse, buttons[i].arg)
    end)

    button.text = button:CreateFontString()
    button.text:SetFont(GameFontNormal:GetFont(), 16, "Outline")
    button.text:SetText(buttons[i].text)
    local r, g, b = GetClassColor(buttons[i].color)
    button.text:SetTextColor(r, g, b)
    button.text:SetPoint("Right", 3, -1)
end