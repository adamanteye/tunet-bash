# 清华大学校园网准入脚本自述文档

## 特点

功能通过 Bash 实现, 适合 Live CD 引导装机, 小主机登录维持等场景.

## 使用指南

### 从包管理器安装

#### Arch

- [AUR - tunet-bash](https://aur.archlinux.org/packages/tunet-bash)

#### Debian

```sh
curl -fsS https://gpg.adamanteye.cc/ada.pub | sudo tee /etc/apt/keyrings/debian.adamanteye.cc.asc

cat <<EOF | sudo tee /etc/apt/sources.list.d/adamanteye.sources
Types: deb
URIs: https://debian.adamanteye.cc/
Suites: trixie # or bookworm
Components: main
Signed-By: /etc/apt/keyrings/debian.adamanteye.cc.asc
EOF

cat <<EOF | sudo tee /etc/apt/preferences.d/03-adamanteye.pref
Explanation: By default, discard all packages from debian.adamanteye.cc
Package: *
Pin: origin debian.adamanteye.cc
Pin-Priority: 1

Explanation: Allow installing/updating tunet-bash from debian.adamanteye.cc
Package: tunet-bash
Pin: origin debian.adamanteye.cc
Pin-Priority: 500
EOF

sudo apt-update && sudo apt-get install tunet-bash
```

### 从源码安装

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
$ tunet-bash --login            # automatically use auth4 or auth6
```

```sh
$ export TUNET_USERNAME=<your username>
$ export TUNET_PASSWORD=<your password>
$ tunet-bash --login --auth 6
[2025-01-29 11:18:23+08:00] INFO login_ok
```

或者, 也可以将用户名和密码写入 `$HOME/.cache/tunet-bash/passwd` 文件中, 这一过程可以通过以下命令完成:

```sh
$ tunet-bash --config
username: qingxiaohua
password:
```

此后将使用已设定的用户名和密码, 环境变量可以覆盖文件中的用户名和密码.

也可以选择使用 [pass](https://www.passwordstore.org/) 存储密码:

```sh
$ tunet-bash --config --pass
username: qingxiaohua
passname: tsinghua/qingxiaohua
```

这种情况下密码不再是明文存储.

如果查询当前登入用户, 可以使用:

```sh
$ tunet-bash --whoami
[2025-01-29 10:13:33+08:00] INFO qingxiaohua
```

```sh
$ tunet-bash --whoami --verbose
Username:          qingxiaohua
Login Time:        2025-09-04 00:27:05+08:00
Age:               19.37 h
Billing Name:      计费
Products Name:     学生
Device Online:     2
User Balance:      0 CNY
Traffic In:        25.53 Mi
Traffic Out:       220.60 Mi
Traffic Sum:       246.14 Mi
Traffic Total:     0.00 Gi
MAC Address:       00:10:20:30:40:50
IP Address:        166.111.0.1

Device Details:
  Device 1:
    Rad Online ID: 355735784
    IPv4:          59.66.0.1
    IPv6:          2402:f000:4:1008:809:ffff:fdba:aaaa

  Device 2:
    Rad Online ID: 398436141
    IPv4:          166.111.0.1
    IPv6:          2402:f000:4:1007:809:3d3:76ba:aaaa

System Version:    1.01.20250403
```

`Traffic In`, `Traffic Out`, `Traffic Sum` 统计当前登陆会话的流量, `Traffic Total` 统计本月总流量.

更多参数说明请查看手册页.

### 守护登陆

[crontab/autologin.sh](./crontab/autologin.sh) 提供了一个简单的断线后重新登陆脚本, 可以设置为以下的 crontab 任务:

```
0,20,40 * * * * /root/autologin.sh
```

## 功能

- [x] Auth 4
- [x] Auth 6
- [ ] Net

- [x] 登入登出
- [x] 当前用户查询
- [x] 在线时间, 流量查询
- [x] 余额查询
- [x] 在线设备查询

## 依赖

- bash
- openssl
- curl

## 可选依赖

- [pass](https://www.passwordstore.org/)
- jq

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

### v1.2.9

- 修复在线设备查询错误

### v1.2.8

- 在仅有 IPv6 连接下的兼容性

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

- 合并 `tea.sh`, `tunet-bash.sh`
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
- 将 `tunet-bash.sh` 安装为 `tunet-bash`
