# WlkUI
魔兽世界界面插件。

## 项目背景
不喜欢整合插件的臃肿和单体插件的麻烦。

## 功能介绍
调整游戏界面布局，优化游戏体验。

## 安装方法
解压文件至 %WOW_HOME%/_retail\_/Interface/AddOns。

## 使用说明
只适用于魔兽世界正式服。

- ExportFrame.lua
  - 使用命令 “/efn” 导出调试模式下高亮框架名。  
  ![](https://github.com/czy211/picture-library/blob/master/resources/wlk-ui/efn.jpg)
  - 使用命令 “/esa” 导出系统 API。
  ![](https://github.com/czy211/picture-library/blob/master/resources/wlk-ui/esa.jpg)
  - 使用命令 “/ec” 导出鼠标指针所在位置的聊天框内容或聊天框全部内容。
  ![](https://github.com/czy211/picture-library/blob/master/resources/wlk-ui/ec.jpg)
- GridFrame.lua
  - 使用命令 “/tg” 显示或隐藏界面网格。参数可设置水平方向和垂直方向的网格个数，使用一个空格隔开（例如：/tg 80 40），默认值是 64 和 36。
  ![](https://github.com/czy211/picture-library/blob/master/resources/wlk-ui/tg.jpg)
- ChatFrame.lua
  - 调整聊天输入框外观和位置，移动光标不需要按住 “Alt” 键。

## 其它说明
插件基于个人兴趣和使用制作，所以界面布局和部分功能并不适用于所有人。

## 改动日志
### v4.0.0
- 重构代码。
- 添加功能
  - 使用命令 “/efn” 导出调试模式下高亮框架名。

### v3.0.0
- 使插件适用于全职业。
- 修复 bug。
