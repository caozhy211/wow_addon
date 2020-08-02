---@type Frame
local UIParent = UIParent
--- WorldMapFrame 底部相对屏幕底部偏移 430px，ExtraActionBarFrame（包括纹理）顶部相对屏幕底部偏移 405px，所有使用 TOP_OFFSET
--- 属性设置位置的框架都将下移
UIParent:SetAttribute("TOP_OFFSET", -116 - (430 - 315 - 90))
---@type Frame
local talkingHeadFrame = TalkingHeadFrame
talkingHeadFrame:ClearAllPoints()
--- TalkingHeadFrame 的宽度是 570px，TopLeftCorner 顶部相对 PortraitFrameTemplate 顶部偏移 16px
talkingHeadFrame:SetPoint("CENTER", UIParent, "TOPLEFT", 570 / 2, (UIParent:GetAttribute("TOP_OFFSET") + 16) / 2)
talkingHeadFrame.SetPoint = nop

---@type Frame
local buffFrame = BuffFrame

--- 设置 BuffFrame 的位置
hooksecurefunc("UIParent_UpdateTopFramePositions", function()
    local buffsAreaTopOffset = 5
    ---@type Frame
    local orderHallCommandBar = OrderHallCommandBar
    -- 职业大厅条显示时需要下移
    if orderHallCommandBar and orderHallCommandBar:IsShown() then
        buffsAreaTopOffset = buffsAreaTopOffset + orderHallCommandBar:GetHeight()
    end
    -- 左边界相对屏幕右边偏移 -570px，AuraButton 的宽度是 30px
    buffFrame:SetPoint("TOPRIGHT", -570 + (30 * BUFFS_PER_ROW + BUFF_HORIZ_SPACING * (1 - BUFFS_PER_ROW)),
            -buffsAreaTopOffset)
end)

--- BuffFrame 的高度是 50px，BuffArea 相对屏幕顶部偏移 -13px，OrderHallCommandBar 的高度是 25px，BuffArea 下边界相对屏幕顶部偏
--- 移 -315px，TemporaryEnchant 最多有 3 个
local buffMaxRows = ceil((BUFF_MAX_DISPLAY + 3) / BUFFS_PER_ROW)
local debuffMaxRows = ceil(DEBUFF_MAX_DISPLAY / BUFFS_PER_ROW)
local buffRowSpacing = floor((315 - 5 - 25 - 50 - (buffMaxRows + debuffMaxRows) * BUFF_BUTTON_HEIGHT) / (buffMaxRows
        + debuffMaxRows - 1))

--- 设置 BuffButton 位置
hooksecurefunc("BuffFrame_UpdateAllBuffAnchors", function()
    local aboveBuff, index
    local numBuffs = 0
    local slack = BuffFrame.numEnchants
    for i = 1, BUFF_ACTUAL_DISPLAY do
        ---@type Button
        local buff = _G["BuffButton" .. i]
        numBuffs = numBuffs + 1
        index = numBuffs + slack
        if index > 1 and mod(index, BUFFS_PER_ROW) == 1 then
            -- 设置非第一行的第一个 buff 的位置
            buff:ClearAllPoints()
            buff:SetPoint("TOPRIGHT", aboveBuff, "BOTTOMRIGHT", 0, -buffRowSpacing)
            aboveBuff = buff
        elseif index == 1 then
            aboveBuff = buff
        elseif numBuffs == 1 and slack > 0 then
            -- 有 TemporaryEnchant 时，第二行第一个 buff 的锚点是 TemporaryEnchantFrame
            aboveBuff = TemporaryEnchantFrame
        end
    end
end)

--- 设置 DebuffButton 位置
hooksecurefunc("DebuffButton_UpdateAnchors", function(buttonName, index)
    local numBuffs = BUFF_ACTUAL_DISPLAY + BuffFrame.numEnchants
    local rows = ceil(numBuffs / BUFFS_PER_ROW)
    ---@type Button
    local buff = _G[buttonName .. index]
    if index > 1 and mod(index, BUFFS_PER_ROW) == 1 then
        buff:SetPoint("TOP", _G[buttonName .. (index - BUFFS_PER_ROW)], "BOTTOM", 0, -buffRowSpacing)
    elseif index == 1 then
        local yOffset
        if rows < 2 then
            yOffset = 2 * buffRowSpacing + BUFF_BUTTON_HEIGHT
        else
            yOffset = rows * (BUFF_BUTTON_HEIGHT + buffRowSpacing)
        end
        buff:SetPoint("TOPRIGHT", buffFrame, "BOTTOMRIGHT", 0, -yOffset)
    end
end)

