---@type Frame
local noticePane = CreateFrame("Frame", "WLK_NoticePane", UIParent)
noticePane:SetSize(540 - 298 - 2, 158 - 2 * 2)
noticePane:SetPoint("BOTTOMRIGHT", -298 - 1, 2)

local numSlots = 5
local spacing = 5

---@param self Frame
local function SlotOnEnter(self)
    local notice = self:GetParent()
    ---@type AnimationGroup
    local animOut = notice.animOut
    animOut:Stop()
    notice:SetAlpha(1)
    GameTooltip:Hide()
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 30, -30)
end

---@param notice Frame
local function CreateSlotFrame(notice, index)
    local size = (notice:GetHeight() - 2 * 2) - 26
    ---@type Frame
    local slot = CreateFrame("Frame", nil, notice)
    slot:SetSize(size, size)
    slot:SetPoint("TOPRIGHT", (size + spacing) * (1 - index) - 2, -2)
    slot:Hide()

    ---@type Texture
    local icon = slot:CreateTexture()
    icon:SetAllPoints()
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    slot.icon = icon

    slot:SetScript("OnEnter", SlotOnEnter)

    slot:SetScript("OnLeave", function()
        ---@type AnimationGroup
        local animOut = notice.animOut
        animOut:Play()
        GameTooltip:Hide()
    end)

    notice["slot" .. index] = slot
end

local maxActiveNotice = 3
local height = (noticePane:GetHeight() - (maxActiveNotice - 1) * spacing) / maxActiveNotice
local numArrows = 5
local arrowsConfig = {
    { delay = 0, x = 0, },
    { delay = 0.1, x = -8, },
    { delay = 0.2, x = 16, },
    { delay = 0.3, x = 8, },
    { delay = 0.4, x = -16, },
}
---@type table<number, Frame>
local createdNotices = {}
---@type table<number, Frame>
local activeNotices = {}
---@type table<number, Frame>
local queuedNotices = {}

