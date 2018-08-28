local ss = CreateFrame("Frame", "SoulShard", UIParent)
ss:SetClampedToScreen(true)
ss:RegisterEvent("PLAYER_LOGIN")
ss:RegisterEvent("UNIT_POWER_UPDATE")

ss.shards = {}

function ss:Update()
    -- 7：靈魂裂片
    local available = UnitPower("player", 7)
    for i = 1, #ss.shards do
        local alpha = i > available and 0.15 or 1
        ss.shards[i]:SetAlpha(alpha)
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
            -- 7：靈魂裂片
            local numPower = UnitPowerMax("player", 7)
            local size = 36

            if ss:GetHeight() == 0 then
                ss:SetHeight(size)
                ss:SetWidth(size * numPower)
                ss:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 195)
            end
            ss:Show()

            if next(ss.shards) == nil then
                for i = 1, numPower do
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