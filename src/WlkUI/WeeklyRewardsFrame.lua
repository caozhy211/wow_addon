local pvpLoaded, challengesLoaded

---@type Frame
local listener = CreateFrame("Frame")

listener:RegisterEvent("ADDON_LOADED")
listener:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... == "Blizzard_PVPUI" then
            pvpLoaded = true
        elseif ... == "Blizzard_ChallengesUI" then
            challengesLoaded = true
        end
        if pvpLoaded and challengesLoaded then
            listener:UnregisterEvent(event)
            if LoadAddOn("Blizzard_WeeklyRewards") then
                PVPQueueFrame.HonorInset.CasualPanel.WeeklyChest:HookScript("OnMouseDown", function()
                    WeeklyRewardsFrame:Show()
                end)
                ChallengesFrame.WeeklyInfo.Child.WeeklyChest:HookScript("OnMouseDown", function()
                    WeeklyRewardsFrame:Show()
                end)
            end
        end
    end
end)
