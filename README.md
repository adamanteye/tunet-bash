# 清华大学校园网准入脚本自述文档

## 特点

功能通过 Bash 实现, 适合 Live CD 引导装机, 小主机登录维持等场景.

## 使用指南

### 从包管理器安装

#### Arch

- [AUR - tunet-bash](https://aur.archlinux.org/packages/tunet-bash)

#### Debian

```sh
curl -fsS https://gpg.adamanteye.cc/ada.pub | sudo tee /etc/apt/keyrings/debian.adamanteye.cc.asc > /dev/null

cat <<EOF | sudo tee /etc/apt/sources.list.d/adamanteye.sources > /dev/null
Types: deb
URIs: https://debian.adamanteye.cc/
Suites: trixie
Components: main
Signed-By: /etc/apt/keyrings/debian.adamanteye.cc.asc
EOF

cat <<EOF | sudo tee /etc/apt/preferences.d/03-adamanteye.pref > /dev/null
Explanation: By default, discard all packages from debian.adamanteye.cc
Package: *
Pin: origin debian.adamanteye.cc
Pin-Priority: 1

Explanation: Allow installing/updating tunet-bash from debian.adamanteye.cc
Package: tunet-bash
Pin: origin debian.adamanteye.cc
Pin-Priority: 500
EOF

sudo apt-get update && sudo apt-get install tunet-bash
```

### 从源码安装

```sh
$ make install
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

配置用户名和密码, 它们会被写入 `$HOME/.cache/tunet-bash/passwd`:

```sh
$ tunet-bash --config
username: qingxiaohua
password:
```

通过 auth4 登录

```sh
$ tunet-bash --login --auth 4
INFO auth4 login
INFO login_ok
```

查询当前登入用户:

```sh
$ tunet-bash --whoami
qingxiaohua
```

```sh
$ tunet-bash --whoami --verbose
Username:          qingxiaohua
Session Start:     2025-10-18T13:54:35+08:00
Session Age:       0.29 h
Billing Profile:   计费
Product Plan:      学生
Online Devices:    4
Balance:           0 CNY
Session Inbound:   2.35 Mi
Session Outbound:  2.33 Mi
Session Total:     4.68 Mi
Monthly Total:     13.28 Gi
MAC Address:       10:20:30:40:50:60
IP Address:        166.111.0.1

Device Details:
  Device 1:
    Rad Online ID: 400000078
    IPv4 Address:  59.66.0.1
    IPv6 Address:  2402:f000::1

  Device 2:
    Rad Online ID: 400000088
    IPv4 Address:  166.111.0.1
    IPv6 Address:  2402:f000::2
    Class Name:    Linux
    OS Name:       Linux

System Version:    1.01.20250403
```

### 技巧

使用 [pass](https://www.passwordstore.org/) 存储密码:

```sh
$ tunet-bash --config --pass
username: qingxiaohua
passname: tsinghua/qingxiaohua
```

更多参数说明请查看手册页.

### systemd

以 root 用户作为系统服务运行:

```
sudo systemd enable --now tunet-bash.timer
```

## 功能

- [x] Auth 4
- [x] Auth 6

- [x] 登入登出
- [x] 当前用户查询
- [x] 在线时间, 流量查询
- [x] 余额查询
- [x] 在线设备查询

## 依赖

- bash
- openssl
- curl
- coreutils

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
- [某校园网认证 api 分析](https://www.ciduid.top/2022/0706/school-network-auth/)
- [tunet-python](https://github.com/yuantailing/tunet-python/)
- [GoAuthing](https://github.com/z4yx/GoAuthing)
- [Tiny Encryption Algorithm - Wikipedia](https://en.wikipedia.org/wiki/Tiny_Encryption_Algorithm)
- [Bash Bitwise Operators | Baeldung on Linux](https://www.baeldung.com/linux/bash-bitwise-operators)

## 已知问题

### 建华楼有线网 IPv6 同时宣告 SLAAC 以及 DHCPv6

校园网准入联动 (srun portal) 的 IPv6 地址必须是 DHCPv6 下发的.
但是建华楼有线网配置错误, 设备可能会错误拿到 SLAAC 地址.

## Change Log

### 1.3.1

- 移除日志中的时间戳
- 增加 systemd timer

### 1.3.0

- 应对校园网登出接口变更

### 1.2.9

- 修复在线设备查询错误

### 1.2.8

- 在仅有 IP6 连接下的兼容性

### 1.2.7

- 修复 Makefile 打包

### 1.2.6

- 修改 Makefile 打包

### 1.2.5

- 增加可选依赖: [pass](https://www.passwordstore.org/)
- 密码可以非明文存储

### 1.2.4

- 更通用的 shebang
- 打印版本

### 1.2.3

- 支持短选项组合
- 设置 `LC_ALL=C`

### 1.2.2

- 修复 `-a auto` 条件判断

### 1.2.1

- MAC, 在线设备数, 余额查询

### 1.2.0

- 支持 `--date-format` 选项
- 替换 `--v4`, `--v6` 选项为 `--auth`
- 允许自动确定 auth4 或 auth6

### 1.1.1

- 修复短选项解析错误

### 1.1.0

- 在线时间, 流量等查询
- 指定 auth4 或 auth6

### 1.0.1

- 合并 `tea.sh`, `tunet-bash.sh`
- 短选项支持

### 1.0.0

- 将 `tea.cpp` 部分换为 Bash 实现

### 0.3.0

- 更改命令格式
- 更改安装路径
- 增加 man 手册页

### 0.2.3

- 不再依赖 jq 解析 json

### 0.2.2

- 修复未登录下没有设置 v4 或 v6 的问题

### 0.2.1

- 修复有线网 auth6 跳转

### 0.2.0

- 针对校园网 2025-01-15 的升级, 更新获取 ac_id 的逻辑
- 针对校园网 2025-01-15 的升级, 更新 whoami 查询的逻辑
- 将 `tunet-bash.sh` 安装为 `tunet-bash`
