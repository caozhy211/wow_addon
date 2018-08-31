local ss = CreateFrame("Frame", "SoulShard", UIParent)
ss:SetClampedToScreen(true)
ss:RegisterEvent("PLAYER_LOGIN")
ss:RegisterEvent("UNIT_POWER_UPDATE")

ss.shards = {}

-- 靈魂裂片碎塊文字
ss.text = ss:CreateFontString("Slivers", "Overlay")
ss.text:SetFont("Fonts\\ARHei.ttf", 24)
ss.text:SetTextColor(1, 0, 0)

-- 靈魂裂片大小
local size = 36

function ss:Update()
    local numPower = WarlockPowerBar_UnitPower("player")
    local numShards, numSlivers = math.modf(numPower)
    for i = 1, #ss.shards do
        local alpha = i > numShards and 0.15 or 1
        ss.shards[i]:SetAlpha(alpha)

        -- 顯示靈魂裂片碎塊數量
        if i == numShards + 1 and numSlivers > 0 then
            ss.text:SetText(numSlivers * 10)
            ss.text:SetPoint("Center", ss, "Left", size * (numShards + 0.5), 0)
        elseif numSlivers == 0 then
            ss.text:SetText("")
        end
    end
end

ss:SetScript("OnEvent", function(self, event, unit, ...)
    if event == "UNIT_POWER_UPDATE" and unit == "player" then
        ss:Update()
    elseif event == "PLAYER_LOGIN" then
        local spec = GetSpecialization()
        spec = spec and GetSpecializationInfo(spec) or nil
        -- 265:痛苦，266：惡魔，267：毀滅
        if spec == 265 or spec == 266 or spec == 267 then
            local maxNumPower = UnitPowerMax("player", Enum.PowerType.SoulShards)

            if ss:GetHeight() == 0 then
                ss:SetHeight(size)
                ss:SetWidth(size * maxNumPower)
                ss:SetPoint("Top", UIParent, "Bottom", 0, 240)
            end
            ss:Show()

            if next(ss.shards) == nil then
                for i = 1, maxNumPower do
                    local shard = ss:CreateTexture(nil, "Artwork")
                    shard:SetTexture("Interface\\ICONS\\INV_Misc_Gem_Amethyst_02")
                    shard:SetWidth(size)
                    shard:SetHeight(size)
                    shard:SetPoint("Left", size * (i - 1), 0)
                    ss.shards[i] = shard
                end
            end
            ss:Update()
        else
            ss:Hide()
        end
    end
end)