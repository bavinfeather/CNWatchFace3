# 独立颜色与模拟器设置文件修复

2026-09-05

- 移除 Theme / Night 统一方案和跟随方案选项。
- 12 个位置分别使用独立颜色值，参考 MAX2 的颜色列表；各位置原版参考色均放最后。
- 旧 -1 哨兵迁移为独立默认颜色，保留用户已经选择的具体色值。
- 手机设置与手表端菜单由同一 schema 生成，20 个设置。
- 六个目标构建均通过；每个 PRG 的同名 settings JSON 同步到模拟器 GARMIN/Settings。
- tools/run-simulator.ps1 统一使用 CNWatchFace3.prg，并同步 CNWATCHFACE3-settings.json。二者生成/复制校验通过。
- 本次属性编辑器 UI 验证未完成：计算机工具返回 foreground window did not report a process id。不能将构建和文件校验视为编辑器打开成功。
