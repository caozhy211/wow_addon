local addOnInfo = {}

local f = CreateFrame("Frame")

f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function()
    for i = 1, GetNumAddOns() do
        if not addOnInfo[i] and IsAddOnLoaded(i) then
            local name = GetAddOnInfo(i)
            local memory = GetAddOnMemoryUsage(i)
            addOnInfo[i] = { name = name, memory = memory, min = 100000, max = 0 }
        end
    end
end)

f:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 1 then
        return
    end
    self.elapsed = 0

    UpdateAddOnMemoryUsage()
    collectgarbage("collect")

    for _, info in pairs(addOnInfo) do
        local name = info.name
        local memory = GetAddOnMemoryUsage(name)

        if memory < info.min then
            info.min = memory
        end
        if memory > info.max then
            info.max = memory
        end

        info.memory = memory
    end
end)

local function formatNumber(number)
    if number < 1000 then
        return format("%.2f KB", number)
    end
    return format("%.2f MB", number / 1000)
end

local button = CreateFrame("Button", "ShowMemUsageButton", UIParent)
button:SetWidth(25)
button:SetHeight(25)
button:SetPoint("Top", QuickJoinToastButton, "Bottom")

button:RegisterForClicks("AnyUp")
button:SetScript("OnClick", function()
    local info = addOnInfo

    -- 根据内存降序排序
    table.sort(info, function(element1, element2)
        if element1 == nil then
            return false
        end
        if element2 == nil then
            return true
        end

        local mem1 = element1.memory
        local mem2 = element2.memory
        if mem1 ~= mem2 then
            return mem1 > mem2
        end
    end)

    local totalMem = 0
    print("|cff8787ed-----------------------------------------------------------------|r")
    for _, value in pairs(info) do
        local name = value.name
        local memory = formatNumber(value.memory)
        local min = formatNumber(value.min)
        local max = formatNumber(value.max)
        print(name .. ": |cffffff00" .. memory .. "|r (|cff00ff00min: " .. min .. "|r, |cffff0000max: " .. max .. "|r)")
        totalMem = totalMem + value.memory
    end
    print("|cff8787ed-----------------------------------------------------------------|r")
    print("Total (" .. #info .. "): " .. formatNumber(totalMem))
    print("|cff8787ed-----------------------------------------------------------------|r")
end)

button.text = button:CreateFontString()
button.text:SetFont(GameFontNormal:GetFont(), 16, "Outline")
button.text:SetText("内")
button.text:SetTextColor(1, 1, 0)
button.text:SetPoint("Center")