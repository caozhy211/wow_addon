local toastFrame = CreateFrame("Frame", "ToastFrame", UIParent)
toastFrame:SetSize(229, 130)
toastFrame:SetPoint("BottomLeft", UIParent, "Bottom", 420, 0)

local function SanitizeLink(link)
    if not link or link == "[]" or link == "" then
        return
    end

    local temp, name = string.match(link, "|H(.+)|h%[(.+)%]|h")
    link = temp or link

    local linkTable = { string.split(":", link) }

    if linkTable[1] ~= "item" then
        return link, link, linkTable[1], tonumber(linkTable[2]), name
    end

    if linkTable[12] ~= "" then
        linkTable[12] = ""

        tremove(linkTable, 15 + (tonumber(linkTable[14]) or 0))
    end

    return table.concat(linkTable, ":"), link, linkTable[1], tonumber(linkTable[2]), name
end

local slots = {
    ["INVTYPE_HEAD"] = { INVSLOT_HEAD },
    ["INVTYPE_NECK"] = { INVSLOT_NECK },
    ["INVTYPE_SHOULDER"] = { INVSLOT_SHOULDER },
    ["INVTYPE_CHEST"] = { INVSLOT_CHEST },
    ["INVTYPE_ROBE"] = { INVSLOT_CHEST },
    ["INVTYPE_WAIST"] = { INVSLOT_WAIST },
    ["INVTYPE_LEGS"] = { INVSLOT_LEGS },
    ["INVTYPE_FEET"] = { INVSLOT_FEET },
    ["INVTYPE_WRIST"] = { INVSLOT_WRIST },
    ["INVTYPE_HAND"] = { INVSLOT_HAND },
    ["INVTYPE_FINGER"] = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
    ["INVTYPE_TRINKET"] = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
    ["INVTYPE_CLOAK"] = { INVSLOT_BACK },
    ["INVTYPE_WEAPON"] = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
    ["INVTYPE_2HWEAPON"] = { INVSLOT_MAINHAND },
    ["INVTYPE_WEAPONMAINHAND"] = { INVSLOT_MAINHAND },
    ["INVTYPE_HOLDABLE"] = { INVSLOT_OFFHAND },
    ["INVTYPE_SHIELD"] = { INVSLOT_OFFHAND },
    ["INVTYPE_WEAPONOFFHAND"] = { INVSLOT_OFFHAND },
    ["INVTYPE_RANGED"] = { INVSLOT_RANGED },
    ["INVTYPE_RANGEDRIGHT"] = { INVSLOT_RANGED },
    ["INVTYPE_RELIC"] = { INVSLOT_RANGED },
    ["INVTYPE_THROWN"] = { INVSLOT_RANGED },
}

local function GetItemLevel(itemLink)
    local _, _, _, _, _, _, _, _, itemEquipLoc, _, _, itemClassID, itemSubClassID = GetItemInfo(itemLink)

    if (itemClassID == 3 and itemSubClassID == 11) or slots[itemEquipLoc] then
        return GetDetailedItemLevelInfo(itemLink) or 0
    end

    return 0
end

local maxActiveToasts = 3
local toasts, activeToasts, queuedToasts, createdToasts = {}, {}, {}, {}
local arrowsConfig = {
    { delay = 0, x = 0 },
    { delay = 0.1, x = -8 },
    { delay = 0.2, x = 16 },
    { delay = 0.3, x = 8 },
    { delay = 0.4, x = -16 },
}
local oldMoney
local textsToAnimate = {}

local function PostSetAnimatedValue(text, value)
    if text.isGold then
        text:SetText(GetMoneyString(value))
    else
        text:SetText(value == 1 and "" or value)
    end
end

