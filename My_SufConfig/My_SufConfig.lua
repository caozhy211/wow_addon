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

        -- 因爲解鎖框架時，會調用setfenv函數改變Update函數的環境，所以不能使用hooksecurefunc函數
        auras.Update = function(self, frame)
            -- Update函數的原內容
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

            -- 重新加載光環
            local function ReloadUnitAuras()
                for _, unitFrame in pairs(ShadowUF.Units.unitFrames) do
                    if (UnitExists(unitFrame.unit) and unitFrame.visibility.auras) then
                        auras:UpdateFilter(unitFrame)
                        unitFrame:FullUpdate()
                    end
                end
            end

            -- 更新黑名單
            local function UpdateBlackLists()
                if ShadowUF.Config and ShadowUF.Config.options then
                    local blacklists = ShadowUF.Config.options.args.filter.args.filters.args.blacklists
                    local filterIndex = 0
                    local spellIndex = 0

                    for filter, spells in pairs(ShadowUF.db.profile.filters["blacklists"]) do
                        filterIndex = filterIndex + 1
                        blacklists.args[tostring(filterIndex)].args.spells.args = {}

                        local hasSpell
                        for spellName in pairs(spells) do
                            if spellName ~= "buffs" and spellName ~= "debuffs" then
                                hasSpell = true
                                spellIndex = spellIndex + 1
                                blacklists.args[tostring(filterIndex)].args.spells.args[spellIndex .. "label"] = {
                                    order = spellIndex,
                                    type = "description",
                                    width = "double",
                                    fontSize = "medium",
                                    name = spellName,
                                }
                                blacklists.args[tostring(filterIndex)].args.spells.args[tostring(spellIndex)] = {
                                    order = spellIndex + 0.5,
                                    type = "execute",
                                    name = ShadowUF.L["Delete"],
                                    width = "half",
                                    func = function(info)
                                        ShadowUF.db.profile.filters["blacklists"][filter][spellName] = nil

                                        ReloadUnitAuras()
                                        UpdateBlackLists()
                                    end
                                }
                            end
                        end

                        if not hasSpell then
                            blacklists.args[tostring(filterIndex)].args.spells.args.noSpells = {
                                order = 0,
                                type = "description",
                                name = ShadowUF.L["This filter has no auras in it, you will have to add some using the "
                                        .. "dialog above."],
                            }
                        end
                    end
                end
            end

            -- 點擊增益光環
            if frame.auras.buffs then
                local buttons = frame.auras.buffs.buttons
                for _, button in pairs(buttons) do
                    button:RegisterForClicks("AnyUp")
                    button:SetScript("OnClick", function(self, mouse)
                        if mouse == "LeftButton" then
                            local value = UnitAura(self.unit, self.auraID, self.filter)
                            ShadowUF.db.profile.filters["blacklists"]["增益"][value] = true
                            ReloadUnitAuras()
                            UpdateBlackLists()
                        elseif InCombatLockdown() or self.filter == "TEMP" or (not UnitIsUnit(self.parent.unit, "player")
                                and not UnitIsUnit(self.parent.unit, "vehicle")) then
                            return
                        elseif mouse == "RightButton" then
                            CancelUnitBuff(self.parent.unit, self.auraID, self.filter)
                        end
                    end)
                end
            end

            -- 點擊減益光環
            if frame.auras.debuffs then
                local buttons = frame.auras.debuffs.buttons
                for _, button in pairs(buttons) do
                    button:RegisterForClicks("LeftButtonUp")
                    button:SetScript("OnClick", function(self, mouse)
                        local value = UnitAura(self.unit, self.auraID, self.filter)
                        ShadowUF.db.profile.filters["blacklists"]["減益"][value] = true
                        ReloadUnitAuras()
                        UpdateBlackLists()
                    end)
                end
            end
        end
    end
end)

