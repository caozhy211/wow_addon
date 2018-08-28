local addOnInfo = {}

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    for i = 1, GetNumAddOns() do
        if not addOnInfo[i] and IsAddOnLoaded(i) then
            local name, _ = GetAddOnInfo(i)
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

    for i, info in pairs(addOnInfo) do
        local name = info.name
        local memory = GetAddOnMemoryUsage(name)

        if memory < info.min then
            info.min = memory
        elseif memory > info.max then
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

SlashCmdList["MEMUSAGE"] = function()
    local nowInfo = addOnInfo

    -- 根据内存降序排序
    table.sort(nowInfo, function(element1, element2)
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
    for i, info in pairs(nowInfo) do
        local name = info.name
        local memory = formatNumber(info.memory)
        local min = formatNumber(info.min)
        local max = formatNumber(info.max)
        print(name .. ": |cffffff00" .. memory .. "|r (|cff00ff00min: " .. min .. "|r, |cffff0000max: " .. max .. "|r)")
        totalMem = totalMem + info.memory
    end
    print("|cff8787ed-----------------------------------------------------------------|r")
    print("Total (" .. #nowInfo .. "): " .. formatNumber(totalMem))
    print("|cff8787ed-----------------------------------------------------------------|r")
end

SLASH_MEMUSAGE1 = "/mu"