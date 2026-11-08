# Changelog

## v1.2
- watchdog 改用 `setsid`，脱离 Termux/终端会话
- 日志文件创建后 `chmod 644`，普通用户可读
- 增加 `libproot` 引擎检查：启动 180 秒后引擎不在，force-stop 并重启 App
- 杀旧 watchdog 前校验 PID 对应进程，避免 PID 复用误杀

## v1.1
- 增加 watchdog：每 10 秒检查 App 进程，被清掉后自动拉起
- 开机自动启动 App
- 只豁免 DSH 的 Doze，其他 App 恢复 Doze

## v1.0
- 初始版本：phantom 设置、Doze 白名单、后台 appops、standby bucket
