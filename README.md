# 清华大学校园网准入脚本自述文档

## 特点

功能通过 Bash 实现, 适合 Live CD 引导装机, 小主机登录维持等场景.

## 使用指南

### 从包管理器安装

#### Arch

```
$ paru -S tunet-bash
```

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

注意: 从源码安装**默认不会**拷贝 `systemd` 定时任务, 如果有需求请修改 `systemd`
下的文件, 将 `/usr/bin/tunet-bash` 改为实际的路径, 并将文件安装到
`/etc/systemd/system/tunet-bash.service` 与
`/etc/systemd/system/tunet-bash.timer`.

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

**此支持尚不完全, 可能存在未知的问题**

启用定时任务:

```sh
$ sudo systemd enable --now tunet-bash.timer
```

查看日志 (如果没有输出, 可尝试修改日志等级为
`LogLevelMax=info`
):

```sh
$ sudo journalctl -u tunet-bash.service
```

## 功能

- [x] Auth 4
- [x] Auth 6

- [x] 登入登出
- [x] 当前用户查询
- [x] 在线时间, 流量查询
- [x] 余额查询
- [x] 在线设备查询

- [ ] 下线特定 IP
- [ ] 准入代认证

- [ ] 兼容 macOS

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

查看[变更日志](./CHANGELOG.md).
