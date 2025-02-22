# 清华大学校园网准入脚本自述文档

## 特点

功能通过 Bash 实现, 适合 Live CD 引导装机, 小主机登录维持等场景.

## 使用指南

### 从包管理器安装

- Arch Linux: [AUR - tunet_bash](https://aur.archlinux.org/packages/tunet_bash)

### 从源代码安装

```sh
$ make install # default to $HOME/.local
```

或者安装到自定义路径:

```sh
$ sudo make prefix=/usr/local install
```

如果要卸载:

```sh
$ make uninstall
```

### 示例

```sh
$ export TUNET_USERNAME=<your username>
$ export TUNET_PASSWORD=<your password>
$ export TUNET_LOG_LEVEL=debug  # default info
$ tunet_bash --login            # automatically use auth4 or auth6
```

```sh
$ export TUNET_USERNAME=<your username>
$ export TUNET_PASSWORD=<your password>
$ tunet_bash --login --auth 6
[2025-01-29 11:18:23+08:00] INFO login_ok
```

或者, 也可以将用户名和密码写入 `$HOME/.cache/tunet_bash/passwd` 文件中, 这一过程可以通过以下命令完成:

```sh
$ tunet_bash --config
username: yangzheh22
password:
```

此后将使用已设定的用户名和密码, 环境变量可以覆盖文件中的用户名和密码.

也可以选择使用 [pass](https://www.passwordstore.org/) 存储密码:

```sh
$ tunet_bash --config --pass
username: yangzheh22
passname: tsinghua/yangzheh22
```

这种情况下密码不再是明文存储.

如果查询当前登入用户, 可以使用:

```sh
$ tunet_bash --whoami
[2025-01-29 10:13:33+08:00] INFO yangzheh22
```

```sh
$ tunet_bash --whoami --verbose --auth 6
[2025-01-29 12:08:53+08:00] INFO yangzheh22
LOGIN                       UP(h)  DEVICE  BALANCE  TRAFFIC_IN(MiB)  TRAFFIC_OUT(MiB)  TRAFFIC_SUM(MiB)  TRAFFIC_TOTAL(GiB)  MAC                IP
2025-01-30 00:22:24+08:00   1.06   3       0        8.18             2.52              10.71             37.46               00:10:20:30:40:50  2402:f000:4:1008:809:ffff:ffff:3138
```

`TRAFFIC_IN`, `TRAFFIC_OUT`, `TRAFFIC_SUM` 统计当前登陆会话的流量, `TRAFFIC_TOTAL` 统计本月总流量.

更多参数说明请查看手册页.

### 守护登陆

[crontab/autologin.sh](./crontab/autologin.sh) 提供了一个简单的断线后重新登陆脚本, 可以设置为以下的 crontab 任务:

```
0,20,40 * * * * /home/root/autologin.sh
```

## 功能

- [x] Auth 4
- [x] Auth 6
- [ ] Net

- [x] 登入登出
- [x] 当前用户查询
- [x] 在线时间, 流量查询

## 依赖

- bash
- openssl
- curl

## 可选依赖

- [pass](https://www.passwordstore.org/)

## 构建依赖

- make
- [scdoc](https://git.sr.ht/~sircmpwn/scdoc)

## 参考

以下项目或博客为实现 Bash 版本的认证逻辑提供了参考:

- [tunet-rust](https://github.com/Berrysoft/tunet-rust)
- [清华校园网自动连接脚本](https://github.com/WhymustIhaveaname/TsinghuaTunet)
- [某校园网认证api分析](https://www.ciduid.top/2022/0706/school-network-auth/)
- [tunet-python](https://github.com/yuantailing/tunet-python/)
- [GoAuthing](https://github.com/z4yx/GoAuthing)
- [Tiny Encryption Algorithm - Wikipedia](https://en.wikipedia.org/wiki/Tiny_Encryption_Algorithm)
- [Bash Bitwise Operators | Baeldung on Linux](https://www.baeldung.com/linux/bash-bitwise-operators)

## Change Log

### v1.2.7

- 修复 Makefile 打包

### v1.2.6

- 修改 Makefile 打包

### v1.2.5

- 增加可选依赖: [pass](https://www.passwordstore.org/)
- 密码可以非明文存储

### v1.2.4

- 更通用的 shebang
- 打印版本

### v1.2.3

- 支持短选项组合
- 设置 `LC_ALL=C`

### v1.2.2

- 修复 `-a auto` 条件判断

### v1.2.1

- MAC, 在线设备数, 余额查询

### v1.2.0

- 支持 `--date-format` 选项
- 替换 `--v4`, `--v6` 选项为 `--auth`
- 允许自动确定 auth4 或 auth6

### v1.1.1

- 修复短选项解析错误

### v1.1.0

- 在线时间, 流量等查询
- 指定 auth4 或 auth6

### v1.0.1

- 合并 `tea.sh`, `tunet_bash.sh`
- 短选项支持

### v1.0.0

- 将 `tea.cpp` 部分换为 Bash 实现

### v0.3.0

- 更改命令格式
- 更改安装路径
- 增加 man 手册页

### v0.2.3

- 不再依赖 jq 解析 json

### v0.2.2

- 修复未登录下没有设置 v4 或 v6 的问题

### v0.2.1

- 修复有线网 auth6 跳转

### v0.2.0

- 针对校园网 2025-01-15 的升级, 更新获取 ac_id 的逻辑
- 针对校园网 2025-01-15 的升级, 更新 whoami 查询的逻辑
- 将 `tunet_bash.sh` 安装为 `tunet_bash`
