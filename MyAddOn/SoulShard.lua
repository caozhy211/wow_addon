local _, class = UnitClass("player")
if class == "WARLOCK" then
    local color = RAID_CLASS_COLORS[class]
    local shards = {}
    local soulShard = CreateFrame("Frame", "MySoulShard", UIParent)
    soulShard:SetSize(228, 20)
    soulShard:SetPoint("BottomRight", CastingBarFrame, "TopRight", 0, 3 + 2)
    local text = soulShard:CreateFontString()
    text:SetFont(GameFontNormal:GetFont(), 16, "Outline")
    text:SetTextColor(1, 1, 0)
    local height = soulShard:GetHeight()
    local width = height * 2
    local border = 2
    local spacing

    soulShard:RegisterEvent("PLAYER_LOGIN")
    soulShard:RegisterEvent("UNIT_POWER_UPDATE")

    soulShard:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_LOGIN" then
            local maxNumPower = UnitPowerMax("player", Enum.PowerType.SoulShards)
            spacing = (self:GetWidth() - maxNumPower * width) / (maxNumPower - 1)
            for i = 1, maxNumPower do
                local shard = self:CreateTexture()
                shard:SetSize(width, height)
                shard:SetPoint("Left", (width + spacing) * (i - 1), 0)
                shard:SetColorTexture(color:GetRGB())
                self:CreateShardBorder(shard)
                shards[i] = shard
            end
            self:Update()
        elseif unit == "player" then
            self:Update()
        end
    end)

    function soulShard:CreateShardBorder(shard)
        local top = self:CreateTexture(nil, "Overlay")
        top:SetSize(width - 2 * border, border)
        top:SetPoint("Top", shard)
        top:SetColorTexture(1, 1, 1)
        local bottom = self:CreateTexture(nil, "Overlay")
        bottom:SetSize(width - 2 * border, border)
        bottom:SetPoint("Bottom", shard)
        bottom:SetColorTexture(1, 1, 1)
        local left = self:CreateTexture(nil, "Overlay")
        left:SetSize(border, height)
        left:SetPoint("Left", shard)
        left:SetColorTexture(1, 1, 1)
        local right = self:CreateTexture(nil, "Overlay")
        right:SetSize(border, height)
        right:SetPoint("Right", shard)
        right:SetColorTexture(1, 1, 1)
    end

    function soulShard:Update()
        local numPower = WarlockPowerBar_UnitPower("player")
        local numShards, numSlivers = math.modf(numPower)
        for i = 1, #shards do
            shards[i]:SetAlpha(i > numShards and 0 or 1)

            if i == numShards + 1 and numSlivers > 0 then
                text:SetText(numSlivers * 10)
                text:SetPoint("Center", shards[i])
            elseif numSlivers == 0 then
                text:SetText("")
            end
        end
    end
end