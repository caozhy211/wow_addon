local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    if Skada then
        -- 使用中文單位簡化數字
        Skada.FormatNumber = function(self, number)
            if number then
                if number >= 1e8 then
                    return ("%02.2f億"):format(number / 1e8)
                end
                if number >= 1e4 then
                    return ("%02.2f萬"):format(number / 1e4)
                end
                return math.floor(number)
            end
        end
        -- 設置Skada框架大小和位置
        if Skada:GetWindows()[1] ~= nil then
            Skada:GetWindows()[1].bargroup:ClearAllPoints()
            Skada:GetWindows()[1].bargroup:SetPoint("BottomLeft", UIParent, "BottomLeft", 0, 0)
            Skada:GetWindows()[1].db.barwidth = 540
            Skada:GetWindows()[1].db.background.height = 90
        end
    end
end)