--- 显示通知框架
---@param notice Frame
local function ShowNotice(notice)
    if #activeNotices >= maxActiveNotice then
        -- 已经显示最大个数了，添加到队列中
        tinsert(queuedNotices, notice)
        return
    end
    if #activeNotices > 0 then
        notice:SetPoint("TOP", activeNotices[#activeNotices], "BOTTOM", 0, -spacing)
    else
        notice:SetPoint("TOP")
    end
    tinsert(activeNotices, notice)
    notice:Show()
end

---@param self Frame
local function NoticeOnEnter(self)
    self:SetAlpha(1)
    ---@type AnimationGroup
    local animOut = self.animOut
    animOut:Stop()
    GameTooltip:Hide()
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 30, -30)
end

--- 回收通知框架
---@param notice Frame
local function RecycleNotice(notice)
    notice:ClearAllPoints()
    notice:SetAlpha(1)
    notice:Hide()
    wipe(notice.data)
    notice.arrowsAnim:Stop()
    notice.animIn:Stop()
    notice.animOut:Stop()
    notice.bonus:Hide()
    notice.iconText1:SetText("")
    notice.iconText1.type = nil
    notice.iconText2:SetText("")
    notice.iconText2.type = nil
    notice.iconText2.blink:Stop()
    notice.skull:Hide()
    notice.title:SetText("")
    notice.text:SetText("")
    notice.text.type = nil
    notice:SetBackdropBorderColor(GetTableColor(BLACK_FONT_COLOR))
    notice.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    notice:SetScript("OnEnter", NoticeOnEnter)
    for i = 1, numSlots do
        ---@type Frame
        local slot = notice["slot" .. i]
        slot:SetScript("OnEnter", SlotOnEnter)
        slot:Hide()
    end
    for i = 1, numArrows do
        ---@type Texture
        local arrow = notice["arrow" .. i]
        arrow:SetAlpha(0)
    end
    tDeleteItem(activeNotices, notice)
    tDeleteItem(queuedNotices, notice)
    tinsert(createdNotices, notice)
    for i = 1, #activeNotices do
        local activeNotice = activeNotices[i]
        activeNotice:ClearAllPoints()
        if i == 1 then
            activeNotice:SetPoint("TOP")
        else
            activeNotice:SetPoint("TOP", activeNotices[i - 1], "BOTTOM", 0, -spacing)
        end
    end
    local queuedNotice = tremove(queuedNotices, 1)
    if queuedNotice then
        ShowNotice(queuedNotice)
    end
end

--- 创建通知框架
local function CreateNoticeFrame()
    ---@type Frame
    local noticeFrame = CreateFrame("Frame", nil, noticePane)
    noticeFrame:SetSize(noticePane:GetWidth(), height)
    noticeFrame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background-Dark",
        edgeFile = "Interface/Buttons/WHITE8X8",
        edgeSize = 2,
    })
    noticeFrame:SetBackdropBorderColor(GetTableColor(BLACK_FONT_COLOR))
    noticeFrame:Hide()

    ---@type Frame
    local iconFrame = CreateFrame("Frame", nil, noticeFrame)
    iconFrame:SetSize(height - 2 * 2, height - 2 * 2)
    iconFrame:SetPoint("LEFT", 2, 0)
    noticeFrame.iconFrame = iconFrame

    ---@type Texture
    local icon = iconFrame:CreateTexture()
    icon:SetAllPoints()
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    noticeFrame.icon = icon

    ---@type FontString
    local text1 = iconFrame:CreateFontString(nil, "ARTWORK", "Game12Font_o1")
    text1:SetPoint("BOTTOMRIGHT")
    noticeFrame.iconText1 = text1

    ---@type FontString
    local text2 = iconFrame:CreateFontString(nil, "ARTWORK", "Game12Font_o1")
    text2:SetPoint("BOTTOMRIGHT", text1, "TOPRIGHT")
    noticeFrame.iconText2 = text2

    ---@type AnimationGroup
    local textAnimGroup = noticeFrame:CreateAnimationGroup()
    textAnimGroup:SetToFinalAlpha(true)
    text2.blink = textAnimGroup

    ---@type Alpha
    local textAlphaAnim = textAnimGroup:CreateAnimation("Alpha")
    textAlphaAnim:SetChildKey("iconText2")
    textAlphaAnim:SetOrder(1)
    textAlphaAnim:SetFromAlpha(1)
    textAlphaAnim:SetToAlpha(0)
    textAlphaAnim:SetDuration(0)

    textAlphaAnim = textAnimGroup:CreateAnimation("Alpha")
    textAlphaAnim:SetChildKey("iconText2")
    textAlphaAnim:SetOrder(2)
    textAlphaAnim:SetFromAlpha(1)
    textAlphaAnim:SetToAlpha(0)
    textAlphaAnim:SetDuration(0.2)

    textAlphaAnim = textAnimGroup:CreateAnimation("Alpha")
    textAlphaAnim:SetChildKey("iconText2")
    textAlphaAnim:SetOrder(3)
    textAlphaAnim:SetFromAlpha(0)
    textAlphaAnim:SetToAlpha(1)
    textAlphaAnim:SetDuration(0.4)
    textAlphaAnim:SetStartDelay(0.4)

    ---@type Texture
    local skull = iconFrame:CreateTexture()
    skull:SetSize(16, 20)
    skull:SetPoint("TOPRIGHT")
    skull:SetTexture("Interface/LFGFrame/UI-LFG-ICON-HEROIC")
    skull:SetTexCoord(0, 0.5, 0, 0.625)
    skull:Hide()
    noticeFrame.skull = skull

    ---@type AnimationGroup
    local arrowsAnimGroup = noticeFrame:CreateAnimationGroup()
    arrowsAnimGroup:SetToFinalAlpha(true)
    noticeFrame.arrowsAnim = arrowsAnimGroup

    for i = 1, numArrows do
        local config = arrowsConfig[i]
        ---@type Texture
        local arrow = iconFrame:CreateTexture(nil, "ARTWORK", "LootUpgradeFrame_ArrowTemplate")
        arrow:SetPoint("CENTER", iconFrame, "BOTTOM", config.x, 0)
        arrow:SetAlpha(0)
        noticeFrame["arrow" .. i] = arrow

        ---@type Alpha
        local arrowAlphaAnim = arrowsAnimGroup:CreateAnimation("Alpha")
        arrowAlphaAnim:SetChildKey("arrow" .. i)
        arrowAlphaAnim:SetOrder(1)
        arrowAlphaAnim:SetFromAlpha(1)
        arrowAlphaAnim:SetToAlpha(0)
        arrowAlphaAnim:SetDuration(0)

        arrowAlphaAnim = arrowsAnimGroup:CreateAnimation("Alpha")
        arrowAlphaAnim:SetChildKey("arrow" .. i)
        arrowAlphaAnim:SetOrder(2)
        arrowAlphaAnim:SetFromAlpha(0)
        arrowAlphaAnim:SetToAlpha(1)
        arrowAlphaAnim:SetDuration(0.25)
        arrowAlphaAnim:SetStartDelay(config.delay)
        arrowAlphaAnim:SetSmoothing("IN")

        arrowAlphaAnim = arrowsAnimGroup:CreateAnimation("Alpha")
        arrowAlphaAnim:SetChildKey("arrow" .. i)
        arrowAlphaAnim:SetOrder(2)
        arrowAlphaAnim:SetFromAlpha(1)
        arrowAlphaAnim:SetToAlpha(0)
        arrowAlphaAnim:SetDuration(0.25)
        arrowAlphaAnim:SetStartDelay(config.delay + 0.25)
        arrowAlphaAnim:SetSmoothing("OUT")

        arrowAlphaAnim = arrowsAnimGroup:CreateAnimation("Alpha")
        arrowAlphaAnim:SetChildKey("arrow" .. i)
        arrowAlphaAnim:SetOrder(3)
        arrowAlphaAnim:SetFromAlpha(1)
        arrowAlphaAnim:SetToAlpha(0)
        arrowAlphaAnim:SetDuration(0)

        ---@type Translation
        local arrowTransAnim = arrowsAnimGroup:CreateAnimation("Translation")
        arrowTransAnim:SetChildKey("arrow" .. i)
        arrowTransAnim:SetOrder(2)
        arrowTransAnim:SetOffset(0, 60)
        arrowTransAnim:SetDuration(0.5)
        arrowTransAnim:SetStartDelay(config.delay)
    end

    ---@type FontString
    local title = noticeFrame:CreateFontString(nil, "ARTWORK", "Game12Font")
    title:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 0, -2)
    title:SetTextColor(GetTableColor(NORMAL_FONT_COLOR))
    noticeFrame.title = title

    ---@type FontString
    local text = noticeFrame:CreateFontString(nil, "ARTWORK", "Game12Font")
    text:SetSize(noticeFrame:GetWidth() - 2 * 2 - iconFrame:GetWidth(), 26)
    text:SetPoint("BOTTOM", iconFrame:GetWidth() / 2, 2)
    text:SetIndentedWordWrap()
    noticeFrame.text = text

    ---@type Texture
    local bonus = noticeFrame:CreateTexture()
    bonus:SetPoint("TOPRIGHT")
    bonus:SetAtlas("Bonus-ToastBanner", true)
    bonus:Hide()
    noticeFrame.bonus = bonus

    for i = 1, numSlots do
        CreateSlotFrame(noticeFrame, i)
    end

    ---@type Texture
    local glow = noticeFrame:CreateTexture(nil, "OVERLAY")
    glow:SetSize(noticeFrame:GetWidth() * 1.3, noticeFrame:GetHeight() * 2.6)
    glow:SetPoint("CENTER")
    glow:SetTexture("Interface/AchievementFrame/UI-Achievement-Alert-Glow")
    glow:SetTexCoord(5 / 512, 395 / 512, 5 / 256, 167 / 256)
    glow:SetAlpha(0)
    glow:SetBlendMode("ADD")
    noticeFrame.glow = glow

    ---@type Texture
    local shine = noticeFrame:CreateTexture(nil, "OVERLAY")
    shine:SetSize(noticeFrame:GetWidth() * 0.25, noticeFrame:GetHeight())
    shine:SetPoint("BOTTOMLEFT")
    shine:SetTexture("Interface/AchievementFrame/UI-Achievement-Alert-Glow")
    shine:SetTexCoord(403 / 512, 465 / 512, 14 / 256, 62 / 256)
    shine:SetAlpha(0)
    shine:SetBlendMode("ADD")
    noticeFrame.shine = shine

    ---@type AnimationGroup
    local animGroup = noticeFrame:CreateAnimationGroup()
    animGroup:SetToFinalAlpha(true)
    animGroup:SetScript("OnFinished", function()
        if noticeFrame.data.showArrows then
            noticeFrame.arrowsAnim:Play()
            noticeFrame.data.showArrows = false
        end
    end)
    noticeFrame.animIn = animGroup

    ---@type Alpha
    local frameAlphaAnim = animGroup:CreateAnimation("Alpha")
    frameAlphaAnim:SetOrder(1)
    frameAlphaAnim:SetFromAlpha(0)
    frameAlphaAnim:SetToAlpha(1)
    frameAlphaAnim:SetDuration(0)

    frameAlphaAnim = animGroup:CreateAnimation("Alpha")
    frameAlphaAnim:SetChildKey("glow")
    frameAlphaAnim:SetOrder(2)
    frameAlphaAnim:SetFromAlpha(0)
    frameAlphaAnim:SetToAlpha(1)
    frameAlphaAnim:SetDuration(0.2)

    frameAlphaAnim = animGroup:CreateAnimation("Alpha")
    frameAlphaAnim:SetChildKey("glow")
    frameAlphaAnim:SetOrder(3)
    frameAlphaAnim:SetFromAlpha(1)
    frameAlphaAnim:SetToAlpha(0)
    frameAlphaAnim:SetDuration(0.5)

    frameAlphaAnim = animGroup:CreateAnimation("Alpha")
    frameAlphaAnim:SetChildKey("shine")
    frameAlphaAnim:SetOrder(2)
    frameAlphaAnim:SetFromAlpha(0)
    frameAlphaAnim:SetToAlpha(1)
    frameAlphaAnim:SetDuration(0.2)

    frameAlphaAnim = animGroup:CreateAnimation("Alpha")
    frameAlphaAnim:SetChildKey("shine")
    frameAlphaAnim:SetOrder(3)
    frameAlphaAnim:SetFromAlpha(1)
    frameAlphaAnim:SetToAlpha(0)
    frameAlphaAnim:SetStartDelay(0.35)
    frameAlphaAnim:SetDuration(0.5)

    ---@type Translation
    local frameTransAnim = animGroup:CreateAnimation("Translation")
    frameTransAnim:SetChildKey("shine")
    frameTransAnim:SetOrder(3)
    frameTransAnim:SetOffset(168, 0)
    frameTransAnim:SetDuration(0.85)

    animGroup = noticeFrame:CreateAnimationGroup()
    animGroup:SetScript("OnFinished", function()
        RecycleNotice(noticeFrame)
    end)
    noticeFrame.animOut = animGroup

    frameAlphaAnim = animGroup:CreateAnimation("Alpha")
    frameAlphaAnim:SetOrder(1)
    frameAlphaAnim:SetFromAlpha(1)
    frameAlphaAnim:SetToAlpha(0)
    frameAlphaAnim:SetStartDelay(5)
    frameAlphaAnim:SetDuration(1.2)
    animGroup.anim = frameAlphaAnim

    noticeFrame:SetScript("OnShow", function(self)
        if self.data.sound then
            PlaySound(self.data.sound)
        end
        ---@type AnimationGroup
        local animIn = self.animIn
        animIn:Play()
        ---@type AnimationGroup
        local animOut = self.animOut
        animOut:Play()
    end)

    noticeFrame:SetScript("OnEnter", NoticeOnEnter)

    noticeFrame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        ---@type GameTooltip
        local garrisonFollowerTooltip = GarrisonFollowerTooltip
        garrisonFollowerTooltip:Hide()
        ---@type GameTooltip
        local garrisonShipyardFollowerTooltip = GarrisonShipyardFollowerTooltip
        garrisonShipyardFollowerTooltip:Hide()
        ---@type GameTooltip
        local battlePetTooltip = BattlePetTooltip
        battlePetTooltip:Hide()
        ---@type GameTooltip
        local shoppingTooltip1 = ShoppingTooltip1
        shoppingTooltip1:Hide()
        ---@type GameTooltip
        local shoppingTooltip2 = ShoppingTooltip2
        shoppingTooltip2:Hide()
        ---@type AnimationGroup
        local animOut = self.animOut
        animOut:Play()
    end)

    noticeFrame.data = {}
    return noticeFrame
