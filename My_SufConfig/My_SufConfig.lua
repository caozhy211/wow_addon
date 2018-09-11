local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
    if ShadowUF then
        -- 使用中文單位簡化數字
        ShadowUF.FormatLargeNumber = function(self, number)
            if number < 1e4 then
                return number
            end
            if number < 1e6 then
                return ("%02.1f萬"):format(number / 1e4)
            end
            if number < 1e8 then
                return ("%d萬"):format(number / 1e4)
            end
            return ("%02.2f億"):format(number / 1e8)
        end

        -- 左鍵點擊光環加入黑名單
        local table = ShadowUF.modules.auras
        hooksecurefunc(table, "Update", function(self, frame)
            local buttons = frame.auras.buffs.buttons
            for _, button in pairs(buttons) do
                button:RegisterForClicks("AnyUp")
                button:SetScript("OnClick", function(self, mouse)
                    if mouse == "LeftButton" then
                        local value = UnitAura(self.unit, self.auraID, self.filter)
                        local filter
                        if self.filter == "buffs" or self.filter == "HELPFUL" then
                            filter = "增益"
                        else
                            filter = "减益"
                        end
                        ShadowUF.db.profile.filters["blacklists"][filter][value] = true

                        for _, unitFrame in pairs(ShadowUF.Units.unitFrames) do
                            if (UnitExists(unitFrame.unit) and unitFrame.visibility.auras) then
                                table:UpdateFilter(unitFrame)
                                unitFrame:FullUpdate()
                            end
                        end
                    elseif InCombatLockdown() or self.filter == "TEMP" or (not UnitIsUnit(self.parent.unit, "player")
                            and not UnitIsUnit(self.parent.unit, "vehicle")) then
                        return
                    elseif mouse == "RightButton" then
                        CancelUnitBuff(self.parent.unit, self.auraID, self.filter)
                    end
                end)
            end
        end)
    end
end)