local function CreateBorder(frame)
    frame.topBorder = frame:CreateTexture(nil, "Overlay")
    frame.topBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    frame.topBorder:SetColorTexture(0, 0, 0)
    frame.topBorder:SetSize(frame:GetWidth() - 4, 2)
    frame.topBorder:SetPoint("Top")

    frame.bottomBorder = frame:CreateTexture(nil, "Overlay")
    frame.bottomBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    frame.bottomBorder:SetColorTexture(0, 0, 0)
    frame.bottomBorder:SetSize(frame:GetWidth() - 4, 2)
    frame.bottomBorder:SetPoint("Bottom")

    frame.leftBorder = frame:CreateTexture(nil, "Overlay")
    frame.leftBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    frame.leftBorder:SetColorTexture(0, 0, 0)
    frame.leftBorder:SetSize(2, frame:GetHeight())
    frame.leftBorder:SetPoint("Left")

    frame.rightBorder = frame:CreateTexture(nil, "Overlay")
    frame.rightBorder:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    frame.rightBorder:SetColorTexture(0, 0, 0)
    frame.rightBorder:SetSize(2, frame:GetHeight())
    frame.rightBorder:SetPoint("Right")
end

local function ColorBorder(frame, color)
    frame.topBorder:SetColorTexture(color.r, color.g, color.b)
    frame.bottomBorder:SetColorTexture(color.r, color.g, color.b)
    frame.leftBorder:SetColorTexture(color.r, color.g, color.b)
    frame.rightBorder:SetColorTexture(color.r, color.g, color.b)
end

