# dsh-keepalive

给 **DSH Go**（Android 手机 App）用的 root 保活模块：App 被系统清掉后自动拉起，尽量让引擎继续跑。

> 适用包名：`io.github.ccch1mneyyy.dsh_app`（DSH Go）。  
> 只在 **SukiSU / KernelSU / Magisk** 环境测试过；需要 root。  
> 先说清楚：**没有任何模块能保证 App 绝对不被系统杀死**。强制停止、清理全部、LMK 内存回收都能杀；这个模块做的是“被清掉后尽快拉回来”。

## 功能

- 关闭 phantom 进程限制（`settings_enable_monitor_phantom_procs=false`、`max_phantom_processes`）
- 只把 DSH 加入 Doze 白名单，其他 App 的 Doze 保持正常
- 后台 appops（`RUN_IN_BACKGROUND` / `RUN_ANY_IN_BACKGROUND`）、standby bucket=active、`set-inactive false`
- 开机自动启动 DSH
- watchdog 每 10 秒检查一次 App 进程，被清掉后自动拉起
- 启动 180 秒后如果 `libproot.so` 引擎不在，强制停止并重启 App（v1.2 起）

## 环境

- Android 手机，已 root
- SukiSU / KernelSU / Magisk（模块格式通用）
- DSH Go 已安装，包名 `io.github.ccch1mneyyy.dsh_app`

如果你用的是别的包名，改 `service.sh` 里的 `PKG=`。

## 安装

1. 下载 Release 里的 `dsh-keepalive-<version>.zip`
2. 打开 SukiSU / KernelSU / Magisk → 模块 → 从本地安装 → 选 zip
3. 重启手机
4. 不想重启的话，装完手动跑一次：

```sh
su -c 'sh /data/adb/modules/dsh_keepalive/service.sh'
```

## 验证

```sh
su -c 'cat /data/adb/modules/dsh_keepalive/watchdog.pid'
su -c 'ps -A -o PID,PPID,ETIME,ARGS | grep -E "dsh_app|libproot"'
cat /sdcard/Download/DSH-Go/keepalive.log
```

正常情况下：

- watchdog 的 PPID 是 1（已脱离终端）
- 同时能看到 `dsh_app` 和 `libproot`
- 日志里有 `service.sh start`、`watchdog started`

测试：把 DSH 从最近任务划掉，10–20 秒内应自动回来，日志写 `watchdog relaunch`。

## 日志

`/sdcard/Download/DSH-Go/keepalive.log`

如果普通用户读不了，用：

```sh
su -c 'cat /sdcard/Download/DSH-Go/keepalive.log'
```

## 原理

`service.sh` 在开机 late_start 执行：

1. 关闭 phantom 进程限制
2. 把 DSH 加入 Doze 白名单、放后台限制
3. 用 `setsid` 启动一个脱离终端的 watchdog
4. watchdog 轮询 `pidof`；App 没了就 `monkey` / `am start` 拉起；`libproot` 没了就 force-stop 后重启 App

## 限制

- **挡不住**系统设置里的“强行停止”；被 force-stop 后 watchdog 可能拉不起来，需要手动打开一次
- 挡不住 ROM 禁止后台启动；需要同时在系统设置里给 DSH 开自启动/后台运行
- 你主动把 App 从最近任务划掉，也会被 watchdog 拉回来；不想要就卸载模块
- v1.2 的引擎检查会在 `libproot` 消失 180 秒后强制重启 App；不想要这段就把 `service.sh` 里 `elif ... pgrep ...` 整段注释掉
- root 脚本有风险，先看代码再装；不同 ROM 行为可能不同

## 卸载

SukiSU / KernelSU / Magisk → 模块 → 卸载 → 重启。  
`uninstall.sh` 会尝试杀掉 watchdog。
声明：本模块由DeepSeek-V4.1-Flash完成，她主人只是个吃白饭的。

## License

MIT
