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
        local auras = ShadowUF.modules.auras

        local function reloadUnitAuras()
            for _, frame in pairs(ShadowUF.Units.unitFrames) do
                if (UnitExists(frame.unit) and frame.visibility.auras) then
                    auras:UpdateFilter(frame)
                    frame:FullUpdate()
                end
            end
        end

        auras.Update = function(self, frame)
            local config = ShadowUF.db.profile.units[frame.unitType].auras
            if frame.auras.anchor then
                frame.auras.anchor.totalAuras = frame.auras.anchor.temporaryEnchants

                auras.scan(frame.auras, frame.auras.anchor, frame.auras.primary, config[frame.auras.primary],
                        config[frame.auras.primary], frame.auras[frame.auras.primary].filter)
                auras.scan(frame.auras, frame.auras.anchor, frame.auras.secondary, config[frame.auras.secondary],
                        config[frame.auras.primary], frame.auras[frame.auras.secondary].filter)
            else
                if config.buffs.enabled then
                    frame.auras.buffs.totalAuras = frame.auras.buffs.temporaryEnchants
                    auras.scan(frame.auras, frame.auras.buffs, "buffs", config.buffs, config.buffs,
                            frame.auras.buffs.filter)
                end

                if config.debuffs.enabled then
                    frame.auras.debuffs.totalAuras = 0
                    auras.scan(frame.auras, frame.auras.debuffs, "debuffs", config.debuffs, config.debuffs,
                            frame.auras.debuffs.filter)
                end

                if frame.auras.anchorAurasOn then
                    auras.anchorGroupToGroup(frame, config[frame.auras.anchorAurasOn.type], frame.auras.anchorAurasOn,
                            config[frame.auras.anchorAurasChild.type], frame.auras.anchorAurasChild)
                end
            end

            if frame.auras.buffs then
                local buttons = frame.auras.buffs.buttons
                for _, button in pairs(buttons) do
                    button:RegisterForClicks("AnyUp")
                    button:SetScript("OnClick", function(self, mouse)
                        if mouse == "LeftButton" then
                            local value = UnitAura(self.unit, self.auraID, self.filter)
                            ShadowUF.db.profile.filters["blacklists"]["增益"][value] = true
                            reloadUnitAuras()
                        elseif InCombatLockdown() or self.filter == "TEMP" or (not UnitIsUnit(self.parent.unit, "player")
                                and not UnitIsUnit(self.parent.unit, "vehicle")) then
                            return
                        elseif mouse == "RightButton" then
                            CancelUnitBuff(self.parent.unit, self.auraID, self.filter)
                        end
                    end)
                end
            end

            if frame.auras.debuffs then
                local buttons = frame.auras.debuffs.buttons
                for _, button in pairs(buttons) do
                    button:RegisterForClicks("LeftButtonUp")
                    button:SetScript("OnClick", function(self, mouse)
                        local value = UnitAura(self.unit, self.auraID, self.filter)
                        ShadowUF.db.profile.filters["blacklists"]["減益"][value] = true
                        reloadUnitAuras()
                    end)
                end
            end
        end
    end
end)
