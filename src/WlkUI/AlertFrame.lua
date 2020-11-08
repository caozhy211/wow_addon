---@type ColorMixin
local RED_FONT_COLOR = RED_FONT_COLOR

local frameWidth = 300
local frameHeight = 132
local maxAlerts = 3
local spacing = 2
local width = frameWidth
local height = (frameHeight - (maxAlerts * spacing)) / maxAlerts
local numAlerts = 0
local backdrop = {
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = 2,
}
local borderSize = 2
local iconSize = height - borderSize * 2
local maxArrows = 5
local arrowConfig = {
    { delay = 0, x = 0, },
    { delay = 0.1, x = -8, },
    { delay = 0.2, x = 16, },
    { delay = 0.3, x = 8, },
    { delay = 0.4, x = -16, },
}
local textWidth = width - height
local textXOffset = iconSize / 2
local rewardSize = 21
local maxRewards = 5
local displayTime = 5
---@type WlkAlertButton[]
local activeAlerts = {}
---@type WlkAlertButton[]
local queuedAlerts = {}
---@type WlkAlertButton[]
local freeAlerts = {}
---@type table<FontString, string>
local textToAnimate = {}
local followerData = {}
local ITEM_LEVEL_REGEX = gsub(ITEM_LEVEL, "%%d", "(%%d+)")
local YOU_LOSE_LABEL = RED_FONT_COLOR:WrapTextInColorCode("你失去了")
local tradeSkillRankTextures = {
    "|TInterface/LootFrame/toast-star:12:12:0:0:32:32:0:21:0:21|t",
    "|TInterface/LootFrame/toast-star-2:12:24:0:0:64:32:0:42:0:21|t",
    "|TInterface/LootFrame/toast-star-3:12:36:0:0:64:32:0:64:0:21|t",
}
local lastMoney
local LOOT_ITEM_SELF_MULTIPLE_PATTERN = gsub(gsub(LOOT_ITEM_SELF_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local LOOT_ITEM_PUSHED_MULTIPLE_PATTERN = gsub(gsub(LOOT_ITEM_PUSHED_SELF_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local LOOT_ITEM_CREATED_MULTIPLE_PATTERN = gsub(gsub(LOOT_ITEM_CREATED_SELF_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local LOOT_ITEM_PATTERN = gsub(LOOT_ITEM_SELF, "%%s", "(.+)")
local LOOT_ITEM_PUSHED_PATTERN = gsub(LOOT_ITEM_PUSHED_SELF, "%%s", "(.+)")
local LOOT_ITEM_CREATED_PATTERN = gsub(LOOT_ITEM_CREATED_SELF, "%%s", "(.+)")
local CURRENCY_GAINED_MULTIPLE_PATTERN = gsub(gsub(CURRENCY_GAINED_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local CURRENCY_GAINED_PATTERN = gsub(CURRENCY_GAINED, "%%s", "(.+)")
local scannerName = "WlkAlertItemScanner"

---@type Frame
local alertFrame = CreateFrame("Frame", "WlkAlertFrame", UIParent)
---@type GameTooltip
local scanner = CreateFrame("GameTooltip", scannerName, UIParent, "GameTooltipTemplate")

---@param self WlkAlertButton
local function alertButtonOnEnter(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    self:SetAlpha(1)
    self.animOut:Stop()
end

---@param self WlkAlertButton
local function alertButtonOnLeave(self)
    GameTooltip:Hide()
    GarrisonFollowerTooltip:Hide()
    GarrisonShipyardFollowerTooltip:Hide()
    self.animOut:Play()
end

---@param self WlkAlertButton
local function alertButtonOnShow(self)
    if self.data.sound then
        PlaySound(self.data.sound)
    end
    self.animIn:Play()
    self.animOut:Play()
end

---@param self Frame
local function rewardFrameOnEnter(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    ---@type WlkAlertButton
    local alert = self:GetParent()
    alert:SetAlpha(1)
    alert.animOut:Stop()
end

---@param self Frame
local function rewardFrameOnLeave(self)
    GameTooltip:Hide()
    ---@type WlkAlertButton
    local alert = self:GetParent()
    alert.animOut:Play()
end

---@param alert WlkAlertButton
local function showAlert(alert)
    if #activeAlerts >= maxAlerts then
        tinsert(queuedAlerts, alert)
    else
        alert:SetPoint("BOTTOM", 0, (height + spacing) * #activeAlerts)
        alert:Show()
        tinsert(activeAlerts, alert)
    end
end

---@param alert WlkAlertButton
local function releaseAlert(alert)
    alert:ClearAllPoints()
    alert:SetAlpha(1)
    alert:Hide()
    alert:SetScript("OnEnter", alertButtonOnEnter)
    alert:SetBackdropBorderColor(0, 0, 0)

    alert.arrows:Stop()
    alert.animIn:Stop()
    alert.animOut:Stop()
    alert.bonus:Hide()
    alert.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    alert.count:SetText("")
    alert.count.type = nil
    alert.increment:SetText("")
    alert.increment.type = nil
    alert.increment.blink:Stop()
    alert.skull:Hide()
    alert.title:SetText("")
    alert.text:SetText("")
    alert.text.type = nil
    wipe(alert.data)
    for i = 1, maxArrows do
        ---@type Texture
        local arrow = alert["arrow" .. i]
        arrow:SetAlpha(0)
    end
    for i = 1, maxRewards do
        ---@type WlkAlertRewardFrame
        local reward = alert["reward" .. i]
        reward:Hide()
        reward:SetScript("OnEnter", rewardFrameOnEnter)
        wipe(reward.data)
    end

    tinsert(freeAlerts, alert)
    tDeleteItem(activeAlerts, alert)
    tDeleteItem(queuedAlerts, alert)
    for i, activeAlert in ipairs(activeAlerts) do
        activeAlert:ClearAllPoints()
        activeAlert:SetPoint("BOTTOM", 0, (i - 1) * (height + spacing))
    end
    local queuedAlert = tremove(queuedAlerts, 1)
    if queuedAlert then
        showAlert(queuedAlert)
    end
end

---@param self AnimationGroup
local function alertAnimInOnFinished(self)
    ---@type WlkAlertButton
    local alert = self:GetParent()
    if alert.data.arrows then
        alert.arrows:Play()
        alert.data.arrows = nil
    end
end

---@param self AnimationGroup
local function alertAnimOutOnFinished(self)
    releaseAlert(self:GetParent())
end

local function createAlert()
    numAlerts = numAlerts + 1
    ---@class WlkAlertButton:Button
    local button = CreateFrame("Button", "WlkAlertButton" .. numAlerts, alertFrame, "BackdropTemplate")
    ---@type Alpha|Translation
    local animation

    button:SetSize(width, height)
    button:SetBackdrop(backdrop)
    button:SetBackdropBorderColor(0, 0, 0)
    button:Hide()

    button.icon = button:CreateTexture(nil, "BORDER")
    button.icon:SetSize(iconSize, iconSize)
    button.icon:SetPoint("LEFT", borderSize, 0)
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.count = button:CreateFontString(nil, "ARTWORK", "Game12Font_o1")
    button.count:SetPoint("BOTTOMRIGHT", button.icon)

    ---@type WlkAlertIncrementLabel
    button.increment = button:CreateFontString(nil, "ARTWORK", "Game12Font_o1")
    button.increment:SetPoint("BOTTOMRIGHT", button.count, "TOPRIGHT")

    button.increment.blink = button:CreateAnimationGroup()
    button.increment.blink:SetToFinalAlpha(true)

    animation = button.increment.blink:CreateAnimation("Alpha")
    animation:SetChildKey("increment")
    animation:SetOrder(1)
    animation:SetFromAlpha(1)
    animation:SetToAlpha(0)
    animation:SetDuration(0)
    animation:SetChildKey("increment")
    animation:SetOrder(2)
    animation:SetFromAlpha(0)
    animation:SetToAlpha(1)
    animation:SetDuration(0.2)
    animation:SetChildKey("increment")
    animation:SetOrder(3)
    animation:SetFromAlpha(0)
    animation:SetToAlpha(1)
    animation:SetDuration(0.4)
    animation:SetStartDelay(0.4)

    button.skull = button:CreateTexture()
    button.skull:SetSize(16, 20)
    button.skull:SetPoint("TOPRIGHT", button.icon)
    button.skull:SetTexture("Interface/LFGFrame/UI-LFG-ICON-HEROIC")
    button.skull:SetTexCoord(0, 0.5, 0, 0.625)
    button.skull:Hide()

    button.arrows = button:CreateAnimationGroup()
    button.arrows:SetToFinalAlpha(true)
    for i = 1, maxArrows do
        local xOffset = arrowConfig[i].x
        local delay = arrowConfig[i].delay
        local key = "arrow" .. i
        local arrow = button:CreateTexture(nil, "ARTWORK", "LootUpgradeFrame_ArrowTemplate")
        arrow:ClearAllPoints()
        arrow:SetPoint("BOTTOM", button.icon, xOffset, -iconSize / 2)
        arrow:SetAlpha(0)
        button[key] = arrow

        animation = button.arrows:CreateAnimation("Alpha")
        animation:SetChildKey(key)
        animation:SetOrder(1)
        animation:SetFromAlpha(1)
        animation:SetToAlpha(0)
        animation:SetDuration(0)
        animation = button.arrows:CreateAnimation("Alpha")
        animation:SetChildKey(key)
        animation:SetOrder(2)
        animation:SetFromAlpha(0)
        animation:SetToAlpha(1)
        animation:SetDuration(0.25)
        animation:SetStartDelay(delay)
        animation:SetSmoothing("IN")
        animation = button.arrows:CreateAnimation("Alpha")
        animation:SetChildKey(key)
        animation:SetOrder(2)
        animation:SetFromAlpha(1)
        animation:SetToAlpha(0)
        animation:SetDuration(0.25)
        animation:SetStartDelay(delay + 0.25)
        animation:SetSmoothing("OUT")
        animation = button.arrows:CreateAnimation("Translation")
        animation:SetChildKey(key)
        animation:SetOrder(2)
        animation:SetDuration(0.5)
        animation:SetStartDelay(delay)
        animation:SetOffset(0, 60)
        animation = button.arrows:CreateAnimation("Alpha")
        animation:SetChildKey(key)
        animation:SetOrder(3)
        animation:SetFromAlpha(1)
        animation:SetToAlpha(0)
    end

    button.title = button:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med1")
    button.title:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 5, -3)
    button.title:SetTextColor(1, 0.82, 0)

    button.text = button:CreateFontString(nil, "ARTWORK", "SystemFont_Shadow_Med1")
    button.text:SetWidth(textWidth)
    button.text:SetPoint("BOTTOM", textXOffset, borderSize)
    button.text:SetMaxLines(1)

    button.bonus = button:CreateTexture()
    button.bonus:SetPoint("RIGHT", -borderSize, 0)
    button.bonus:SetAtlas("Bonus-ToastBanner", true)
    button.bonus:Hide()

    button.glow = button:CreateTexture(nil, "OVERLAY")
    button.glow:SetSize(width + 80, height * 2)
    button.glow:SetPoint("CENTER")
    button.glow:SetBlendMode("ADD")
    button.glow:SetAlpha(0)
    button.glow:SetTexture("Interface/AchievementFrame/UI-Achievement-Alert-Glow")
    button.glow:SetTexCoord(0, 0.78125, 0, 0.66796875)

    button.shine = button:CreateTexture(nil, "OVERLAY")
    button.shine:SetSize(67, height)
    button.shine:SetPoint("BOTTOMLEFT")
    button.shine:SetBlendMode("ADD")
    button.shine:SetAlpha(0)
    button.shine:SetTexture("Interface/AchievementFrame/UI-Achievement-Alert-Glow")
    button.shine:SetTexCoord(0.78125, 0.912109375, 0, 0.28125)

    button.animIn = button:CreateAnimationGroup()
    button.animIn:SetToFinalAlpha(true)
    button.animIn:SetScript("OnFinished", alertAnimInOnFinished)

    animation = button.animIn:CreateAnimation("Alpha")
    animation:SetChildKey("glow")
    animation:SetOrder(1)
    animation:SetFromAlpha(0)
    animation:SetToAlpha(1)
    animation:SetDuration(0)
    animation = button.animIn:CreateAnimation("Alpha")
    animation:SetChildKey("glow")
    animation:SetOrder(2)
    animation:SetFromAlpha(0)
    animation:SetToAlpha(1)
    animation:SetDuration(0.2)
    animation = button.animIn:CreateAnimation("Alpha")
    animation:SetChildKey("glow")
    animation:SetOrder(3)
    animation:SetFromAlpha(1)
    animation:SetToAlpha(0)
    animation:SetDuration(0.5)
    animation = button.animIn:CreateAnimation("Alpha")
    animation:SetChildKey("shine")
    animation:SetOrder(2)
    animation:SetFromAlpha(0)
    animation:SetToAlpha(1)
    animation:SetDuration(0.2)
    animation = button.animIn:CreateAnimation("Translation")
    animation:SetChildKey("shine")
    animation:SetOrder(3)
    animation:SetDuration(0.85)
    animation:SetOffset(width - button.shine:GetWidth(), 0)
    animation = button.animIn:CreateAnimation("Alpha")
    animation:SetChildKey("shine")
    animation:SetOrder(3)
    animation:SetFromAlpha(1)
    animation:SetToAlpha(0)
    animation:SetDuration(0.5)
    animation:SetStartDelay(0.35)

    button.animOut = button:CreateAnimationGroup()
    button.animOut:SetScript("OnFinished", alertAnimOutOnFinished)

    animation = button.animOut:CreateAnimation("Alpha")
    animation:SetOrder(1)
    animation:SetFromAlpha(1)
    animation:SetToAlpha(0)
    animation:SetDuration(1.2)
    animation:SetStartDelay(displayTime)

    for i = 1, maxRewards do
        ---@class WlkAlertRewardFrame:Frame
        local reward = CreateFrame("Frame", nil, button)

        reward:SetSize(rewardSize, rewardSize)
        reward:SetPoint("TOPRIGHT", (1 - i) * (rewardSize + 2) - borderSize, -borderSize)
        reward:Hide()
        reward:SetScript("OnEnter", rewardFrameOnEnter)
        reward:SetScript("OnLeave", rewardFrameOnLeave)

        reward.data = {}
        reward.icon = reward:CreateTexture()
        reward.icon:SetAllPoints()
        reward.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        button["reward" .. i] = reward
    end

    button:SetScript("OnEnter", alertButtonOnEnter)
    button:SetScript("OnLeave", alertButtonOnLeave)
    button:SetScript("OnShow", alertButtonOnShow)

    button.data = {}

    return button
end

local function findAlert(event, key, value)
    if key and value then
        for _, alert in ipairs(activeAlerts) do
            if (not event or event == alert.data.event) and alert.data[key] == value then
                return alert
            end
        end
        for _, alert in ipairs(queuedAlerts) do
            if (not event or event == alert.data.event) and alert.data[key] == value then
                return alert, true
            end
        end
    end
end

local function getAlert(event, key, value)
    local alert, isQueued = findAlert(event, key, value)
    local isNew
    if not alert then
        isNew = true
        alert = tremove(freeAlerts, 1)
        if not alert then
            alert = createAlert()
        end
    end
    return alert, isNew, isQueued
end

---@param label FontString
local function setLabelText(label, value)
    if not label.type then
        label:SetText(value)
    elseif label.type == "normal" then
        label:SetText(value == 1 and "" or value)
    elseif label.type == "large" then
        label:SetText(value == 1 and "" or FormatLargeNumber(abs(value)))
    elseif label.type == "money" then
        label:SetText(GetMoneyString(abs(value), true))
    end
end

local function setLabelTextShowMode(label, value, animate)
    if animate then
        label.value = label.value or 1
        label.elapsed = 0
        textToAnimate[label] = value
    else
        label.value = value
        label.elapsed = 0
        setLabelText(label, value)
    end
end

local function achievementAlertOnEnter(self)
    if self.data.achievementId then
        local _, name, _, _, month, day, year, description = GetAchievementInfo(self.data.achievementId)
        if name then
            if day and day > 0 then
                GameTooltip:AddDoubleLine(name, FormatShortDate(day, month, year), nil, nil, nil, 0.5, 0.5, 0.5)
            else
                GameTooltip:AddLine(name)
            end

            if description then
                GameTooltip:AddLine(description, 1, 1, 1, true)
            end
        end
        GameTooltip:Show()
    end
end

local function showAchievementAlert(event, achievementId, arg, isCriteria)
    local alert = getAlert()
    local _, name, points, _, _, _, _, _, _, icon, _, isGuildAchievement = GetAchievementInfo(achievementId)

    if isCriteria then
        alert.title:SetText(ACHIEVEMENT_PROGRESSED)
        alert.text:SetText(arg)
        alert.count:SetText("")
    else
        alert.title:SetText(isGuildAchievement and GUILD_ACHIEVEMENT_UNLOCKED or ACHIEVEMENT_UNLOCKED)
        alert.text:SetText(name)
        if arg then
            alert.count:SetText("")
        else
            alert:SetBackdropBorderColor(0.9, 0.75, 0.26)
            alert.count:SetText(points == 0 and "" or points)
        end
    end
    alert.icon:SetTexture(icon)

    alert.data.event = event
    alert.data.achievementId = achievementId
    alert.data.sound = SOUNDKIT.ACHIEVEMENT_MENU_OPEN

    alert:HookScript("OnEnter", achievementAlertOnEnter)

    showAlert(alert)
end

local function showDigSiteCompleteAlert(event, researchBranchId)
    local alert = getAlert()
    local name, texture = GetArchaeologyRaceInfoByID(researchBranchId)

    alert:SetBackdropBorderColor(0.9, 0.4, 0.1)
    alert.title:SetText(ARCHAEOLOGY_DIGSITE_COMPLETE_TOAST_FRAME_TITLE)
    alert.text:SetText(name)
    alert.icon:SetTexture(texture)
    alert.icon:SetTexCoord(0, 0.578125, 0, 0.75)

    alert.data.event = event
    alert.data.sound = SOUNDKIT.UI_DIG_SITE_COMPLETION_TOAST

    showAlert(alert)
end

local function showCollectionAlert(event, id, isMount, isPet, isToy)
    local alert, isNew, isQueued = getAlert(event, "collectionId", id)

    if isNew then
        local color, name, icon, rarity, _
        if isMount then
            name, _, icon = C_MountJournal.GetMountInfoByID(id)
        elseif isPet then
            local customName
            _, _, _, _, rarity = C_PetJournal.GetPetStats(id)
            _, customName, _, _, _, _, _, name, icon = C_PetJournal.GetPetInfoByPetID(id)
            rarity = (rarity or 2) - 1
            color = ITEM_QUALITY_COLORS[rarity]
            name = customName or name
        elseif isToy then
            _, name, icon = C_ToyBox.GetToyInfo(id)
        end

        if not name then
            releaseAlert(alert)
            return
        end

        if rarity then
            alert:SetBackdropBorderColor(GetTableColor(color))
        end

        alert.title:SetText(COLLECTED)
        alert.text:SetText(name)
        alert.icon:SetTexture(icon)
        alert.count.type = "normal"
        setLabelTextShowMode(alert.count, 1)

        alert.data.collectionId = id
        alert.data.count = 1
        alert.data.event = event
        alert.data.sound = SOUNDKIT.UI_WARFORGED_ITEM_LOOT_TOAST

        showAlert(alert)
    else
        alert.data.count = alert.data.count + 1
        if isQueued then
            setLabelTextShowMode(alert.count, alert.data.count)
        else
            setLabelTextShowMode(alert.count, alert.data.count, true)
            alert.increment:SetText("+1")
            alert.increment.blink:Stop()
            alert.increment.blink:Play()
            alert.animOut:Stop()
            if not MouseIsOver(alert) then
                alert.animOut:Play()
            end
        end
    end
end

local function showGarrisonMissionAlert(event, missionId, isAdded)
    local missionInfo = C_Garrison.GetBasicMissionInfo(missionId)
    local rarity = missionInfo.isRare and Enum.ItemQuality.Rare or Enum.ItemQuality.Common
    local color = ITEM_QUALITY_COLORS[rarity]
    local level = missionInfo.iLevel == 0 and missionInfo.level or missionInfo.iLevel
    local alert = getAlert()

    alert:SetBackdropBorderColor(GetTableColor(color))
    alert.title:SetText(isAdded and GARRISON_MISSION_ADDED_TOAST1 or GARRISON_MISSION_COMPLETE)
    alert.text:SetText(missionInfo.name)
    alert.icon:SetTexCoord(0, 1, 0, 1)
    alert.icon:SetAtlas(missionInfo.typeAtlas)
    alert.count:SetText(level)

    alert.data.event = event
    alert.data.sound = SOUNDKIT.UI_GARRISON_TOAST_MISSION_COMPLETE

    showAlert(alert)
end

local function garrisonFollowerAlertOnEnter(self)
    if self.data.followerId then
        local isOk, link = pcall(C_Garrison.GetFollowerLink, self.data.followerId)

        if not isOk then
            isOk, link = pcall(C_Garrison.GetFollowerLinkByID, self.data.followerId)
        end

        if isOk and link then
            local _, followerId, quality, level, itemLevel, ability1, ability2, ability3, ability4, trait1, trait2,
            trait3, trait4, spec1 = strsplit(":", link)
            followerId = tonumber(followerId)
            followerData.garrisonFollowerID = followerId
            followerData.followerTypeID = C_Garrison.GetFollowerTypeByID(followerId)
            followerData.collected = false
            followerData.hyperlink = false
            followerData.name = C_Garrison.GetFollowerNameByID(followerId)
            followerData.spec = C_Garrison.GetFollowerClassSpecByID(followerId)
            followerData.portraitIconID = C_Garrison.GetFollowerPortraitIconIDByID(followerId)
            followerData.quality = tonumber(quality)
            followerData.level = tonumber(level)
            followerData.xp = 0
            followerData.levelxp = 0
            followerData.iLevel = tonumber(itemLevel)
            followerData.spec1 = tonumber(spec1)
            followerData.ability1 = tonumber(ability1)
            followerData.ability2 = tonumber(ability2)
            followerData.ability3 = tonumber(ability3)
            followerData.ability4 = tonumber(ability4)
            followerData.trait1 = tonumber(trait1)
            followerData.trait2 = tonumber(trait2)
            followerData.trait3 = tonumber(trait3)
            followerData.trait4 = tonumber(trait4)
            followerData.isTroop = C_Garrison.GetFollowerIsTroop(followerId)
            ---@type GameTooltip
            local tooltip
            if followerData.followerTypeID == Enum.GarrisonFollowerType.FollowerType_6_2 then
                tooltip = GarrisonShipyardFollowerTooltip
                GarrisonFollowerTooltipTemplate_SetShipyardFollower(tooltip, followerData)
            else
                tooltip = GarrisonFollowerTooltip
                GarrisonFollowerTooltipTemplate_SetGarrisonFollower(tooltip, followerData)
            end
            tooltip:Show()
            tooltip:ClearAllPoints()
            tooltip:SetPoint(GameTooltip:GetPoint())
        end
    end
end

local function showGarrisonFollowerAlert(event, followerId, name, _, level, quality, isUpgraded, _, followerTypeId)
    local followerInfo = C_Garrison.GetFollowerInfo(followerId)
    local followerStrings = GarrisonFollowerOptions[followerTypeId].strings
    local upgradeTexture = LOOTUPGRADEFRAME_QUALITY_TEXTURES[quality] or LOOTUPGRADEFRAME_QUALITY_TEXTURES[2]
    local color = ITEM_QUALITY_COLORS[quality]
    local alert = getAlert()

    local portrait
    if followerInfo.portraitIconID and followerInfo.portraitIconID ~= 0 then
        portrait = followerInfo.portraitIconID
    else
        portrait = "Interface/Garrison/Portraits/FollowerPortrait_NoPortrait"
    end
    alert.icon:SetTexture(portrait)
    alert.icon:SetTexCoord(0, 1, 0, 1)

    if isUpgraded then
        alert.title:SetText(followerStrings.FOLLOWER_ADDED_UPGRADED_TOAST)
        for i = 1, maxArrows do
            ---@type Texture
            local arrow = alert["arrow" .. i]
            arrow:SetAtlas(upgradeTexture.arrow, true)
        end
    else
        alert.title:SetText(followerStrings.FOLLOWER_ADDED_TOAST)
    end

    alert:SetBackdropBorderColor(GetTableColor(color))
    alert.text:SetText(name)
    alert.count:SetText(level)

    alert.data.event = event
    alert.data.followerId = followerId
    alert.data.arrows = isUpgraded
    alert.data.sound = SOUNDKIT.UI_GARRISON_TOAST_FOLLOWER_GAINED

    alert:HookScript("OnEnter", garrisonFollowerAlertOnEnter)

    showAlert(alert)
end

local function showGarrisonBuildingAlert(event, buildingName)
    local alert = getAlert()

    alert.title:SetText(GARRISON_UPDATE)
    alert.text:SetText(buildingName)
    alert.icon:SetTexture("Interface/Icons/Garrison_Build")

    alert.data.event = event
    alert.data.sound = SOUNDKIT.UI_GARRISON_TOAST_BUILDING_COMPLETE

    showAlert(alert)
end

local function showGarrisonTalentAlert(event, talent)
    local alert = getAlert()

    alert.title:SetText(GARRISON_TALENT_ORDER_ADVANCEMENT)
    alert.text:SetText(talent.name)
    alert.icon:SetTexture(talent.icon)

    alert.data.event = event
    alert.data.sound = SOUNDKIT.UI_ORDERHALL_TALENT_READY_TOAST

    showAlert(alert)
end

local function hookRewardFrameOnEnter(self)
    if self.data.type == "item" then
        GameTooltip:SetHyperlink(self.data.value)
    else
        GameTooltip:AddLine(YOU_EARNED_LABEL)
        local text
        if self.data.type == "xp" then
            text = format(BONUS_OBJECTIVE_EXPERIENCE_FORMAT, self.data.value)
        elseif self.data.type == "money" then
            text = GetMoneyString(self.data.value, true)
        elseif self.data.type == "currency" then
            text = format("%s|T%s:0|t", self.data.value, self.data.texture)
        end
        GameTooltip:AddLine(text, 1, 1, 1)
    end
    GameTooltip:Show()
end

local function showLfgCompleteAlert(event, name, subtypeId, texture, moneyReward, xpReward, numItemRewards,
                                    isScenario, isScenarioBonusComplete)
    local alert = getAlert()
    local sound
    ---@type WlkAlertRewardFrame
    local reward
    local index = 0

    if moneyReward and moneyReward > 0 then
        index = index + 1
        reward = alert["reward" .. index]
        if reward then
            reward.icon:SetTexture("Interface/Icons/INV_Misc_Coin_02")
            reward.data.type = "money"
            reward.data.value = moneyReward
            reward:Show()
            reward:HookScript("OnEnter", hookRewardFrameOnEnter)
        end
    end

    if xpReward and xpReward > 0 and UnitLevel("player") < MAX_PLAYER_LEVEL then
        index = index + 1
        reward = alert["reward" .. index]
        if reward then
            reward.icon:SetTexture("Interface/Icons/XP_ICON")
            reward.data.type = "xp"
            reward.data.value = xpReward
            reward:Show()
            reward:HookScript("OnEnter", hookRewardFrameOnEnter)
        end
    end

    for i = 1, numItemRewards or 0 do
        local link = GetLFGCompletionRewardItemLink(i)
        if link then
            index = index + 1
            reward = alert["reward" .. index]
            if reward then
                local rewardIcon = GetLFGCompletionRewardItem(i)
                reward.icon:SetTexture(rewardIcon or "Interface/Icons/INV_Box_02")
                reward.data.type = "item"
                reward.data.value = link
                reward:Show()
                reward:HookScript("OnEnter", hookRewardFrameOnEnter)
            end
        end
    end

    if isScenario then
        if isScenarioBonusComplete then
            alert.bonus:Show()
        end
        alert.title:SetText(SCENARIO_COMPLETED)
        sound = SOUNDKIT.UI_SCENARIO_ENDING
    else
        if subtypeId == LFG_SUBTYPEID_HEROIC then
            alert.skull:Show()
        end
        alert.title:SetText(DUNGEON_COMPLETED)
        sound = SOUNDKIT.LFG_REWARDS
    end

    alert.icon:SetTexture(texture or "Interface/LFGFrame/LFGICON-DUNGEON")
    alert.text:SetText(name)
    alert.data.event = event
    alert.data.sound = sound

    showAlert(alert)
end

local function getLinkInfo(link)
    if not link or link == "[]" or link == "" then
        return
    end
    local linkString, name = strmatch(link, "|H(.+)|h%[(.+)%]|h")
    link = linkString or link
    local tbl = { strsplit(":", link) }
    if tbl[1] ~= "item" then
        return link, link, tbl[1], tonumber(tbl[2]), name
    end
    if tbl[12] ~= "" then
        tbl[12] = ""
        tremove(tbl, 15 + (tonumber(tbl[14]) or 0))
    end
    return table.concat(tbl, ":"), link, tbl[1], tonumber(tbl[2]), name
end

local function getItemLevel(event, link)
    local _, _, quality, _, _, _, _, _, equipLoc, _, _, classId, subclassId = GetItemInfo(link)
    if (classId == LE_ITEM_CLASS_GEM and subclassId == LE_ITEM_GEM_ARTIFACTRELIC) or _G[equipLoc] then
        if event == "SHOW_LOOT_TOAST" or quality == Enum.ItemQuality.Heirloom then
            scanner:SetOwner(UIParent, "ANCHOR_NONE")
            scanner:SetHyperlink(link)
            for i = 2, min(5, scanner:NumLines()) do
                ---@type FontString
                local label = _G[scannerName .. "TextLeft" .. i]
                local level = strmatch(label:GetText(), ITEM_LEVEL_REGEX)
                if level then
                    return tonumber(level)
                end
            end
            return 0
        else
            return GetDetailedItemLevelInfo(link) or 0
        end
    end
    return 0
end

local function lootCommonAlertOnEnter(self)
    local link = self.data.originalLink
    if link then
        if strmatch(link, "item") then
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        elseif strmatch(link, "battlepet") then
            local _, speciesId, level, breedQuality, maxHealth, power, speed = strsplit(":", link)
            BattlePetToolTip_Show(tonumber(speciesId), tonumber(level), tonumber(breedQuality), tonumber(maxHealth),
                    tonumber(power), tonumber(speed))
        end
    end
end

local function showLootCommonItemAlert(event, link, quantity)
    local linkString, originalLinkString, linkType, itemId = getLinkInfo(link)
    local isNew, isQueued
    ---@type WlkAlertButton
    local alert
    alert, isQueued = findAlert(nil, "itemId", itemId)
    if alert then
        if alert.data.event ~= event then
            return
        end
    else
        alert, isNew, isQueued = getAlert(event, "link", linkString)
    end

    if isNew then
        local name, quality, icon, _, classId, subclassId, bindType

        if linkType == "battlepet" then
            local _, speciesId, _, breedQuality, _ = strsplit(":", originalLinkString)
            name, icon = C_PetJournal.GetPetInfoBySpeciesID(speciesId)
            quality = tonumber(breedQuality)
        else
            name, _, quality, _, _, _, _, _, _, icon, _, classId, subclassId, bindType = GetItemInfo(originalLinkString)
        end

        if name and (quality and quality >= Enum.ItemQuality.Poor and quality <= Enum.ItemQuality.Legendary
                or quality == Enum.ItemQuality.Heirloom) then
            local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[Enum.ItemQuality.Common]
            alert:SetBackdropBorderColor(GetTableColor(color))

            local title = YOU_EARNED_LABEL
            local sound = SOUNDKIT.UI_EPICLOOT_TOAST
            if quality == Enum.ItemQuality.Legendary then
                title = LEGENDARY_ITEM_LOOT_LABEL
                sound = SOUNDKIT.UI_LEGENDARY_LOOT_TOAST
            end

            local iLevel = getItemLevel(event, originalLinkString)
            if iLevel > 0 then
                name = format("[%s%d%s]%s", color.hex, iLevel, FONT_COLOR_CODE_CLOSE, name)
            end

            alert.title:SetText(title)
            alert.text:SetText(name)
            alert.icon:SetTexture(icon)
            alert.count.type = "normal"
            setLabelTextShowMode(alert.count, quantity)

            alert.data.count = quantity
            alert.data.event = event
            alert.data.itemId = itemId
            alert.data.link = linkString
            alert.data.originalLink = originalLinkString
            alert.data.sound = sound

            alert:HookScript("OnEnter", lootCommonAlertOnEnter)

            showAlert(alert)
        else
            releaseAlert(alert)
        end
    else
        alert.data.count = alert.data.count + quantity
        if isQueued then
            setLabelTextShowMode(alert.count, alert.data.count)
        else
            setLabelTextShowMode(alert.count, alert.data.count, true)
            alert.increment:SetText("+" .. quantity)
            alert.increment.blink:Stop()
            alert.increment.blink:Play()
            alert.animOut:Stop()
            if not MouseIsOver(alert) then
                alert.animOut:Play()
            end
        end
    end
end

local function lootSpecialAlertOnEnter(self)
    local link = self.data.originalLink
    if link then
        if strmatch(link, "item") then
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        elseif strmatch(link, "battlepet") then
            local _, speciesId, level, breedQuality, maxHealth, power, speed = strsplit(":", link)
            BattlePetToolTip_Show(tonumber(speciesId), tonumber(level), tonumber(breedQuality), tonumber(maxHealth),
                    tonumber(power), tonumber(speed))
        end
    end
end

local function showLootSpecialItemAlert(event, link, quantity, lessAwesome, isUpgraded, baseQuality, isLegendary,
                                        isAzerite, isCorrupted)
    if link then
        local linkString, originalLinkString, _, itemId = getLinkInfo(link)
        local alert, isNew, isQueued = getAlert(event, "link", linkString)
        if isNew then
            local name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(originalLinkString)
            if name and (quality and quality >= Enum.ItemQuality.Poor and quality <= Enum.ItemQuality.Legendary) then
                local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[Enum.ItemQuality.Common]
                alert:SetBackdropBorderColor(GetTableColor(color))
                local title = YOU_EARNED_LABEL
                local sound = SOUNDKIT.UI_EPICLOOT_TOAST
                if lessAwesome then
                    sound = SOUNDKIT.UI_RAID_LOOT_TOAST_LESSER_ITEM_WON
                elseif isUpgraded then
                    if baseQuality and baseQuality < quality then
                        title = format(format(LOOTUPGRADEFRAME_TITLE, "%s%s|r"), color.hex,
                                _G["ITEM_QUALITY" .. quality .. "_DESC"])
                    else
                        title = ITEM_UPGRADED_LABEL
                    end
                    sound = SOUNDKIT.UI_PERSONAL_LOOT_BANNER
                    local upgradeTexture = LOOTUPGRADEFRAME_QUALITY_TEXTURES[quality]
                            or LOOTUPGRADEFRAME_QUALITY_TEXTURES[Enum.ItemQuality.Uncommon]
                    for i = 1, maxArrows do
                        ---@type Texture
                        local arrow = alert["arrow" .. i]
                        arrow:SetAtlas(upgradeTexture.arrow, true)
                    end
                elseif isLegendary then
                    title = LEGENDARY_ITEM_LOOT_LABEL
                    sound = SOUNDKIT.UI_LEGENDARY_LOOT_TOAST
                elseif isAzerite then
                    title = AZERITE_EMPOWERED_ITEM_LOOT_LABEL
                    sound = SOUNDKIT.UI_AZERITE_EMPOWERED_ITEM_LOOT_TOAST
                elseif isCorrupted then
                    title = CORRUPTED_ITEM_LOOT_LABEL
                    sound = SOUNDKIT.UI_CORRUPTED_ITEM_LOOT_TOAST
                end

                local iLevel = getItemLevel(event, originalLinkString)
                if iLevel > 0 then
                    name = format("[%s%d%s]%s", color.hex, iLevel, FONT_COLOR_CODE_CLOSE, name)
                end

                alert.title:SetText(title)
                alert.text:SetText(name)
                alert.icon:SetTexture(icon)
                alert.count.type = "normal"
                setLabelTextShowMode(alert.count, quantity)

                alert.data.count = quantity
                alert.data.event = event
                alert.data.link = linkString
                alert.data.originalLink = originalLinkString
                alert.data.itemId = itemId
                alert.data.sound = sound
                alert.data.arrows = isUpgraded

                alert:HookScript("OnEnter", lootSpecialAlertOnEnter)

                showAlert(alert)
            else
                releaseAlert(alert)
            end
        else
            alert.data.count = alert.data.count + quantity
            if isQueued then
                setLabelTextShowMode(alert.count, alert.data.count)
            else
                setLabelTextShowMode(alert.count, alert.data.count, true)
                alert.increment:SetText("+" .. quantity)
                alert.increment.blink:Stop()
                alert.increment.blink:Play()
                alert.animOut:Stop()
                if not MouseIsOver(alert) then
                    alert.animOut:Play()
                end
            end
        end
    end
end

local function showMoneyAlert(event, quantity)
    local alert, isNew, isQueued = getAlert(nil, "event", event)
    if isNew then
        alert:SetBackdropBorderColor(0.9, 0.75, 0.26)
        alert.title:SetText(quantity > 0 and YOU_EARNED_LABEL or YOU_LOSE_LABEL)
        local texture = "Interface/Icons/INV_Misc_Coin_02"
        if abs(quantity) < 100 then
            texture = "Interface/Icons/INV_Misc_Coin_06"
        elseif abs(quantity) < 10000 then
            texture = "Interface/Icons/INV_Misc_Coin_04"
        end
        alert.icon:SetTexture(texture)
        alert.text.type = "money"
        setLabelTextShowMode(alert.text, quantity)

        alert.data.event = event
        alert.data.count = quantity
        alert.data.sound = SOUNDKIT.LOOT_WINDOW_COIN_SOUND

        showAlert(alert)
    else
        alert.data.count = alert.data.count + quantity
        if abs(alert.data.count) < 100 then
            alert.icon:SetTexture("Interface/Icons/INV_Misc_Coin_06")
        elseif abs(alert.data.count) < 10000 then
            alert.icon:SetTexture("Interface/Icons/INV_Misc_Coin_04")
        else
            alert.icon:SetTexture("Interface/Icons/INV_Misc_Coin_02")
        end
        if alert.data.count > 0 then
            alert.title:SetText(YOU_EARNED_LABEL)
        elseif alert.data.count < 0 then
            alert.title:SetText(YOU_LOSE_LABEL)
        end
        if isQueued then
            setLabelTextShowMode(alert.text, alert.data.count)
        else
            setLabelTextShowMode(alert.text, alert.data.count, true)
            alert.animOut:Stop()
            if not MouseIsOver(alert) then
                alert.animOut:Play()
            end
        end
    end
end

local function lootCurrencyAlertOnEnter(self)
    GameTooltip:SetHyperlink(self.data.originalLink)
    GameTooltip:Show()
end

local function showLootCurrencyAlert(event, link, quantity)
    local linkString, originalLinkString = getLinkInfo(link)
    local alert, isNew, isQueued = getAlert(event, "link", linkString)

    if isNew then
        local info = C_CurrencyInfo.GetCurrencyInfoFromLink(link)
        local color = ITEM_QUALITY_COLORS[info.quality or Enum.ItemQuality.Common]
        alert:SetBackdropBorderColor(GetTableColor(color))

        alert.title:SetText(YOU_EARNED_LABEL)
        alert.text:SetText(info.name)
        alert.icon:SetTexture(info.iconFileID)
        alert.count.type = "large"
        setLabelTextShowMode(alert.count, quantity)

        alert.data.event = event
        alert.data.count = quantity
        alert.data.link = linkString
        alert.data.originalLink = originalLinkString
        alert.data.sound = SOUNDKIT.IG_BACKPACK_COIN_OK

        alert:HookScript("OnEnter", lootCurrencyAlertOnEnter)

        showAlert(alert)
    else
        alert.data.count = alert.data.count + quantity
        if isQueued then
            setLabelTextShowMode(alert.count, alert.data.count)
        else
            setLabelTextShowMode(alert.count, alert.data.count, true)
            alert.increment:SetText("+" .. quantity)
            alert.increment.blink:Stop()
            alert.increment.blink:Play()
            alert.animOut:Stop()
            if not MouseIsOver(alert) then
                alert.animOut:Play()
            end
        end
    end
end

local function recipeAlertOnEnter(self)
    if self.data.recipeId then
        GameTooltip:SetSpellByID(self.data.recipeId)
        GameTooltip:Show()
    end
end

local function showRecipeAlert(event, recipeId)
    local tradeSkillId = C_TradeSkillUI.GetTradeSkillLineForRecipe(recipeId)
    if tradeSkillId then
        local recipeName = GetSpellInfo(recipeId)
        if recipeName then
            local alert = getAlert()
            local rank = GetSpellRank(recipeId)
            alert.title:SetText(rank and rank > 1 and UPGRADED_RECIPE_LEARNED_TITLE or NEW_RECIPE_LEARNED_TITLE)
            alert.text:SetText(recipeName .. (tradeSkillRankTextures[rank] or ""))
            alert.icon:SetTexture(C_TradeSkillUI.GetTradeSkillTexture(tradeSkillId))

            alert.data.event = event
            alert.data.recipeId = recipeId
            alert.data.sound = SOUNDKIT.UI_PROFESSIONS_NEW_RECIPE_LEARNED_TOAST

            alert:HookScript("OnEnter", recipeAlertOnEnter)

            showAlert(alert)
        end
    end
end

local function storeAlertOnEnter(self)
    local link = self.data.originalLink
    if link and strmatch(link, "item") then
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end
end

local function showStoreAlert(event, entitlementType, texture, name, payloadId, payloadLink)
    ---@type WlkAlertButton
    local alert
    local quality, sanitizedLink, originalLink, _
    if payloadLink then
        sanitizedLink, originalLink = getLinkInfo(payloadLink)
        alert = getAlert(event, "link", sanitizedLink)
        _, _, quality = GetItemInfo(originalLink)

        alert.data.link = sanitizedLink
        alert.data.originalLink = originalLink
    else
        alert = getAlert()
    end

    if entitlementType == Enum.WoWEntitlementType.Appearance then
        alert.data.link = "transmogappearance:" .. payloadId
    elseif entitlementType == Enum.WoWEntitlementType.AppearanceSet then
        alert.data.link = "transmogset:" .. payloadId
    elseif entitlementType == Enum.WoWEntitlementType.Illusion then
        alert.data.link = "transmogillusion:" .. payloadId
    end

    quality = quality or Enum.ItemQuality.Common
    alert:SetBackdropBorderColor(GetTableColor(ITEM_QUALITY_COLORS[quality]))
    alert.title:SetText(event == "ENTITLEMENT_DELIVERED" and BLIZZARD_STORE_PURCHASE_COMPLETE or YOU_EARNED_LABEL)
    alert.text:SetText(name)
    alert.icon:SetTexture(texture)

    alert.data.event = event
    alert.data.sound = SOUNDKIT.UI_IG_STORE_PURCHASE_DELIVERED_TOAST_01

    alert:HookScript("OnEnter", storeAlertOnEnter)

    showAlert(alert)
end

local function getStoreItemLink(itemId, texture)
    if itemId then
        if select(5, GetItemInfoInstant(itemId)) == texture then
            local _, link = GetItemInfo(itemId)
            if link then
                return link, false
            end
            return nil, true
        end
    end
    return nil, false
end

local function onEventEntitlementDelivered(event, entitlementType, texture, name, payloadId)
    if entitlementType == Enum.WoWEntitlementType.Invalid then
        return
    end
    local link, tryAgain = getStoreItemLink(payloadId, texture)
    if tryAgain then
        return C_Timer.After(0.25, function()
            onEventEntitlementDelivered(event, entitlementType, texture, name, payloadId)
        end)
    end
    showStoreAlert(event, entitlementType, texture, name, payloadId, link)
end

local function showTransmogAlert(event, sourceId, isAdded, attempt)
    local _, visualId, _, icon, _, _, link = C_TransmogCollection.GetAppearanceSourceInfo(sourceId)
    local name, linkString
    linkString, _, _, _, name = getLinkInfo(link)
    if not linkString then
        return attempt < 4 and C_Timer.After(0.25, function()
            showTransmogAlert(event, sourceId, isAdded, attempt + 1)
        end)
    end
    if findAlert(event, "visualId", visualId) then
        return
    end
    local alert, isNew, isQueued = getAlert(nil, "sourceId", sourceId)
    if isNew then
        alert:SetBackdropBorderColor(1, 0.5, 1)
        alert.title:SetText(isAdded and COLLECTED or YOU_LOSE_LABEL)
        alert.text:SetText(name)
        alert.icon:SetTexture(icon)

        alert.data.event = event
        alert.data.sound = SOUNDKIT.UI_TRANSMOG_REVERTING_GEAR_SLOT
        alert.data.sourceId = sourceId
        alert.data.visualId = visualId

        showAlert(alert)
    else
        alert.title:SetText(isAdded and COLLECTED or YOU_LOSE_LABEL)
        if not isQueued then
            alert.animOut:Stop()
            if not MouseIsOver(alert) then
                alert.animOut:Play()
            end
        end
    end
end

local function showWorldQuestCompleteAlert(event, isUpdate, questId, name, moneyReward, xpReward, numCurrencyRewards,
                                           link)
    local alert, isNew, isQueued = getAlert(nil, "questId", questId)
    if isUpdate and isNew then
        releaseAlert(alert)
        return
    end
    ---@type WlkAlertRewardFrame
    local reward
    if isNew then
        local index = 0
        if moneyReward and moneyReward > 0 then
            index = index + 1
            reward = alert["reward" .. index]
            if reward then
                reward.icon:SetTexture("Interface/Icons/INV_Misc_Coin_02")
                reward.data.type = "money"
                reward.data.value = moneyReward
                reward:HookScript("OnEnter", hookRewardFrameOnEnter)
                reward:Show()
            end
        end

        if xpReward and xpReward > 0 and UnitLevel("player") < MAX_PLAYER_LEVEL then
            index = index + 1
            reward = alert["reward" .. index]
            if reward then
                reward.icon:SetTexture("Interface/Icons/XP_ICON")
                reward.data.type = "xp"
                reward.data.value = xpReward
                reward:HookScript("OnEnter", hookRewardFrameOnEnter)
                reward:Show()
            end
        end

        for i = 1, numCurrencyRewards or 0 do
            index = index + 1
            reward = alert["reward" .. index]
            if reward then
                local _, texture, count = GetQuestLogRewardCurrencyInfo(i, questId)
                texture = texture or "Interface/Icons/INV_Box_02"
                reward.icon:SetTexture(texture)
                reward.data.type = "currency"
                reward.data.value = count
                reward.data.texture = texture
                reward:HookScript("OnEnter", hookRewardFrameOnEnter)
                reward:Show()
            end
        end

        local _, _, worldQuestType, rarity, _, tradeSkillLineIndex = C_QuestLog.GetQuestTagInfo(questId)
        if worldQuestType == Enum.QuestTagType.PvP then
            alert.icon:SetTexture("Interface/Icons/ACHIEVEMENT_ARENA_2V2_1")
        elseif worldQuestType == Enum.QuestTagType.PetBattle then
            alert.icon:SetTexture("Interface/Icons/INV_Pet_BattlePetTraining")
        elseif worldQuestType == Enum.QuestTagType.Profession and tradeSkillLineIndex then
            alert.icon:SetTexture(select(2, GetProfessionInfo(tradeSkillLineIndex)))
        elseif worldQuestType == Enum.QuestTagType.Dungeon or worldQuestType == Enum.QuestTagType.Raid then
            alert.icon:SetTexture("Interface/Icons/INV_Misc_Bone_Skull_02")
        else
            alert.icon:SetTexture("Interface/Icons/Achievement_Quests_Completed_TwilightHighlands")
        end
        local color = WORLD_QUEST_QUALITY_COLORS[rarity or Enum.WorldQuestQuality.Common]
        alert:SetBackdropBorderColor(GetTableColor(color))
        alert.title:SetText(WORLD_QUEST_COMPLETE)
        alert.text:SetText(name)

        alert.data.event = event
        alert.data.questId = questId
        alert.data.sound = SOUNDKIT.UI_WORLDQUEST_COMPLETE
        alert.data.numRewards = index

        showAlert(alert)
    else
        if link then
            alert.data.numRewards = alert.data.numRewards + 1
            reward = alert["reward" .. alert.data.numRewards]
            if reward then
                local _, _, _, _, texture = GetItemInfoInstant(link)
                texture = texture or "Interface/Icons/INV_Box_02"
                reward.icon:SetTexture(texture)
                reward.data.type = "item"
                reward.data.value = link
                reward:HookScript("OnEnter", hookRewardFrameOnEnter)
                reward:Show()
            end
        end
        if not isQueued then
            alert.animOut:Stop()
            if not MouseIsOver(alert) then
                alert.animOut:Play()
            end
        end
    end
end

local function onEventQuestTurnedIn(questId)
    if QuestUtils_IsQuestWorldQuest(questId) then
        if not HaveQuestRewardData(questId) then
            C_TaskQuest.RequestPreloadRewardData(questId)
            C_Timer.After(0.5, function()
                onEventQuestTurnedIn(questId)
            end)
            return
        end
        showWorldQuestCompleteAlert("QUEST_TURNED_IN", false, questId, C_TaskQuest.GetQuestInfoByQuestID(questId),
                GetQuestLogRewardMoney(questId), GetQuestLogRewardXP(questId), GetNumQuestLogRewardCurrencies(questId))
    end
end

local function onEventQuestLootReceived(questId, itemLink)
    if not findAlert(nil, "questId", questId) then
        if not HaveQuestRewardData(questId) then
            C_TaskQuest.RequestPreloadRewardData(questId)
            C_Timer.After(0.5, function()
                onEventQuestLootReceived(questId, itemLink)
            end)
            return
        end
        onEventQuestTurnedIn(questId)
    end
    showWorldQuestCompleteAlert("QUEST_LOOT_RECEIVED", true, questId, nil, nil, nil, nil, itemLink)
end

local function hideFrames(...)
    for i = 1, select("#", ...) do
        ---@type Frame
        local frame = select(i, ...)
        frame:Hide()
        frame:UnregisterAllEvents()
    end
end

alertFrame:SetSize(frameWidth, frameHeight)
alertFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", -120, 301)
alertFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.05 then
        return
    end
    self.elapsed = 0

    for label, value in pairs(textToAnimate) do
        local newValue
        label.elapsed = label.elapsed + 0.05
        if label.value >= value then
            newValue = floor(Lerp(label.value, value, label.elapsed / 0.6))
        else
            newValue = ceil(Lerp(label.value, value, label.elapsed / 0.6))
        end
        if newValue == value then
            textToAnimate[label] = nil
        end
        label.value = newValue
        setLabelText(label, newValue)
    end
end)
alertFrame:RegisterEvent("ACHIEVEMENT_EARNED")
alertFrame:RegisterEvent("CRITERIA_EARNED")

alertFrame:RegisterEvent("ARTIFACT_DIGSITE_COMPLETE")

alertFrame:RegisterEvent("NEW_MOUNT_ADDED")
alertFrame:RegisterEvent("NEW_PET_ADDED")
alertFrame:RegisterEvent("NEW_TOY_ADDED")

alertFrame:RegisterEvent("GARRISON_FOLLOWER_ADDED")
alertFrame:RegisterEvent("GARRISON_MISSION_FINISHED")
alertFrame:RegisterEvent("GARRISON_RANDOM_MISSION_ADDED")
alertFrame:RegisterEvent("GARRISON_BUILDING_ACTIVATABLE")
alertFrame:RegisterEvent("GARRISON_TALENT_COMPLETE")

alertFrame:RegisterEvent("LFG_COMPLETION_REWARD")

alertFrame:RegisterEvent("CHAT_MSG_LOOT")

alertFrame:RegisterEvent("CHAT_MSG_CURRENCY")

alertFrame:RegisterEvent("PLAYER_LOGIN")
alertFrame:RegisterEvent("PLAYER_MONEY")

alertFrame:RegisterEvent("AZERITE_EMPOWERED_ITEM_LOOTED")
alertFrame:RegisterEvent("LOOT_ITEM_ROLL_WON")
alertFrame:RegisterEvent("SHOW_LOOT_TOAST")
alertFrame:RegisterEvent("SHOW_LOOT_TOAST_UPGRADE")
alertFrame:RegisterEvent("SHOW_PVP_FACTION_LOOT_TOAST")
alertFrame:RegisterEvent("SHOW_RATED_PVP_REWARD_TOAST")
alertFrame:RegisterEvent("SHOW_LOOT_TOAST_LEGENDARY_LOOTED")

alertFrame:RegisterEvent("NEW_RECIPE_LEARNED")

alertFrame:RegisterEvent("ENTITLEMENT_DELIVERED")
alertFrame:RegisterEvent("RAF_ENTITLEMENT_DELIVERED")

alertFrame:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_ADDED")
alertFrame:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_REMOVED")

alertFrame:RegisterEvent("QUEST_TURNED_IN")
alertFrame:RegisterEvent("QUEST_LOOT_RECEIVED")

alertFrame:RegisterEvent("ADDON_LOADED")

alertFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" and ... == "Blizzard_ArchaeologyUI" then
        alertFrame:UnregisterEvent(event)
        ArcheologyDigsiteProgressBar:ClearAllPoints()
        ArcheologyDigsiteProgressBar:SetPoint("BOTTOM", 0, 130)
        ArcheologyDigsiteProgressBar.SetPoint = nop
    elseif event == "ACHIEVEMENT_EARNED" then
        showAchievementAlert(event, ...)
    elseif event == "CRITERIA_EARNED" then
        local achievementId, description = ...
        showAchievementAlert(event, achievementId, description, true)
    elseif event == "ARTIFACT_DIGSITE_COMPLETE" then
        showDigSiteCompleteAlert(event, ...)
    elseif event == "NEW_MOUNT_ADDED" then
        local mountId = ...
        showCollectionAlert(event, mountId, true)
    elseif event == "NEW_PET_ADDED" then
        local petId = ...
        showCollectionAlert(event, petId, nil, true)
    elseif event == "NEW_TOY_ADDED" then
        local toyId = ...
        showCollectionAlert(event, toyId, nil, nil, true)
    elseif event == "GARRISON_FOLLOWER_ADDED" then
        showGarrisonFollowerAlert(event, ...)
    elseif event == "GARRISON_MISSION_FINISHED" then
        local _, instanceType = GetInstanceInfo()
        if instanceType == "none" or C_Garrison.IsOnGarrisonMap() then
            local _, missionId = ...
            showGarrisonMissionAlert(event, missionId)
        end
    elseif event == "GARRISON_RANDOM_MISSION_ADDED" then
        local _, missionId = ...
        showGarrisonMissionAlert(event, missionId)
    elseif event == "GARRISON_BUILDING_ACTIVATABLE" then
        showGarrisonBuildingAlert(event, ...)
    elseif event == "GARRISON_TALENT_COMPLETE" then
        local garrisonTypeId, doAlert = ...
        if doAlert then
            local talent = C_Garrison.GetTalentInfo(C_Garrison.GetCompleteTalent(garrisonTypeId))
            showGarrisonTalentAlert(event, talent)
        end
    elseif event == "LFG_COMPLETION_REWARD" then
        if C_Scenario.IsInScenario() and not C_Scenario.TreatScenarioAsDungeon() then
            local _, _, _, _, hasBonusStep, isBonusStepComplete, _, _, _, scenarioType = C_Scenario.GetInfo()
            if scenarioType ~= LE_SCENARIO_TYPE_LEGION_INVASION then
                local name, _, subtypeId, texture, moneyBase, moneyVar, experienceBase, experienceVar, numStrangers,
                numItemRewards = GetLFGCompletionReward()
                showLfgCompleteAlert(event, name, subtypeId, texture, moneyBase + moneyVar * numStrangers,
                        experienceBase + experienceVar * numStrangers, numItemRewards, true,
                        hasBonusStep and isBonusStepComplete)
            end
        else
            local name, _, subtypeId, texture, moneyBase, moneyVar, experienceBase, experienceVar, numStrangers,
            numItemRewards = GetLFGCompletionReward()
            showLfgCompleteAlert(event, name, subtypeId, texture, moneyBase + moneyVar * numStrangers,
                    experienceBase + experienceVar * numStrangers, numItemRewards)
        end
    elseif event == "CHAT_MSG_LOOT" then
        local message, _, _, _, _, _, _, _, _, _, _, guid = ...
        if guid ~= UnitGUID("player") then
            return
        end
        local link, quantity = strmatch(message, LOOT_ITEM_SELF_MULTIPLE_PATTERN)
        if not link then
            link, quantity = strmatch(message, LOOT_ITEM_PUSHED_MULTIPLE_PATTERN)
            if not link then
                link, quantity = strmatch(message, LOOT_ITEM_CREATED_MULTIPLE_PATTERN)
                if not link then
                    quantity, link = 1, strmatch(message, LOOT_ITEM_PATTERN)
                    if not link then
                        quantity, link = 1, strmatch(message, LOOT_ITEM_PUSHED_PATTERN)
                        if not link then
                            quantity, link = 1, strmatch(message, LOOT_ITEM_CREATED_PATTERN)
                        end
                    end
                end
            end
        end
        if not link then
            return
        end
        C_Timer.After(0.3, function()
            showLootCommonItemAlert(event, link, tonumber(quantity) or 0)
        end)
    elseif event == "CHAT_MSG_CURRENCY" then
        local message = ...
        local link, quantity = strmatch(message, CURRENCY_GAINED_MULTIPLE_PATTERN)
        if not link then
            quantity, link = 1, strmatch(message, CURRENCY_GAINED_PATTERN)
        end
        if not link then
            return
        end
        showLootCurrencyAlert(event, link, tonumber(quantity) or 0)
    elseif event == "PLAYER_LOGIN" then
        alertFrame:UnregisterEvent(event)
        lastMoney = GetMoney()
    elseif event == "PLAYER_MONEY" then
        local money = GetMoney()
        if money - lastMoney ~= 0 then
            showMoneyAlert(event, money - lastMoney)
        end
        lastMoney = money
    elseif event == "AZERITE_EMPOWERED_ITEM_LOOTED" then
        local link = ...
        showLootSpecialItemAlert(event, link, 1, nil, nil, nil, nil, nil, true)
    elseif event == "LOOT_ITEM_ROLL_WON" then
        local link, quantity, _, _, isUpgraded = ...
        showLootSpecialItemAlert(event, link, quantity, nil, isUpgraded)
    elseif event == "SHOW_LOOT_TOAST" then
        local typeId, link, quantity, _, _, _, _, lessAwesome, isUpgraded, isCorrupted = ...
        if typeId == "item" then
            showLootSpecialItemAlert(event, link, quantity, lessAwesome, isUpgraded, nil, nil, nil, isCorrupted)
        end
    elseif event == "SHOW_LOOT_TOAST_UPGRADE" then
        local link, quantity, _, _, baseQuality = ...
        showLootSpecialItemAlert(event, link, quantity, nil, true, baseQuality)
    elseif event == "SHOW_PVP_FACTION_LOOT_TOAST" or event == "SHOW_RATED_PVP_REWARD_TOAST" then
        local typeId, link, quantity, _, _, _, lessAwesome = ...
        if typeId == "item" then
            showLootSpecialItemAlert(event, link, quantity, lessAwesome)
        end
    elseif event == "SHOW_LOOT_TOAST_LEGENDARY_LOOTED" then
        local link = ...
        showLootSpecialItemAlert(event, link, 1, nil, nil, nil, true)
    elseif event == "NEW_RECIPE_LEARNED" then
        showRecipeAlert(event, ...)
    elseif event == "ENTITLEMENT_DELIVERED" or event == "RAF_ENTITLEMENT_DELIVERED" then
        local entitlementType, texture, name, payloadId = ...
        onEventEntitlementDelivered(event, entitlementType, texture, name, payloadId)
    elseif event == "TRANSMOG_COLLECTION_SOURCE_ADDED" then
        local sourceId = ...
        if C_TransmogCollection.PlayerKnowsSource(sourceId) then
            showTransmogAlert(event, sourceId, true, 1)
        end
    elseif event == "TRANSMOG_COLLECTION_SOURCE_REMOVED" then
        local sourceId = ...
        if C_TransmogCollection.PlayerKnowsSource(sourceId) then
            showTransmogAlert(event, sourceId, nil, 1)
        end
    elseif event == "QUEST_TURNED_IN" then
        onEventQuestTurnedIn(...)
    elseif event == "QUEST_LOOT_RECEIVED" then
        onEventQuestLootReceived(...)
    end
end)

BonusRollFrame.FinishRollAnim:HookScript("OnFinished", function()
    if BonusRollFrame.rewardType == "item" then
        showLootSpecialItemAlert("LOOT_ITEM_BONUS_ROLL_WON", BonusRollFrame.rewardLink, BonusRollFrame.rewardQuantity)
    end
    GroupLootContainer_RemoveFrame(GroupLootContainer, BonusRollFrame)
end)

hideFrames(LootFrame, AlertFrame)

---@class WlkAlertIncrementLabel:FontString
