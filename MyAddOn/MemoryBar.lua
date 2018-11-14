local font = GameFontNormal:GetFont()
local addons = {}
local bar = CreateFrame("StatusBar", "MyMemoryBar", UIParent)
bar:SetSize(298 - 119 - 47, 11)
bar:SetPoint("BottomRight", -47, 88 - 11)
bar:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground" })
bar:SetBackdropColor(0, 0, 0, 0.8)
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
bar:SetStatusBarColor(1, 1, 0)

local left = bar:CreateFontString()
left:SetFont(font, 10, "Outline")
left:SetPoint("Left", 2, 0)

local right = bar:CreateFontString()
right:SetFont(font, 10, "Outline")
right:SetPoint("Right", -2, 0)

bar:RegisterEvent("PLAYER_LOGIN")

bar:SetScript("OnEvent", function()
    local index = 0
    for i = 1, GetNumAddOns() do
        if not addons[i] and IsAddOnLoaded(i) then
            index = index + 1
            local name = GetAddOnInfo(i)
            local memory = GetAddOnMemoryUsage(i)
            addons[index] = { name = name, memory = memory, minMemory = 100000, maxMemory = 0, }
        end
    end
end)

C_Timer.NewTicker(1, function()
    UpdateAddOnMemoryUsage()

    bar.minTotal = 0
    bar.currentTotal = 0
    bar.maxTotal = 0

    for i = 1, #addons do
        local name = addons[i].name
        local memory = GetAddOnMemoryUsage(name)
        if memory < addons[i].minMemory then
            addons[i].minMemory = memory
        end
        if memory > addons[i].maxMemory then
            addons[i].maxMemory = memory
        end
        addons[i].memory = memory

        bar.minTotal = bar.minTotal + addons[i].minMemory
        bar.currentTotal = bar.currentTotal + addons[i].memory
        bar.maxTotal = bar.maxTotal + addons[i].maxMemory
    end

    bar:SetMinMaxValues(0, bar.maxTotal)
    bar:SetValue(bar.currentTotal)

    left:SetFormattedText("|cff00ff00%.2fMB|r", bar.minTotal / 1000)
    right:SetFormattedText("|cffff0000%.2fMB|r", bar.maxTotal / 1000)

    collectgarbage()
end)

local function FormatMemory(memory, type)
    local color = type == "min" and "|cff00ff00min: " or type == "max" and "|cffff0000max: " or "|cffffff00"
    if memory < 1000 then
        return format(color .. "%.2fKB|r", memory)
    end
    return format(color .. "%.2fMB|r", memory / 1000)
end

bar:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("Bottom", self, "Top", 0, 2)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(FormatMemory(self.currentTotal))
    GameTooltip:Show()
    self:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 1 then
            return
        end
        self.elapsed = 0
        _G["GameTooltipTextLeft1"]:SetText(FormatMemory(self.currentTotal))
    end)
end)

bar:SetScript("OnLeave", function(self)
    self:SetScript("OnUpdate", nil)
    GameTooltip:Hide()
end)

bar:SetScript("OnMouseDown", function()
    local data = addons
    table.sort(data, function(a, b)
        if not a or a.memory == nil then
            return false
        elseif not b or b.memory == nil then
            return true
        else
            return a.memory > b.memory
        end
    end)

    local minTotal = 0
    local total = 0
    local maxTotal = 0
    print("-----------------------------------------------------------------")
    for i = 1, #data do
        local name = data[i].name
        local memory = FormatMemory(data[i].memory)
        local minMemory = FormatMemory(data[i].minMemory, "min")
        local maxMemory = FormatMemory(data[i].maxMemory, "max")
        print(name .. ": " .. memory .. " (" .. minMemory .. ", " .. maxMemory .. ")")
        minTotal = minTotal + data[i].minMemory
        total = total + data[i].memory
        maxTotal = maxTotal + data[i].maxMemory
    end
    total = FormatMemory(total)
    minTotal = FormatMemory(minTotal, "min")
    maxTotal = FormatMemory(maxTotal, "max")
    print("-----------------------------------------------------------------")
    print("Total (" .. #data .. "): " .. total .. " (" .. minTotal .. ", " .. maxTotal .. ")")
    print("-----------------------------------------------------------------")
end)