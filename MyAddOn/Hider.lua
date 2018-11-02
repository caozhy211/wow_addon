PlayerFrame:Hide()

ITEM_CREATED_BY = nil

if LoadAddOn("Blizzard_CombatText") then
    COMBAT_TEXT_TYPE_INFO["HEAL"] = nil
    COMBAT_TEXT_TYPE_INFO["HEAL_ABSORB"] = nil
    COMBAT_TEXT_TYPE_INFO["HEAL_CRIT"] = nil
    COMBAT_TEXT_TYPE_INFO["HEAL_CRIT_ABSORB"] = nil
    COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL"] = nil
    COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL_ABSORB"] = nil
    COMBAT_TEXT_TYPE_INFO["PERIODIC_HEAL_CRIT"] = nil
    COMBAT_TEXT_TYPE_INFO["ABSORB_ADDED"] = nil
end

local function FrameOnShow(self)
    if not InCombatLockdown() then
        self:Hide()
    end
end

local function HideFrames()
    local frames = {
        TargetFrame, FocusFrame, LootFrame, AlertFrame
    }
    local parent = CreateFrame("Frame")
    parent:Hide()

    for i = 1, MAX_BOSS_FRAMES do
        local name = "Boss" .. i .. "TargetFrame"
        frames[#frames + 1] = _G[name]
        frames[#frames + 1] = _G[name .. "HealthBar"]
        frames[#frames + 1] = _G[name .. "ManaBar"]
    end

    for i = 1, #frames do
        local frame = frames[i]
        frame:UnregisterAllEvents()
        frame:Hide()

        if frame.healthbar then
            frame.healthbar:UnregisterAllEvents()
        end
        if frame.manabar then
            frame.manabar:UnregisterAllEvents()
        end
        if frame.spellbar then
            frame.spellbar:UnregisterAllEvents()
        end
        if frame.powerBarAlt then
            frame.powerBarAlt:UnregisterAllEvents()
        end

        frame:SetParent(parent)
        frame:HookScript("OnShow", FrameOnShow)
    end
end

HideFrames()