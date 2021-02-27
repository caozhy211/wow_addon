---@type Frame
local listener = CreateFrame("Frame")

listener:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 1 then
        return
    end
    self.elapsed = 0

    --- categoryID（2：地城，3：团队副本，8：战场，9：积分战场）
    if LFGListFrame.SearchPanel.categoryID == 3 or LFGListFrame.SearchPanel.categoryID == 9 then
        LE_LFG_LIST_DISPLAY_TYPE_CLASS_ENUMERATE = 1
    elseif LFGListFrame.SearchPanel.categoryID == 2 or LFGListFrame.SearchPanel.categoryID == 8 then
        LE_LFG_LIST_DISPLAY_TYPE_CLASS_ENUMERATE = 2
    else
        LE_LFG_LIST_DISPLAY_TYPE_CLASS_ENUMERATE = 3
    end
end)
