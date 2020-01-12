local _, class = UnitClass("player")
if class == "WARLOCK" then
    ---@type Frame
    local shardFrame = CreateFrame("Frame", "WLK_SoulShardFrame", UIParent)
    shardFrame:SetSize(228, 20)
    shardFrame:SetPoint("BOTTOM", 0, 185)
    shardFrame:SetAlpha(0)

    ---@type FontString 灵魂碎片裂片标签
    local partialLabel = shardFrame:CreateFontString(nil, "ARTWORK", "Game15Font_o1")
    partialLabel:SetTextColor(GetTableColor(YELLOW_FONT_COLOR))

    local maxShards = UnitPowerMax("player", Enum.PowerType.SoulShards)
    local shardWidth = shardFrame:GetHeight() * 2
    local spacing = floor((shardFrame:GetWidth() - maxShards * shardWidth) / (maxShards - 1))
    ---@type table<number, Frame>
    local shards = {}
    for i = 1, maxShards do
        ---@type Frame
        local shard = CreateFrame("Frame", nil, shardFrame)
        shard:SetSize(shardWidth, shardFrame:GetHeight())
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

    if UnitLevel("player") < SHARDBAR_SHOW_LEVEL then
        shardFrame:RegisterEvent("PLAYER_LEVEL_UP")
    else
        shardFrame:RegisterEvent("PLAYER_LOGIN")
        shardFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    end

    shardFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_LEVEL_UP" then
            local level = ...
            if level >= SHARDBAR_SHOW_LEVEL then
                shardFrame:UnregisterEvent(event)
                shardFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
                shardFrame:SetAlpha(1)
            end
        elseif event == "PLAYER_LOGIN" or event == "UNIT_POWER_FREQUENT" then
            if event == "PLAYER_LOGIN" then
                shardFrame:UnregisterEvent(event)
                shardFrame:SetAlpha(1)
            end
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
    end)
end
