local bar = CreateFrame("Frame", "ChatBar", UIParent)
bar:SetWidth(30)
bar:SetHeight(300)
bar:SetPoint("TopLeft", ChatFrame1, "TopRight", 21, 0)

local function OpenChat(channel)
    ChatFrame_OpenChat(channel .. SELECTED_DOCK_FRAME.editBox:GetText(), SELECTED_DOCK_FRAME)
end

local function TeamChannel(self, button)
    if button == "RightButton" then
        local _, channelName, _ = GetChannelName("組隊頻道")
        if channelName == nil then
            JoinPermanentChannel("組隊頻道", nil, 1, 1)
            ChatFrame_AddChannel(SELECTED_DOCK_FRAME, "組隊頻道")
            print("|cff00d200已加入組隊頻道|r")
        else
            LeaveChannelByName("組隊頻道")
            print("|cffd20000已离开組隊頻道|r")
        end
    else
        local channel, _, _ = GetChannelName("組隊頻道")
        ChatFrame_OpenChat("/" .. channel .. " " .. SELECTED_DOCK_FRAME.editBox:GetText(), SELECTED_DOCK_FRAME)
    end
end

local function Roll()
    RandomRoll(1, 100)
end

local function Clear()
    SELECTED_DOCK_FRAME:Clear()
end

local function Reload()
    ReloadUI()
end

bar.buttons = {
    { text = "說", color = RAID_CLASS_COLORS["PRIEST"], channel = "/s " },
    { text = "喊", color = RAID_CLASS_COLORS["DEATHKNIGHT"], channel = "/y " },
    { text = "隊", color = RAID_CLASS_COLORS["WARLOCK"], channel = "/p " },
    { text = "會", color = RAID_CLASS_COLORS["MONK"], channel = "/g " },
    { text = "團", color = RAID_CLASS_COLORS["DRUID"], channel = "/raid " },
    { text = "副", color = RAID_CLASS_COLORS["PALADIN"], channel = "/i " },
    { text = "綜", color = RAID_CLASS_COLORS["WARRIOR"], channel = "/1 " },
    { text = "尋", color = RAID_CLASS_COLORS["DEMONHUNTER"], channel = "/4 " },
    { text = "組", color = RAID_CLASS_COLORS["SHAMAN"], onClick = TeamChannel },
    { text = "骰", color = RAID_CLASS_COLORS["ROGUE"], onClick = Roll },
    { text = "清", color = RAID_CLASS_COLORS["HUNTER"], onClick = Clear },
    { text = "重", color = RAID_CLASS_COLORS["MAGE"], onClick = Reload },
}

for i = 1, #bar.buttons do
    local button = CreateFrame("Button", nil, bar)
    button:SetWidth(25)
    button:SetHeight(25)
    button:SetPoint("Top", bar, "Top", 0, (i - 1) * -25)
    button:RegisterForClicks("AnyUp")
    button:SetScript("OnClick", function()
        if bar.buttons[i].channel then
            OpenChat(bar.buttons[i].channel)
        else
            bar.buttons[i].onClick()
        end
    end)

    button.text = button:CreateFontString(nil, "Artwork")
    button.text:SetFont("Fonts\\ARHei.ttf", 16, "Outline")
    button.text:SetText(bar.buttons[i].text)
    local color = bar.buttons[i].color
    button.text:SetTextColor(color.r, color.g, color.b)
    button.text:SetPoint("Center", button, "Center", 0, 0)
end