--- 设置光环持续时间的字体和位置
hooksecurefunc("AuraButton_OnUpdate", function(self)
    ---@type FontString
    local duration = self.duration
    -- 提高字体的层级，防止被 debuff 的边框覆盖
    duration:SetDrawLayer("OVERLAY")
    if self.timeLeft > SECONDS_PER_HOUR and self.timeLeft < SECONDS_PER_DAY then
        duration:SetFontObject("Game10Font_o1")
    else
        duration:SetFontObject("SystemFont_Outline_Small")
    end
    duration:ClearAllPoints()
    duration:SetPoint("TOPRIGHT")
end)

--- LossOfControlFrame 的高度是 58px，纹理 RedLineTop 和 RedLineBottom 的高度是 27px，下边界相对屏幕底部偏移 185 + 20 + 1 +
--- 33 + 1 = 240px，上边界相对屏幕底部偏移 314px
local scale = (314 - 240) / (58 + 27 * 2)
--- 保留两位小数
scale = scale - scale % 0.01
---@type Frame
local lossOfControlFrame = LossOfControlFrame
lossOfControlFrame:SetScale(scale)
lossOfControlFrame:SetPoint("CENTER", UIParent, "BOTTOM", 0, (240 + (314 - 240) / 2) / scale)

--- 待更新位置的团队队伍框架
local needUpdateFrames = {}
--- 团队单位之间的间距，Settings.lua 中自定义设置的值
local spacing = 2
--- 团队队伍的行数，Settings.lua 中自定义设置的值
local rows = 4

--- 调整团队单位框架位置
---@param frame Frame 团队队伍框架
local function UpdateCompactRaidGroupLayout(frame)
    local name = frame:GetName()
    ---@type Button 队名
    local title = frame.title
    local totalHeight = title:GetHeight()
    local totalWidth = 0
    ---@type Frame 队伍的第一个单位
    local frame1 = _G[frame:GetName() .. "Member1"]
    frame1:ClearAllPoints()

    if CUF_HORIZONTAL_GROUPS then
        -- 队伍水平排列
        frame1:SetPoint("TOPLEFT", 0, -totalHeight - spacing)
        for i = 2, MEMBERS_PER_RAID_GROUP do
            ---@type Frame 团队单位
            local unitFrame = _G[name .. "Member" .. i]
            unitFrame:ClearAllPoints()
            unitFrame:SetPoint("LEFT", _G[name .. "Member" .. (i - 1)], "RIGHT", spacing, 0)
        end
        totalHeight = totalHeight + spacing + frame1:GetHeight()
        totalWidth = totalWidth + MEMBERS_PER_RAID_GROUP * frame1:GetWidth() + (MEMBERS_PER_RAID_GROUP - 1) * spacing
    else
        -- 队伍垂直排列
        local id = frame:GetID()
        if id > 0 and mod(id, rows) ~= 1 then
            -- 非第一行的队伍标题需要向下偏移 spacing
            title:ClearAllPoints()
            title:SetPoint("TOP", 0, -spacing)
            totalHeight = totalHeight + spacing
        end
        frame1:SetPoint("TOPRIGHT", 0, -totalHeight - spacing)
        for i = 2, MEMBERS_PER_RAID_GROUP do
            ---@type Frame 团队单位
            local unitFrame = _G[name .. "Member" .. i]
            unitFrame:ClearAllPoints()
            unitFrame:SetPoint("TOP", _G[name .. "Member" .. (i - 1)], "BOTTOM", 0, -spacing)
        end
        totalHeight = totalHeight + (frame1:GetHeight() + spacing) * MEMBERS_PER_RAID_GROUP
        totalWidth = totalWidth + frame1:GetWidth() + spacing
    end

    -- 添加边框大小
    ---@type Frame
    local borderFrame = frame.borderFrame
    if borderFrame:IsShown() then
        totalWidth = totalWidth + 12
        totalHeight = totalHeight + 4
    end
    -- 重新设置团队队伍框架大小
    frame:SetSize(totalWidth, totalHeight)
end

---@type Frame
local objectiveTrackerFrame = ObjectiveTrackerFrame
--- 使框体可以被移动
objectiveTrackerFrame:SetMovable(true)
--- 不使用 blz 的 UIParent.lua 动态调整位置
objectiveTrackerFrame:SetUserPlaced(true)

---@type Frame
local eventListener = CreateFrame("Frame")

eventListener:RegisterEvent("PLAYER_LOGIN")

