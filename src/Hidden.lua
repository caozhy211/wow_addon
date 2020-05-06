ITEM_CREATED_BY = nil

---@type Frame
local playerFrame = PlayerFrame
playerFrame:Hide()

---@param frame Frame
local function HideFrame(frame)
    frame:UnregisterAllEvents()
    frame:Hide()

    ---@type StatusBar
    local healthBar = frame.healthBar
    if healthBar then
        healthBar:Hide()
    end
    ---@type StatusBar
    local manaBar = frame.manaBar
    if manaBar then
        manaBar:Hide()
    end
    ---@type StatusBar
    local spellbar = frame.spellbar
    if spellbar then
        spellbar:Hide()
    end
    ---@type StatusBar
    local powerBarAlt = frame.powerBarAlt
    if powerBarAlt then
        powerBarAlt:Hide()
    end

    ---@type Frame
    local parent = CreateFrame("Frame")
    parent:Hide()
    frame:SetParent(parent)

    ---@param self Frame
    frame:HookScript("OnShow", function(self)
        if not InCombatLockdown() then
            self:Hide()
        end
    end)
end

HideFrame(TargetFrame)
HideFrame(FocusFrame)
HideFrame(LootFrame)
HideFrame(AlertFrame)
for i = 1, MAX_BOSS_FRAMES do
    local name = "Boss" .. i .. "TargetFrame"
    local frame = _G[name]
    HideFrame(frame)
    frame = _G[name .. "HealthBar"]
    HideFrame(frame)
    frame = _G[name .. "ManaBar"]
    HideFrame(frame)
end
for i = 1, MAX_ARENA_ENEMIES do
    HideFrame(_G["ArenaPrepFrame" .. i])
end