C_Timer.NewTicker(0.05, function()
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

local num = 0
local function GetToastName()
    num = num + 1
    return "MyToast" .. num
end

local function ShowToast(toast)
    toast.data = toast.data or {}
    if #activeToasts >= maxActiveToasts then
        tinsert(queuedToasts, toast)
        return
    end
    if #activeToasts > 0 then
        toast:SetPoint("Top", activeToasts[#activeToasts], "Bottom", 0, -5)
    else
        toast:SetPoint("Top")
    end
    tinsert(activeToasts, toast)
    toast:Show()
end

local function RecycleToast(toast)
    toast:ClearAllPoints()
    toast:SetAlpha(1)
    toast:Hide()
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
    for i = 1, 5 do
        toast["slot" .. i]:Hide()
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
    tinsert(createdToasts, toast)
    for i = 1, #activeToasts do
        local activeToast = activeToasts[i]
        activeToast:ClearAllPoints()
        if i == 1 then
            activeToast:SetPoint("Top")
        else
            activeToast:SetPoint("Top", activeToasts[i - 1], "Bottom", 0, -5)
        end

        local queuedToast = tremove(queuedToasts, 1)
        if queuedToast then
            ShowToast(queuedToast)
        end
    end
end

local function CreateToast()
    local toast = CreateFrame("Button", GetToastName(), toastFrame)
    toast:SetSize(toastFrame:GetWidth(), 40)
    toast:Hide()
    toast:SetScript("OnShow", function(self)
        if self.data.sound then
            PlaySound(self.data.sound)
        end
        self.animIn:Play()
        self.animOut:Play()
    end)

    toast.bg = toast:CreateTexture()
    toast.bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    toast.bg:SetColorTexture(0, 0, 0, 0.8)
    toast.bg:SetAllPoints()

    CreateBorder(toast)

    local title = toast:CreateFontString()
    title:SetFont(GameFontNormal:GetFont(), 12)
    title:SetPoint("TopLeft", 40, -4)
    title:SetTextColor(1, 0.82, 0)
    toast.title = title

    local text = toast:CreateFontString()
    text:SetFont(GameFontNormal:GetFont(), 12)
    text:SetPoint("Bottom", 18, 4)
    toast.text = text

    local bonus = toast:CreateTexture()
    bonus:SetAtlas("Bonus-ToastBanner", true)
    bonus:SetPoint("TopRight")
    bonus:Hide()
    toast.bonus = bonus

    local iconFrame = CreateFrame("Frame", nil, toast)
    iconFrame:SetSize(36, 36)
    iconFrame:SetPoint("Left", 2, 0)
    toast.iconFrame = iconFrame

    local icon = iconFrame:CreateTexture()
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetAllPoints()
    toast.icon = icon

    local iconText1 = iconFrame:CreateFontString()
    iconText1:SetFont(GameFontNormal:GetFont(), 11, "Outline")
    iconText1:SetPoint("BottomRight")
    toast.iconText1 = iconText1

    local iconText2 = iconFrame:CreateFontString()
    iconText2:SetFont(GameFontNormal:GetFont(), 11, "Outline")
    iconText2:SetPoint("Bottom", iconText1, "Top")
    toast.iconText2 = iconText2
    do
        local ag = toast:CreateAnimationGroup()
        ag:SetToFinalAlpha(true)
        iconText2.blink = ag

        local anim = ag:CreateAnimation("Alpha")
        anim:SetChildKey("iconText2")
        anim:SetOrder(1)
        anim:SetFromAlpha(1)
        anim:SetToAlpha(0)
        anim:SetDuration(0)

        anim:SetChildKey("iconText2")
        anim:SetOrder(2)
        anim:SetFromAlpha(0)
        anim:SetToAlpha(1)
        anim:SetDuration(0.2)

        anim = ag:CreateAnimation("Alpha")
        anim:SetChildKey("iconText2")
        anim:SetOrder(3)
        anim:SetFromAlpha(1)
        anim:SetToAlpha(0)
        anim:SetStartDelay(0.4)
        anim:SetDuration(0.4)
    end

    local skull = iconFrame:CreateTexture()
    skull:SetSize(16, 20)
    skull:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-HEROIC")
    skull:SetTexCoord(0 / 32, 16 / 32, 0 / 32, 20 / 32)
    skull:SetPoint("TopRight", -2, -2)
    skull:Hide()
    toast.skull = skull

    do
        local ag = toast:CreateAnimationGroup()
        ag:SetToFinalAlpha(true)
        toast.animArrows = ag

        for i = 1, 5 do
            local arrow = iconFrame:CreateTexture(nil, "Artwork", "LootUpgradeFrame_ArrowTemplate")
            arrow:ClearAllPoints()
            arrow:SetPoint("Center", iconFrame, "Bottom", arrowsConfig[i].x, 0)
            arrow:SetAlpha(0)
            toast["arrow" .. i] = arrow

            local anim = ag:CreateAnimation("Alpha")
            anim:SetChildKey("arrow" .. i)
            anim:SetOrder(1)
            anim:SetFromAlpha(1)
            anim:SetToAlpha(0)
            anim:SetDuration(0)

            anim = ag:CreateAnimation("Alpha")
            anim:SetChildKey("arrow" .. i)
            anim:SetSmoothing("In")
            anim:SetOrder(2)
            anim:SetFromAlpha(0)
            anim:SetToAlpha(1)
            anim:SetStartDelay(arrowsConfig[i].delay)
            anim:SetDuration(0.25)

            anim = ag:CreateAnimation("Alpha")
            anim:SetChildKey("arrow" .. i)
            anim:SetSmoothing("Out")
            anim:SetOrder(2)
            anim:SetFromAlpha(1)
            anim:SetToAlpha(0)
            anim:SetStartDelay(arrowsConfig[i].delay + 0.25)
            anim:SetDuration(0.25)

            anim = ag:CreateAnimation("Translation")
            anim:SetChildKey("arrow" .. i)
            anim:SetOrder(2)
            anim:SetOffset(0, 60)
            anim:SetStartDelay(arrowsConfig[i].delay)
            anim:SetDuration(0.5)

            anim = ag:CreateAnimation("Alpha")
            anim:SetChildKey("arrow" .. i)
            anim:SetDuration(0)
            anim:SetOrder(3)
            anim:SetFromAlpha(1)
            anim:SetToAlpha(0)
        end
    end

    local glow = toast:CreateTexture(nil, "Overlay")
    glow:SetSize(318, 152)
    glow:SetPoint("Center")
    glow:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Glow")
    glow:SetTexCoord(5 / 512, 395 / 512, 5 / 256, 167 / 256)
    glow:SetBlendMode("Add")
    glow:SetAlpha(0)
    toast.glow = glow

    local shine = toast:CreateTexture(nil, "Overlay")
    shine:SetSize(66, 52)
    shine:SetPoint("BottomLeft", 0, -2)
    shine:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Alert-Glow")
    shine:SetTexCoord(403 / 512, 465 / 512, 14 / 256, 62 / 256)
    shine:SetBlendMode("Add")
    shine:SetAlpha(0)
    toast.shine = shine

    do
        local ag = toast:CreateAnimationGroup()
        ag:SetScript("OnFinished", function()
            if toast.data.showArrows then
                toast.animArrows:Play()
                toast.data.showArrows = false
            end
        end)
        ag:SetToFinalAlpha(true)
        toast.animIn = ag

        local anim = ag:CreateAnimation("Alpha")
        anim:SetOrder(1)
        anim:SetFromAlpha(0)
        anim:SetToAlpha(1)
        anim:SetDuration(0)

        anim = ag:CreateAnimation("Alpha")
        anim:SetChildKey("glow")
        anim:SetOrder(2)
        anim:SetFromAlpha(0)
        anim:SetToAlpha(1)
        anim:SetDuration(0.2)

        anim = ag:CreateAnimation("Alpha")
        anim:SetChildKey("glow")
        anim:SetOrder(3)
        anim:SetFromAlpha(1)
        anim:SetToAlpha(0)
        anim:SetDuration(0.5)

        anim = ag:CreateAnimation("Alpha")
        anim:SetChildKey("shine")
        anim:SetOrder(2)
        anim:SetFromAlpha(0)
        anim:SetToAlpha(1)
        anim:SetDuration(0.2)

        anim = ag:CreateAnimation("Translation")
        anim:SetChildKey("shine")
        anim:SetOrder(3)
        anim:SetOffset(168, 0)
        anim:SetDuration(0.85)

        anim = ag:CreateAnimation("Alpha")
        anim:SetChildKey("shine")
        anim:SetOrder(3)
        anim:SetFromAlpha(1)
        anim:SetToAlpha(0)
        anim:SetStartDelay(0.35)
        anim:SetDuration(0.5)

        ag = toast:CreateAnimationGroup()
        ag:SetScript("OnFinished", function()
            RecycleToast(toast)
        end)
        toast.animOut = ag

        anim = ag:CreateAnimation("Alpha")
        anim:SetOrder(1)
        anim:SetFromAlpha(1)
        anim:SetToAlpha(0)
        anim:SetStartDelay(5)
        anim:SetDuration(1.2)
        ag.anim = anim
    end

    for i = 1, 5 do
        local slot = CreateFrame("Frame", nil, toast)
        slot:SetSize(18, 18)
        slot:Hide()
        toast["slot" .. i] = slot

        local slotIcon = slot:CreateTexture()
        slotIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        slotIcon:SetAllPoints()
        slot.icon = slotIcon

        if i == 1 then
            slot:SetPoint("TopRight", -2, -2)
        else
            slot:SetPoint("Right", toast["slot" .. (i - 1)], "Left", -4, 0)
        end
    end

    tinsert(toasts, toast)
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

local function LootCommonToast(event, link, quantity)
    local sanitizedLink, originalLink, linkType, itemID = SanitizeLink(link)
    local toast, isNew, isQueued

    toast, isQueued = FindToast(nil, "itemId", itemID)

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
            local _, speciesID, _, breedQuality, _ = string.split(":", originalLink)
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
                itemId = itemID,
                sound = 31578,
            }

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

                        for i = 1, 5 do
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
                        itemId = itemID,
                        link = sanitizedLink,
                        showArrows = isUpgraded,
                        sound = sound,
                    }

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

local function LootGoldToast(event, quantity)
    local toast, isNew, isQueued = GetToast(nil, "event", event)

    if isNew then
        toast.text.postSetAnimatedValue = true
        toast.text.isGold = true

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
        achId = achievementID,
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

local function CollectionToast(event, ID, isMount, isPet, isToy)
    local toast, isNew, isQueued = GetToast(event, "collectionId", ID)

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
            collectionId = ID,
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
        missionId = missionID,
        sound = 44294,
    }

    ShowToast(toast)
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

        for i = 1, 5 do
            toast["arrow" .. i]:SetAtlas(upgradeTexture.arrow, true)
        end
    else
        toast.title:SetText(followerStrings.FOLLOWER_ADDED_TOAST)
    end

    ColorBorder(toast, color)

    toast.text:SetText(name)

    toast.data = {
        event = event,
        followerId = followerID,
        showArrows = isUpgraded,
        sound = 44296,
    }

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
        talentId = talentID,
        sound = 73280,
    }

    ShowToast(toast)
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
                recipeId = recipeID,
                tradeSkillId = tradeSkillID,
                sound = 73919,
            }

            ShowToast(tostring())
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

    local toast, isNew, isQueued = GetToast(nil, "sourceId", sourceID)

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
            sourceId = sourceID,
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

