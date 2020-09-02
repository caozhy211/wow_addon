--- MicroButtonAndBagsBar 左边相对 UIParent 右边的偏移值
local OFFSET_X1 = -298
--- PlayerPowerBarAlt 右边相对 UIParent 右边的偏移值
local offsetX1 = -535
--- OrderHallCommandBar 底部相对 UIParent 顶部的偏移值
local OFFSET_Y1 = -25
--- PlayerPowerBarAlt 底部相对 UIParent 顶部的偏移值
local OFFSET_Y2 = -217

---@type Frame
local alertFrame = CreateFrame("Frame", "WlkAlertFrame", UIParent)
alertFrame:SetSize(OFFSET_X1 - offsetX1, OFFSET_Y1 - OFFSET_Y2)
alertFrame:SetPoint("TOPRIGHT", OFFSET_X1, OFFSET_Y1)

local width = OFFSET_X1 - offsetX1
local height = 45
local maxNumActives = 4
local spacing = 4
local padding = 2
local iconSize = height - padding * 2
local backdrop = {
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = 2,
}
local numArrows = 5
local arrowsConfig = {
    { delay = 0, x = 0, },
    { delay = 0.1, x = -8, },
    { delay = 0.2, x = 16, },
    { delay = 0.3, x = 8, },
    { delay = 0.4, x = -16, },
}
local rewardSize = 20
local numRewards = 5
local showTime = 5

---@type Button[]
local releasedAlert = {}
---@type Button[]
local activeAlerts = {}
---@type Button[]
local queuedAlerts = {}
local numCreated = 0

