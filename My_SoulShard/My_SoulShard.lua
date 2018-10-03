local ss = CreateFrame("Frame", "SoulShardFrame", UIParent)

-- 靈魂裂片碎塊文字
ss.text = ss:CreateFontString(nil, "Overlay")
ss.text:SetFont(GameFontNormal:GetFont(), 16)
ss.text:SetTextColor(1, 1, 0)

local shards = {}

-- 靈魂裂片大小
local height = 22
local width = 40
local spacing = 7

local maxNumPower = UnitPowerMax("player", Enum.PowerType.SoulShards)
ss:SetHeight(height)
ss:SetWidth(width * maxNumPower + spacing * (maxNumPower - 1))
ss:SetPoint("Bottom", SwingBar, "Top", 0, 7)
for i = 1, maxNumPower do
    local shard = ss:CreateTexture(nil, "Artwork")
    shard:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    shard:SetColorTexture(0.53, 0.53, 0.93, 1)
    shard:SetWidth(width)
    shard:SetHeight(height)
    shard:SetPoint("Left", (width + spacing) * (i - 1), 0)
    shards[i] = shard

    local topBorder = ss:CreateTexture(nil, "Overlay")
    topBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    topBorder:SetWidth(width)
    topBorder:SetHeight(2)
    topBorder:SetPoint("Top", shard)

    local bottomBorder = ss:CreateTexture(nil, "Overlay")
    bottomBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bottomBorder:SetWidth(width)
    bottomBorder:SetHeight(2)
    bottomBorder:SetPoint("Bottom", shard)

    local leftBorder = ss:CreateTexture(nil, "Overlay")
    leftBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    leftBorder:SetWidth(2)
    leftBorder:SetHeight(height)
    leftBorder:SetPoint("Left", shard)

    local rightBorder = ss:CreateTexture(nil, "Overlay")
    rightBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    rightBorder:SetWidth(2)
    rightBorder:SetHeight(height)
    rightBorder:SetPoint("Right", shard)
end

function ss:Update()
    local numPower = WarlockPowerBar_UnitPower("player")
    local numShards, numSlivers = math.modf(numPower)
    for i = 1, #shards do
        shards[i]:SetAlpha(i > numShards and 0 or 1)

        -- 顯示靈魂裂片碎塊數量
        if i == numShards + 1 and numSlivers > 0 then
            self.text:SetText(numSlivers * 10)
            self.text:SetPoint("Center", ss, "Left", width * (numShards + 0.5) + spacing * numShards, 0)
        elseif numSlivers == 0 then
            self.text:SetText("")
        end
    end
end

ss:RegisterEvent("PLAYER_LOGIN")
ss:RegisterEvent("UNIT_POWER_UPDATE")
ss:SetScript("OnEvent", function(self, event, unit, ...)
    if event == "UNIT_POWER_UPDATE" and unit == "player" and self:IsShown() then
        self:Update()
    elseif event == "PLAYER_LOGIN" then
        local _, class = UnitClass("player")
        if class == "WARLOCK" then
            self:Update()
        else
            self:Hide()
        end
    end
end)