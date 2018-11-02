local addons = {}
local listener = CreateFrame("Frame")
local height = QuickJoinToastButton:GetBottom() - ChatFrame1ButtonFrameBackground:GetTop()
local button = CreateFrame("Button", nil, UIParent)
button:SetSize(32, height)
button:SetPoint("Top", QuickJoinToastButton, "Bottom")

button.text = button:CreateFontString()
button.text:SetFont(GameFontNormal:GetFont(), 16, "Outline")
button.text:SetPoint("Center")
button.text:SetText("內")
button.text:SetTextColor(1, 1, 0)

listener:RegisterEvent("PLAYER_LOGIN")

listener:SetScript("OnEvent", function()
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

listener:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 1 then
        return
    end
    self.elapsed = 0

    UpdateAddOnMemoryUsage()
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
    end
    collectgarbage()
end)

local function FormatMemory(memory, type)
    local color = type == "min" and "|cff00ff00min: " or type == "max" and "|cffff0000max: " or "|cffffff00"
    if memory < 1000 then
        return format(color .. "%.2f KB|r", memory)
    end
    return format(color .. "%.2f MB|r", memory / 1000)
end

button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

button:SetScript("OnClick", function()
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

    local total = 0
    print("-----------------------------------------------------------------")
    for i = 1, #data do
        local name = data[i].name
        local memory = FormatMemory(data[i].memory)
        local minMemory = FormatMemory(data[i].minMemory, "min")
        local maxMemory = FormatMemory(data[i].maxMemory, "max")
        print(name .. ": " .. memory .. " (" .. minMemory .. ", " .. maxMemory .. ")")
        total = total + data[i].memory
    end
    print("-----------------------------------------------------------------")
    print("Total (" .. #data .. "): " .. FormatMemory(total))
    print("-----------------------------------------------------------------")
end)