---@param self Frame
eventListener:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        objectiveTrackerFrame:ClearAllPoints()
        -- MicroButtonAndBagsBar 左边相对屏幕右边偏移 -298px，PoiButton 左边相对 objectiveTrackerFrame 左边偏移 -29px，上边界
        -- 相对屏幕顶部偏移 -330px；MultiBarRightButton 的宽度是 32px，MultiBarRightButton 右边相对屏幕右边偏移 -2px，
        -- MicroButtonAndBagsBar 顶部相对屏幕底部偏移 88px
        objectiveTrackerFrame:SetPoint("TOPLEFT", GetScreenWidth() - 298 + 29, -330)
        objectiveTrackerFrame:SetPoint("BOTTOMRIGHT", -(2 + 32), 88 + 2)
        -- 防止框体被移至默认位置
        objectiveTrackerFrame:SetMovable(false)
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- 位置更新后，清空 needUpdateFrames 并取消注册 PLAYER_REGEN_ENABLED 事件
        for i = 1, #needUpdateFrames do
            UpdateCompactRaidGroupLayout(needUpdateFrames[i])
        end
        wipe(needUpdateFrames)
    end
    self:UnregisterEvent(event)
end)

--- 修改团队单位之间的间距
hooksecurefunc("CompactRaidGroup_UpdateLayout", function(frame)
    if InCombatLockdown() then
        -- 处于战斗状态时，把 frame 添加到 needUpdateFrames 中，并注册 PLAYER_REGEN_ENABLED 事件，当离开战斗时再更新位置
        tinsert(needUpdateFrames, frame)
        if not eventListener:IsEventRegistered("PLAYER_REGEN_ENABLED") then
            eventListener:RegisterEvent("PLAYER_REGEN_ENABLED")
        end
    else
        UpdateCompactRaidGroupLayout(frame)
    end
end)

---@type Frame
local bankFrame = BankFrame

--- 调整背包位置
hooksecurefunc("UpdateContainerFrameAnchors", function()
    -- ContainerFrame1 底部相对屏幕底部偏移 130px，NoticePane 顶部相对屏幕底部偏移 156px
    local containerOffsetY = CONTAINER_OFFSET_Y + 156 - 130
    local containerFrameOffsetX = max(CONTAINER_OFFSET_X, MINIMUM_CONTAINER_OFFSET_X)
    local xOffset, yOffset, screenHeight, freeScreenHeight, leftMostPoint, column
    local screenWidth = GetScreenWidth()
    local containerScale = 1
    local leftLimit = 0
    if bankFrame:IsShown() then
        leftLimit = bankFrame:GetRight() - 25
    end

    while containerScale > CONTAINER_SCALE do
        screenHeight = GetScreenHeight() / containerScale
        -- Adjust the start anchor for bags depending on the multibars
        xOffset = containerFrameOffsetX / containerScale
        yOffset = containerOffsetY / containerScale
        -- freeScreenHeight determines when to start a new column of bags
        freeScreenHeight = screenHeight - yOffset
        leftMostPoint = screenWidth - xOffset
        column = 1
        local frameHeight
        for i = 1, #(ContainerFrame1.bags) do
            ---@type Frame
            local containerFrame = _G[ContainerFrame1.bags[i]]
            frameHeight = containerFrame:GetHeight()
            if freeScreenHeight < frameHeight then
                -- Start a new column
                column = column + 1
                leftMostPoint = screenWidth - (column * CONTAINER_WIDTH * containerScale) - xOffset
                freeScreenHeight = screenHeight - yOffset
            end
            freeScreenHeight = freeScreenHeight - frameHeight - VISIBLE_CONTAINER_SPACING
        end
        if leftMostPoint < leftLimit then
            containerScale = containerScale - 0.01
        else
            break
        end
    end

    if containerScale < CONTAINER_SCALE then
        containerScale = CONTAINER_SCALE
    end

    screenHeight = GetScreenHeight() / containerScale
    -- Adjust the start anchor for bags depending on the multibars
    xOffset = containerFrameOffsetX / containerScale
    yOffset = containerOffsetY / containerScale
    -- freeScreenHeight determines when to start a new column of bags
    freeScreenHeight = screenHeight - yOffset
    column = 0
    for i = 1, #(ContainerFrame1.bags) do
        --for index, frameName in ipairs(ContainerFrame1.bags) do
        ---@type Frame
        local frame = _G[ContainerFrame1.bags[i]]
        frame:SetScale(containerScale)
        if i == 1 then
            -- First bag
            frame:SetPoint("BOTTOMRIGHT", -xOffset, yOffset)
        elseif freeScreenHeight < frame:GetHeight() then
            -- Start a new column
            column = column + 1
            freeScreenHeight = screenHeight - yOffset
            frame:SetPoint("BOTTOMRIGHT", -(column * CONTAINER_WIDTH) - xOffset, yOffset)
        else
            -- Anchor to the previous bag
            frame:SetPoint("BOTTOMRIGHT", ContainerFrame1.bags[i - 1], "TOPRIGHT", 0, CONTAINER_SPACING)
        end
        freeScreenHeight = freeScreenHeight - frame:GetHeight() - VISIBLE_CONTAINER_SPACING
    end
end)
