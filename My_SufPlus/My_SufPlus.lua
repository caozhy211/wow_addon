local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
    if ShadowUF then
        -- 使用中文單位簡化數字
        function ShadowUF:FormatLargeNumber(number)
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

        -- 因爲解鎖框架時，會調用setfenv函數改變Update函數的環境，所以不能使用hooksecurefunc函數
        function auras:Update(frame)
            -- Update函數的原內容
            local config = ShadowUF.db.profile.units[frame.unitType].auras
            if frame.auras.anchor then
                frame.auras.anchor.totalAuras = frame.auras.anchor.temporaryEnchants

                self.scan(frame.auras, frame.auras.anchor, frame.auras.primary, config[frame.auras.primary], config[frame.auras.primary], frame.auras[frame.auras.primary].filter)
                self.scan(frame.auras, frame.auras.anchor, frame.auras.secondary, config[frame.auras.secondary], config[frame.auras.primary], frame.auras[frame.auras.secondary].filter)
            else
                if config.buffs.enabled then
                    frame.auras.buffs.totalAuras = frame.auras.buffs.temporaryEnchants
                    self.scan(frame.auras, frame.auras.buffs, "buffs", config.buffs, config.buffs, frame.auras.buffs.filter)
                end

                if config.debuffs.enabled then
                    frame.auras.debuffs.totalAuras = 0
                    self.scan(frame.auras, frame.auras.debuffs, "debuffs", config.debuffs, config.debuffs, frame.auras.debuffs.filter)
                end

                if frame.auras.anchorAurasOn then
                    self.anchorGroupToGroup(frame, config[frame.auras.anchorAurasOn.type], frame.auras.anchorAurasOn, config[frame.auras.anchorAurasChild.type], frame.auras.anchorAurasChild)
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
                    button:SetScript("OnClick", function(self)
                        local value = UnitAura(self.unit, self.auraID, self.filter)
                        ShadowUF.db.profile.filters["blacklists"]["減益"][value] = true
                        ReloadUnitAuras()
                        UpdateBlackLists()
                    end)
                end
            end
        end

        -- 修復不顯示連擊點的問題
        local function createIcons(config, pointsFrame)
            local point, relativePoint, x, y
            local pointsConfig = pointsFrame.cpConfig

            if config.growth == "LEFT" then
                point, relativePoint = "BottomRight", "BottomLeft"
                x = config.spacing
            elseif config.growth == "UP" then
                point, relativePoint = "BottomLeft", "TopLeft"
                y = config.spacing
            elseif config.growth == "DOWN" then
                point, relativePoint = "TopLeft", "BottomLeft"
                y = config.spacing
            else
                point, relativePoint = "BottomLeft", "BottomRight"
                x = config.spacing
            end

            x = x or 0
            y = y or 0

            for id = 1, pointsConfig.max do
                pointsFrame.icons[id] = pointsFrame.icons[id] or pointsFrame:CreateTexture(nil, "Overlay")
                local texture = pointsFrame.icons[id]
                texture:SetTexture(pointsConfig.icon)
                texture:SetSize(config.size or 16, config.size or 16)

                if id > 1 then
                    texture:ClearAllPoints()
                    texture:SetPoint(point, pointsFrame.icons[id - 1], relativePoint, x, y)
                else
                    texture:ClearAllPoints()
                    texture:SetPoint("Center")
                end
            end
        end

        local function createBlocks(config, pointsFrame)
            local pointsConfig = pointsFrame.cpConfig
            if pointsConfig.max == 0 then
                return
            end
            pointsFrame.visibleBlocks = pointsConfig.max

            -- Position bars, the 5 accounts for borders
            local blockWidth = (pointsFrame:GetWidth() - ((pointsConfig.max / (pointsConfig.grouping or 1)) - 1)) / pointsConfig.max
            for id = 1, pointsConfig.max do
                pointsFrame.blocks[id] = pointsFrame.blocks[id] or pointsFrame:CreateTexture(nil, "Overlay")
                local texture = pointsFrame.blocks[id]
                local color = ShadowUF.db.profile.powerColors[pointsConfig.colorKey or "COMBOPOINTS"]
                texture:SetVertexColor(color.r, color.g, color.b, color.a)
                texture:SetHorizTile(false)
                texture:SetTexture(ShadowUF.Layout.mediaPath.statusbar)
                texture:SetHeight(pointsFrame:GetHeight())
                texture:SetWidth(blockWidth)
                texture:ClearAllPoints()

                if not texture.background and config.background then
                    texture.background = pointsFrame:CreateTexture(nil, "Border")
                    texture.background:SetHeight(1)
                    texture.background:SetWidth(1)
                    texture.background:SetAllPoints(texture)
                    texture.background:SetHorizTile(false)
                    texture.background:SetVertexColor(color.r, color.g, color.b, ShadowUF.db.profile.bars.backgroundAlpha)
                    texture.background:SetTexture(ShadowUF.Layout.mediaPath.statusbar)
                end

                if texture.background then
                    texture.background:SetShown(config.background)
                end

                local offset = 1
                if pointsConfig.grouping and ((id - 1) % pointsConfig.grouping ~= 0) then
                    offset = 0
                end
                if config.growth == "LEFT" then
                    if id > 1 then
                        texture:SetPoint("TopRight", pointsFrame.blocks[id - 1], "TopLeft", -offset, 0)
                    else
                        texture:SetPoint("TopRight")
                    end
                else
                    if id > 1 then
                        texture:SetPoint("TopLeft", pointsFrame.blocks[id - 1], "TopRight", offset, 0)
                    else
                        texture:SetPoint("TopLeft")
                    end
                end
            end
        end

        function ShadowUF.ComboPoints:UpdateBarBlocks(frame, event, unit, powerType)
            local key = self:GetComboPointType()
            local pointsFrame = frame[key]
            if not pointsFrame or not pointsFrame.cpConfig.eventType or not pointsFrame.blocks then
                return
            end
            if event and powerType ~= pointsFrame.cpConfig.eventType then
                return
            end

            local max = self.GetMaxPoints and self:GetMaxPoints() or UnitPowerMax(frame.unit, pointsFrame.cpConfig.powerType)
            if max == 0 or pointsFrame.visibleBlocks == max then
                return
            end

            pointsFrame.cpConfig.max = max

            if not ShadowUF.db.profile.units[frame.unitType][key].isBar then
                createIcons(ShadowUF.db.profile.units[frame.unitType][key], pointsFrame)
                pointsFrame.visibleBlocks = max
                return
            else
                createBlocks(ShadowUF.db.profile.units[frame.unitType][key], pointsFrame)
                pointsFrame.visibleBlocks = max
            end

            local blockWidth = (pointsFrame:GetWidth() - (max - 1)) / max
            for id = 1, max do
                pointsFrame.blocks[id]:SetWidth(blockWidth)
                pointsFrame.blocks[id]:Show()
            end

            for id = max + 1, #pointsFrame.blocks do
                pointsFrame.blocks[id]:Hide()
            end
        end

        -- 特殊能量條顯示數值
        function ShadowUF.modules.altPowerBar:Update(frame, event, unit, type)
            if event and type ~= "ALTERNATE" then
                return
            end

            local _, minPower = UnitAlternatePowerInfo(frame.unit)
            local minValue = minPower or 0
            frame.altPowerBar:SetMinMaxValues(minValue, UnitPowerMax(frame.unit, ALTERNATE_POWER_INDEX) or 0)
            frame.altPowerBar:SetValue(UnitPower(frame.unit, ALTERNATE_POWER_INDEX) or 0)

            if not frame.altPowerBar.text then
                frame.altPowerBar.text = frame.altPowerBar:CreateFontString(nil, "Overlay")
                frame.altPowerBar.text:SetFont(GameFontNormal:GetFont(), 10, "Outline")
                frame.altPowerBar.text:SetPoint("Center")
            end

            local _, maxValue = frame.altPowerBar:GetMinMaxValues()
            local value = frame.altPowerBar:GetValue()
            local text = "(" .. math.ceil((value / maxValue) * 100) .. "%) " .. value .. " / " .. maxValue
            frame.altPowerBar.text:SetText(text)
        end
    end
end)