local function WorldToast(event, isUpdate, questID, name, moneyReward, xpReward, numCurrencyRewards, itemReward, isInvasion, isInvasionBonusComplete)
    local toast, isNew, isQueued = GetToast(nil, "questId", questID)

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
                toast.icon:SetTexture(select(2, GetProfessionInfo(tradeSkillLineIndex)))
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
            questId = questID,
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

                slot:Show()
            end
        end

        if not isQueued then
            toast.animOut:Stop()
            toast.animOut:Play()
        end
    end
end

local LOOT_ITEM_PATTERN = LOOT_ITEM_SELF:gsub("%%s", "(.+)"):gsub("^", "^")
local LOOT_ITEM_PUSHED_PATTERN = LOOT_ITEM_PUSHED_SELF:gsub("%%s", "(.+)"):gsub("^", "^")
local LOOT_ITEM_MULTIPLE_PATTERN = LOOT_ITEM_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)"):gsub("^", "^")
local LOOT_ITEM_PUSHED_MULTIPLE_PATTERN = LOOT_ITEM_PUSHED_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)"):gsub("^", "^")

local CURRENCY_GAINED_PATTERN = CURRENCY_GAINED:gsub("%%s", "(.+)"):gsub("^", "^")
local CURRENCY_GAINED_MULTIPLE_PATTERN = CURRENCY_GAINED_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)"):gsub("^", "^")

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

