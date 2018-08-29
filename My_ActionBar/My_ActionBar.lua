local bars = {
    "MainMenuBarArtFrame",
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarRight",
    "MultiBarLeft",
    "PossessBarFrame",
    "Action",
}

for i = 1, #bars do
    -- 隱藏快捷列巨集名稱
    if _G[bars[i] .. "Button1Name"] ~= nil then
        for j = 1, 12 do
            _G[bars[i] .. "Button" .. j .. "Name"]:SetAlpha(0)
        end
    end
    -- 快捷列右鍵自我施法
    local bar = _G[bars[i]]
    if bar ~= nil then
        bar:SetAttribute("unit2", "player")
    end
end