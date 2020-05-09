--- 创建将鼠标悬停位置框架设置为焦点的按钮
---@type CheckButton
local focusButton = CreateFrame("CheckButton", "WLK_SetFocusButton", UIParent, "SecureActionButtonTemplate")
--- 设置鼠标左键点击 focusButton 时执行将鼠标悬停位置的框架设置为焦点的宏命令
focusButton:SetAttribute("type1", "macro")
focusButton:SetAttribute("macrotext", "/focus mouseover")
--- 绑定 “SHIFT + 鼠标左键” 点击 focusButton
local modifierKey = "SHIFT"
local button = 1
SetOverrideBindingClick(focusButton, true, modifierKey .. "-BUTTON" .. button, focusButton:GetName())

--- 添加 “SHIFT + 鼠标左键” 点击框架将其设置为焦点的属性
---@param frame Frame
local function SetFocus(frame)
    frame:SetAttribute(modifierKey .. "-TYPE" .. button, "focus")
end

--- 使用 SecureUnitButtonTemplate 模板创建框架后，添加设置焦点属性
hooksecurefunc("CreateFrame", function(_, name, _, frameTemplate)
    if frameTemplate == "SecureUnitButtonTemplate" then
        SetFocus(_G[name])
    end
end)

--- 为在插件之前已创建的框架添加设置焦点属性
local frames = {
    PlayerFrame, PetFrame, TargetFrame, TargetFrameToT, PartyMemberFrame1, PartyMemberFrame2, PartyMemberFrame3,
    PartyMemberFrame4, PartyMemberFrame1PetFrame, PartyMemberFrame2PetFrame, PartyMemberFrame3PetFrame,
    PartyMemberFrame4PetFrame, Boss1TargetFrame, Boss2TargetFrame, Boss3TargetFrame, Boss4TargetFrame, Boss5TargetFrame,
}
for i = 1, #frames do
    SetFocus(frames[i])
end
