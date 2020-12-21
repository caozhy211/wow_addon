if LoadAddOn("Blizzard_PVPUI") and LoadAddOn("Blizzard_ChallengesUI") and LoadAddOn("Blizzard_WeeklyRewards") then
    PVPQueueFrame.HonorInset.CasualPanel.WeeklyChest:HookScript("OnMouseDown", function()
        WeeklyRewardsFrame:Show()
    end)
    ChallengesFrame.WeeklyInfo.Child.WeeklyChest:HookScript("OnMouseDown", function()
        WeeklyRewardsFrame:Show()
    end)
end
