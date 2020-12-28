local pvpLoaded, challengesLoaded

---@type Frame
local listener = CreateFrame("Frame")

listener:RegisterEvent("ADDON_LOADED")
listener:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... == "Blizzard_PVPUI" then
            pvpLoaded = true
            if LoadAddOn("Blizzard_WeeklyRewards") then
                PVPQueueFrame.HonorInset.CasualPanel.WeeklyChest:SetScript("OnMouseDown", function()
                    WeeklyRewardsFrame:Show()
                end)
                PVPQueueFrame.HonorInset.RatedPanel.WeeklyChest:SetScript("OnMouseDown", function()
                    WeeklyRewardsFrame:Show()
                end)
            end
        elseif ... == "Blizzard_ChallengesUI" then
            challengesLoaded = true
            if LoadAddOn("Blizzard_WeeklyRewards") then
                ChallengesFrame.WeeklyInfo.Child.WeeklyChest:HookScript("OnMouseDown", function()
                    WeeklyRewardsFrame:Show()
                end)
            end
        end
        if pvpLoaded and challengesLoaded then
            listener:UnregisterEvent(event)
        end
    end
end)
