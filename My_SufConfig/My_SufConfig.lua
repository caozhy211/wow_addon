local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
    if ShadowUF then
        -- 使用中文單位簡化數字
        ShadowUF.FormatLargeNumber = function(self, number)
            if number < 1e4 then
                return number
            end
            if number < 1e6 then
                return ("%02.1f萬"):format(number / 1e4)
            end
            if number < 1e8 then
                return ("%d萬"):format(number / 1e4)
            end
            return ("%02.2f億"):format(number / 1e8)
        end
    end
end)