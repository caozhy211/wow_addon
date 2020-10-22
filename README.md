# WlkUI
魔兽世界界面插件。调整游戏界面布局，优化游戏体验。

## 安装说明
解压文件至 %WOW_HOME%/_retail\_/Interface/AddOns。

## 使用说明
适用于魔兽世界正式服 DPS 专精。

不想启用的的功能在 WlkUI.toc 中对应的文件名前添加“#”。

- ActionBarFrames.lua
    1. 修改动作条和按钮大小、位置、外观。
    2. 右键点击按钮自我施法。
    3. 超出距离按钮图标染红。
- AlertFrame.lua
    - 使用自定义的通知框架替代暴雪通知框架和拾取框架。
- AuraButtons.lua
    - 修改玩家光环按钮大小、位置、外观。
- CastingBarFrame.lua
    1. 显示施法延迟。
    2. 显示法术段数，使用聊天命令“/st 'spellID' 'ticks'”添加法术段数。
    3. 合并专业制造施法条。
    4. 显示全局冷却条。
- ChatFrame.lua
    1. 修改聊天框大小、位置。
    2. 简写聊天频道名。
- ChatMenuFrame.lua
    1. 显示聊天菜单按钮。
    2. 右键点击“綜”和“世”可加入或离开综合频道和大脚世界频道。
    3. 使用聊天命令“/cc”清除聊天框，“/ru”重载界面。
- Cooldown.lua
    - 显示冷却计时。
- DamageLogFrame.lua
    - 显示伤害统计。
- ExportFrame.lua
    1. 使用聊天命令“/nc”导出数字常量。
    2. 使用聊天命令“/cc”导出聊天框内容。
    3. 在查看 frame stack 时按“F5”导出当前选择的对象名。
- Filter.lua
    - 使用聊天命令“/ak 'keyword'”添加关键字，过滤聊天框内容和社区邀请。
- GridFrame.lua
    - 使用聊天命令“/tg”显示或隐藏网格。
- ItemButton.lua
    - 在物品按钮和聊天链接上显示物品信息。
- ItemTrackerFrame.lua
    - 显示已装备的可使用物品和任务可使用物品。
- MarkerFrame.lua
    - 显示标记按钮。左键点击标记当前目标，Alt+左键点击标记自己，Shift+左键点击标记焦点，Ctrl+左键点击放置光柱，右键点击清除光柱。
- MerchantFrame.lua
    - 自动修理装备和自动出售垃圾物品。
- Minimap.lua
    1. 修改小地图外观。
    2. 使用滚轮缩放小地图。
- MirrorTimer.lua
    1. 修改镜像计时条外观。
    2. 显示镜像计时条时间。
- Nameplate.lua
    1. 显示姓名板选中标记、任务标记、单位生命值和单位名称。
    2. 修改姓名板名称、类型、光环位置。
    3. 修改姓名板材质。
- PerformanceFrames.lua
    - 显示网络延迟、FPS 和内存使用。
- PowerFrames.lua
    - 显示玩家能量框架。
- PvPTalentFrame.lua
    - 显示 PvP 天赋技能按钮。
- SettingsButtons.lua
    1. 一键恢复默认设置和一键应用自定义设置。
    2. 修改任务追踪框架、团队框架和发言人肖像框架位置。
    3. Shift+左键点击单位设置单位为焦点。
    3. 确认删除对话框的编辑框自动添加“DELETE”。
- StatInfoFrame.lua
    - 显示玩家属性。
- Tooltip.lua
    1. 修改鼠标提示默认位置。
    2. 显示物品 ID、法术 ID 和 光环 ID。
    3. 修改数据条材质，显示数据条数值。
    4. 修改文字颜色，显示目标。
    5. 按住 Ctrl 键显示单位装等和专精。

## 更新日志
### v4.0.1
- 修正了玩家能量框架在切换专精后没有更新的问题。
### v4.0.0
- 适配魔兽世界 9.0.1。