end

--- 查找通知框架
local function FindNotice(event, type, value)
    if type and value then
        for i = 1, #activeNotices do
            local activeNotice = activeNotices[i]
            if (not event or event == activeNotice.data.event) and activeNotice.data[type] == value then
                return activeNotice
            end
        end
        for i = 1, #queuedNotices do
            local queuedNotice = queuedNotices[i]
            if (not event or event == queuedNotice.data.event) and queuedNotice.data[type] == value then
                return queuedNotice, true
            end
        end
    end
end

--- 获取通知框架
local function GetNotice(event, type, value)
    local notice, isQueued = FindNotice(event, type, value)
    local isNew
    if not notice then
        notice = tremove(createdNotices, 1)
        if not notice then
            notice = CreateNoticeFrame()
        end
        isNew = true
    end
    return notice, isNew, isQueued
end

--- 创建获得成就时的通知
local function SetUpAchievementNotice(event, achievementID, flag, isCriteria)
    local notice = GetNotice()
    local _, name, points, _, month, day, year, description, _, icon = GetAchievementInfo(achievementID)
    if isCriteria then
        notice.title:SetText(ACHIEVEMENT_PROGRESSED)
        notice.text:SetText(flag)
        notice.iconText1:SetText("")
    else
        notice.title:SetText(ACHIEVEMENT_UNLOCKED)
        notice.text:SetText(name)
        if flag then
            notice.iconText1:SetText("")
        else
            notice:SetBackdropBorderColor(0.9, 0.75, 0.26)
            notice.iconText1:SetText(points == 0 and "" or points)
        end
    end
    notice.icon:SetTexture(icon)

    notice.data.event = event
    notice.data.achID = achievementID

    notice:HookScript("OnEnter", function(self)
        if self.data.achID and name then
            if day and day > 0 then
                GameTooltip:AddDoubleLine(name, FormatShortDate(day, month, year), nil, nil, nil, 0.5, 0.5, 0.5)
            else
                GameTooltip:AddLine(name)
            end
            if description then
                GameTooltip:AddLine(description, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end
    end)
    ShowNotice(notice)
end

--- 创建挖掘场完成时的通知
local function SetUpDigsiteNotice(event, researchFieldID)
    local notice = GetNotice()
    local raceName, raceTexture = GetArchaeologyRaceInfoByID(researchFieldID)
    notice:SetBackdropBorderColor(0.9, 0.4, 0.1)
    notice.title:SetText(ARCHAEOLOGY_DIGSITE_COMPLETE_TOAST_FRAME_TITLE)
    notice.text:SetText(raceName)
    notice.icon:SetTexture(raceTexture)
    notice.icon:SetTexCoord(0 / 128, 74 / 128, 0 / 128, 88 / 128)

    notice.data.event = event
    notice.data.sound = SOUNDKIT.UI_DIG_SITE_COMPLETION_TOAST

    ShowNotice(notice)
end

local textsToAnimate = {}

--- 显示动态文字
---@param label FontString
local function PostSetAnimatedText(label, value)
    if label.type == "default" then
        label:SetText(value == 1 and "" or value)
    elseif label.type == "money" then
        label:SetText(GetMoneyString(abs(value)), true)
    elseif label.type == "large" then
        label:SetText(value == 1 and "" or FormatLargeNumber(abs(value)))
    end
end

C_Timer.NewTicker(0.05, function()
    ---@param label FontString
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
        if label.type then
            PostSetAnimatedText(label, newValue)
        else
            label:SetText(newValue)
        end
    end
end)

---@param label FontString
local function SetAnimatedText(label, value, skip)
    if skip then
        label.value = value
        label.elapsed = 0
        if label.type then
            PostSetAnimatedText(label, value)
        else
            label:SetText(value)
        end
    else
        label.value = label.value or 1
        label.elapsed = 0
        textsToAnimate[label] = value
    end
end

--- 创建获得收藏时的通知
local function SetUpCollectionNotice(event, id, isMount, isPet, isToy)
    local notice, isNew, isQueued = GetNotice(event, "collectionID", id)
    if isNew then
        local color, name, icon, rarity, _
        if isMount then
            name, _, icon = C_MountJournal.GetMountInfoByID(id)
        elseif isPet then
            local customName
            _, _, _, _, rarity = C_PetJournal.GetPetStats(id)
            _, customName, _, _, _, _, _, name, icon = C_PetJournal.GetPetInfoByPetID(id)
            rarity = (rarity or LE_ITEM_QUALITY_UNCOMMON) - 1
            color = ITEM_QUALITY_COLORS[rarity]
            name = customName or name
        elseif isToy then
            _, name, icon = C_ToyBox.GetToyInfo(id)
        end
        if not name then
            RecycleNotice(notice)
            return
        end
        if rarity then
            notice:SetBackdropBorderColor(GetTableColor(color))
        end
        notice.title:SetText(YOU_EARNED_LABEL)
        notice.text:SetText(name)
        notice.icon:SetTexture(icon)
        notice.iconText1.type = "default"
        SetAnimatedText(notice.iconText1, 1, true)

        notice.data.collectionID = id
        notice.data.count = 1
        notice.data.event = event
        notice.data.sound = SOUNDKIT.UI_EPICLOOT_TOAST

        ShowNotice(notice)
    else
        if isQueued then
            notice.data.count = notice.data.count + 1
            SetAnimatedText(notice.iconText1, notice.data.count, true)
        else
            notice.data.count = notice.data.count + 1
            SetAnimatedText(notice.iconText1, notice.data.count)
            notice.iconText2:SetText("+1")
            notice.iconText2.blink:Stop()
            notice.iconText2.blink:Play()
            notice.animOut:Stop()
            notice.animOut:Play()
        end
    end
end

--- 创建新增和完成要塞任务时的通知
local function SetUpMissionNotice(event, missionID, isAdded)
    local missionInfo = C_Garrison.GetBasicMissionInfo(missionID)
    local rarity = missionInfo.isRare and LE_ITEM_QUALITY_RARE or LE_ITEM_QUALITY_COMMON
    local color = ITEM_QUALITY_COLORS[rarity]
    local level = missionInfo.iLevel == 0 and missionInfo.level or missionInfo.iLevel
    local notice = GetNotice()

    notice:SetBackdropBorderColor(GetTableColor(color))
    if isAdded then
        notice.title:SetText(GARRISON_MISSION_ADDED_TOAST1)
    else
        notice.title:SetText(GARRISON_MISSION_COMPLETE)
    end
    notice.text:SetText(missionInfo.name)
    notice.icon:SetTexCoord(0, 1, 0, 1)
    notice.icon:SetAtlas(missionInfo.typeAtlas, false)
    notice.iconText1:SetText(level)

    notice.data.event = event
    notice.data.missionID = missionID
    notice.data.sound = SOUNDKIT.UI_GARRISON_TOAST_MISSION_COMPLETE

    ShowNotice(notice)
end

--- 创建获得追随者时的通知
local function SetUpFollowerNotice(event, followerID, name, _, level, quality, isUpgraded, texPrefix, followerTypeID)
    local followerInfo = C_Garrison.GetFollowerInfo(followerID)
    local followerStrings = GarrisonFollowerOptions[followerTypeID].strings
    local upgradeTexture = LOOTUPGRADEFRAME_QUALITY_TEXTURES[quality] or LOOTUPGRADEFRAME_QUALITY_TEXTURES[2]
    local color = ITEM_QUALITY_COLORS[quality]
    local notice = GetNotice()

    if followerTypeID == LE_FOLLOWER_TYPE_SHIPYARD_6_2 then
        notice.icon:SetTexCoord(0, 1, 0, 1)
        notice.icon:SetAtlas(texPrefix .. "-Portrait", false)
    else
        local portrait
        if followerInfo.portraitIconID and followerInfo.portraitIconID ~= 0 then
            portrait = followerInfo.portraitIconID
        else
            portrait = "Interface/Garrison/Portraits/FollowerPortrait_NoPortrait"
        end
        notice.icon:SetTexture(portrait)
        notice.icon:SetTexCoord(0, 1, 0, 1)
        notice.iconText1:SetText(level)
    end

    if isUpgraded then
        notice.title:SetText(followerStrings.FOLLOWER_ADDED_UPGRADED_TOAST)
        for i = 1, numArrows do
            ---@type Texture
            local arrow = notice["arrow" .. i]
            arrow:SetAtlas(upgradeTexture.arrow, true)
        end
    else
        notice.title:SetText(followerStrings.FOLLOWER_ADDED_TOAST)
    end

    notice:SetBackdropBorderColor(GetTableColor(color))
    notice.text:SetText(name)

    notice.data.event = event
    notice.data.followerID = followerID
    notice.showArrows = isUpgraded

    notice:HookScript("OnEnter", function(self)
        if self.data.followerID then
            local isOK, link = pcall(C_Garrison.GetFollowerLink, self.data.followerID)
            if not isOK then
                isOK, link = pcall(C_Garrison.GetFollowerLinkByID, self.data.followerID)
            end

            if isOK and link then
                local _, garrisonFollowerID, tooltipQuality, tooltipLevel, itemLevel, ability1, ability2, ability3,
                ability4, trait1, trait2, trait3, trait4, spec1 = strsplit(":", link)
                garrisonFollowerID = tonumber(garrisonFollowerID)
                local data = {
                    garrisonFollowerID = garrisonFollowerID,
                    followerTypeID = C_Garrison.GetFollowerTypeByID(garrisonFollowerID),
                    collected = false,
                    hyperlink = false,
                    name = C_Garrison.GetFollowerNameByID(garrisonFollowerID),
                    spec = C_Garrison.GetFollowerClassSpecByID(garrisonFollowerID),
                    portraitIconID = C_Garrison.GetFollowerPortraitIconIDByID(garrisonFollowerID),
                    quality = tonumber(tooltipQuality),
                    level = tonumber(tooltipLevel),
                    xp = 0,
                    levelxp = 0,
                    iLevel = tonumber(itemLevel),
                    spec1 = tonumber(spec1),
                    ability1 = tonumber(ability1),
                    ability2 = tonumber(ability2),
                    ability3 = tonumber(ability3),
                    ability4 = tonumber(ability4),
                    trait1 = tonumber(trait1),
                    trait2 = tonumber(trait2),
                    trait3 = tonumber(trait3),
                    trait4 = tonumber(trait4),
                    isTroop = C_Garrison.GetFollowerIsTroop(garrisonFollowerID),
                }
                ---@type GameTooltip
                local tooltip
                if data.followerTypeID == LE_FOLLOWER_TYPE_SHIPYARD_6_2 then
                    tooltip = GarrisonShipyardFollowerTooltip
                    GarrisonFollowerTooltipTemplate_SetShipyardFollower(tooltip, data)
                else
                    tooltip = GarrisonFollowerTooltip
                    GarrisonFollowerTooltipTemplate_SetGarrisonFollower(tooltip, data)
                end
                tooltip:Show()
                tooltip:ClearAllPoints()
                tooltip:SetPoint(GameTooltip:GetPoint())
            end
        end
    end)

    ShowNotice(notice)
end

--- 创建要塞建筑完成时的通知
local function SetUpBuildingNotice(event, buildingName)
    local notice = GetNotice()
    notice.title:SetText(GARRISON_UPDATE)
    notice.text:SetText(buildingName)
    notice.icon:SetTexture("Interface/Icons/Garrison_Build")

    notice.data.event = event
    notice.data.sound = SOUNDKIT.UI_GARRISON_TOAST_BUILDING_COMPLETE

    ShowNotice(notice)
end

--- 创建职业大厅升级时的通知
local function SetUpTalentNotice(event, talentID)
    local talent = C_Garrison.GetTalent(talentID)
    local notice = GetNotice()
    notice.title:SetText(GARRISON_TALENT_ORDER_ADVANCEMENT)
    notice.text:SetText(talent.name)
    notice.icon:SetTexture(talent.icon)

    notice.data.event = event
    notice.data.talentID = talentID
    notice.data.sound = SOUNDKIT.UI_ORDERHALL_TALENT_READY_TOAST

    ShowNotice(notice)
end

--- 创建完成地下城获得奖励时的通知
local function SetUpInstanceNotice(event, name, subTypeID, textureFile, moneyReward, xpReward, numItemRewards,
                                   isScenario, isScenarioBonusComplete)
    local notice = GetNotice()
    local usedSlots = 0
    local sound

    if moneyReward and moneyReward > 0 then
        usedSlots = usedSlots + 1
        ---@type Frame
        local slot = notice["slot" .. usedSlots]
        if slot then
            slot.icon:SetTexture("Interface/Icons/INV_Misc_Coin_02")
            slot:HookScript("OnEnter", function()
                GameTooltip:AddLine(YOU_RECEIVED_LABEL)
                GameTooltip:AddLine(GetMoneyString(moneyReward, true), GetTableColor(HIGHLIGHT_FONT_COLOR))
                GameTooltip:Show()
            end)
            slot:Show()
        end
    end

    if xpReward and xpReward > 0 and UnitLevel("player") < MAX_PLAYER_LEVEL then
        usedSlots = usedSlots + 1
        ---@type Frame
        local slot = notice["slot" .. usedSlots]
        if slot then
            slot.icon:SetTexture("Interface/Icons/XP_ICON")
            slot:HookScript("OnEnter", function()
                GameTooltip:AddLine(YOU_RECEIVED_LABEL)
                GameTooltip:AddLine(format(BONUS_OBJECTIVE_EXPERIENCE_FORMAT, xpReward),
                        GetTableColor(HIGHLIGHT_FONT_COLOR))
                GameTooltip:Show()
            end)
            slot:Show()
        end
    end

    for i = 1, numItemRewards or 0 do
        local link = GetLFGCompletionRewardItemLink(i)
        if link then
            usedSlots = usedSlots + 1
            ---@type Frame
            local slot = notice["slot" .. usedSlots]
            if slot then
                local texture = GetLFGCompletionRewardItem(i)
                texture = texture or "Interface/Icons/INV_Box_02"
                slot.icon:SetTexture(texture)
                slot:HookScript("OnEnter", function()
                    GameTooltip:SetHyperlink(link)
                    GameTooltip:Show()
                end)
                slot:Show()
            end
        end
    end

    if isScenario then
        if isScenarioBonusComplete then
            notice.bonus:Show()
        end
        notice.title:SetText(SCENARIO_COMPLETED)
        sound = SOUNDKIT.UI_SCENARIO_ENDING
    else
        if subTypeID == LFG_SUBTYPEID_HEROIC then
            notice.skull:Show()
        end
        notice.title:SetText(DUNGEON_COMPLETED)
        sound = SOUNDKIT.LFG_REWARDS
    end

    notice.text:SetText(name)
    notice.icon:SetTexture(textureFile or "Interface/LFGFrame/LFGICON-DUNGEON")

    notice.data.event = event
    notice.data.sound = sound

    ShowNotice(notice)
end

local function SanitizeLink(link)
    if not link or link == "[]" or link == "" then
        return
    end

    local temp, name = strmatch(link, "|H(.+)|h%[(.+)%]|h")
    link = temp or link

    local linkTable = { strsplit(":", link) }

    if linkTable[1] ~= "item" then
        return link, link, linkTable[1], tonumber(linkTable[2]), name
    end

    if linkTable[12] ~= "" then
        linkTable[12] = ""
        tremove(linkTable, 15 + (tonumber(linkTable[14]) or 0))
    end

    return table.concat(linkTable, ":"), link, linkTable[1], tonumber(linkTable[2]), name
end

--- 获取物品等级
local function GetItemLevel(itemLink)
    local itemEquipLoc, _, _, itemClassID, itemSubClassID = select(9, GetItemInfo(itemLink))
    if (itemClassID == LE_ITEM_CLASS_GEM and itemSubClassID == LE_ITEM_GEM_ARTIFACTRELIC) or _G[itemEquipLoc] then
        return GetDetailedItemLevelInfo(itemLink) or 0
    end
    return 0
end

--- 创建获得普通物品时的通知
local function SetUpLootCommonNotice(event, link, quantity)
    local sanitizedLink, originalLink, linkType, itemID = SanitizeLink(link)
    local isNew, isQueued
    ---@type Frame
    local notice

    notice, isQueued = FindNotice(nil, "itemID", itemID)

    if notice then
        if notice.data.event ~= event then
            return
        end
    else
        notice, isNew, isQueued = GetNotice(event, "link", sanitizedLink)
    end

    if isNew then
        local name, quality, icon, _, classID, subClassID, bindType

        if linkType == "battlepet" then
            local _, speciesID, _, breedQuality, _ = strsplit(":", originalLink)
            name, icon = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
            quality = tonumber(breedQuality)
        else
            name, _, quality, _, _, _, _, _, _, icon, _, classID, subClassID, bindType = GetItemInfo(originalLink)
        end

        if name and (quality and quality >= LE_ITEM_QUALITY_POOR and quality <= LE_ITEM_QUALITY_LEGENDARY) then
            local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[LE_ITEM_QUALITY_COMMON]
            notice:SetBackdropBorderColor(GetTableColor(color))

            local title = YOU_RECEIVED_LABEL
            local sound = SOUNDKIT.UI_EPICLOOT_TOAST
            if quality == LE_ITEM_QUALITY_LEGENDARY then
                title = LEGENDARY_ITEM_LOOT_LABEL
                sound = SOUNDKIT.UI_LEGENDARY_LOOT_TOAST
            end

            local iLevel = GetItemLevel(originalLink)
            if iLevel > 0 then
                name = "[" .. color.hex .. iLevel .. "|r] " .. name
            end

            notice.title:SetText(title)
            notice.text:SetText(name)
            notice.icon:SetTexture(icon)
            notice.iconText1.type = "default"
            SetAnimatedText(notice.iconText1, quantity, true)

            notice.data.count = quantity
            notice.data.event = event
            notice.data.itemID = itemID
            notice.data.link = sanitizedLink
            notice.data.sound = sound

            notice:HookScript("OnEnter", function()
                if originalLink then
                    if strfind(originalLink, "item") then
                        GameTooltip:SetHyperlink(originalLink)
                        GameTooltip:Show()
                    elseif strfind(originalLink, "battlepet") then
                        local _, speciesID, level, breedQuality, maxHealth, power, speed = strsplit(":", originalLink)
                        BattlePetToolTip_Show(tonumber(speciesID), tonumber(level), tonumber(breedQuality),
                                tonumber(maxHealth), tonumber(power), tonumber(speed))
                    end
                end
            end)

            ShowNotice(notice)
        else
            RecycleNotice(notice)
        end
    else
        if isQueued then
            notice.data.count = notice.data.count + quantity
            SetAnimatedText(notice.iconText1, notice.data.count, true)
        else
            notice.data.count = notice.data.count + quantity
            SetAnimatedText(notice.iconText1, notice.data.count)
            notice.iconText2:SetText("+" .. quantity)
            notice.iconText2.blink:Stop()
            notice.iconText2.blink:Play()
            notice.animOut:Stop()
            notice.animOut:Play()
        end
    end
end

local LOOT_ITEM_SELF_MULTIPLE_PATTERN = gsub(gsub(LOOT_ITEM_SELF_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local LOOT_ITEM_PUSHED_MULTIPLE_PATTERN = gsub(gsub(LOOT_ITEM_PUSHED_SELF_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local LOOT_ITEM_CREATED_MULTIPLE_PATTERN = gsub(gsub(LOOT_ITEM_CREATED_SELF_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local LOOT_ITEM_PATTERN = gsub(LOOT_ITEM_SELF, "%%s", "(.+)")
local LOOT_ITEM_PUSHED_PATTERN = gsub(LOOT_ITEM_PUSHED_SELF, "%%s", "(.+)")
local LOOT_ITEM_CREATED_PATTERN = gsub(LOOT_ITEM_CREATED_SELF, "%%s", "(.+)")

--- 创建获得通货时的通知
local function SetUpLootCurrencyNotice(event, link, quantity)
    local sanitizedLink, originalLink = SanitizeLink(link)
    local notice, isNew, isQueued = GetNotice(event, "link", sanitizedLink)

    if isNew then
        local name, _, icon, _, _, _, _, quality = GetCurrencyInfo(link)
        local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[LE_ITEM_QUALITY_COMMON]
        notice:SetBackdropBorderColor(GetTableColor(color))

        notice.title:SetText(YOU_RECEIVED_LABEL)
        notice.text:SetText(name)
        notice.icon:SetTexture(icon)
        notice.iconText1.type = "large"
        SetAnimatedText(notice.iconText1, quantity, true)

        notice.data.event = event
        notice.data.count = quantity
        notice.data.link = sanitizedLink
        notice.data.sound = SOUNDKIT.UI_EPICLOOT_TOAST

        notice:HookScript("OnEnter", function()
            GameTooltip:SetHyperlink(originalLink)
            GameTooltip:Show()
        end)

        ShowNotice(notice)
    else
        if isQueued then
            notice.data.count = notice.data.count + quantity
            SetAnimatedText(notice.iconText1, notice.data.count, true)
        else
            notice.data.count = notice.data.count + quantity
            SetAnimatedText(notice.iconText1, notice.data.count)
            notice.iconText2:SetText("+" .. quantity)
            notice.iconText2.blink:Stop()
            notice.iconText2.blink:Play()
            notice.animOut:Stop()
            notice.animOut:Play()
        end
    end
end

local CURRENCY_GAINED_MULTIPLE_PATTERN = gsub(gsub(CURRENCY_GAINED_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local CURRENCY_GAINED_PATTERN = gsub(CURRENCY_GAINED, "%%s", "(.+)")

--- 创建获得或失去金钱时的通知
local function SetUpLootGoldNotice(event, quantity)
    local notice, isNew, isQueued = GetNotice(nil, "event", event)
    if isNew then
        notice:SetBackdropBorderColor(0.9, 0.75, 0.26)
        notice.title:SetText(quantity > 0 and YOU_RECEIVED_LABEL
                or (RED_FONT_COLOR_CODE .. "你失去" .. FONT_COLOR_CODE_CLOSE))
        local texture = "Interface/Icons/INV_Misc_Coin_02"
        if abs(quantity) < 100 then
            texture = "Interface/Icons/INV_Misc_Coin_06"
        elseif abs(quantity) < 10000 then
            texture = "Interface/Icons/INV_Misc_Coin_04"
        end
        notice.icon:SetTexture(texture)
        notice.text.type = "money"
        SetAnimatedText(notice.text, quantity, true)

        notice.data.event = event
        notice.data.count = quantity
        notice.data.sound = SOUNDKIT.IG_BACKPACK_COIN_OK

        ShowNotice(notice)
    else
        notice.data.count = notice.data.count + quantity
        if abs(notice.data.count) < 100 then
            notice.icon:SetTexture("Interface/Icons/INV_Misc_Coin_06")
        elseif abs(notice.data.count) < 10000 then
            notice.icon:SetTexture("Interface/Icons/INV_Misc_Coin_04")
        else
            notice.icon:SetTexture("Interface/Icons/INV_Misc_Coin_02")
        end
        if notice.data.count > 0 then
            notice.title:SetText(YOU_RECEIVED_LABEL)
        elseif notice.data.count < 0 then
            notice.title:SetText(RED_FONT_COLOR_CODE .. "你失去" .. FONT_COLOR_CODE_CLOSE)
        end
        if isQueued then
            SetAnimatedText(notice.text, notice.data.count, true)
        else
            SetAnimatedText(notice.text, notice.data.count)
            notice.animOut:Stop()
            notice.animOut:Play()
        end
    end
end

local oldMoney

--- 创建获得特殊物品时的通知
local function SetUpLootSpecialNotice(event, link, quantity, lessAwesome, isUpgraded, baseQuality, isLegendary,
                                      isAzerite, isCorrupted)
    if link then
        local sanitizedLink, originalLink, _, itemID = SanitizeLink(link)
        local notice, isNew, isQueued = GetNotice(event, "link", sanitizedLink)
        if isNew then
            local name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(originalLink)
            if name and (quality and quality >= LE_ITEM_QUALITY_POOR and quality <= LE_ITEM_QUALITY_LEGENDARY) then
                local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[LE_ITEM_QUALITY_COMMON]
                notice:SetBackdropBorderColor(GetTableColor(color))
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
                        local arrow = notice["arrow" .. i]
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

                local iLevel = GetItemLevel(originalLink)
                if iLevel > 0 then
                    name = "[" .. color.hex .. iLevel .. FONT_COLOR_CODE_CLOSE .. "]" .. name
                end

                notice.title:SetText(title)
                notice.text:SetText(name)
                notice.icon:SetTexture(icon)
                notice.iconText1.type = "default"
                SetAnimatedText(notice.iconText1, quantity, true)

                notice.data.count = quantity
                notice.data.event = event
                notice.data.link = sanitizedLink
                notice.data.itemID = itemID
                notice.data.sound = sound
                notice.data.showArrows = isUpgraded

                notice:HookScript("OnEnter", function()
                    if originalLink then
                        if strfind(originalLink, "item") then
                            GameTooltip:SetHyperlink(originalLink)
                            GameTooltip:Show()
                        elseif strfind(originalLink, "battlepet") then
                            local _, speciesID, level, breedQuality, maxHealth, power, speed = strsplit(":",
                                    originalLink)
                            BattlePetToolTip_Show(tonumber(speciesID), tonumber(level), tonumber(breedQuality),
                                    tonumber(maxHealth), tonumber(power), tonumber(speed))
                        end
                    end
                end)

                ShowNotice(notice)
            else
                RecycleNotice(notice)
            end
        else
            notice.data.count = notice.data.count + quantity
            if isQueued then
                SetAnimatedText(notice.iconText1, notice.data.count, true)
            else
                SetAnimatedText(notice.iconText1, notice.data.count)
                notice.iconText2:SetText("+" .. quantity)
                notice.iconText2.blink:Stop()
                notice.iconText2.blink:Play()
                notice.animOut:Stop()
                notice.animOut:Play()
            end
        end
    end
end

---@type AnimationGroup
local finishRollAnim = BonusRollFrame.FinishRollAnim
---@param self AnimationGroup
finishRollAnim:SetScript("OnFinished", function(self)
    local frame = self:GetParent()
    if frame.rewardType == "item" then
        SetUpLootSpecialNotice("LOOT_ITEM_BONUS_ROLL_WON", frame.rewardLink, frame.rewardQuantity)
    end
    GroupLootContainer_RemoveFrame(GroupLootContainer, frame)
end)

--- 创建获得配方时的通知
local function SetUpRecipeNotice(event, recipeID)
    local tradeSkillID = C_TradeSkillUI.GetTradeSkillLineForRecipe(recipeID)
    if tradeSkillID then
        local recipeName = GetSpellInfo(recipeID)
        if recipeName then
            local notice = GetNotice()
            local rank = GetSpellRank(recipeID)
            local rankTexture
            if rank == 1 then
                rankTexture = "|TInterface/LootFrame/toast-star:12:12:0:0:32:32:0:21:0:21|t"
            elseif rank == 2 then
                rankTexture = "|TInterface/LootFrame/toast-star-2:12:24:0:0:64:32:0:42:0:21|t"
            elseif rank == 3 then
                rankTexture = "|TInterface/LootFrame/toast-star-3:12:36:0:0:64:32:0:64:0:21|t"
            end
            notice.title:SetText(rank and rank > 1 and UPGRADED_RECIPE_LEARNED_TITLE or NEW_RECIPE_LEARNED_TITLE)
            notice.text:SetText(recipeName)
            notice.icon:SetTexture(C_TradeSkillUI.GetTradeSkillTexture(tradeSkillID))
            notice.iconText1:SetText(rankTexture)

            notice.data.event = event
            notice.data.sound = SOUNDKIT.UI_PROFESSIONS_NEW_RECIPE_LEARNED_TOAST

            notice:HookScript("OnEnter", function()
                if recipeID then
                    GameTooltip:SetSpellByID(recipeID)
                    GameTooltip:Show()
                end
            end)

            ShowNotice(notice)
        end
    end
end

--- 创建获得商城物品时的通知
local function SetUpStoreNotice(event, entitlementType, textureID, name, payloadID, payloadLink)
    ---@type Frame
    local notice
    local quality, _, sanitizedLink, originalLink
    if payloadLink then
        sanitizedLink, originalLink = SanitizeLink(payloadLink)
        notice = GetNotice(event, "link", sanitizedLink)
        _, _, quality = GetItemInfo(originalLink)

        notice.data.link = sanitizedLink
    else
        notice = GetNotice()
    end

    if entitlementType == Enum.WoWEntitlementType.Appearance then
        notice.data.link = "transmogappearance:" .. payloadID
    elseif entitlementType == Enum.WoWEntitlementType.AppearanceSet then
        notice.data.link = "transmogset:" .. payloadID
    elseif entitlementType == Enum.WoWEntitlementType.Illusion then
        notice.data.link = "transmogillusion:" .. payloadID
    end

    quality = quality or LE_ITEM_QUALITY_COMMON
    local color = ITEM_QUALITY_COLORS[quality]
    notice:SetBackdropBorderColor(GetTableColor(color))
    notice.title:SetText(event == "ENTITLEMENT_DELIVERED" and BLIZZARD_STORE_PURCHASE_COMPLETE or YOU_RECEIVED_LABEL)
    notice.text:SetText(name)
    notice.icon:SetTexture(textureID)

    notice.data.event = event
    notice.data.sound = SOUNDKIT.UI_IG_STORE_PURCHASE_DELIVERED_TOAST_01

    notice:HookScript("OnEnter", function()
        if originalLink and strfind(originalLink, "item") then
            GameTooltip:SetHyperlink(originalLink)
            GameTooltip:Show()
        end
    end)

    ShowNotice(notice)
end

--- 获取物品 Link
local function GetItemLink(itemID, textureID)
    if itemID then
        if select(5, GetItemInfoInstant(itemID)) == textureID then
            local _, link = GetItemInfo(itemID)
            if link then
                return link, false
            end
            return nil, true
        end
    end
    return nil, false
end

--- 在商城支付后调用函数
local function OnEventEntitlementDelivered(event, entitlementType, textureID, name, payloadID)
    if entitlementType == Enum.WoWEntitlementType.Invalid then
        return
    end
    local link, tryAgain = GetItemLink(payloadID, textureID)
    if tryAgain then
        return C_Timer.After(0.25, function()
            OnEventEntitlementDelivered(event, entitlementType, textureID, name, payloadID)
        end)
    end
    SetUpStoreNotice(event, entitlementType, textureID, name, payloadID, link)
end

--- 创建获得和失去外观时的提示
local function SetUpTransmogNotice(event, sourceID, isAdded, attempt)
    local _, visualID, _, icon, _, _, link = C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
    local name
    link, _, _, _, name = SanitizeLink(link)
    if not link then
        return attempt < 4 and C_Timer.After(0.25, function()
            SetUpTransmogNotice(event, sourceID, isAdded, attempt + 1)
        end)
    end
    if FindNotice(event, "visualID", visualID) then
        return
    end
    local notice, isNew, isQueued = GetNotice(nil, "sourceID", sourceID)
    if isNew then
        notice:SetBackdropBorderColor(1, 0.5, 1)
        notice.title:SetText(isAdded and "外觀已加入" or (RED_FONT_COLOR_CODE .. "外觀已移除" .. FONT_COLOR_CODE_CLOSE))
        notice.text:SetText(name)
        notice.icon:SetTexture(icon)

        notice.data.event = event
        notice.data.sound = SOUNDKIT.UI_DIG_SITE_COMPLETION_TOAST
        notice.data.sourceID = sourceID
        notice.data.visualID = visualID

        ShowNotice(notice)
    else
        notice.title:SetText(isAdded and "外觀已加入" or (RED_FONT_COLOR_CODE .. "外觀已移除" .. FONT_COLOR_CODE_CLOSE))
        if not isQueued then
            notice.animOut:Stop()
            notice.animOut:Play()
        end
    end
end

--- 创建完成世界任务时的通知
local function SetUpWorldNotice(event, isUpdate, questID, name, moneyReward, xpReward, numCurrencyRewards, itemReward)
    local notice, isNew, isQueued = GetNotice(nil, "questID", questID)
    if isUpdate and isNew then
        RecycleNotice(notice)
        return
    end
    if isNew then
        local usedSlots = 0
        if moneyReward and moneyReward > 0 then
            usedSlots = usedSlots + 1
            ---@type Frame
            local slot = notice["slot" .. usedSlots]
            if slot then
                slot.icon:SetTexture("Interface/Icons/INV_Misc_Coin_02")
                slot:HookScript("OnEnter", function()
                    GameTooltip:AddLine(YOU_RECEIVED_LABEL)
                    GameTooltip:AddLine(GetMoneyString(moneyReward), GetTableColor(HIGHLIGHT_FONT_COLOR))
                    GameTooltip:Show()
                end)
                slot:Show()
            end
        end

        if xpReward and xpReward > 0 then
            usedSlots = usedSlots + 1
            ---@type Frame
            local slot = notice["slot" .. usedSlots]
            if slot then
                slot.icon:SetTexture("Interface/Icons/XP_ICON")
                slot:HookScript("OnEnter", function()
                    GameTooltip:AddLine(YOU_RECEIVED_LABEL)
                    GameTooltip:AddLine(format(BONUS_OBJECTIVE_EXPERIENCE_FORMAT, xpReward),
                            GetTableColor(HIGHLIGHT_FONT_COLOR))
                    GameTooltip:Show()
                end)
                slot:Show()
            end
        end

        for i = 1, numCurrencyRewards do
            usedSlots = usedSlots + 1
            ---@type Frame
            local slot = notice["slot" .. usedSlots]
            if slot then
                local _, texture, count = GetQuestLogRewardCurrencyInfo(i, questID)
                texture = texture or "Interface/Icons/INV_Box_02"
                slot.icon:SetTexture(texture)
                slot:HookScript("OnEnter", function()
                    GameTooltip:AddLine(YOU_RECEIVED_LABEL)
                    GameTooltip:AddLine(format("%s|T%s:0|t", count, texture), GetTableColor(HIGHLIGHT_FONT_COLOR))
                    GameTooltip:Show()
                end)
                slot:Show()
            end
        end

        local _, _, worldQuestType, rarity, _, tradeSkillLineIndex = GetQuestTagInfo(questID)
        if worldQuestType == LE_QUEST_TAG_TYPE_PVP then
            notice.icon:SetTexture("Interface/Icons/ACHIEVEMENT_ARENA_2V2_1")
        elseif worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE then
            notice.icon:SetTexture("Interface/Icons/INV_Pet_BattlePetTraining")
        elseif worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION and tradeSkillLineIndex then
            notice.icon:SetTexture(select(2, GetProfessionInfo(tradeSkillLineIndex)))
        elseif worldQuestType == LE_QUEST_TAG_TYPE_DUNGEON or worldQuestType == LE_QUEST_TAG_TYPE_RAID then
            notice.icon:SetTexture("Interface/Icons/INV_Misc_Bone_Skull_02")
        else
            notice.icon:SetTexture("Interface/Icons/Achievement_Quests_Completed_TwilightHighlands")
        end
        local color = WORLD_QUEST_QUALITY_COLORS[rarity] or WORLD_QUEST_QUALITY_COLORS[LE_WORLD_QUEST_QUALITY_COMMON]
        notice:SetBackdropBorderColor(GetTableColor(color))
        notice.title:SetText(WORLD_QUEST_COMPLETE)
        notice.text:SetText(name)

        notice.data.event = event
        notice.data.questID = questID
        notice.data.sound = SOUNDKIT.UI_WORLDQUEST_COMPLETE
        notice.data.usedSlots = usedSlots

        ShowNotice(notice)
    else
        if itemReward then
            notice.data.usedSlots = notice.data.usedSlots + 1
            ---@type Frame
            local slot = notice["slot" .. notice.data.usedSlots]
            if slot then
                local _, _, _, _, texture = GetItemInfoInstant(itemReward)
                texture = texture or "Interface/Icons/INV_Box_02"
                slot.icon:SetTexture(texture)
                slot:HookScript("OnEnter", function()
                    GameTooltip:SetHyperlink(itemReward)
                    GameTooltip:Show()
                end)
                slot:Show()
            end
        end
        if not isQueued then
            notice.animOut:Stop()
            notice.animOut:Play()
        end
    end
end

--- 接受任务时调用的函数
local function OnEventQuestTurnedIn(questID)
    if QuestUtils_IsQuestWorldQuest(questID) then
        if not HaveQuestRewardData(questID) then
            C_TaskQuest.RequestPreloadRewardData(questID)
            C_Timer.After(0.5, function()
                OnEventQuestTurnedIn(questID)
            end)
            return
        end
        SetUpWorldNotice("QUEST_TURNED_IN", false, questID, C_TaskQuest.GetQuestInfoByQuestID(questID),
                GetQuestLogRewardMoney(questID), GetQuestLogRewardXP(questID), GetNumQuestLogRewardCurrencies(questID))
    end
end

--- 收到任务奖励时调用的函数
local function OnEventQuestLootReceived(questID, itemLink)
    if not FindNotice(nil, "questID", questID) then
        if not HaveQuestRewardData(questID) then
            C_TaskQuest.RequestPreloadRewardData(questID)
            C_Timer.After(0.5, function()
                OnEventQuestLootReceived(questID, itemLink)
            end)
            return
        end
        OnEventQuestTurnedIn(questID)
    end
    SetUpWorldNotice("QUEST_LOOT_RECEIVED", true, questID, nil, nil, nil, nil, itemLink)
end

noticePane:RegisterEvent("ACHIEVEMENT_EARNED")
noticePane:RegisterEvent("CRITERIA_EARNED")

noticePane:RegisterEvent("ARTIFACT_DIGSITE_COMPLETE")

noticePane:RegisterEvent("NEW_MOUNT_ADDED")
noticePane:RegisterEvent("NEW_PET_ADDED")
noticePane:RegisterEvent("NEW_TOY_ADDED")

noticePane:RegisterEvent("GARRISON_MISSION_FINISHED")
noticePane:RegisterEvent("GARRISON_RANDOM_MISSION_ADDED")
noticePane:RegisterEvent("GARRISON_FOLLOWER_ADDED")
noticePane:RegisterEvent("GARRISON_BUILDING_ACTIVATABLE")
noticePane:RegisterEvent("GARRISON_TALENT_COMPLETE")

noticePane:RegisterEvent("LFG_COMPLETION_REWARD")

noticePane:RegisterEvent("CHAT_MSG_LOOT")

noticePane:RegisterEvent("CHAT_MSG_CURRENCY")

noticePane:RegisterEvent("PLAYER_LOGIN")
noticePane:RegisterEvent("PLAYER_MONEY")

noticePane:RegisterEvent("AZERITE_EMPOWERED_ITEM_LOOTED")
noticePane:RegisterEvent("LOOT_ITEM_ROLL_WON")
noticePane:RegisterEvent("SHOW_LOOT_TOAST")
noticePane:RegisterEvent("SHOW_LOOT_TOAST_UPGRADE")
noticePane:RegisterEvent("SHOW_PVP_FACTION_LOOT_TOAST")
noticePane:RegisterEvent("SHOW_RATED_PVP_REWARD_TOAST")
noticePane:RegisterEvent("SHOW_LOOT_TOAST_LEGENDARY_LOOTED")

noticePane:RegisterEvent("NEW_RECIPE_LEARNED")

noticePane:RegisterEvent("ENTITLEMENT_DELIVERED")
noticePane:RegisterEvent("RAF_ENTITLEMENT_DELIVERED")

noticePane:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_ADDED")
noticePane:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_REMOVED")

noticePane:RegisterEvent("QUEST_TURNED_IN")
noticePane:RegisterEvent("QUEST_LOOT_RECEIVED")

---@param self Frame
noticePane:SetScript("OnEvent", function(self, event, ...)
    if event == "ACHIEVEMENT_EARNED" then
        SetUpAchievementNotice(event, ...)
    elseif event == "CRITERIA_EARNED" then
        local achievementID, criteriaString = ...
        SetUpAchievementNotice(event, achievementID, criteriaString, true)
    elseif event == "ARTIFACT_DIGSITE_COMPLETE" then
        SetUpDigsiteNotice(event, ...)
    elseif event == "NEW_MOUNT_ADDED" then
        local mountID = ...
        SetUpCollectionNotice(event, mountID, true)
    elseif event == "NEW_PET_ADDED" then
        local petID = ...
        SetUpCollectionNotice(event, petID, nil, true)
    elseif event == "NEW_TOY_ADDED" then
        local toyID = ...
        SetUpCollectionNotice(event, toyID, nil, nil, true)
    elseif event == "GARRISON_MISSION_FINISHED" then
        local _, instanceType = GetInstanceInfo()
        if instanceType == "none" or C_Garrison.IsOnGarrisonMap() then
            local _, missionID = ...
            SetUpMissionNotice(event, missionID)
        end
    elseif event == "GARRISON_RANDOM_MISSION_ADDED" then
        local _, missionID = ...
        SetUpMissionNotice(event, missionID)
    elseif event == "GARRISON_FOLLOWER_ADDED" then
        SetUpFollowerNotice(event, ...)
    elseif event == "GARRISON_BUILDING_ACTIVATABLE" then
        SetUpBuildingNotice(event, ...)
    elseif event == "GARRISON_TALENT_COMPLETE" then
        local garrisonType, doAlert = ...
        if doAlert then
            SetUpTalentNotice(event, C_Garrison.GetCompleteTalent(garrisonType))
        end
    elseif event == "LFG_COMPLETION_REWARD" then
        if C_Scenario.IsInScenario() and not C_Scenario.TreatScenarioAsDungeon() then
            local _, _, _, _, hasBonusStep, isBonusStepComplete, _, _, _, scenarioType = C_Scenario.GetInfo()
            if scenarioType ~= LE_SCENARIO_TYPE_LEGION_INVASION then
                local name, _, subTypeID, textureFile, moneyBase, moneyVar, experienceBase, experienceVar, numStrangers,
                numItemRewards = GetLFGCompletionReward()
                SetUpInstanceNotice(event, name, subTypeID, textureFile, moneyBase + moneyVar * numStrangers,
                        experienceBase + experienceVar * numStrangers, numItemRewards, true,
                        hasBonusStep and isBonusStepComplete)
            end
        else
            local name, _, subTypeID, textureFile, moneyBase, moneyVar, experienceBase, experienceVar, numStrangers,
            numItemRewards = GetLFGCompletionReward()
            SetUpInstanceNotice(event, name, subTypeID, textureFile, moneyBase + moneyVar * numStrangers,
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
            SetUpLootCommonNotice(event, link, tonumber(quantity) or 0)
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
        SetUpLootCurrencyNotice(event, link, tonumber(quantity) or 0)
    elseif event == "PLAYER_LOGIN" then
        oldMoney = GetMoney()
        self:UnregisterEvent(event)
    elseif event == "PLAYER_MONEY" then
        local currentMoney = GetMoney()
        if currentMoney - oldMoney ~= 0 then
            SetUpLootGoldNotice(event, currentMoney - oldMoney)
        end
        oldMoney = currentMoney
    elseif event == "AZERITE_EMPOWERED_ITEM_LOOTED" then
        local link = ...
        SetUpLootSpecialNotice(event, link, 1, nil, nil, nil, nil, nil, true)
    elseif event == "LOOT_ITEM_ROLL_WON" then
        local link, quantity, _, _, isUpgraded = ...
        SetUpLootSpecialNotice(event, link, quantity, nil, isUpgraded)
    elseif event == "SHOW_LOOT_TOAST" then
        local typeID, link, quantity, _, _, _, _, lessAwesome, isUpgraded, isCorrupted = ...
        if typeID == "item" then
            SetUpLootSpecialNotice(event, link, quantity, lessAwesome, isUpgraded, nil, nil, nil, isCorrupted)
        end
    elseif event == "SHOW_LOOT_TOAST_UPGRADE" then
        local link, quantity, _, _, baseQuality = ...
        SetUpLootSpecialNotice(event, link, quantity, nil, true, baseQuality)
    elseif event == "SHOW_PVP_FACTION_LOOT_TOAST" or event == "SHOW_RATED_PVP_REWARD_TOAST" then
        local typeID, link, quantity, _, _, _, lessAwesome = ...
        if typeID == "item" then
            SetUpLootSpecialNotice(event, link, quantity, lessAwesome)
        end
    elseif event == "SHOW_LOOT_TOAST_LEGENDARY_LOOTED" then
        local link = ...
        SetUpLootSpecialNotice(event, link, 1, nil, nil, nil, true)
    elseif event == "NEW_RECIPE_LEARNED" then
        SetUpRecipeNotice(event, ...)
    elseif event == "ENTITLEMENT_DELIVERED" or event == "RAF_ENTITLEMENT_DELIVERED" then
        local entitlementType, textureID, name, payloadID = ...
        OnEventEntitlementDelivered(event, entitlementType, textureID, name, payloadID)
    elseif event == "TRANSMOG_COLLECTION_SOURCE_ADDED" then
        local sourceID = ...
        if C_TransmogCollection.PlayerKnowsSource(sourceID) then
            SetUpTransmogNotice(event, sourceID, true, 1)
        end
    elseif event == "TRANSMOG_COLLECTION_SOURCE_REMOVED" then
        local sourceID = ...
        if C_TransmogCollection.PlayerKnowsSource(sourceID) then
            SetUpTransmogNotice(event, sourceID, nil, 1)
        end
    elseif event == "QUEST_TURNED_IN" then
        OnEventQuestTurnedIn(...)
    elseif event == "QUEST_LOOT_RECEIVED" then
        OnEventQuestLootReceived(...)
    end
end)
