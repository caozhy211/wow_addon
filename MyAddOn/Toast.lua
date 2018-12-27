local font = GameFontNormal:GetFont()
local oldMoney
local createdToasts, activeToasts, queuedToasts = {}, {}, {}
local maxActiveToasts = 3
local spacing = 5
local numToasts = 0
local maxSlots = 5
local arrowsConfig = {
    { delay = 0, x = 0 },
    { delay = 0.1, x = -8 },
    { delay = 0.2, x = 16 },
    { delay = 0.3, x = 8 },
    { delay = 0.4, x = -16 },
}
local slots = {
    INVTYPE_HEAD = true, INVTYPE_NECK = true, INVTYPE_SHOULDER = true, INVTYPE_CHEST = true, INVTYPE_ROBE = true,
    INVTYPE_WAIST = true, INVTYPE_LEGS = true, INVTYPE_FEET = true, INVTYPE_WRIST = true, INVTYPE_HAND = true,
    INVTYPE_FINGER = true, INVTYPE_TRINKET = true, INVTYPE_CLOAK = true, INVTYPE_WEAPON = true, INVTYPE_2HWEAPON = true,
    INVTYPE_WEAPONMAINHAND = true, INVTYPE_HOLDABLE = true, INVTYPE_SHIELD = true, INVTYPE_WEAPONOFFHAND = true,
    INVTYPE_RANGED = true, INVTYPE_RANGEDRIGHT = true, INVTYPE_RELIC = true, INVTYPE_THROWN = true,
}
local textsToAnimate = {}
local lootItemPattern = gsub(LOOT_ITEM_SELF, "%%s", "(.+)")
local lootItemPushedPattern = gsub(LOOT_ITEM_PUSHED_SELF, "%%s", "(.+)")
local lootItemMultiplePattern = gsub(gsub(LOOT_ITEM_SELF_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local lootItemPushedMultiplePattern = gsub(gsub(LOOT_ITEM_PUSHED_SELF_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local currencyGainedPattern = gsub(CURRENCY_GAINED, "%%s", "(.+)")
local currencyGainedMultiplePattern = gsub(gsub(CURRENCY_GAINED_MULTIPLE, "%%s", "(.+)"), "%%d", "(%%d+)")
local toasts = CreateFrame("Frame", "MyToastFrame", UIParent)
toasts:SetSize(240, 130)
toasts:SetPoint("BottomLeft", 1380, 0)

local function PostSetAnimatedValue(text, value)
    if text.isMoney then
        text:SetText(GetMoneyString(value))
    else
        text:SetText(value == 1 and "" or value)
    end
end

toasts:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.05 then
        return
    end
    self.elapsed = 0

    for text, targetValue in pairs(textsToAnimate) do
        local newValue

        text.elapsed = text.elapsed + 0.05

        if text.value >= targetValue then
            newValue = floor(Lerp(text.value, targetValue, text.elapsed / 0.6))
        else
            newValue = ceil(Lerp(text.value, targetValue, text.elapsed / 0.6))
        end

        if newValue == targetValue then
            textsToAnimate[text] = nil
        end

        text.value = newValue

        if text.postSetAnimatedValue then
            PostSetAnimatedValue(text, newValue)
        else
            text:SetText(newValue)
        end
    end
end)

local function ShowToast(toast)
    toast.data = toast.data or {}
    if #activeToasts >= maxActiveToasts then
        queuedToasts[#queuedToasts + 1] = toast
        return
    end
    if #activeToasts > 0 then
        toast:SetPoint("Top", activeToasts[#activeToasts], "Bottom", 0, -5)
    else
        toast:SetPoint("Top")
    end
    activeToasts[#activeToasts + 1] = toast
    toast:Show()
end

local function SlotOnEnter(self)
    local toast = self:GetParent()
    toast.animOut:Stop()
    toast:SetAlpha(1)
    GameTooltip:Hide()
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 30, -12)
end

local function SlotOnLeave(self)
    local toast = self:GetParent()
    toast.animOut:Play()
    GameTooltip:Hide()
end

local function ToastOnEnter(self)
    self.animOut:Stop()
    self:SetAlpha(1)
    GameTooltip:Hide()
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT", 30, -12)
end

local function ToastOnLeave(self)
    BattlePetTooltip:Hide()
    GameTooltip:Hide()
    GarrisonFollowerTooltip:Hide()
    GarrisonShipyardFollowerTooltip:Hide()
    ShoppingTooltip1:Hide()
    ShoppingTooltip2:Hide()
    self.animOut:Play()
end

local function ColorBorder(toast, color)
    toast.top:SetColorTexture(color.r, color.g, color.b)
    toast.bottom:SetColorTexture(color.r, color.g, color.b)
    toast.left:SetColorTexture(color.r, color.g, color.b)
    toast.right:SetColorTexture(color.r, color.g, color.b)
end

local function RecycleToast(toast)
    toast:ClearAllPoints()
    toast:SetAlpha(1)
    toast:Hide()

    toast:SetScript("OnEnter", ToastOnEnter)

    toast.data = nil
    toast.animArrows:Stop()
    toast.animIn:Stop()
    toast.animOut:Stop()
    toast.bonus:Hide()
    toast.iconText1:SetText("")
    toast.iconText1.PostSetAnimatedValue = nil
    toast.iconText2:SetText("")
    toast.iconText2.blink:Stop()
    toast.iconText2.PostSetAnimatedValue = nil
    toast.skull:Hide()
    toast.title:SetText("")
    toast.text:SetText("")
    toast.text.PostSetAnimatedValue = nil
    ColorBorder(toast, { r = 0, g = 0, b = 0 })
    toast.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    for i = 1, 5 do
        toast["slot" .. i]:Hide()
        toast["slot" .. i]:SetScript("OnEnter", SlotOnEnter)
        toast["slot" .. i].data = nil
        toast["arrow" .. i]:SetAlpha(0)
    end
    for i = 1, #activeToasts do
        if toast == activeToasts[i] then
            tremove(activeToasts, i)
        end
    end
    for i = 1, #queuedToasts do
        if toast == queuedToasts[i] then
            tremove(queuedToasts, i)
        end
    end
    createdToasts[#createdToasts + 1] = toast

    for i = 1, #activeToasts do
        local activeToast = activeToasts[i]
        activeToast:ClearAllPoints()
        if i == 1 then
            activeToast:SetPoint("Top")
        else
            activeToast:SetPoint("Top", activeToasts[i - 1], "Bottom", 0, -spacing)
        end

        local queuedToast = tremove(queuedToasts, 1)
        if queuedToast then
            ShowToast(queuedToast)
        end
    end
end

local function GetToastName()
    numToasts = numToasts + 1
    return "MyToast" .. numToasts
end

local function CreateBorder(toast)
    local size = toast.borderSize
    local width = toast:GetWidth() - size * 2
    local height = toast:GetHeight()

    toast.top = toast:CreateTexture(nil, "Overlay")
    toast.top:SetSize(width, size)
    toast.top:SetPoint("Top")
    toast.bottom = toast:CreateTexture(nil, "Overlay")
    toast.bottom:SetSize(width, size)
    toast.bottom:SetPoint("Bottom")
    toast.left = toast:CreateTexture(nil, "Overlay")
    toast.left:SetSize(size, height)
    toast.left:SetPoint("Left")
    toast.right = toast:CreateTexture(nil, "Overlay")
    toast.right:SetSize(size, height)
    toast.right:SetPoint("Right")

    ColorBorder(toast, { r = 0, g = 0, b = 0 })
end

local function CreateIconFrame(toast)
    local frame = CreateFrame("Frame", nil, toast)
    local size = toast:GetHeight() - toast.borderSize * 2
    frame:SetSize(size, size)
    frame:SetPoint("Left", toast.borderSize, 0)
    toast.iconFrame = frame

    local icon = frame:CreateTexture()
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetAllPoints()
    toast.icon = icon

    local text1 = frame:CreateFontString()
    text1:SetFont(font, 11, "Outline")
    text1:SetPoint("BottomRight")
    toast.iconText1 = text1

    local text2 = frame:CreateFontString()
    text2:SetFont(font, 11, "Outline")
    text2:SetPoint("Bottom", text1, "Top")
    toast.iconText2 = text2
    local animTextGroup = toast:CreateAnimationGroup()
    animTextGroup:SetToFinalAlpha(true)
    text2.blink = animTextGroup

    local animText = animTextGroup:CreateAnimation("Alpha")
    animText:SetChildKey("iconText2")
    animText:SetOrder(1)
    animText:SetFromAlpha(1)
    animText:SetToAlpha(0)
    animText:SetDuration(0)

    animText:SetChildKey("iconText2")
    animText:SetOrder(2)
    animText:SetFromAlpha(0)
    animText:SetToAlpha(1)
    animText:SetDuration(0.2)

    animText = animTextGroup:CreateAnimation("Alpha")
    animText:SetChildKey("iconText2")
    animText:SetOrder(3)
    animText:SetFromAlpha(1)
    animText:SetToAlpha(0)
    animText:SetStartDelay(0.4)
    animText:SetDuration(0.4)

    local skull = frame:CreateTexture()
    skull:Hide()
    skull:SetSize(16, 20)
    skull:SetPoint("TopRight", -2, -2)
    skull:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-HEROIC")
    skull:SetTexCoord(0 / 32, 16 / 32, 0 / 32, 20 / 32)
    toast.skull = skull

    local animArrowGroup = toast:CreateAnimationGroup()
    animArrowGroup:SetToFinalAlpha(true)
    toast.animArrows = animArrowGroup
    for i = 1, #arrowsConfig do
        local arrow = frame:CreateTexture(nil, "Artwork", "LootUpgradeFrame_ArrowTemplate")
        arrow:ClearAllPoints()
        arrow:SetPoint("Center", frame, "Bottom", arrowsConfig[i].x, 0)
        arrow:SetAlpha(0)
        toast["arrow" .. i] = arrow

        local animArrow = animArrowGroup:CreateAnimation("Alpha")
        animArrow:SetChildKey("arrow" .. i)
        animArrow:SetOrder(1)
        animArrow:SetFromAlpha(1)
        animArrow:SetToAlpha(0)
        animArrow:SetDuration(0)

        animArrow = animArrowGroup:CreateAnimation("Alpha")
        animArrow:SetChildKey("arrow" .. i)
        animArrow:SetSmoothing("In")
        animArrow:SetOrder(2)
        animArrow:SetFromAlpha(0)
        animArrow:SetToAlpha(1)
        animArrow:SetStartDelay(arrowsConfig[i].delay)
        animArrow:SetDuration(0.25)

        animArrow = animArrowGroup:CreateAnimation("Alpha")
        animArrow:SetChildKey("arrow" .. i)
        animArrow:SetSmoothing("Out")
        animArrow:SetOrder(2)
        animArrow:SetFromAlpha(1)
        animArrow:SetToAlpha(0)
        animArrow:SetStartDelay(arrowsConfig[i].delay + 0.25)
        animArrow:SetDuration(0.25)

        animArrow = animArrowGroup:CreateAnimation("Translation")
        animArrow:SetChildKey("arrow" .. i)
        animArrow:SetOrder(2)
        animArrow:SetOffset(0, 60)
        animArrow:SetStartDelay(arrowsConfig[i].delay)
        animArrow:SetDuration(0.5)

        animArrow = animArrowGroup:CreateAnimation("Alpha")
        animArrow:SetChildKey("arrow" .. i)
        animArrow:SetDuration(0)
        animArrow:SetOrder(3)
        animArrow:SetFromAlpha(1)
        animArrow:SetToAlpha(0)
    end
end

local function CreateTitle(toast)
    local title = toast:CreateFontString()
    title:SetFont(font, 12, "Outline")
    title:SetPoint("TopLeft", toast.iconFrame, "TopRight", 2, -4)
    title:SetTextColor(1, 1, 0)
    toast.title = title
end

local function CreateText(toast)
    local text = toast:CreateFontString()
    text:SetFont(font, 12)
    text:SetPoint("Bottom", toast.iconFrame:GetWidth() / 2, 4)
    toast.text = text
end

local function CreateBonus(toast)
    local bonus = toast:CreateTexture()
    bonus:SetAtlas("Bonus-ToastBanner", true)
    bonus:SetPoint("TopRight")
    bonus:Hide()
    toast.bonus = bonus
end

local function CreateGlow(toast)
    local glow = toast:CreateTexture(nil, "Overlay")
    glow:SetSize(318, 152)
    glow:SetPoint("Center")
    glow:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Glow")
    glow:SetTexCoord(5 / 512, 395 / 512, 5 / 256, 167 / 256)
    glow:SetBlendMode("Add")
    glow:SetAlpha(0)
    toast.glow = glow
end

local function CreateShine(toast)
    local shine = toast:CreateTexture(nil, "Overlay")
    shine:SetSize(66, 52)
    shine:SetPoint("BottomLeft", 0, -2)
    shine:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Glow")
    shine:SetTexCoord(403 / 512, 465 / 512, 14 / 256, 62 / 256)
    shine:SetBlendMode("Add")
    shine:SetAlpha(0)
    toast.shine = shine
end

local function CreateAnimInOut(toast)
    local animGroup = toast:CreateAnimationGroup()
    animGroup:SetScript("OnFinished", function()
        if toast.data.showArrows then
            toast.animArrows:Play()
            toast.data.showArrows = false
        end
    end)
    animGroup:SetToFinalAlpha(true)
    toast.animIn = animGroup

    local anim = animGroup:CreateAnimation("Alpha")
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
    anim:SetOffset(168, 0)
    anim:SetDuration(0.85)

    anim = animGroup:CreateAnimation("Alpha")
    anim:SetChildKey("shine")
    anim:SetOrder(3)
    anim:SetFromAlpha(1)
    anim:SetToAlpha(0)
    anim:SetStartDelay(0.35)
    anim:SetDuration(0.5)

    animGroup = toast:CreateAnimationGroup()
    animGroup:SetScript("OnFinished", function()
        RecycleToast(toast)
    end)
    toast.animOut = animGroup

    anim = animGroup:CreateAnimation("Alpha")
    anim:SetOrder(1)
    anim:SetFromAlpha(1)
    anim:SetToAlpha(0)
    anim:SetStartDelay(5)
    anim:SetDuration(1.2)
    animGroup.anim = anim
end

local function CreateSlots(toast)
    local size = (toast:GetHeight() - toast.borderSize * 2) / 2
    for i = 1, maxSlots do
        local slot = CreateFrame("Frame", nil, toast)
        slot:SetSize(size, size)
        slot:Hide()

        slot:SetScript("OnEnter", SlotOnEnter)
        slot:SetScript("OnLeave", SlotOnLeave)

        toast["slot" .. i] = slot

        local slotIcon = slot:CreateTexture()
        slotIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        slotIcon:SetAllPoints()
        slot.icon = slotIcon

        if i == 1 then
            slot:SetPoint("TopRight", -toast.borderSize, -toast.borderSize)
        else
            slot:SetPoint("Right", toast["slot" .. (i - 1)], "Left", -4, 0)
        end
    end
end

local function CreateToast()
    local toast = CreateFrame("Button", GetToastName(), toasts)
    toast:SetSize(toasts:GetWidth(), (toasts:GetHeight() - (maxActiveToasts - 1) * spacing) / maxActiveToasts)
    toast:Hide()
    toast:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
    toast:SetBackdropColor(0, 0, 0, 0.8)

    toast.borderSize = 2
    CreateBorder(toast)
    CreateIconFrame(toast)
    CreateTitle(toast)
    CreateText(toast)
    CreateBonus(toast)
    CreateGlow(toast)
    CreateShine(toast)
    CreateAnimInOut(toast)
    CreateSlots(toast)

    toast:SetScript("OnShow", function(self)
        if self.data.sound then
            PlaySound(self.data.sound)
        end
        self.animIn:Play()
        self.animOut:Play()
    end)

    toast:SetScript("OnEnter", ToastOnEnter)
    toast:SetScript("OnLeave", ToastOnLeave)

    return toast
end

local function FindToast(event, type, value)
    if type and value then
        for i = 1, #activeToasts do
            if (not event or event == activeToasts[i].data.event) and activeToasts[i].data[type] == value then
                return activeToasts[i]
            end
        end
        for i = 1, #queuedToasts do
            if (not event or event == queuedToasts[i].data.event) and queuedToasts[i].data[type] == value then
                return queuedToasts[i], true
            end
        end
    end
end

local function GetToast(event, type, value)
    local toast, isQueued = FindToast(event, type, value)
    local isNew
    if not toast then
        toast = tremove(createdToasts, 1)
        if not toast then
            toast = CreateToast()
        end
        isNew = true
    end
    return toast, isNew, isQueued
end

local function AchievementToast(event, achievementID, flag, isCriteria)
    local toast = GetToast()
    local _, name, points, _, _, _, _, _, _, icon = GetAchievementInfo(achievementID)

    if isCriteria then
        toast.title:SetText(ACHIEVEMENT_PROGRESSED)
        toast.text:SetText(flag)
        toast.iconText1:SetText("")
    else
        toast.title:SetText(ACHIEVEMENT_UNLOCKED)
        toast.text:SetText(name)

        if flag then
            toast.iconText1:SetText("")
        else
            ColorBorder(toast, { r = 0.9, g = 0.75, b = 0.26 })
            toast.iconText1:SetText(points == 0 and "" or points)
        end
    end
    toast.icon:SetTexture(icon)
    toast.data = {
        event = event,
        achID = achievementID,
    }

    ShowToast(toast)
end

local function ArchaeologyToast(event, researchFieldID)
    local toast = GetToast()
    local raceName, raceTexture = GetArchaeologyRaceInfoByID(researchFieldID)

    ColorBorder(toast, { r = 0.9, g = 0.4, b = 0.1 })

    toast.title:SetText(ARCHAEOLOGY_DIGSITE_COMPLETE_TOAST_FRAME_TITLE)
    toast.text:SetText(raceName)
    toast.icon:SetTexture(raceTexture)
    toast.icon:SetTexCoord(0 / 128, 74 / 128, 0 / 128, 88 / 128)

    toast.data = {
        event = event,
        sound = 38326,
    }

    ShowToast(toast)
end

local function SetAnimatedValue(text, value, skip)
    if skip then
        text.value = value
        text.elapsed = 0

        if text.postSetAnimatedValue then
            PostSetAnimatedValue(text, value)
        else
            text:SetText(value)
        end
    else
        text.value = text.value or 1
        text.elapsed = 0

        textsToAnimate[text] = value
    end
end

local function CollectionToast(event, ID, isMount, isPet, isToy)
    local toast, isNew, isQueued = GetToast(event, "collectionID", ID)

    if isNew then
        local color, name, icon, rarity, _

        if isMount then
            name, _, icon = C_MountJournal.GetMountInfoByID(ID)
        elseif isPet then
            local customName
            _, _, _, _, rarity = C_PetJournal.GetPetStats(ID)
            _, customName, _, _, _, _, _, name, icon = C_PetJournal.GetPetInfoByPetID(ID)
            rarity = (rarity or 2) - 1
            color = ITEM_QUALITY_COLORS[rarity]
            name = customName or name
        elseif isToy then
            _, name, icon = C_ToyBox.GetToyInfo(ID)
        end

        if not name then
            return RecycleToast(toast)
        end

        toast.iconText1.postSetAnimatedValue = true

        if rarity then
            ColorBorder(toast, color)
        end

        toast.title:SetText(YOU_EARNED_LABEL)
        toast.text:SetText(name)
        toast.icon:SetTexture(icon)
        SetAnimatedValue(toast.iconText1, 1, true)

        toast.data = {
            collectionID = ID,
            count = 1,
            event = event,
            isMount = isMount,
            isPet = isPet,
            isToy = isToy,
            sound = 31578,
        }

        ShowToast(toast)
    else
        if isQueued then
            toast.data.count = toast.data.count + 1
            SetAnimatedValue(toast.iconText1, toast.data.count, true)
        else
            toast.data.count = toast.data.count + 1
            SetAnimatedValue(toast.iconText1, toast.data.count)

            toast.iconText2:SetText("+1")
            toast.iconText2.blink:Stop()
            toast.iconText2.blink:Play()

            toast.animOut:Stop()
            toast.animOut:Play()
        end
    end
end

local function MissionToast(event, missionID, isAdded)
    local missionInfo = C_Garrison.GetBasicMissionInfo(missionID)
    local rarity = missionInfo.isRare and 3 or 1
    local color = ITEM_QUALITY_COLORS[rarity]
    local level = missionInfo.iLevel == 0 and missionInfo.level or missionInfo.iLevel
    local toast = GetToast()

    if isAdded then
        toast.title:SetText(GARRISON_MISSION_ADDED_TOAST1)
    else
        toast.title:SetText(GARRISON_MISSION_COMPLETE)
    end

    ColorBorder(toast, color)

    toast.text:SetText(missionInfo.name)
    toast.icon:SetTexCoord(0, 1, 0, 1)
    toast.icon:SetAtlas(missionInfo.typeAtlas, false)
    toast.iconText1:SetText(level)

    toast.data = {
        event = event,
        missionID = missionID,
        sound = 44294,
    }

    ShowToast(toast)
end

local function FollowerToastOnEnter(self)
    if self.data then
        local isOK, link = pcall(C_Garrison.GetFollowerLink, self.data.followerID)
        if not isOK then
            isOK, link = pcall(C_Garrison.GetFollowerLinkByID, self.data.followerID)
        end
        if isOK and link then
            local _, garrisonFollowerID, quality, level, itemLevel, ability1, ability2, ability3, ability4, trait1, trait2, trait3, trait4, spec1 = strsplit(":", link)
            garrisonFollowerID = tonumber(garrisonFollowerID)
            local data = {
                garrisonFollowerID = garrisonFollowerID,
                followerTypeID = C_Garrison.GetFollowerTypeByID(garrisonFollowerID),
                collected = false,
                hyperlink = false,
                name = C_Garrison.GetFollowerNameByID(garrisonFollowerID),
                spec = C_Garrison.GetFollowerClassSpecByID(garrisonFollowerID),
                portraitIconID = C_Garrison.GetFollowerPortraitIconIDByID(garrisonFollowerID),
                quality = tonumber(quality),
                level = tonumber(level),
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
end

local function FollowerToast(event, followerTypeID, followerID, name, texPrefix, level, quality, isUpgraded)
    local followerInfo = C_Garrison.GetFollowerInfo(followerID)
    local followerStrings = GarrisonFollowerOptions[followerTypeID].strings
    local upgradeTexture = LOOTUPGRADEFRAME_QUALITY_TEXTURES[quality] or LOOTUPGRADEFRAME_QUALITY_TEXTURES[2]
    local color = ITEM_QUALITY_COLORS[quality]
    local toast = GetToast()

    if followerTypeID == LE_FOLLOWER_TYPE_SHIPYARD_6_2 then
        toast.icon:SetTexCoord(0, 1, 0, 1)
        toast.icon:SetAtlas(texPrefix .. "-Portrait", false)
    else
        local portrait
        if followerInfo.portraitIconID and followerInfo.portraitIconID ~= 0 then
            portrait = followerInfo.portraitIconID
        else
            portrait = "Interface\\Garrison\\Portraits\\FollowerPortrait_NoPortrait"
        end

        toast.icon:SetTexture(portrait)
        toast.icon:SetTexCoord(0, 1, 0, 1)
        toast.iconText1:SetText(level)
    end

    if isUpgraded then
        toast.title:SetText(followerStrings.FOLLOWER_ADDED_UPGRADED_TOAST)

        for i = 1, #arrowsConfig do
            toast["arrow" .. i]:SetAtlas(upgradeTexture.arrow, true)
        end
    else
        toast.title:SetText(followerStrings.FOLLOWER_ADDED_TOAST)
    end

    ColorBorder(toast, color)

    toast.text:SetText(name)

    toast.data = {
        event = event,
        followerID = followerID,
        showArrows = isUpgraded,
        sound = 44296,
    }

    toast:HookScript("OnEnter", FollowerToastOnEnter)
    ShowToast(toast)
end

local function BuildingToast(event, buildingName)
    local toast = GetToast()

    toast.title:SetText(GARRISON_UPDATE)
    toast.text:SetText(buildingName)
    toast.icon:SetTexture("Interface\\Icons\\Garrison_Build")

    toast.data = {
        event = event,
        sound = 44295,
    }

    ShowToast(toast)
end

local function TalentToast(event, talentID)
    local talent = C_Garrison.GetTalent(talentID)
    local toast = GetToast()

    toast.title:SetText(GARRISON_TALENT_ORDER_ADVANCEMENT)
    toast.text:SetText(talent.name)
    toast.icon:SetTexture(talent.icon)

    toast.data = {
        event = event,
        talentID = talentID,
        sound = 73280,
    }

    ShowToast(toast)
end

local function InstanceToastSlotOnEnter(self)
    local data = self.data
    if data then
        if data.type == "item" then
            GameTooltip:SetHyperlink(data.link)
        elseif data.type == "xp" then
            GameTooltip:AddLine(YOU_RECEIVED_LABEL)
            GameTooltip:AddLine(format(BONUS_OBJECTIVE_EXPERIENCE_FORMAT, data.count), 1, 1, 1)
        elseif data.type == "money" then
            GameTooltip:AddLine(YOU_RECEIVED_LABEL)
            GameTooltip:AddLine(GetMoneyString(data.count), 1, 1, 1)
        end
        GameTooltip:Show()
    end
end

local function InstanceToast(event, name, subTypeID, textureFile, moneyReward, xpReward, numItemRewards, isScenario, isScenarioBonusComplete)
    local toast = GetToast()
    local usedSlots = 0
    local sound

    if moneyReward and moneyReward > 0 then
        usedSlots = usedSlots + 1
        local slot = toast["slot" .. usedSlots]

        if slot then
            slot.icon:SetTexture("Interface\\Icons\\inv_misc_coin_02")

            slot.data = {
                type = "money",
                count = moneyReward,
            }

            slot:HookScript("OnEnter", InstanceToastSlotOnEnter)
            slot:Show()
        end
    end

    if xpReward and xpReward > 0 and UnitLevel("player") < MAX_PLAYER_LEVEL then
        usedSlots = usedSlots + 1
        local slot = toast["slot" .. usedSlots]

        if slot then
            slot.icon:SetTexture("Interface\\Icons\\xp_icon")

            slot.data = {
                type = "xp",
                count = xpReward,
            }

            slot:HookScript("OnEnter", InstanceToastSlotOnEnter)
            slot:Show()
        end
    end

    for i = 1, numItemRewards or 0 do
        local link = GetLFGCompletionRewardItemLink(i)

        if link then
            usedSlots = usedSlots + 1
            local slot = toast["slot" .. usedSlots]

            if slot then
                local texture = GetLFGCompletionRewardItem(i)
                texture = texture or "Interface\\Icons\\INV_Box_02"

                slot.icon:SetTexture(texture)

                slot.data = {
                    type = "item",
                    link = link,
                }

                slot:HookScript("OnEnter", InstanceToastSlotOnEnter)
                slot:Show()
            end
        end
    end

    if isScenario then
        if isScenarioBonusComplete then
            toast.bonus:Show()
        end

        toast.title:SetText(SCENARIO_COMPLETED)

        sound = 31754
    else
        if subTypeID == LFG_SUBTYPEID_HEROIC then
            toast.skull:Show()
        end

        toast.title:SetText(DUNGEON_COMPLETED)

        sound = 17316
    end

    toast.text:SetText(name)
    toast.icon:SetTexture(textureFile or "Interface\\LFGFrame\\LFGIcon-Dungeon")

    toast.data = {
        event = event,
        usedSlots = usedSlots,
        sound = sound,
    }

    ShowToast(toast)
end

local function SanitizeLink(link)
    if not link or link == "[]" or link == "" then
        return
    end

    local temp, name = strmatch(link, "|H(.+)|h%[(.+)%]|h")
    link = temp or link

    local links = { strsplit(":", link) }

    if links[1] ~= "item" then
        return link, link, links[1], tonumber(links[2]), name
    end

    if links[12] ~= "" then
        links[12] = ""
        tremove(links, 15 + (tonumber(links[14]) or 0))
    end

    return table.concat(links, ":"), link, links[1], tonumber(links[2]), name
end

local function GetItemLevel(itemLink)
    local _, _, _, _, _, _, _, _, itemEquipLoc, _, _, itemClassID, itemSubClassID = GetItemInfo(itemLink)

    if (itemClassID == 3 and itemSubClassID == 11) or slots[itemEquipLoc] then
        return GetDetailedItemLevelInfo(itemLink) or 0
    end

    return 0
end

local function LootCommonToastOnEnter(self)
    if strfind(self.data.tooltipLink, "item") then
        GameTooltip:SetHyperlink(self.data.tooltipLink)
        GameTooltip:Show()
    elseif strfind(self.data.tooltipLink, "battlepet") then
        local _, speciesID, level, breedQuality, maxHealth, power, speed = strsplit(":", self.data.tooltipLink)
        BattlePetToolTip_Show(tonumber(speciesID), tonumber(level), tonumber(breedQuality), tonumber(maxHealth), tonumber(power), tonumber(speed))
    end
end

local function LootCommonToast(event, link, quantity)
    local sanitizedLink, originalLink, linkType, itemID = SanitizeLink(link)
    local toast, isNew, isQueued

    toast, isQueued = FindToast(nil, "itemID", itemID)

    if toast then
        if toast.data.event ~= event then
            return
        end
    else
        toast, isNew, isQueued = GetToast(event, "link", sanitizedLink)
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

        if name and (quality and quality >= 0 and quality <= 5) then
            local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[1]

            toast.iconText1.postSetAnimatedValue = true

            ColorBorder(toast, color)

            local iLevel = GetItemLevel(originalLink)
            if iLevel > 0 then
                name = "[" .. color.hex .. iLevel .. "|r] " .. name
            end

            toast.title:SetText(YOU_RECEIVED_LABEL)
            toast.text:SetText(name)
            toast.icon:SetTexture(icon)
            SetAnimatedValue(toast.iconText1, quantity, true)

            toast.data = {
                count = quantity,
                event = event,
                link = sanitizedLink,
                tooltipLink = originalLink,
                itemID = itemID,
                sound = 31578,
            }

            toast:HookScript("OnEnter", LootCommonToastOnEnter)
            ShowToast(toast)
        else
            RecycleToast(toast)
        end
    else
        if isQueued then
            toast.data.count = toast.data.count + quantity
            SetAnimatedValue(toast.iconText1, toast.data.count, true)
        else
            toast.data.count = toast.data.count + quantity
            SetAnimatedValue(toast.iconText1, toast.data.count)

            toast.iconText2:SetText("+" .. quantity)
            toast.iconText2.blink:Stop()
            toast.iconText2.blink:Play()

            toast.animOut:Stop()
            toast.animOut:Play()
        end
    end
end

local function LootCurrencyToastOnEnter(self)
    GameTooltip:SetHyperlink(self.data.tooltipLink)
    GameTooltip:Show()
end

local function LootCurrencyToast(event, link, quantity)
    local sanitizedLink, originalLink = SanitizeLink(link)
    local toast, isNew, isQueued = GetToast(event, "link", sanitizedLink)

    if isNew then
        local name, _, icon, _, _, _, _, quality = GetCurrencyInfo(link)
        local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[1]

        ColorBorder(toast, color)

        toast.title:SetText(YOU_RECEIVED_LABEL)
        toast.text:SetText(name)
        toast.icon:SetTexture(icon)
        SetAnimatedValue(toast.iconText1, quantity, true)

        toast.data = {
            event = event,
            count = quantity,
            link = sanitizedLink,
            tooltipLink = originalLink,
            sound = 31578,
        }

        toast:HookScript("OnEnter", LootCurrencyToastOnEnter)
        ShowToast(toast)
    else
        if isQueued then
            toast.data.count = toast.data.count + quantity
            SetAnimatedValue(toast.iconText1, toast.data.count, true)
        else
            toast.data.count = toast.data.count + quantity
            SetAnimatedValue(toast.iconText1, toast.data.count)

            toast.iconText2:SetText("+" .. quantity)
            toast.iconText2.blink:Stop()
            toast.iconText2.blink:Play()

            toast.animOut:Stop()
            toast.animOut:Play()
        end
    end
end

local function LootGoldToast(event, quantity)
    local toast, isNew, isQueued = GetToast(nil, "event", event)

    if isNew then
        toast.text.postSetAnimatedValue = true
        toast.text.isMoney = true

        ColorBorder(toast, { r = 0.9, g = 0.75, b = 0.26 })

        toast.title:SetText(YOU_RECEIVED_LABEL)
        SetAnimatedValue(toast.text, quantity, true)
        toast.icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_02")

        toast.data = {
            event = event,
            count = quantity,
            sound = 865,
        }

        ShowToast(toast)
    else
        if isQueued then
            toast.data.count = toast.data.count + quantity
            SetAnimatedValue(toast.text, toast.data.count, true)
        else
            toast.data.count = toast.data.count + quantity
            SetAnimatedValue(toast.text, toast.data.count)

            toast.animOut:Stop()
            toast.animOut:Play()
        end
    end
end

local function LootSpecialToastOnEnter(self)
    if self.data then
        if strfind(self.data.tooltipLink, "item") then
            GameTooltip:SetHyperlink(self.data.tooltipLink)
            GameTooltip:Show()
        elseif strfind(self.data.tooltipLink, "battlepet") then
            local _, speciesID, level, breedQuality, maxHealth, power, speed = strsplit(":", self.data.tooltipLink)
            BattlePetToolTip_Show(tonumber(speciesID), tonumber(level), tonumber(breedQuality), tonumber(maxHealth), tonumber(power), tonumber(speed))
        end
    end
end

local function LootSpecialToast(event, link, quantity, rollType, roll, isItem, isHonor, isPersonal, lessAwesome, isUpgraded, baseQuality, isLegendary, isStorePurchase, isAzerite)
    if isItem then
        if link then
            local sanitizedLink, originalLink, _, itemID = SanitizeLink(link)
            local toast, isNew, isQueued = GetToast(event, "link", sanitizedLink)

            if isNew then
                local name, _, quality, _, _, _, _, _, _, icon = GetItemInfo(originalLink)

                if name and (quality and quality >= 0 and quality <= 5) then
                    local color = ITEM_QUALITY_COLORS[quality] or ITEM_QUALITY_COLORS[1]
                    local title = YOU_WON_LABEL
                    local sound = 31578

                    toast.iconText1.postSetAnimatedValue = true

                    if isPersonal or lessAwesome then
                        title = YOU_RECEIVED_LABEL

                        if lessAwesome then
                            sound = 51402
                        end
                    end

                    if isUpgraded then
                        if baseQuality and baseQuality < quality then
                            title = LOOTUPGRADEFRAME_TITLE:format("%s%s|r"):format(color.hex, _G["ITEM_QUALITY" .. quality .. "_DESC"])
                        else
                            title = ITEM_UPGRADED_LABEL
                        end

                        sound = 51561

                        local upgradeTexture = LOOTUPGRADEFRAME_QUALITY_TEXTURES[quality] or LOOTUPGRADEFRAME_QUALITY_TEXTURES[2]

                        for i = 1, #arrowsConfig do
                            toast["arrow" .. i]:SetAtlas(upgradeTexture.arrow, true)
                        end
                    end

                    if isLegendary then
                        title = LEGENDARY_ITEM_LOOT_LABEL
                        sound = 63971
                    end

                    if isStorePurchase then
                        title = BLIZZARD_STORE_PURCHASE_COMPLETE
                        sound = 39517
                    end

                    if isAzerite then
                        title = AZERITE_EMPOWERED_ITEM_LOOT_LABEL
                        sound = 118238
                    end

                    if rollType == LOOT_ROLL_TYPE_NEED then
                        title = TITLE_NEED_TEMPLATE:format(title, roll)
                    elseif rollType == LOOT_ROLL_TYPE_GREED then
                        title = TITLE_GREED_TEMPLATE:format(title, roll)
                    elseif rollType == LOOT_ROLL_TYPE_DISENCHANT then
                        title = TITLE_DE_TEMPLATE:format(title, roll)
                    end

                    ColorBorder(toast, color)

                    local iLevel = GetItemLevel(originalLink)
                    if iLevel > 0 then
                        name = "[" .. color.hex .. iLevel .. "|r] " .. name
                    end

                    toast.title:SetText(title)
                    toast.text:SetText(name)
                    toast.icon:SetTexture(icon)
                    SetAnimatedValue(toast.iconText1, quantity, true)

                    toast.data = {
                        count = quantity,
                        event = event,
                        itemID = itemID,
                        link = sanitizedLink,
                        tooltipLink = originalLink,
                        showArrows = isUpgraded,
                        sound = sound,
                    }

                    toast:HookScript("OnEnter", LootSpecialToastOnEnter)
                    ShowToast(toast)
                else
                    RecycleToast(toast)
                end
            else
                if rollType then
                    if rollType == LOOT_ROLL_TYPE_NEED then
                        toast.title:SetFormattedText(TITLE_NEED_TEMPLATE, YOU_WON_LABEL, roll)
                    elseif rollType == LOOT_ROLL_TYPE_GREED then
                        toast.title:SetFormattedText(TITLE_GREED_TEMPLATE, YOU_WON_LABEL, roll)
                    elseif rollType == LOOT_ROLL_TYPE_DISENCHANT then
                        toast.title:SetFormattedText(TITLE_DE_TEMPLATE, YOU_WON_LABEL, roll)
                    end
                end

                if isQueued then
                    toast.data.count = toast.data.count + quantity
                    SetAnimatedValue(toast.iconText1, toast.data.count, true)
                else
                    toast.data.count = toast.data.count + quantity
                    SetAnimatedValue(toast.iconText1, toast.data.count)

                    toast.iconText2:SetText("+" .. quantity)
                    toast.iconText2.blink:Stop()
                    toast.iconText2.blink:Play()

                    toast.animOut:Stop()
                    toast.animOut:Play()
                end
            end
        end
    elseif isHonor then
        local toast, isNew, isQueued = GetToast(event, "isHonor", true)

        if isNew then
            toast.title:SetText(YOU_RECEIVED_LABEL)
            toast.text:SetText(HONOR_POINTS)
            toast.icon:SetTexture("Interface\\Icons\\Achievement_LegionPVPTier4")
            SetAnimatedValue(toast.iconText1, quantity, true)

            toast.data = {
                count = quantity,
                event = event,
                isHonor = true,
                sound = 31578,
            }

            ShowToast(toast)
        else
            if isQueued then
                toast.data.count = toast.data.count + quantity
                SetAnimatedValue(toast.iconText1, toast.data.count, true)
            else
                toast.data.count = toast.data.count + quantity
                SetAnimatedValue(toast.iconText1, toast.data.count)

                toast.iconText2:SetText("+" .. quantity)
                toast.iconText2.blink:Stop()
                toast.iconText2.blink:Play()

                toast.animOut:Stop()
                toast.animOut:Play()
            end
        end
    end
end

local function StoreProductDelivered(event, payloadID)
    local _, link = GetItemInfo(payloadID)

    if link then
        LootSpecialToast(event, link, 1, nil, nil, nil, true, nil, nil, nil, nil, nil, nil, true)
    else
        return C_Timer.After(0.25, function()
            StoreProductDelivered(event, payloadID)
        end)
    end
end

local function RecipeToastOnEnter(self)
    if self.data then
        GameTooltip:SetSpellByID(self.data.recipeID)
        GameTooltip:Show()
    end
end

local function RecipeToast(event, recipeID)
    local tradeSkillID = C_TradeSkillUI.GetTradeSkillLineForRecipe(recipeID)

    if tradeSkillID then
        local recipeName = GetSpellInfo(recipeID)

        if recipeName then
            local toast = GetToast()
            local rank = GetSpellRank(recipeID)
            local rankTexture = ""

            if rank == 1 then
                rankTexture = "|TInterface\\LootFrame\\toast-star:12:12:0:0:32:32:0:21:0:21|t"
            elseif rank == 2 then
                rankTexture = "|TInterface\\LootFrame\\toast-star-2:12:24:0:0:64:32:0:42:0:21|t"
            elseif rank == 3 then
                rankTexture = "|TInterface\\LootFrame\\toast-star-3:12:36:0:0:64:32:0:64:0:21|t"
            end

            toast.title:SetText(rank and rank > 1 and UPGRADED_RECIPE_LEARNED_TITLE or NEW_RECIPE_LEARNED_TITLE)
            toast.text:SetText(recipeName)
            toast.icon:SetTexture(C_TradeSkillUI.GetTradeSkillTexture(tradeSkillID))
            toast.iconText1:SetText(rankTexture)

            toast.data = {
                event = event,
                recipeID = recipeID,
                tradeSkillID = tradeSkillID,
                sound = 73919,
            }

            toast:HookScript("OnEnter", RecipeToastOnEnter)
            ShowToast(toast)
        end
    end
end

local function TransmogToast(event, sourceID, isAdded, attempt)
    local _, _, _, icon, _, _, link = C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
    local name
    link, _, _, _, name = SanitizeLink(link)

    if not link then
        return attempt < 4 and C_Timer.After(0.25, function()
            TransmogToast(event, sourceID, isAdded, attempt + 1)
        end)
    end

    local toast, isNew, isQueued = GetToast(nil, "sourceID", sourceID)

    if isNew then
        if isAdded then
            toast.title:SetText("外觀已加入")
        else
            toast.title:SetText("外觀已移除")
        end

        ColorBorder(toast, { r = 1, g = 0.5, b = 1 })

        toast.text:SetText(name)
        toast.icon:SetTexture(icon)

        toast.data = {
            event = event,
            link = link,
            sourceID = sourceID,
            sound = 38326,
        }

        ShowToast(toast)
    else
        if isAdded then
            toast.title:SetText("外觀已加入")
        else
            toast.title:SetText("外觀已移除")
        end

        if not isQueued then
            toast.animOut:Stop()
            toast.animOut:Play()
        end
    end
end

local function IsAppearanceKnown(sourceID)
    local data = C_TransmogCollection.GetSourceInfo(sourceID)
    local sources = C_TransmogCollection.GetAppearanceSources(data.visualID)

    if sources then
        for i = 1, #sources do
            if sources[i].isCollected and sourceID ~= sources[i].sourceID then
                return true
            end
        end
    else
        return nil
    end

    return false
end

local function TransmogCollectionSourceAdded(event, sourceID, attempt)
    if C_TransmogCollection.PlayerKnowsSource(sourceID) then
        local isKnown = IsAppearanceKnown(sourceID)
        attempt = attempt or 1

        if attempt < 4 then
            if isKnown == false then
                TransmogToast(event, sourceID, true, 1)
            elseif isKnown == nil then
                C_Timer.After(0.25, function()
                    TransmogCollectionSourceAdded(event, sourceID, attempt + 1)
                end)
            end
        end
    end
end

local function TransmogCollectionSourceRemoved(event, sourceID, attempt)
    if C_TransmogCollection.PlayerKnowsSource(sourceID) then
        local isKnown = IsAppearanceKnown(sourceID, true)
        attempt = attempt or 1

        if attempt < 4 then
            if isKnown == false then
                TransmogToast(event, sourceID, nil, 1)
            elseif isKnown == nil then
                C_Timer.After(0.25, function()
                    TransmogCollectionSourceRemoved(event, sourceID, attempt + 1)
                end)
            end
        end
    end
end

local function WorldToastSlotOnEnter(self)
    local data = self.data
    if data then
        if data.type == "item" then
            GameTooltip:SetHyperlink(data.link)
        elseif data.type == "xp" then
            GameTooltip:AddLine(YOU_RECEIVED_LABEL)
            GameTooltip:AddLine(format(BONUS_OBJECTIVE_EXPERIENCE_FORMAT, data.count), 1, 1, 1)
        elseif data.type == "money" then
            GameTooltip:AddLine(YOU_RECEIVED_LABEL)
            GameTooltip:AddLine(GetMoneyString(data.count), 1, 1, 1)
        elseif data.type == "currency" then
            GameTooltip:AddLine(YOU_RECEIVED_LABEL)
            GameTooltip:AddLine(format("%s|T%s:0|t", data.count, data.texture))
        end
        GameTooltip:Show()
    end
end

local function WorldToast(event, isUpdate, questID, name, moneyReward, xpReward, numCurrencyRewards, itemReward, isInvasion, isInvasionBonusComplete)
    local toast, isNew, isQueued = GetToast(nil, "questID", questID)

    if isUpdate and isNew then
        RecycleToast(toast)
        return
    end

    if isNew then
        local usedSlots = 0
        local sound

        if moneyReward and moneyReward > 0 then
            usedSlots = usedSlots + 1
            local slot = toast["slot" .. usedSlots]

            if slot then
                slot.icon:SetTexture("Interface\\Icons\\inv_misc_coin_02")

                slot.data = {
                    type = "money",
                    count = moneyReward,
                }

                slot:HookScript("OnEnter", WorldToastSlotOnEnter)
                slot:Show()
            end
        end

        if xpReward and xpReward > 0 and UnitLevel("player") < MAX_PLAYER_LEVEL then
            usedSlots = usedSlots + 1
            local slot = toast["slot" .. usedSlots]

            if slot then
                slot.icon:SetTexture("Interface\\Icons\\xp_icon")

                slot.data = {
                    type = "xp",
                    count = xpReward,
                }

                slot:HookScript("OnEnter", WorldToastSlotOnEnter)
                slot:Show()
            end
        end

        for i = 1, numCurrencyRewards or 0 do
            usedSlots = usedSlots + 1
            local slot = toast["slot" .. usedSlots]

            if slot then
                local _, texture, count = GetQuestLogRewardCurrencyInfo(i, questID)
                texture = texture or "Interface\\Icons\\INV_Box_02"

                slot.icon:SetTexture(texture)

                slot.data = {
                    type = "currency",
                    count = count,
                    texture = texture,
                }

                slot:HookScript("OnEnter", WorldToastSlotOnEnter)
                slot:Show()
            end
        end

        if isInvasion then
            if isInvasionBonusComplete then
                toast.bonus:Show()
            end

            ColorBorder(toast, 60 / 255, 255 / 255, 38 / 255)

            toast.title:SetText(SCENARIO_INVASION_COMPLETE)
            toast.icon:SetTexture("Interface\\Icons\\Ability_Warlock_DemonicPower")

            sound = 31754
        else
            local _, _, worldQuestType, rarity, _, tradeSkillLineIndex = GetQuestTagInfo(questID)
            local color = WORLD_QUEST_QUALITY_COLORS[rarity] or WORLD_QUEST_QUALITY_COLORS[1]

            if worldQuestType == LE_QUEST_TAG_TYPE_PVP then
                toast.icon:SetTexture("Interface\\Icons\\achievement_arena_2v2_1")
            elseif worldQuestType == LE_QUEST_TAG_TYPE_PET_BATTLE then
                toast.icon:SetTexture("Interface\\Icons\\INV_Pet_BattlePetTraining")
            elseif worldQuestType == LE_QUEST_TAG_TYPE_PROFESSION and tradeSkillLineIndex then
                local _, icon = GetProfessionInfo(tradeSkillLineIndex)
                toast.icon:SetTexture(icon)
            elseif worldQuestType == LE_QUEST_TAG_TYPE_DUNGEON or worldQuestType == LE_QUEST_TAG_TYPE_RAID then
                toast.icon:SetTexture("Interface\\Icons\\INV_Misc_Bone_Skull_02")
            else
                toast.icon:SetTexture("Interface\\Icons\\Achievement_Quests_Completed_TwilightHighlands")
            end

            ColorBorder(toast, color)

            toast.title:SetText(WORLD_QUEST_COMPLETE)

            sound = 73277
        end

        toast.text:SetText(name)

        toast.data = {
            event = event,
            questID = questID,
            usedSlots = usedSlots,
            sound = sound,
        }

        ShowToast(toast)
    else
        if itemReward then
            toast.data.usedSlots = toast.data.usedSlots + 1
            local slot = toast["slot" .. toast.data.usedSlots]

            if slot then
                local _, _, _, _, texture = GetItemInfoInstant(itemReward)
                texture = texture or "Interface\\Icons\\INV_Box_02"

                slot.icon:SetTexture(texture)

                slot.data = {
                    type = "item",
                    link = itemReward,
                }

                slot:HookScript("OnEnter", WorldToastSlotOnEnter)
                slot:Show()
            end
        end

        if not isQueued then
            toast.animOut:Stop()
            toast.animOut:Play()
        end
    end
end

local function QuestTurnedIn(event, questID)
    if QuestUtils_IsQuestWorldQuest(questID) then
        WorldToast(event, false, questID, C_TaskQuest.GetQuestInfoByQuestID(questID), GetQuestLogRewardMoney(questID), GetQuestLogRewardXP(questID), GetNumQuestLogRewardCurrencies(questID))
    end
end

toasts:RegisterEvent("PLAYER_ENTERING_WORLD")
toasts:RegisterEvent("ACHIEVEMENT_EARNED")
toasts:RegisterEvent("CRITERIA_EARNED")
toasts:RegisterEvent("ARTIFACT_DIGSITE_COMPLETE")
toasts:RegisterEvent("NEW_MOUNT_ADDED")
toasts:RegisterEvent("NEW_PET_ADDED")
toasts:RegisterEvent("TOYS_UPDATED")
toasts:RegisterEvent("GARRISON_FOLLOWER_ADDED")
toasts:RegisterEvent("GARRISON_MISSION_FINISHED")
toasts:RegisterEvent("GARRISON_RANDOM_MISSION_ADDED")
toasts:RegisterEvent("GARRISON_BUILDING_ACTIVATABLE")
toasts:RegisterEvent("GARRISON_TALENT_COMPLETE")
toasts:RegisterEvent("LFG_COMPLETION_REWARD")
toasts:RegisterEvent("CHAT_MSG_LOOT")
toasts:RegisterEvent("CHAT_MSG_CURRENCY")
toasts:RegisterEvent("PLAYER_MONEY")
toasts:RegisterEvent("AZERITE_EMPOWERED_ITEM_LOOTED")
toasts:RegisterEvent("LOOT_ITEM_ROLL_WON")
toasts:RegisterEvent("SHOW_LOOT_TOAST_LEGENDARY_LOOTED")
toasts:RegisterEvent("SHOW_LOOT_TOAST_UPGRADE")
toasts:RegisterEvent("SHOW_LOOT_TOAST")
toasts:RegisterEvent("SHOW_PVP_FACTION_LOOT_TOAST")
toasts:RegisterEvent("SHOW_RATED_PVP_REWARD_TOAST")
toasts:RegisterEvent("STORE_PRODUCT_DELIVERED")
toasts:RegisterEvent("NEW_RECIPE_LEARNED")
toasts:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_ADDED")
toasts:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_REMOVED")
toasts:RegisterEvent("SCENARIO_COMPLETED")
toasts:RegisterEvent("QUEST_TURNED_IN")
toasts:RegisterEvent("QUEST_LOOT_RECEIVED")

toasts:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        oldMoney = GetMoney()
    elseif event == "ACHIEVEMENT_EARNED" then
        local achievementID, alreadyEarned = ...
        AchievementToast(event, achievementID, alreadyEarned)
    elseif event == "CRITERIA_EARNED" then
        local achievementID, criteriaString = ...
        AchievementToast(event, achievementID, criteriaString, true)
    elseif event == "ARTIFACT_DIGSITE_COMPLETE" then
        local researchFieldID = ...
        ArchaeologyToast(event, researchFieldID)
    elseif event == "NEW_MOUNT_ADDED" then
        local mountID = ...
        CollectionToast(event, mountID, true)
    elseif event == "NEW_PET_ADDED" then
        local petID = ...
        CollectionToast(event, petID, nil, true)
    elseif event == "TOYS_UPDATED" then
        local toyID, isNew = ...
        if toyID and isNew then
            CollectionToast(event, toyID, nil, nil, true)
        end
    elseif event == "GARRISON_FOLLOWER_ADDED" then
        local followerID, name, _, level, quality, isUpgraded, texPrefix, followerTypeID = ...
        FollowerToast(event, followerTypeID, followerID, name, texPrefix, level, quality, isUpgraded)
    elseif event == "GARRISON_MISSION_FINISHED" then
        local _, missionID = ...
        local _, instanceType = GetInstanceInfo()
        local validInstance = false

        if instanceType == "none" or C_Garrison.IsOnGarrisonMap() then
            validInstance = true
        end

        if validInstance then
            MissionToast(event, missionID)
        end
    elseif event == "GARRISON_RANDOM_MISSION_ADDED" then
        local _, missionID = ...
        MissionToast(event, missionID, true)
    elseif event == "GARRISON_BUILDING_ACTIVATABLE" then
        local buildingName = ...
        BuildingToast(event, buildingName)
    elseif event == "GARRISON_TALENT_COMPLETE" then
        local garrisonType, doAlert = ...
        if doAlert then
            TalentToast(event, C_Garrison.GetCompleteTalent(garrisonType))
        end
    elseif event == "LFG_COMPLETION_REWARD" then
        if C_Scenario.IsInScenario() and not C_Scenario.TreatScenarioAsDungeon() then
            local _, _, _, _, hasBonusStep, isBonusStepComplete, _, _, _, scenarioType = C_Scenario.GetInfo()

            if scenarioType ~= LE_SCENARIO_TYPE_LEGION_INVASION then
                local name, _, subTypeID, textureFile, moneyBase, moneyVar, experienceBase, experienceVar, numStrangers, numItemRewards = GetLFGCompletionReward()

                InstanceToast(event, name, subTypeID, textureFile, moneyBase + moneyVar * numStrangers, experienceBase + experienceVar * numStrangers, numItemRewards, true, hasBonusStep and isBonusStepComplete)
            end
        else
            local name, _, subTypeID, textureFile, moneyBase, moneyVar, experienceBase, experienceVar, numStrangers, numItemRewards = GetLFGCompletionReward()

            InstanceToast(event, name, subTypeID, textureFile, moneyBase + moneyVar * numStrangers, experienceBase + experienceVar * numStrangers, numItemRewards)
        end
    elseif event == "CHAT_MSG_LOOT" then
        local message, _, _, _, target = ...
        if strsplit("-", target) ~= UnitName("player") then
            return
        end

        local link, quantity = strmatch(message, lootItemMultiplePattern)

        if not link then
            link, quantity = strmatch(message, lootItemPushedMultiplePattern)

            if not link then
                quantity, link = 1, strmatch(message, lootItemPattern)

                if not link then
                    quantity, link = 1, strmatch(message, lootItemPushedPattern)

                    if not link then
                        return
                    end
                end
            end
        end

        C_Timer.After(0.125, function()
            LootCommonToast(event, link, tonumber(quantity) or 0)
        end)
    elseif event == "CHAT_MSG_CURRENCY" then
        local message = ...
        local link, quantity = strmatch(message, currencyGainedMultiplePattern)

        if not link then
            quantity, link = 1, strmatch(message, currencyGainedPattern)

            if not link then
                return
            end
        end

        LootCurrencyToast(event, link, tonumber(quantity) or 0)
    elseif event == "PLAYER_MONEY" then
        local currentMoney = GetMoney()

        if currentMoney - oldMoney > 0 then
            LootGoldToast(event, currentMoney - oldMoney)
        end

        oldMoney = currentMoney
    elseif event == "AZERITE_EMPOWERED_ITEM_LOOTED" then
        local link = ...
        LootSpecialToast(event, link, 1, nil, nil, true, nil, nil, nil, nil, nil, nil, nil, true)
    elseif event == "LOOT_ITEM_ROLL_WON" then
        local link, quantity, rollType, roll, isUpgraded = ...
        LootSpecialToast(event, link, quantity, rollType, roll, true, nil, nil, nil, isUpgraded)
    elseif event == "SHOW_LOOT_TOAST" then
        local typeID, link, quantity, _, _, isPersonal, _, lessAwesome, isUpgraded = ...
        LootSpecialToast(event, link, quantity, nil, nil, typeID == "item", typeID == "honor", isPersonal, lessAwesome, isUpgraded)
    elseif event == "SHOW_LOOT_TOAST_UPGRADE" then
        local link, quantity, _, _, baseQuality = ...
        LootSpecialToast(event, link, quantity, nil, nil, true, nil, nil, nil, true, baseQuality)
    elseif event == "SHOW_PVP_FACTION_LOOT_TOAST" then
        local typeID, link, quantity, _, _, isPersonal, lessAwesome = ...
        LootSpecialToast(event, link, quantity, nil, nil, typeID == "item", typeID == "honor", isPersonal, lessAwesome)
    elseif event == "SHOW_RATED_PVP_REWARD_TOAST" then
        local typeID, link, quantity, _, _, isPersonal, lessAwesome = ...
        LootSpecialToast(event, link, quantity, nil, nil, typeID == "item", typeID == "honor", isPersonal, lessAwesome)
    elseif event == "SHOW_LOOT_TOAST_LEGENDARY_LOOTED" then
        local link = ...
        LootSpecialToast(event, link, 1, nil, nil, true, nil, nil, nil, nil, nil, true)
    elseif event == "STORE_PRODUCT_DELIVERED" then
        local _, _, _, payloadID = ...
        StoreProductDelivered(event, payloadID)
    elseif event == "NEW_RECIPE_LEARNED" then
        local recipeID = ...
        RecipeToast(event, recipeID)
    elseif event == "TRANSMOG_COLLECTION_SOURCE_ADDED" then
        local sourceID, attempt = ...
        TransmogCollectionSourceAdded(event, sourceID, attempt)
    elseif event == "TRANSMOG_COLLECTION_SOURCE_REMOVED" then
        local sourceID, attempt = ...
        TransmogCollectionSourceRemoved(event, sourceID, attempt)
    elseif event == "SCENARIO_COMPLETED" then
        local questID = ...
        local scenarioName, _, _, _, hasBonusStep, isBonusStepComplete, _, xp, money, scenarioType, areaName = C_Scenario.GetInfo()

        if scenarioType == LE_SCENARIO_TYPE_LEGION_INVASION then
            if questID then
                WorldToast(event, false, questID, areaName or scenarioName, money, xp, nil, nil, true, hasBonusStep and isBonusStepComplete)
            end
        end
    elseif event == "QUEST_TURNED_IN" then
        local questID = ...
        QuestTurnedIn(event, questID)
    elseif event == "QUEST_LOOT_RECEIVED" then
        local questID, itemLink = ...
        if not FindToast(nil, "questID", questID) then
            QuestTurnedIn("QUEST_TURNED_IN", questID)
        end

        WorldToast(event, true, questID, nil, nil, nil, nil, itemLink)
    end
end)

if not ArchaeologyFrame then
    local hooked = false

    hooksecurefunc("ArchaeologyFrame_LoadUI", function()
        if not hooked then
            ArcheologyDigsiteProgressBar.AnimOutAndTriggerToast:SetScript("OnFinished", function(self)
                self:GetParent():Hide()
            end)

            hooked = true
        end
    end)
else
    ArcheologyDigsiteProgressBar.AnimOutAndTriggerToast:SetScript("OnFinished", function(self)
        self:GetParent():Hide()
    end)
end

BonusRollFrame.FinishRollAnim:SetScript("OnFinished", function(self)
    local frame = self:GetParent()
    LootSpecialToast("LOOT_ITEM_BONUS_ROLL_WON", frame.rewardLink, frame.rewardQuantity, nil, nil, frame .rewardType == "item" or frame.rewardType == "artifact_power")
    GroupLootContainer_RemoveFrame(GroupLootContainer, frame)
end)