---@param self Button
local function AlertButtonOnEnter(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    self:SetAlpha(1)
    self.animOut:Stop()
end

---@param self Button
local function AlertButtonOnLeave(self)
    GameTooltip:Hide()
    GarrisonFollowerTooltip:Hide()
    GarrisonShipyardFollowerTooltip:Hide()
    BattlePetTooltip:Hide()
    ShoppingTooltip1:Hide()
    ShoppingTooltip2:Hide()
    self.animOut:Play()
end

---@param self Button
local function AlertButtonOnShow(self)
    if self.data.sound then
        PlaySound(self.data.sound)
    end
    self.animIn:Play()
    self.animOut:Play()
end

---@param self Frame
local function RewardFrameOnEnter(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    ---@type Button
    local alert = self:GetParent()
    alert:SetAlpha(1)
    alert.animOut:Stop()
end

---@param self Frame
local function RewardFrameOnLeave(self)
    GameTooltip:Hide()
    ---@type Button
    local alert = self:GetParent()
    alert.animOut:Play()
end

---@param alert Button
local function ShowAlert(alert)
    if #activeAlerts >= maxNumActives then
        queuedAlerts[#queuedAlerts + 1] = alert
        return
    end
    alert:SetPoint("BOTTOM", 0, #activeAlerts * (height + spacing))
    activeAlerts[#activeAlerts + 1] = alert
    alert:Show()
end

---@param alert Button
local function ReleaseAlert(alert)
    alert:ClearAllPoints()
    alert:SetAlpha(1)
    alert:Hide()
    alert:SetScript("OnEnter", AlertButtonOnEnter)

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

    alert:SetBackdropBorderColor(0, 0, 0)

    for i = 1, numRewards do
        ---@type Frame
        local reward = alert["reward" .. i]
        wipe(reward.data)
        reward:Hide()
        reward:SetScript("OnEnter", RewardFrameOnEnter)
    end

    for i = 1, numArrows do
        ---@type Texture
        local arrow = alert["arrow" .. i]
        arrow:SetAlpha(0)
    end

    wipe(alert.data)
    releasedAlert[#releasedAlert + 1] = alert
    tDeleteItem(activeAlerts, alert)
    tDeleteItem(queuedAlerts, alert)

    for i, activeAlert in ipairs(activeAlerts) do
        activeAlert:ClearAllPoints()
        activeAlert:SetPoint("BOTTOM", 0, (i - 1) * (height + spacing))
    end
    local queuedAlert = tremove(queuedAlerts, 1)
    if queuedAlert then
        ShowAlert(queuedAlert)
    end
end

---@param self AnimationGroup
local function AlertButtonAnimInOnFinished(self)
    ---@type Button
    local alert = self:GetParent()
    if alert.data.arrows then
        alert.arrows:Play()
        alert.data.arrows = nil
    end
end

---@param self AnimationGroup
local function AlertButtonAnimOutOnFinished(self)
    ReleaseAlert(self:GetParent())
end

local function CreateAlert()
    numCreated = numCreated + 1
    ---@type Button
    local alert = CreateFrame("Button", "WlkAlertButton" .. numCreated, alertFrame)
    alert:Hide()
    alert:SetSize(width, height)
    alert:SetBackdrop(backdrop)
    alert:SetBackdropBorderColor(0, 0, 0)
    alert.data = {}

    ---@type Texture
    local icon = alert:CreateTexture(nil, "BORDER")
    alert.icon = icon
    icon:SetSize(iconSize, iconSize)
    icon:SetPoint("LEFT", padding, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    ---@type FontString
    local count = alert:CreateFontString(nil, "ARTWORK", "Game12Font_o1")
    alert.count = count
    count:SetPoint("BOTTOMRIGHT", icon)

    ---@type FontString
    local increment = alert:CreateFontString(nil, "ARTWORK", "Game12Font_o1")
    alert.increment = increment
    increment:SetPoint("BOTTOMRIGHT", count, "TOPRIGHT")

    ---@type AnimationGroup
    local blinkAnimGroup = alert:CreateAnimationGroup()
    increment.blink = blinkAnimGroup
    blinkAnimGroup:SetToFinalAlpha(true)

    ---@type Alpha
    local blink = blinkAnimGroup:CreateAnimation("Alpha")
    blink:SetChildKey("increment")
    blink:SetOrder(1)
    blink:SetFromAlpha(1)
    blink:SetToAlpha(0)
    blink:SetDuration(0)

    blink:SetChildKey("increment")
    blink:SetOrder(2)
    blink:SetFromAlpha(0)
    blink:SetToAlpha(1)
    blink:SetDuration(0.2)

    blink:SetChildKey("increment")
    blink:SetOrder(3)
    blink:SetFromAlpha(0)
    blink:SetToAlpha(1)
    blink:SetDuration(0.4)
    blink:SetStartDelay(0.4)

    ---@type Texture
    local skull = alert:CreateTexture()
    alert.skull = skull
    skull:Hide()
    skull:SetSize(16, 20)
    skull:SetPoint("TOPRIGHT", icon)
    skull:SetTexture("Interface/LFGFrame/UI-LFG-ICON-HEROIC")
    skull:SetTexCoord(0, 0.5, 0, 0.625)

    ---@type AnimationGroup
    local arrowAnimGroup = alert:CreateAnimationGroup()
    alert.arrows = arrowAnimGroup
    arrowAnimGroup:SetToFinalAlpha(true)

    for i = 1, numArrows do
        local offsetX = arrowsConfig[i].x
        ---@type Texture
        local arrow = alert:CreateTexture(nil, "ARTWORK", "LootUpgradeFrame_ArrowTemplate")
        alert["arrow" .. i] = arrow
        arrow:ClearAllPoints()
        arrow:SetPoint("CENTER", icon, "BOTTOM", offsetX, 0)
        arrow:SetAlpha(0)

        local delay = arrowsConfig[i].delay
        ---@type Alpha|Translation
        local arrowAnim = arrowAnimGroup:CreateAnimation("Alpha")
        arrowAnim:SetChildKey("arrow" .. i)
        arrowAnim:SetOrder(1)
        arrowAnim:SetFromAlpha(1)
        arrowAnim:SetToAlpha(0)
        arrowAnim:SetDuration(0)

        arrowAnim = arrowAnimGroup:CreateAnimation("Alpha")
        arrowAnim:SetChildKey("arrow" .. i)
        arrowAnim:SetOrder(2)
        arrowAnim:SetFromAlpha(0)
        arrowAnim:SetToAlpha(1)
        arrowAnim:SetDuration(0.25)
        arrowAnim:SetStartDelay(delay)
        arrowAnim:SetSmoothing("IN")

        arrowAnim = arrowAnimGroup:CreateAnimation("Alpha")
        arrowAnim:SetChildKey("arrow" .. i)
        arrowAnim:SetOrder(2)
        arrowAnim:SetFromAlpha(1)
        arrowAnim:SetToAlpha(0)
        arrowAnim:SetDuration(0.25)
        arrowAnim:SetStartDelay(delay + 0.25)
        arrowAnim:SetSmoothing("OUT")

        arrowAnim = arrowAnimGroup:CreateAnimation("Translation")
        arrowAnim:SetChildKey("arrow" .. i)
        arrowAnim:SetOrder(2)
        arrowAnim:SetDuration(0.5)
        arrowAnim:SetStartDelay(delay)
        arrowAnim:SetOffset(0, 60)

        arrowAnim = arrowAnimGroup:CreateAnimation("Alpha")
        arrowAnim:SetChildKey("arrow" .. i)
        arrowAnim:SetOrder(3)
        arrowAnim:SetFromAlpha(1)
        arrowAnim:SetToAlpha(0)
        arrowAnim:SetDuration(0)
    end

    ---@type FontString
    local title = alert:CreateFontString(nil, "ARTWORK", "ChatFontSmall")
    alert.title = title
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, -5)
    title:SetTextColor(1, 0.82, 0)

    ---@type FontString
    local text = alert:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
    alert.text = text
    text:SetWidth(width - height)
    text:SetPoint("BOTTOM", iconSize / 2, padding)
    text:SetMaxLines(1)

    ---@type Texture
    local bonus = alert:CreateTexture()
    alert.bonus = bonus
    bonus:SetPoint("RIGHT", -padding, 0)
    bonus:SetAtlas("Bonus-ToastBanner", true)
    bonus:Hide()

    for i = 1, numRewards do
        ---@type Frame
        local reward = CreateFrame("Frame", nil, alert)
        alert["reward" .. i] = reward
        reward:SetSize(rewardSize, rewardSize)
        reward:SetPoint("TOPRIGHT", (1 - i) * rewardSize - padding, -padding)
        reward:Hide()
        reward.data = {}

        ---@type Texture
        local rewardIcon = reward:CreateTexture()
        reward.icon = rewardIcon
        rewardIcon:SetAllPoints()
        rewardIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        reward:SetScript("OnEnter", RewardFrameOnEnter)
        reward:SetScript("OnLeave", RewardFrameOnLeave)
    end

    ---@type Texture
    local glow = alert:CreateTexture(nil, "OVERLAY")
    alert.glow = glow
    glow:SetSize(width + 80, height * 2)
    glow:SetPoint("CENTER")
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0)
    glow:SetTexture("Interface/AchievementFrame/UI-Achievement-Alert-Glow")
    glow:SetTexCoord(0, 0.78125, 0, 0.66796875)

    ---@type Texture
    local shine = alert:CreateTexture(nil, "OVERLAY")
    alert.shine = shine
    shine:SetSize(67, height)
    shine:SetPoint("BOTTOMLEFT")
    shine:SetBlendMode("ADD")
    shine:SetAlpha(0)
    shine:SetTexture("Interface/AchievementFrame/UI-Achievement-Alert-Glow")
    shine:SetTexCoord(0.78125, 0.912109375, 0, 0.28125)

    ---@type AnimationGroup
    local animGroup = alert:CreateAnimationGroup()
    alert.animIn = animGroup
    animGroup:SetToFinalAlpha(true)
    animGroup:SetScript("OnFinished", AlertButtonAnimInOnFinished)

    ---@type Alpha|Translation
    local anim = animGroup:CreateAnimation("Alpha")
    anim:SetChildKey("glow")
    anim:SetOrder(1)
    anim:SetFromAlpha(0)
    anim:SetToAlpha(1)
    anim:SetDuration(0)

    anim = animGroup:CreateAnimation("Alpha")
    anim:SetChildKey("glow")
    anim:SetOrder(2)
    anim:SetFromAlpha(0)
    anim:SetToAlpha(1)
    anim:SetDuration(0.2)

    anim = animGroup:CreateAnimation("Alpha")
    anim:SetChildKey("glow")
    anim:SetOrder(3)
    anim:SetFromAlpha(1)
    anim:SetToAlpha(0)
    anim:SetDuration(0.5)

    anim = animGroup:CreateAnimation("Alpha")
    anim:SetChildKey("shine")
    anim:SetOrder(2)
    anim:SetFromAlpha(0)
    anim:SetToAlpha(1)
    anim:SetDuration(0.2)

    anim = animGroup:CreateAnimation("Translation")
    anim:SetChildKey("shine")
    anim:SetOrder(3)
    anim:SetDuration(0.85)
    anim:SetOffset(width - shine:GetWidth(), 0)

    anim = animGroup:CreateAnimation("Alpha")
    anim:SetChildKey("shine")
    anim:SetOrder(3)
    anim:SetFromAlpha(1)
    anim:SetToAlpha(0)
    anim:SetDuration(0.5)
    anim:SetStartDelay(0.35)

    animGroup = alert:CreateAnimationGroup()
    alert.animOut = animGroup
    animGroup:SetScript("OnFinished", AlertButtonAnimOutOnFinished)

    anim = animGroup:CreateAnimation("Alpha")
    anim:SetOrder(1)
    anim:SetFromAlpha(1)
    anim:SetToAlpha(0)
    anim:SetDuration(1.2)
    anim:SetStartDelay(showTime)

    alert:SetScript("OnEnter", AlertButtonOnEnter)
    alert:SetScript("OnLeave", AlertButtonOnLeave)
    alert:SetScript("OnShow", AlertButtonOnShow)

    return alert
end

---@type table<FontString, number>
local textsToAnimate = {}

---@param label FontString
local function SetDigitText(label, value)
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

---@param label FontString
local function SetAnimatedDigit(label, value, animate)
    if animate then
        label.value = label.value or 1
        label.elapsed = 0
        textsToAnimate[label] = value
    else
        label.value = value
        label.elapsed = 0
        SetDigitText(label, value)
    end
end

alertFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.05 then
        return
    end
    self.elapsed = 0

    for label, value in pairs(textsToAnimate) do
        local newValue
        label.elapsed = label.elapsed + 0.05
        if label.value >= value then
            newValue = floor(Lerp(label.value, value, label.elapsed / 0.6))
        else
            newValue = ceil(Lerp(label.value, value, label.elapsed / 0.6))
        end
        if newValue == value then
            textsToAnimate[label] = nil
        end
        label.value = newValue
        SetDigitText(label, newValue)
    end
end)

local function FindAlert(event, type, value)
    if type and value then
        for _, alert in ipairs(activeAlerts) do
            if (not event or event == alert.data.event) and alert.data[type] == value then
                return alert
            end
        end
        for _, alert in ipairs(queuedAlerts) do
            if (not event or event == alert.data.event) and alert.data[type] == value then
                return alert, true
            end
        end
    end
end

local function GetAlert(event, type, value)
    local alert, isQueued = FindAlert(event, type, value)
    local isNew
    if not alert then
        isNew = true
        alert = tremove(releasedAlert, 1)
        if not alert then
            alert = CreateAlert()
        end
    end
    return alert, isNew, isQueued
end

local function AchievementAlertOnEnter(self)
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

local function CreateAchievementAlert(event, achievementId, arg, isCriteria)
    local alert = GetAlert()
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

    alert:HookScript("OnEnter", AchievementAlertOnEnter)

    ShowAlert(alert)
end

local function CreateDigSiteCompleteAlert(event, researchBranchId)
    local alert = GetAlert()

    local name, texture = GetArchaeologyRaceInfoByID(researchBranchId)
    alert:SetBackdropBorderColor(0.9, 0.4, 0.1)
    alert.title:SetText(ARCHAEOLOGY_DIGSITE_COMPLETE_TOAST_FRAME_TITLE)
    alert.text:SetText(name)
    alert.icon:SetTexture(texture)
    alert.icon:SetTexCoord(0, 0.578125, 0, 0.75)

    alert.data.event = event
    alert.data.sound = SOUNDKIT.UI_DIG_SITE_COMPLETION_TOAST

    ShowAlert(alert)
end

local function CreateCollectionAlert(event, id, isMount, isPet, isToy)
    local alert, isNew, isQueued = GetAlert(event, "collectionId", id)
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
            ReleaseAlert(alert)
            return
        end

        if rarity then
            alert:SetBackdropBorderColor(GetTableColor(color))
        end

        alert.title:SetText(YOU_EARNED_LABEL)
        alert.text:SetText(name)
        alert.icon:SetTexture(icon)
        alert.count.type = "normal"
        SetAnimatedDigit(alert.count, 1)

        alert.data.collectionId = id
        alert.data.count = 1
        alert.data.event = event
        alert.data.sound = SOUNDKIT.UI_EPICLOOT_TOAST
        ShowAlert(alert)
    else
        alert.data.count = alert.data.count + 1
        if isQueued then
            SetAnimatedDigit(alert.count, alert.data.count)
        else
            SetAnimatedDigit(alert.count, alert.data.count, true)
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

local function CreateGarrisonMissionAlert(event, missionId, isAdded)
    local missionInfo = C_Garrison.GetBasicMissionInfo(missionId)
    local rarity = missionInfo.isRare and LE_ITEM_QUALITY_RARE or LE_ITEM_QUALITY_COMMON
    local color = ITEM_QUALITY_COLORS[rarity]
    local level = missionInfo.iLevel == 0 and missionInfo.level or missionInfo.iLevel
    local alert = GetAlert()

    alert:SetBackdropBorderColor(GetTableColor(color))
    alert.title:SetText(isAdded and GARRISON_MISSION_ADDED_TOAST1 or GARRISON_MISSION_COMPLETE)
    alert.text:SetText(missionInfo.name)
    alert.icon:SetTexCoord(0, 1, 0, 1)
    alert.icon:SetAtlas(missionInfo.typeAtlas)
    alert.count:SetText(level)

    alert.data.event = event
    alert.data.sound = SOUNDKIT.UI_GARRISON_TOAST_MISSION_COMPLETE
    ShowAlert(alert)
end

local followerData = {}

local function GarrisonFollowerAlertOnEnter(self)
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
            if followerData.followerTypeID == LE_FOLLOWER_TYPE_SHIPYARD_6_2 then
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

local function CreateGarrisonFollowerAlert(event, followerId, name, _, level, quality, isUpgraded, texturePrefix,
                                           followerTypeId)
    local followerInfo = C_Garrison.GetFollowerInfo(followerId)
    local followerStrings = GarrisonFollowerOptions[followerTypeId].strings
    local upgradeTexture = LOOTUPGRADEFRAME_QUALITY_TEXTURES[quality] or LOOTUPGRADEFRAME_QUALITY_TEXTURES[2]
    local color = ITEM_QUALITY_COLORS[quality]
    local alert = GetAlert()

    if followerTypeId == LE_FOLLOWER_TYPE_SHIPYARD_6_2 then
        alert.icon:SetTexCoord(0, 1, 0, 1)
        alert.icon:SetAtlas(texturePrefix .. "-Portrait")
    else
        local portrait
        if followerInfo.portraitIconID and followerInfo.portraitIconID ~= 0 then
            portrait = followerInfo.portraitIconID
        else
            portrait = "Interface/Garrison/Portraits/FollowerPortrait_NoPortrait"
        end
        alert.icon:SetTexture(portrait)
        alert.icon:SetTexCoord(0, 1, 0, 1)
    end

    if isUpgraded then
        alert.title:SetText(followerStrings.FOLLOWER_ADDED_UPGRADED_TOAST)
        for i = 1, numArrows do
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

    alert:HookScript("OnEnter", GarrisonFollowerAlertOnEnter)

    ShowAlert(alert)
end

local function CreateGarrisonBuildingAlert(event, buildingName)
    local alert = GetAlert()
    alert.title:SetText(GARRISON_UPDATE)
    alert.text:SetText(buildingName)
    alert.icon:SetTexture("Interface/Icons/Garrison_Build")

    alert.data.event = event
    alert.data.sound = SOUNDKIT.UI_GARRISON_TOAST_BUILDING_COMPLETE

    ShowAlert(alert)
end

local function CreateGarrisonTalentAlert(event, talentId)
    local talent = C_Garrison.GetTalent(talentId)
    local alert = GetAlert()
    alert.title:SetText(GARRISON_TALENT_ORDER_ADVANCEMENT)
    alert.text:SetText(talent.name)
    alert.icon:SetTexture(talent.icon)

    alert.data.event = event
    alert.data.sound = SOUNDKIT.UI_ORDERHALL_TALENT_READY_TOAST

    ShowAlert(alert)
end

local function HookRewardFrameOnEnter(self)
    if self.data.type == "item" then
        GameTooltip:SetHyperlink(self.data.value)
    else
        GameTooltip:AddLine(YOU_RECEIVED_LABEL)
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

local function CreateLfgCompletionAlert(event, name, subtypeId, texture, moneyReward, xpReward, numItemRewards,
                                        isScenario, isScenarioBonusComplete)
    local alert = GetAlert()
    local sound
    ---@type Frame
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
            reward:HookScript("OnEnter", HookRewardFrameOnEnter)
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
            reward:HookScript("OnEnter", HookRewardFrameOnEnter)
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
                reward:HookScript("OnEnter", HookRewardFrameOnEnter)
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

    ShowAlert(alert)
end

local linkTable = {}
local tConcat = table.concat

local function SetLinkTable(...)
    wipe(linkTable)
    for i = 1, select("#", ...) do
        linkTable[i] = select(i, ...)
    end
end

local function SanitizeLink(link)
    if not link or link == "[]" or link == "" then
        return
    end

    local temp, name = strmatch(link, "|H(.+)|h%[(.+)%]|h")
    link = temp or link

    SetLinkTable(strsplit(":", link))

    if linkTable[1] ~= "item" then
        return link, link, linkTable[1], tonumber(linkTable[2]), name
    end

    if linkTable[12] ~= "" then
        linkTable[12] = ""
        tremove(linkTable, 15 + (tonumber(linkTable[14]) or 0))
    end

    return tConcat(linkTable, ":"), link, linkTable[1], tonumber(linkTable[2]), name
end

---@type GameTooltip
local scanner = CreateFrame("GameTooltip", "WlkAlertFrameItemScanner", UIParent, "GameTooltipTemplate")

local function GetItemLevel(event, link)
    local _, _, quality, _, _, _, _, _, equipLoc, _, _, classId, subclassId = GetItemInfo(link)
    if (classId == LE_ITEM_CLASS_GEM and subclassId == LE_ITEM_GEM_ARTIFACTRELIC) or _G[equipLoc] then
        if event == "SHOW_LOOT_TOAST" or quality == LE_ITEM_QUALITY_HEIRLOOM then
            scanner:SetOwner(UIParent, "ANCHOR_NONE")
            scanner:SetHyperlink(link)
            for i = 2, 5 do
                ---@type FontString
                local label = _G[scanner:GetName() .. "TextLeft" .. i]
                local text = label:GetText()
                if text then
                    local level = strmatch(text, gsub(ITEM_LEVEL, "%%d", "(%%d+)"))
                            or strmatch(text, gsub(ITEM_LEVEL_ALT, "%%d%(%%d%)", "%%d+%%((%%d+)%%)"))
                    if level then
                        return tonumber(level)
                    end
                end
            end
        else
            return GetDetailedItemLevelInfo(link) or 0
        end
    end
    return 0
end

local function LootCommonAlertOnEnter(self)
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

local function CreateLootCommonItemAlert(event, link, quantity)
    local sanitizedLink, originalLink, linkType, itemId = SanitizeLink(link)
    local isNew, isQueued
    ---@type Button
    local alert
    alert, isQueued = FindAlert(nil, "itemId", itemId)
    if alert then
        if alert.data.event ~= event then
            return
        end
    else
        alert, isNew, isQueued = GetAlert(event, "link", sanitizedLink)
    end

    if isNew then
        local name, quality, icon, _, classId, subclassId, bindType

        if linkType == "battlepet" then
            local _, speciesId, _, breedQuality, _ = strsplit(":", originalLink)
            name, icon = C_PetJournal.GetPetInfoBySpeciesID(speciesId)
            quality = tonumber(breedQuality)
        else
            name, _, quality, _, _, _, _, _, _, icon, _, classId, subclassId, bindType = GetItemInfo(originalLink)
        end

        if name and (quality and quality >= LE_ITEM_QUALITY_POOR and quality <= LE_ITEM_QUALITY_LEGENDARY
                or quality == LE_ITEM_QUALITY_HEIRLOOM) then
            local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[LE_ITEM_QUALITY_COMMON]
            alert:SetBackdropBorderColor(GetTableColor(color))

            local title = YOU_RECEIVED_LABEL
            local sound = SOUNDKIT.UI_EPICLOOT_TOAST
            if quality == LE_ITEM_QUALITY_LEGENDARY then
                title = LEGENDARY_ITEM_LOOT_LABEL
                sound = SOUNDKIT.UI_LEGENDARY_LOOT_TOAST
            end

            local iLevel = GetItemLevel(event, originalLink)
            if iLevel > 0 then
                name = format("[%s%d%s]%s", color.hex, iLevel, FONT_COLOR_CODE_CLOSE, name)
            end

            alert.title:SetText(title)
            alert.text:SetText(name)
            alert.icon:SetTexture(icon)
            alert.count.type = "normal"
            SetAnimatedDigit(alert.count, quantity)

            alert.data.count = quantity
            alert.data.event = event
            alert.data.itemId = itemId
            alert.data.link = sanitizedLink
            alert.data.originalLink = originalLink
            alert.data.sound = sound

            alert:HookScript("OnEnter", LootCommonAlertOnEnter)

            ShowAlert(alert)
        else
            ReleaseAlert(alert)
        end
    else
        alert.data.count = alert.data.count + quantity
        if isQueued then
            SetAnimatedDigit(alert.count, alert.data.count)
        else
            SetAnimatedDigit(alert.count, alert.data.count, true)
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

local function LootCurrencyAlertOnEnter(self)
    GameTooltip:SetHyperlink(self.data.originalLink)
    GameTooltip:Show()
end

local function CreateLootCurrencyAlert(event, link, quantity)
    local sanitizedLink, originalLink = SanitizeLink(link)
    local alert, isNew, isQueued = GetAlert(event, "link", sanitizedLink)

    if isNew then
        local name, _, icon, _, _, _, _, quality = GetCurrencyInfo(link)
        local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[LE_ITEM_QUALITY_COMMON]
        alert:SetBackdropBorderColor(GetTableColor(color))

        alert.title:SetText(YOU_RECEIVED_LABEL)
        alert.text:SetText(name)
        alert.icon:SetTexture(icon)
        alert.count.type = "large"
        SetAnimatedDigit(alert.count, quantity)

        alert.data.event = event
        alert.data.count = quantity
        alert.data.link = sanitizedLink
        alert.data.originalLink = originalLink
        alert.data.sound = SOUNDKIT.UI_EPICLOOT_TOAST

        alert:HookScript("OnEnter", LootCurrencyAlertOnEnter)

        ShowAlert(alert)
    else
        alert.data.count = alert.data.count + quantity
        if isQueued then
            SetAnimatedDigit(alert.count, alert.data.count)
        else
            SetAnimatedDigit(alert.count, alert.data.count, true)
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

local function CreateMoneyAlert(event, quantity)
    local alert, isNew, isQueued = GetAlert(nil, "event", event)
    if isNew then
        alert:SetBackdropBorderColor(0.9, 0.75, 0.26)
        alert.title:SetText(quantity > 0 and YOU_RECEIVED_LABEL
                or (RED_FONT_COLOR_CODE .. "你失去" .. FONT_COLOR_CODE_CLOSE))
        local texture = "Interface/Icons/INV_Misc_Coin_02"
        if abs(quantity) < 100 then
            texture = "Interface/Icons/INV_Misc_Coin_06"
        elseif abs(quantity) < 10000 then
            texture = "Interface/Icons/INV_Misc_Coin_04"
        end
        alert.icon:SetTexture(texture)
        alert.text.type = "money"
        SetAnimatedDigit(alert.text, quantity)

        alert.data.event = event
        alert.data.count = quantity
        alert.data.sound = SOUNDKIT.IG_BACKPACK_COIN_OK

        ShowAlert(alert)
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
            alert.title:SetText(YOU_RECEIVED_LABEL)
        elseif alert.data.count < 0 then
            alert.title:SetText(RED_FONT_COLOR_CODE .. "你失去" .. FONT_COLOR_CODE_CLOSE)
        end
        if isQueued then
            SetAnimatedDigit(alert.text, alert.data.count)
        else
            SetAnimatedDigit(alert.text, alert.data.count, true)
            alert.animOut:Stop()
            if not MouseIsOver(alert) then
                alert.animOut:Play()
            end
        end
    end
end

local function LootSpecialAlertOnEnter(self)
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

local function CreateLootSpecialItemAlert(event, link, quantity, lessAwesome, isUpgraded, baseQuality, isLegendary,
                                          isAzerite, isCorrupted)
    if link then
        local sanitizedLink, originalLink, _, itemId = SanitizeLink(link)
        local alert, isNew, isQueued = GetAlert(event, "link", sanitizedLink)
        if isNew then
            local name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(originalLink)
            if name and (quality and quality >= LE_ITEM_QUALITY_POOR and quality <= LE_ITEM_QUALITY_LEGENDARY) then
                local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[LE_ITEM_QUALITY_COMMON]
                alert:SetBackdropBorderColor(GetTableColor(color))
                local title = YOU_RECEIVED_LABEL
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
                    sound = SOUNDKIT.UI_WARFORGED_ITEM_LOOT_TOAST
                    local upgradeTexture = LOOTUPGRADEFRAME_QUALITY_TEXTURES[quality]
                            or LOOTUPGRADEFRAME_QUALITY_TEXTURES[LE_ITEM_QUALITY_UNCOMMON]
                    for i = 1, numArrows do
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

                local iLevel = GetItemLevel(event, originalLink)
                if iLevel > 0 then
                    name = format("[%s%d%s]%s", color.hex, iLevel, FONT_COLOR_CODE_CLOSE, name)
                end

                alert.title:SetText(title)
                alert.text:SetText(name)
                alert.icon:SetTexture(icon)
                alert.count.type = "normal"
                SetAnimatedDigit(alert.count, quantity)

                alert.data.count = quantity
                alert.data.event = event
                alert.data.link = sanitizedLink
                alert.data.originalLink = originalLink
                alert.data.itemId = itemId
                alert.data.sound = sound
                alert.data.arrows = isUpgraded

                alert:HookScript("OnEnter", LootSpecialAlertOnEnter)

                ShowAlert(alert)
            else
                releasedAlert(alert)
            end
        else
            alert.data.count = alert.data.count + quantity
            if isQueued then
                SetAnimatedDigit(alert.count, alert.data.count)
            else
                SetAnimatedDigit(alert.count, alert.data.count, true)
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

BonusRollFrame.FinishRollAnim:SetScript("OnFinished", function()
    if BonusRollFrame.rewardType == "item" then
        CreateLootSpecialItemAlert("LOOT_ITEM_BONUS_ROLL_WON", BonusRollFrame.rewardLink, BonusRollFrame.rewardQuantity)
    end
    GroupLootContainer_RemoveFrame(GroupLootContainer, BonusRollFrame)
end)

local function RecipeAlertOnEnter(self)
    if self.data.recipeId then
        GameTooltip:SetSpellByID(self.data.recipeId)
        GameTooltip:Show()
    end
end

local function CreateRecipeAlert(event, recipeId)
    local tradeSkillId = C_TradeSkillUI.GetTradeSkillLineForRecipe(recipeId)
    if tradeSkillId then
        local recipeName = GetSpellInfo(recipeId)
        if recipeName then
            local alert = GetAlert()
            local rank = GetSpellRank(recipeId)
            local rankTexture
            if rank == 1 then
                rankTexture = "|TInterface/LootFrame/toast-star:12:12:0:0:32:32:0:21:0:21|t"
            elseif rank == 2 then
                rankTexture = "|TInterface/LootFrame/toast-star-2:12:24:0:0:64:32:0:42:0:21|t"
            elseif rank == 3 then
                rankTexture = "|TInterface/LootFrame/toast-star-3:12:36:0:0:64:32:0:64:0:21|t"
            end
            alert.title:SetText(rank and rank > 1 and UPGRADED_RECIPE_LEARNED_TITLE or NEW_RECIPE_LEARNED_TITLE)
            alert.text:SetText(recipeName .. (rankTexture or ""))
            alert.icon:SetTexture(C_TradeSkillUI.GetTradeSkillTexture(tradeSkillId))

            alert.data.event = event
            alert.data.recipeId = recipeId
            alert.data.sound = SOUNDKIT.UI_PROFESSIONS_NEW_RECIPE_LEARNED_TOAST

            alert:HookScript("OnEnter", RecipeAlertOnEnter)

            ShowAlert(alert)
        end
    end
end

local function StoreAlertOnEnter(self)
    local link = self.data.originalLink
    if link and strmatch(link, "item") then
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end
end

local function CreateStoreAlert(event, entitlementType, texture, name, payloadId, payloadLink)
    ---@type Button
    local alert
    local quality, sanitizedLink, originalLink, _
    if payloadLink then
        sanitizedLink, originalLink = SanitizeLink(payloadLink)
        alert = GetAlert(event, "link", sanitizedLink)
        _, _, quality = GetItemInfo(originalLink)

        alert.data.link = sanitizedLink
        alert.data.originalLink = originalLink
    else
        alert = GetAlert()
    end

    if entitlementType == Enum.WoWEntitlementType.Appearance then
        alert.data.link = "transmogappearance:" .. payloadId
    elseif entitlementType == Enum.WoWEntitlementType.AppearanceSet then
        alert.data.link = "transmogset:" .. payloadId
    elseif entitlementType == Enum.WoWEntitlementType.Illusion then
        alert.data.link = "transmogillusion:" .. payloadId
    end

    quality = quality or LE_ITEM_QUALITY_COMMON
    local color = ITEM_QUALITY_COLORS[quality]
    alert:SetBackdropBorderColor(GetTableColor(color))
    alert.title:SetText(event == "ENTITLEMENT_DELIVERED" and BLIZZARD_STORE_PURCHASE_COMPLETE or YOU_RECEIVED_LABEL)
    alert.text:SetText(name)
    alert.icon:SetTexture(texture)

    alert.data.event = event
    alert.data.sound = SOUNDKIT.UI_IG_STORE_PURCHASE_DELIVERED_TOAST_01

    alert:HookScript("OnEnter", StoreAlertOnEnter)

    ShowAlert(alert)
end

local function GetStoreItemLink(itemId, texture)
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

local function OnEventEntitlementDelivered(event, entitlementType, texture, name, payloadId)
    if entitlementType == Enum.WoWEntitlementType.Invalid then
        return
    end
    local link, tryAgain = GetStoreItemLink(payloadId, texture)
    if tryAgain then
        return C_Timer.After(0.25, function()
            OnEventEntitlementDelivered(event, entitlementType, texture, name, payloadId)
        end)
    end
    CreateStoreAlert(event, entitlementType, texture, name, payloadId, link)
end

local function CreateTransmogAlert(event, sourceId, isAdded, attempt)
    local _, visualId, _, icon, _, _, link = C_TransmogCollection.GetAppearanceSourceInfo(sourceId)
    local name
    link, _, _, _, name = SanitizeLink(link)
    if not link then
        return attempt < 4 and C_Timer.After(0.25, function()
            CreateTransmogAlert(event, sourceId, isAdded, attempt + 1)
        end)
    end
    if FindAlert(event, "visualId", visualId) then
        return
    end
    local alert, isNew, isQueued = GetAlert(nil, "sourceId", sourceId)
    if isNew then
        alert:SetBackdropBorderColor(1, 0.5, 1)
        alert.title:SetText(isAdded and "外觀已加入" or (RED_FONT_COLOR_CODE .. "外觀已移除" .. FONT_COLOR_CODE_CLOSE))
        alert.text:SetText(name)
        alert.icon:SetTexture(icon)

        alert.data.event = event
        alert.data.sound = SOUNDKIT.UI_DIG_SITE_COMPLETION_TOAST
        alert.data.sourceId = sourceId
        alert.data.visualId = visualId

        ShowAlert(alert)
    else
        alert.title:SetText(isAdded and "外觀已加入" or (RED_FONT_COLOR_CODE .. "外觀已移除" .. FONT_COLOR_CODE_CLOSE))
        if not isQueued then
            alert.animOut:Stop()
            if not MouseIsOver(alert) then
                alert.animOut:Play()
            end
        end
    end
end

local function CreateWorldQuestCompleteAlert(event, isUpdate, questId, name, moneyReward, xpReward, numCurrencyRewards, link)
    local alert, isNew, isQueued = GetAlert(nil, "questId", questId)
    if isUpdate and isNew then
        ReleaseAlert(alert)
        return
    end
    ---@type Frame
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
                reward:HookScript("OnEnter", HookRewardFrameOnEnter)
                reward:Show()
            end
        end

        if xpReward and xpReward > 0 then
            index = index + 1
            ---@type Frame
            reward = alert["reward" .. index]
            if reward then
                reward.icon:SetTexture("Interface/Icons/XP_ICON")
                reward.data.type = "xp"
                reward.data.value = xpReward
                reward:HookScript("OnEnter", HookRewardFrameOnEnter)
                reward:Show()
            end
        end

        for i = 1, numCurrencyRewards or 0 do
            index = index + 1
            ---@type Frame
            reward = alert["reward" .. index]
            if reward then
                local _, texture, count = GetQuestLogRewardCurrencyInfo(i, questId)
                texture = texture or "Interface/Icons/INV_Box_02"
                reward.icon:SetTexture(texture)
                reward.data.type = "currency"
                reward.data.value = count
                reward.data.texture = texture
                reward:HookScript("OnEnter", HookRewardFrameOnEnter)
                reward:Show()
            end
        end

        local _, _, worldQuestType, rarity, _, tradeSkillLineIndex = GetQuestTagInfo(questId)
        if worldQuestType == LE_QUEST_TAG_TYPE_PVP then
            alert.icon:SetTexture("Interface/Icons/ACHIEVEMENT_ARENA_2V2_1")
        elseif worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE then
            alert.icon:SetTexture("Interface/Icons/INV_Pet_BattlePetTraining")
        elseif worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION and tradeSkillLineIndex then
            alert.icon:SetTexture(select(2, GetProfessionInfo(tradeSkillLineIndex)))
        elseif worldQuestType == LE_QUEST_TAG_TYPE_DUNGEON or worldQuestType == LE_QUEST_TAG_TYPE_RAID then
            alert.icon:SetTexture("Interface/Icons/INV_Misc_Bone_Skull_02")
        else
            alert.icon:SetTexture("Interface/Icons/Achievement_Quests_Completed_TwilightHighlands")
        end
        local color = WORLD_QUEST_QUALITY_COLORS[rarity] or WORLD_QUEST_QUALITY_COLORS[LE_WORLD_QUEST_QUALITY_COMMON]
        alert:SetBackdropBorderColor(GetTableColor(color))
        alert.title:SetText(WORLD_QUEST_COMPLETE)
        alert.text:SetText(name)

        alert.data.event = event
        alert.data.questId = questId
        alert.data.sound = SOUNDKIT.UI_WORLDQUEST_COMPLETE
        alert.data.numRewardsShown = index

        ShowAlert(alert)
    else
        if link then
            alert.data.numRewardsShown = alert.data.numRewardsShown + 1
            reward = alert["reward" .. alert.data.numRewardsShown]
            if reward then
                local _, _, _, _, texture = GetItemInfoInstant(link)
                texture = texture or "Interface/Icons/INV_Box_02"
                reward.icon:SetTexture(texture)
                reward.data.type = "item"
                reward.data.value = link
                reward:HookScript("OnEnter", HookRewardFrameOnEnter)
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

local function OnEventQuestTurnedIn(questId)
    if QuestUtils_IsQuestWorldQuest(questId) then
        if not HaveQuestRewardData(questId) then
            C_TaskQuest.RequestPreloadRewardData(questId)
            C_Timer.After(0.5, function()
                OnEventQuestTurnedIn(questId)
            end)
            return
        end
        CreateWorldQuestCompleteAlert("QUEST_TURNED_IN", false, questId, C_TaskQuest.GetQuestInfoByQuestID(questId),
                GetQuestLogRewardMoney(questId), GetQuestLogRewardXP(questId), GetNumQuestLogRewardCurrencies(questId))
    end
end

local function OnEventQuestLootReceived(questId, itemLink)
    if not FindAlert(nil, "questId", questId) then
        if not HaveQuestRewardData(questId) then
            C_TaskQuest.RequestPreloadRewardData(questId)
            C_Timer.After(0.5, function()
                OnEventQuestLootReceived(questId, itemLink)
            end)
            return
        end
        OnEventQuestTurnedIn(questId)
    end
    CreateWorldQuestCompleteAlert("QUEST_LOOT_RECEIVED", true, questId, nil, nil, nil, nil, itemLink)
end

local lastMoney

local LOOT_ITEM_SELF_MULTIPLE_PATTERN = gsub(gsub(LOOT_ITEM_SELF_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local LOOT_ITEM_PUSHED_MULTIPLE_PATTERN = gsub(gsub(LOOT_ITEM_PUSHED_SELF_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local LOOT_ITEM_CREATED_MULTIPLE_PATTERN = gsub(gsub(LOOT_ITEM_CREATED_SELF_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local LOOT_ITEM_PATTERN = gsub(LOOT_ITEM_SELF, "%%s", "(.+)")
local LOOT_ITEM_PUSHED_PATTERN = gsub(LOOT_ITEM_PUSHED_SELF, "%%s", "(.+)")
local LOOT_ITEM_CREATED_PATTERN = gsub(LOOT_ITEM_CREATED_SELF, "%%s", "(.+)")

local CURRENCY_GAINED_MULTIPLE_PATTERN = gsub(gsub(CURRENCY_GAINED_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local CURRENCY_GAINED_PATTERN = gsub(CURRENCY_GAINED, "%%s", "(.+)")

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

alertFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ACHIEVEMENT_EARNED" then
        CreateAchievementAlert(event, ...)
    elseif event == "CRITERIA_EARNED" then
        local achievementId, description = ...
        CreateAchievementAlert(event, achievementId, description, true)
    elseif event == "ARTIFACT_DIGSITE_COMPLETE" then
        CreateDigSiteCompleteAlert(event, ...)
    elseif event == "NEW_MOUNT_ADDED" then
        local mountId = ...
        CreateCollectionAlert(event, mountId, true)
    elseif event == "NEW_PET_ADDED" then
        local petId = ...
        CreateCollectionAlert(event, petId, nil, true)
    elseif event == "NEW_TOY_ADDED" then
        local toyId = ...
        CreateCollectionAlert(event, toyId, nil, nil, true)
    elseif event == "GARRISON_FOLLOWER_ADDED" then
        CreateGarrisonFollowerAlert(event, ...)
    elseif event == "GARRISON_MISSION_FINISHED" then
        local _, instanceType = GetInstanceInfo()
        if instanceType == "none" or C_Garrison.IsOnGarrisonMap() then
            local _, missionId = ...
            CreateGarrisonMissionAlert(event, missionId)
        end
    elseif event == "GARRISON_RANDOM_MISSION_ADDED" then
        local _, missionId = ...
        CreateGarrisonMissionAlert(event, missionId)
    elseif event == "GARRISON_BUILDING_ACTIVATABLE" then
        CreateGarrisonBuildingAlert(event, ...)
    elseif event == "GARRISON_TALENT_COMPLETE" then
        local garrisonTypeId, doAlert = ...
        if doAlert then
            CreateGarrisonTalentAlert(event, C_Garrison.GetCompleteTalent(garrisonTypeId))
        end
    elseif event == "LFG_COMPLETION_REWARD" then
        if C_Scenario.IsInScenario() and not C_Scenario.TreatScenarioAsDungeon() then
            local _, _, _, _, hasBonusStep, isBonusStepComplete, _, _, _, scenarioType = C_Scenario.GetInfo()
            if scenarioType ~= LE_SCENARIO_TYPE_LEGION_INVASION then
                local name, _, subtypeId, texture, moneyBase, moneyVar, experienceBase, experienceVar, numStrangers,
                numItemRewards = GetLFGCompletionReward()
                CreateLfgCompletionAlert(event, name, subtypeId, texture, moneyBase + moneyVar * numStrangers,
                        experienceBase + experienceVar * numStrangers, numItemRewards, true,
                        hasBonusStep and isBonusStepComplete)
            end
        else
            local name, _, subtypeId, texture, moneyBase, moneyVar, experienceBase, experienceVar, numStrangers,
            numItemRewards = GetLFGCompletionReward()
            CreateLfgCompletionAlert(event, name, subtypeId, texture, moneyBase + moneyVar * numStrangers,
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
            CreateLootCommonItemAlert(event, link, tonumber(quantity) or 0)
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
        CreateLootCurrencyAlert(event, link, tonumber(quantity) or 0)
    elseif event == "PLAYER_LOGIN" then
        alertFrame:UnregisterEvent(event)
        lastMoney = GetMoney()
    elseif event == "PLAYER_MONEY" then
        local money = GetMoney()
        if money - lastMoney ~= 0 then
            CreateMoneyAlert(event, money - lastMoney)
        end
        lastMoney = money
    elseif event == "AZERITE_EMPOWERED_ITEM_LOOTED" then
        local link = ...
        CreateLootSpecialItemAlert(event, link, 1, nil, nil, nil, nil, nil, true)
    elseif event == "LOOT_ITEM_ROLL_WON" then
        local link, quantity, _, _, isUpgraded = ...
        CreateLootSpecialItemAlert(event, link, quantity, nil, isUpgraded)
    elseif event == "SHOW_LOOT_TOAST" then
        local typeId, link, quantity, _, _, _, _, lessAwesome, isUpgraded, isCorrupted = ...
        if typeId == "item" then
            CreateLootSpecialItemAlert(event, link, quantity, lessAwesome, isUpgraded, nil, nil, nil, isCorrupted)
        end
    elseif event == "SHOW_LOOT_TOAST_UPGRADE" then
        local link, quantity, _, _, baseQuality = ...
        CreateLootSpecialItemAlert(event, link, quantity, nil, true, baseQuality)
    elseif event == "SHOW_PVP_FACTION_LOOT_TOAST" or event == "SHOW_RATED_PVP_REWARD_TOAST" then
        local typeId, link, quantity, _, _, _, lessAwesome = ...
        if typeId == "item" then
            CreateLootSpecialItemAlert(event, link, quantity, lessAwesome)
        end
    elseif event == "SHOW_LOOT_TOAST_LEGENDARY_LOOTED" then
        local link = ...
        CreateLootSpecialItemAlert(event, link, 1, nil, nil, nil, true)
    elseif event == "NEW_RECIPE_LEARNED" then
        CreateRecipeAlert(event, ...)
    elseif event == "ENTITLEMENT_DELIVERED" or event == "RAF_ENTITLEMENT_DELIVERED" then
        local entitlementType, texture, name, payloadId = ...
        OnEventEntitlementDelivered(event, entitlementType, texture, name, payloadId)
    elseif event == "TRANSMOG_COLLECTION_SOURCE_ADDED" then
        local sourceId = ...
        if C_TransmogCollection.PlayerKnowsSource(sourceId) then
            CreateTransmogAlert(event, sourceId, true, 1)
        end
    elseif event == "TRANSMOG_COLLECTION_SOURCE_REMOVED" then
        local sourceId = ...
        if C_TransmogCollection.PlayerKnowsSource(sourceId) then
            CreateTransmogAlert(event, sourceId, nil, 1)
        end
    elseif event == "QUEST_TURNED_IN" then
        OnEventQuestTurnedIn(...)
    elseif event == "QUEST_LOOT_RECEIVED" then
        OnEventQuestLootReceived(...)
    end
end)

SLASH_ALERT_TEST1 = "/at"

SlashCmdList["ALERT_TEST"] = function(arg)
    if arg == "1" or arg == "ach" then
        CreateAchievementAlert("ACHIEVEMENT_TEST", 545, false)
        CreateAchievementAlert("ACHIEVEMENT_TEST", 9828, true)
        CreateAchievementAlert("ACHIEVEMENT_TEST", 4913, false)
    elseif arg == "2" or arg == "dig" then
        CreateDigSiteCompleteAlert("ARCHAEOLOGY_TEST", 4)
    elseif arg == "3" or arg == "col" then
        CreateCollectionAlert("MOUNT_TEST", 129, true)
        local petId = C_PetJournal.GetPetInfoByIndex(1)
        if petId then
            CreateCollectionAlert("PET_TEST", petId, nil, true)
        end
        CreateCollectionAlert("TOY_TEST", 147537, nil, nil, true)
    elseif arg == "4" or arg == "gar" then
        -- 6.0
        -- 追随者
        local followers = C_Garrison.GetFollowers(LE_FOLLOWER_TYPE_GARRISON_6_0)
        local follower = followers and followers[1] or nil
        if follower then
            CreateGarrisonFollowerAlert("GARRISON_FOLLOWER_TEST", follower.followerID, follower.name, nil,
                    follower.level, follower.quality, false, nil, follower.followerTypeID)
        end
        -- 船舰
        followers = C_Garrison.GetFollowers(LE_FOLLOWER_TYPE_SHIPYARD_6_2)
        follower = followers and followers[1] or nil
        if follower then
            CreateGarrisonFollowerAlert("GARRISON_FOLLOWER_TEST", follower.followerID, follower.name, nil,
                    follower.level, follower.quality, false, follower.texPrefix, follower.followerTypeID)
        end
        -- 要塞任务
        local missions = C_Garrison.GetAvailableMissions(LE_FOLLOWER_TYPE_GARRISON_6_0)
        local missionId = missions and missions[1] and missions[1].missionID or nil
        if missionId then
            CreateGarrisonMissionAlert("GARRISON_MISSION_TEST", missionId)
        end
        -- 船舰任务
        missions = C_Garrison.GetAvailableMissions(LE_FOLLOWER_TYPE_SHIPYARD_6_2)
        missionId = missions and missions[1] and missions[1].missionID or nil
        if missionId then
            CreateGarrisonMissionAlert("GARRISON_MISSION_TEST", missionId)
        end
        -- 建筑
        local buildings = C_Garrison.GetBuildings(LE_GARRISON_TYPE_6_0)
        local buildingId = buildings and buildings[1] and buildings[1].buildingID or nil
        if buildingId then
            CreateGarrisonBuildingAlert("GARRISON_BUILDING_TEST", select(2, C_Garrison.GetBuildingInfo(buildingId)))
        end

        -- 7.0
        -- 勇士
        followers = C_Garrison.GetFollowers(LE_FOLLOWER_TYPE_GARRISON_7_0)
        follower = followers and followers[1] or nil
        if follower then
            CreateGarrisonFollowerAlert("GARRISON_FOLLOWER_TEST", follower.followerID, follower.name, nil,
                    follower.level, follower.quality, false, nil, follower.followerTypeID)
        end
        -- 任务
        missions = C_Garrison.GetAvailableMissions(LE_FOLLOWER_TYPE_GARRISON_7_0)
        missionId = missions and missions[1] and missions[1].missionID or nil
        if missionId then
            CreateGarrisonMissionAlert("GARRISON_MISSION_TEST", missionId)
        end
        -- 天赋
        local talentTreeIds = C_Garrison.GetTalentTreeIDsByClassID(LE_GARRISON_TYPE_7_0, select(3, UnitClass("player")))
        local talentTreeId = talentTreeIds and talentTreeIds[1] or nil
        local tree, _
        if talentTreeId then
            _, _, tree = C_Garrison.GetTalentTreeInfoForID(talentTreeId)
        end
        local talentId = tree and tree[1] and tree[1].id or nil
        if talentId then
            CreateGarrisonTalentAlert("GARRISON_TALENT_TEST", talentId)
        end

        -- 8.0
        -- 勇士
        followers = C_Garrison.GetFollowers(LE_FOLLOWER_TYPE_GARRISON_8_0)
        follower = followers and followers[1] or nil
        if follower then
            CreateGarrisonFollowerAlert("GARRISON_FOLLOWER_TEST", follower.followerID, follower.name, nil,
                    follower.level, follower.quality, false, nil, follower.followerTypeID)
        end
        -- 任务
        missions = C_Garrison.GetAvailableMissions(LE_FOLLOWER_TYPE_GARRISON_8_0)
        missionId = missions and missions[1] and missions[1].missionID or nil
        if missionId then
            CreateGarrisonMissionAlert("GARRISON_MISSION_TEST", missionId)
        end
    elseif arg == "5" or arg == "lfg" then
        local name, _, subtypeId = GetLFGDungeonInfo(1)
        if name then
            CreateLfgCompletionAlert("LFG_COMPLETE_TEST", name, subtypeId, nil, 123456, 123456, 0)
        end
        name, _, subtypeId = GetLFGDungeonInfo(504)
        if name then
            CreateLfgCompletionAlert("LFG_COMPLETE_TEST", name, subtypeId, nil, 123456, 123456, 0, true, true)
        end
    elseif arg == "6" or arg == "lci" then
        local _, link = GetItemInfo(124442)
        if link then
            CreateLootCommonItemAlert("COMMON_LOOT_TEST", link, random(9, 99))
        end
        CreateLootCommonItemAlert("COMMON_LOOT_TEST", "battlepet:1155:25:3:1725:276:244:0000000000000000", 1)
    elseif arg == "7" or arg == "cur" then
        CreateLootCurrencyAlert("LOOT_CURRENCY_TEST", "currency:" .. 1220, random(300, 600))
    elseif arg == "8" or arg == "mon" then
        CreateMoneyAlert("MONEY_TEST", random(-1000000, 1000000))
    elseif arg == "9" or arg == "lsi" then
        -- pvp 物品
        local _, link = GetItemInfo(142679)
        if link then
            CreateLootSpecialItemAlert("SPECIAL_LOOT_TEST", link, 1)
        end
        -- 泰坦造物
        _, link = GetItemInfo("item:134222::::::::110:63::36:4:3432:41:1527:3337:::")
        if link then
            CreateLootSpecialItemAlert("SPECIAL_LOOT_TEST", link, 1, nil, true)
        end
        -- 史诗奖励
        _, link = GetItemInfo("item:139055::::::::110:70::36:3:3432:1507:3336:::")
        if link then
            CreateLootSpecialItemAlert("SPECIAL_LOOT_TEST", link, 1, nil, true, 2)
        end
        -- 传说物品
        _, link = GetItemInfo("item:154172::::::::110:64:::1:3571:::")
        if link then
            CreateLootSpecialItemAlert("SPECIAL_LOOT_TEST", link, 1, nil, nil, nil, true)
        end
        -- 艾泽莱晶岩物品
        _, link = GetItemInfo("item:159906::::::::110:581::11::::")
        if link then
            CreateLootSpecialItemAlert("SPECIAL_LOOT_TEST", link, 1, nil, nil, nil, nil, true)
        end
        -- 腐化物品
        _, link = GetItemInfo("item:172187::::::::20:71::3:1:3524:::")
        if link then
            CreateLootSpecialItemAlert("SPECIAL_LOOT_TEST", link, 1, nil, nil, nil, nil, nil, true)
        end
    elseif arg == "10" or arg == "rec" then
        CreateRecipeAlert("RECIPE_TEST", 7183)
        CreateRecipeAlert("RECIPE_TEST", 190992)
    elseif arg == "11" or arg == "sto" then
        -- 魔兽代币
        local name, link, _, _, _, _, _, _, _, icon = GetItemInfo(122270)
        if link then
            CreateStoreAlert("ENTITLEMENT_TEST", Enum.WoWEntitlementType.Item, icon, name, 122270, link)
        end
        name, _, icon = C_MountJournal.GetMountInfoByID(129)
        CreateStoreAlert("ENTITLEMENT_TEST", Enum.WoWEntitlementType.Mount, icon, name, 129)
    elseif arg == "12" or arg == "tra" then
        local appearance = C_TransmogCollection.GetCategoryAppearances(1)
                and C_TransmogCollection.GetCategoryAppearances(1)[1]
        local source = C_TransmogCollection.GetAppearanceSources(appearance.visualID)
                and C_TransmogCollection.GetAppearanceSources(appearance.visualID)[1]
        if source then
            CreateTransmogAlert("TRANSMOG_TEST", source.sourceID, true, 1)
        end
    elseif arg == "13" or arg == "wor" then
        local _, link = GetItemInfo(124124)
        if link then
            local quests = C_TaskQuest.GetQuestsForPlayerByMapID(630)
            if not quests or #quests == 0 then
                quests = C_TaskQuest.GetQuestsForPlayerByMapID(634)
                if not quests or #quests == 0 then
                    quests = C_TaskQuest.GetQuestsForPlayerByMapID(641)
                    if not quests or #quests == 0 then
                        quests = C_TaskQuest.GetQuestsForPlayerByMapID(646)
                        if not quests or #quests == 0 then
                            quests = C_TaskQuest.GetQuestsForPlayerByMapID(680)
                            if not quests or #quests == 0 then
                                quests = C_TaskQuest.GetQuestsForPlayerByMapID(650)
                            end
                        end
                    end
                end
            end

            if quests then
                for _, quest in ipairs(quests) do
                    if HaveQuestData(quest.questId) then
                        if QuestUtils_IsQuestWorldQuest(quest.questId) then
                            CreateWorldQuestCompleteAlert("WORLD_TEST", false, quest.questId,
                                    C_TaskQuest.GetQuestInfoByQuestID(quest.questId), 123456, 123456)
                            CreateWorldQuestCompleteAlert("WORLD_TEST", true, quest.questId, "scenario", nil, nil, nil,
                                    link)
                            return
                        end
                    end
                end
            end
        end
    end
end
