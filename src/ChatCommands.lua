local size = 29
local rows = 4
local columns = 3

---@type Frame
local chatCommandFrame = CreateFrame("Frame", "WLK-ChatCommandFrame", UIParent)
chatCommandFrame:SetSize(size * columns, size * rows)
chatCommandFrame:SetPoint("TOPRIGHT", ChatFrame1ResizeButton, "BOTTOMRIGHT")
--- 设置较高的层级，防止出现和动作条纹理重叠导致按钮无法点击的问题
chatCommandFrame:SetFrameStrata("Dialog")
chatCommandFrame:SetBackdrop({ bgFile = "Interface/ChatFrame/CHATFRAMEBACKGROUND", })
local r, g, b = GetTableColor(DEFAULT_CHATFRAME_COLOR)
chatCommandFrame:SetBackdropColor(r, g, b, DEFAULT_CHATFRAME_ALPHA)

local buttonTables = {
    { text = "說", color = "PRIEST", command = "/s ", },
    { text = "喊", color = "DEATHKNIGHT", command = "/y ", },
    { text = "隊", color = "WARLOCK", command = "/p ", },
    { text = "會", color = "MONK", command = "/g ", },
    { text = "團", color = "DRUID", command = "/raid ", },
    { text = "副", color = "PALADIN", command = "/i ", },
    { text = "綜", color = "WARRIOR", command = COMMUNITIES_DEFAULT_CHANNEL_NAME, },
    { text = "尋", color = "DEMONHUNTER", command = LOOK_FOR_GROUP, },
    { text = "組", color = "SHAMAN", command = "組隊頻道", },
    { text = "骰", color = "ROGUE", command = "/roll", },
    { text = "清", color = "HUNTER", command = "/clear", },
    { text = "重", color = "MAGE", command = "/reload", },
}

--- 点击按钮
---@param button string 鼠标按键
---@param command string 命令
local function CommandButtonOnClick(button, command)
    ---@type MessageFrame
    local chatFrame = SELECTED_DOCK_FRAME
    ---@type EditBox
    local editBox = chatFrame.editBox
    local text = editBox:GetText()

    if command == "/roll" then
        RandomRoll(1, 100)
    elseif command == "/clear" then
        chatFrame:Clear()
    elseif command == "/reload" then
        ReloadUI()
    elseif strfind(command, "/") then
        ChatFrame_OpenChat(command .. text, chatFrame)
    else
        local channelName = command
        local channelIndex
        -- 获取频道列表
        local channelList = { GetChannelList() }
        for i = 2, #channelList, 3 do
            -- 获取频道索引
            if channelList[i] == channelName then
                channelIndex = channelList[i - 1]
                break
            end
        end

        -- 鼠标右键点击时，加入或离开频道；左键点击时，使用此频道打开聊天输入框
        if button == "RightButton" then
            if channelIndex then
                LeaveChannelByName(channelName)
                chatFrame:AddMessage("已離開" .. channelName, GetTableColor(YELLOW_FONT_COLOR))
            else
                JoinPermanentChannel(channelName, nil, chatFrame:GetID(), 1)
                ChatFrame_AddChannel(chatFrame, channelName)
                chatFrame:AddMessage("已加入" .. channelName, GetTableColor(GREEN_FONT_COLOR))
            end
        else
            if channelIndex then
                ChatFrame_OpenChat("/" .. channelIndex .. " " .. text, chatFrame)
            else
                chatFrame:AddMessage("未加入" .. channelName, GetTableColor(RED_FONT_COLOR))
            end
        end
    end
end

--- 创建按钮
---@param row number 第 row 行
---@param column number 第 column 列
local function CreateCommandButton(row, column)
    ---@type Button
    local btn = CreateFrame("Button", nil, chatCommandFrame)
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
        CommandButtonOnClick(button, bTable.command)
    end)
end

for i = 1, rows do
    for j = 1, columns do
        CreateCommandButton(i, j)
    end
end
