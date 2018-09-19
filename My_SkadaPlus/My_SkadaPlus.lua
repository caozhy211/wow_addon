local f = CreateFrame("Frame")

f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function()
    if Skada then
        -- 使用中文單位簡化數字
        function Skada:FormatNumber(number)
            if number then
                if number >= 1e8 then
                    return ("%02.2f億"):format(number / 1e8)
                end
                if number >= 1e4 then
                    return ("%02.2f萬"):format(number / 1e4)
                end
                return floor(number)
            end
        end

        -- 設置Skada框架大小和位置
        local window = Skada:GetWindows()[1]
        if window then
            window.bargroup:ClearAllPoints()
            window.bargroup:SetPoint("BottomLeft", UIParent)
            window.db.barwidth = 470
            window.db.background.height = 90
        end
    end
end)