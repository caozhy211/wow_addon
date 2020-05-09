local _, class = UnitClass("player")
if class == "WARLOCK" then
    ---@type Frame
    local shardPane = CreateFrame("Frame", "WLK_SoulShardPane", UIParent)
    shardPane:SetSize(228, 20)
    shardPane:SetPoint("BOTTOM", 0, 185)

    ---@type FontString 灵魂碎片裂片标签
    local partialLabel = shardPane:CreateFontString(nil, "ARTWORK", "Game15Font_o1")
    partialLabel:SetTextColor(GetTableColor(YELLOW_FONT_COLOR))

    ---@type table<number, Frame>
    local shards = {}

    if UnitLevel("player") < SHARDBAR_SHOW_LEVEL then
        -- 等级低于显示灵魂碎片的等级时，隐藏碎片面板，并注册 PLAYER_LEVEL_UP 事件
        shardPane:SetAlpha(0)
        shardPane:RegisterEvent("PLAYER_LEVEL_UP")
    else
        shardPane:RegisterEvent("PLAYER_LOGIN")
        shardPane:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    end

    --- 创建灵魂碎片框架
    local function CreateShardFrame()
        local shardWidth = shardPane:GetHeight() * 2
        local maxShards = UnitPowerMax("player", Enum.PowerType.SoulShards)
        local spacing = floor((shardPane:GetWidth() - maxShards * shardWidth) / (maxShards - 1))
        for i = 1, maxShards do
            ---@type Frame
            local shard = CreateFrame("Frame", nil, shardPane)
            shard:SetSize(shardWidth, shardPane:GetHeight())
            shard:SetPoint("LEFT", (shardWidth + spacing) * (i - 1), 0)
            shard:SetBackdrop({
                edgeFile = "Interface/Buttons/WHITE8X8",
                edgeSize = 2,
            })
            ---@type Texture
            local background = shard:CreateTexture(nil, "BACKGROUND")
            background:SetAllPoints()
            background:SetTexture("Interface/ChatFrame/CHATFRAMEBACKGROUND")
            background:SetColorTexture(GetClassColor(class))
            shard.background = background
            tinsert(shards, shard)
        end
    end

    --- 更新灵魂碎片
    local function UpdateShards()
        local power = WarlockPowerBar_UnitPower("player")
        local numShards, numPartials = math.modf(power)
        for i = 1, #shards do
            shards[i].background:SetAlpha(i > numShards and 0 or 1)
            -- 显示灵魂碎片裂片数量
            if numPartials > 0 and i == numShards + 1 then
                partialLabel:SetText(numPartials * 10)
                partialLabel:SetPoint("CENTER", shards[i])
            elseif numPartials == 0 then
                partialLabel:SetText("")
            end
        end
    end

    ---@param self Frame
    shardPane:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LEVEL_UP" then
            local level = ...
            if level >= SHARDBAR_SHOW_LEVEL then
                self:UnregisterEvent(event)
                self:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
                self:SetAlpha(1)
                CreateShardFrame()
                UpdateShards()
            end
        elseif event == "PLAYER_LOGIN" then
            self:UnregisterEvent(event)
            CreateShardFrame()
            UpdateShards()
        elseif event == "UNIT_POWER_FREQUENT" then
            UpdateShards()
        end
    end)
end