local function QuestTurnedIn(event, questID)
    if QuestUtils_IsQuestWorldQuest(questID) then
        WorldToast(event, false, questID, C_TaskQuest.GetQuestInfoByQuestID(questID), GetQuestLogRewardMoney(questID), GetQuestLogRewardXP(questID), GetNumQuestLogRewardCurrencies(questID))
    end
end

toastFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
toastFrame:RegisterEvent("ACHIEVEMENT_EARNED")
toastFrame:RegisterEvent("CRITERIA_EARNED")
toastFrame:RegisterEvent("ARTIFACT_DIGSITE_COMPLETE")
toastFrame:RegisterEvent("NEW_MOUNT_ADDED")
toastFrame:RegisterEvent("NEW_PET_ADDED")
toastFrame:RegisterEvent("TOYS_UPDATED")
toastFrame:RegisterEvent("GARRISON_FOLLOWER_ADDED")
toastFrame:RegisterEvent("GARRISON_MISSION_FINISHED")
toastFrame:RegisterEvent("GARRISON_RANDOM_MISSION_ADDED")
toastFrame:RegisterEvent("GARRISON_BUILDING_ACTIVATABLE")
toastFrame:RegisterEvent("GARRISON_TALENT_COMPLETE")
toastFrame:RegisterEvent("LFG_COMPLETION_REWARD")
toastFrame:RegisterEvent("CHAT_MSG_LOOT")
toastFrame:RegisterEvent("CHAT_MSG_CURRENCY")
toastFrame:RegisterEvent("PLAYER_MONEY")
toastFrame:RegisterEvent("AZERITE_EMPOWERED_ITEM_LOOTED")
toastFrame:RegisterEvent("LOOT_ITEM_ROLL_WON")
toastFrame:RegisterEvent("SHOW_LOOT_TOAST_LEGENDARY_LOOTED")
toastFrame:RegisterEvent("SHOW_LOOT_TOAST_UPGRADE")
toastFrame:RegisterEvent("SHOW_LOOT_TOAST")
toastFrame:RegisterEvent("SHOW_PVP_FACTION_LOOT_TOAST")
toastFrame:RegisterEvent("SHOW_RATED_PVP_REWARD_TOAST")
toastFrame:RegisterEvent("STORE_PRODUCT_DELIVERED")
toastFrame:RegisterEvent("NEW_RECIPE_LEARNED")
toastFrame:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_ADDED")
toastFrame:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_REMOVED")
toastFrame:RegisterEvent("SCENARIO_COMPLETED")
toastFrame:RegisterEvent("QUEST_TURNED_IN")
toastFrame:RegisterEvent("QUEST_LOOT_RECEIVED")
toastFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        oldMoney = GetMoney()
    end
    if event == "ACHIEVEMENT_EARNED" then
        local achievementID, alreadyEarned = ...
        AchievementToast(event, achievementID, alreadyEarned)
    end
    if event == "CRITERIA_EARNED" then
        local achievementID, criteriaString = ...
        AchievementToast(event, achievementID, criteriaString, true)
    end
    if event == "ARTIFACT_DIGSITE_COMPLETE" then
        local researchFieldID = ...
        ArchaeologyToast(event, researchFieldID)
    end
    if event == "NEW_MOUNT_ADDED" then
        local mountID = ...
        CollectionToast(event, mountID, true)
    end
    if event == "NEW_PET_ADDED" then
        local petID = ...
        CollectionToast(event, petID, nil, true)
    end
    if event == "TOYS_UPDATED" then
        local toyID, isNew = ...
        if toyID and isNew then
            CollectionToast(event, toyID, nil, nil, true)
        end
    end
    if event == "GARRISON_FOLLOWER_ADDED" then
        local followerID, name, _, level, quality, isUpgraded, texPrefix, followerTypeID = ...
        FollowerToast(event, followerTypeID, followerID, name, texPrefix, level, quality, isUpgraded)
    end
    if event == "GARRISON_MISSION_FINISHED" then
        local followerTypeID, missionID = ...
        local _, instanceType = GetInstanceInfo()
        local validInstance = false

        if instanceType == "none" or C_Garrison.IsOnGarrisonMap() then
            validInstance = true
        end

        if validInstance then
            MissionToast(event, missionID)
        end
    end
    if event == "GARRISON_RANDOM_MISSION_ADDED" then
        local followerTypeID, missionID = ...
        MissionToast(event, missionID, true)
    end
    if event == "GARRISON_BUILDING_ACTIVATABLE" then
        local buildingName = ...
        BuildingToast(event, buildingName)
    end
    if event == "GARRISON_TALENT_COMPLETE" then
        local garrisonType, doAlert = ...
        if doAlert then
            TalentToast(event, C_Garrison.GetCompleteTalent(garrisonType))
        end
    end
    if event == "LFG_COMPLETION_REWARD" then
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
    end
    if event == "CHAT_MSG_LOOT" then
        local message, _, _, _, target = ...
        if target ~= UnitName("player") then
            return
        end

        local link, quantity = message:match(LOOT_ITEM_MULTIPLE_PATTERN)

        if not link then
            link, quantity = message:match(LOOT_ITEM_PUSHED_MULTIPLE_PATTERN)

            if not link then
                quantity, link = 1, message:match(LOOT_ITEM_PATTERN)

                if not link then
                    quantity, link = 1, message:match(LOOT_ITEM_PUSHED_PATTERN)

                    if not link then
                        return
                    end
                end
            end
        end

        C_Timer.After(0.125, function()
            LootCommonToast(event, link, tonumber(quantity) or 0)
        end)
    end
    if event == "CHAT_MSG_CURRENCY" then
        local message = ...
        local link, quantity = message:match(CURRENCY_GAINED_MULTIPLE_PATTERN)

        if not link then
            quantity, link = 1, message:match(CURRENCY_GAINED_PATTERN)

            if not link then
                return
            end
        end

        LootCurrencyToast(event, link, tonumber(quantity) or 0)
    end
    if event == "PLAYER_MONEY" then
        local currentMoney = GetMoney()

        if currentMoney - oldMoney > 0 then
            LootGoldToast(event, currentMoney - oldMoney)
        end

        oldMoney = currentMoney
    end
    if event == "AZERITE_EMPOWERED_ITEM_LOOTED" then
        local link = ...
        LootSpecialToast(event, link, 1, nil, nil, true, nil, nil, nil, nil, nil, nil, nil, true)
    end
    if event == "LOOT_ITEM_ROLL_WON" then
        local link, quantity, rollType, roll, isUpgraded = ...
        LootSpecialToast(event, link, quantity, rollType, roll, true, nil, nil, nil, isUpgraded)
    end
    if event == "SHOW_LOOT_TOAST" then
        local typeID, link, quantity, _, _, isPersonal, _, lessAwesome, isUpgraded = ...
        LootSpecialToast(event, link, quantity, nil, nil, typeID == "item", typeID == "honor", isPersonal, lessAwesome, isUpgraded)
    end
    if event == "SHOW_LOOT_TOAST_UPGRADE" then
        local link, quantity, _, _, baseQuality = ...
        LootSpecialToast(event, link, quantity, nil, nil, true, nil, nil, nil, true, baseQuality)
    end
    if event == "SHOW_PVP_FACTION_LOOT_TOAST" then
        local typeID, link, quantity, _, _, isPersonal, lessAwesome = ...
        LootSpecialToast(event, link, quantity, nil, nil, typeID == "item", typeID == "honor", isPersonal, lessAwesome)
    end
    if event == "SHOW_RATED_PVP_REWARD_TOAST" then
        local typeID, link, quantity, _, _, isPersonal, lessAwesome = ...
        LootSpecialToast(event, link, quantity, nil, nil, typeID == "item", typeID == "honor", isPersonal, lessAwesome)
    end
    if event == "SHOW_LOOT_TOAST_LEGENDARY_LOOTED" then
        local link = ...
        LootSpecialToast(event, link, 1, nil, nil, true, nil, nil, nil, nil, nil, true)
    end
    if event == "STORE_PRODUCT_DELIVERED" then
        local _, _, _, payloadID = ...
        StoreProductDelivered(event, payloadID)
    end
    if event == "NEW_RECIPE_LEARNED" then
        local recipeID = ...
        RecipeToast(event, recipeID)
    end
    if event == "TRANSMOG_COLLECTION_SOURCE_ADDED" then
        local sourceID, attempt = ...
        TransmogCollectionSourceAdded(event, sourceID, attempt)
    end
    if event == "TRANSMOG_COLLECTION_SOURCE_REMOVED" then
        local sourceID, attempt = ...
        TransmogCollectionSourceRemoved(event, sourceID, attempt)
    end
    if event == "SCENARIO_COMPLETED" then
        local questID = ...
        local scenarioName, _, _, _, hasBonusStep, isBonusStepComplete, _, xp, money, scenarioType, areaName = C_Scenario.GetInfo()

        if scenarioType == LE_SCENARIO_TYPE_LEGION_INVASION then
            if questID then
                WorldToast(event, false, questID, areaName or scenarioName, money, xp, nil, nil, true, hasBonusStep and isBonusStepComplete)
            end
        end
    end
    if event == "QUEST_TURNED_IN" then
        local questID = ...
        QuestTurnedIn(event, questID)
    end
    if event == "QUEST_LOOT_RECEIVED" then
        local questID, itemLink = ...
        if not FindToast(nil, "questId", questID) then
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