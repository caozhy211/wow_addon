local size = 29
local rows = 4
local columns = 3

---@type Frame
local channelFrame = CreateFrame("Frame", "WLK-ChatChannelFrame", UIParent)
channelFrame:SetSize(size * columns, size * rows)
channelFrame:SetPoint("TOPRIGHT", ChatFrame1ResizeButton, "BOTTOMRIGHT")
--- 设置较高的层级，防止出现和动作条纹理重叠导致按钮无法点击的问题
channelFrame:SetFrameStrata("Dialog")
channelFrame:SetBackdrop({ bgFile = "Interface/ChatFrame/CHATFRAMEBACKGROUND", })
local r, g, b = GetTableColor(DEFAULT_CHATFRAME_COLOR)
channelFrame:SetBackdropColor(r, g, b, DEFAULT_CHATFRAME_ALPHA)

local buttonTables = {
    { text = "說", color = "PRIEST", arg = "/s ", },
    { text = "喊", color = "DEATHKNIGHT", arg = "/y ", },
    { text = "隊", color = "WARLOCK", arg = "/p ", },
    { text = "會", color = "MONK", arg = "/g ", },
    { text = "團", color = "DRUID", arg = "/raid ", },
    { text = "副", color = "PALADIN", arg = "/i ", },
    { text = "綜", color = "WARRIOR", arg = COMMUNITIES_DEFAULT_CHANNEL_NAME, },
    { text = "尋", color = "DEMONHUNTER", arg = LOOK_FOR_GROUP, },
    { text = "組", color = "SHAMAN", arg = "組隊頻道", },
    { text = "骰", color = "ROGUE", arg = "/roll", },
    { text = "清", color = "HUNTER", arg = "/clear", },
    { text = "重", color = "MAGE", arg = "/reload", },
}

--- 点击按钮
---@param button string 鼠标按键
---@param arg string 参数
local function ChannelButtonOnClick(button, arg)
    ---@type MessageFrame
    local chatFrame = SELECTED_DOCK_FRAME
    ---@type EditBox
    local editBox = chatFrame.editBox
    local text = editBox:GetText()

    if arg == "/roll" then
        RandomRoll(1, 100)
    elseif arg == "/clear" then
        chatFrame:Clear()
    elseif arg == "/reload" then
        ReloadUI()
    elseif strfind(arg, "/") then
        ChatFrame_OpenChat(arg .. text, chatFrame)
    else
        local channelIndex
        -- 获取频道列表
        local channelList = { GetChannelList() }
        for i = 2, #channelList, 3 do
            -- 获取频道索引
            if channelList[i] == arg then
                channelIndex = channelList[i - 1]
                break
            end
        end

        -- 鼠标右键点击时，加入或离开频道；左键点击时，使用此频道打开聊天输入框
        if button == "RightButton" then
            if channelIndex then
                LeaveChannelByName(arg)
                chatFrame:AddMessage("已離開" .. arg, GetTableColor(YELLOW_FONT_COLOR))
            else
                JoinPermanentChannel(arg, nil, chatFrame:GetID(), 1)
                ChatFrame_AddChannel(chatFrame, arg)
                chatFrame:AddMessage("已加入" .. arg, GetTableColor(GREEN_FONT_COLOR))
            end
        else
            if channelIndex then
                ChatFrame_OpenChat("/" .. channelIndex .. " " .. text, chatFrame)
            else
                chatFrame:AddMessage("未加入" .. arg, GetTableColor(RED_FONT_COLOR))
            end
        end
    end
end

--- 创建按钮
---@param row number 第 row 行
---@param column number 第 column 列
local function CreateChannelButton(row, column)
    ---@type Button
    local btn = CreateFrame("Button", nil, channelFrame)
    btn:SetSize(size, size)
    btn:SetPoint("TOPLEFT", (column - 1) * size, (1 - row) * size)

    local index = column + (row - 1) * columns
    local bTable = buttonTables[index]
    ---@type FontString
    local label = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetText(bTable.text)
    label:SetTextColor(GetClassColor(bTable.color))

    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function(_, button)
        ChannelButtonOnClick(button, bTable.arg)
    end)
end

for i = 1, rows do
    for j = 1, columns do
        CreateChannelButton(i, j)
    end
end
