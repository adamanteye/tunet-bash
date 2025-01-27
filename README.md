# 清华大学校园网准入脚本自述文档

## 特点

功能通过 Bash 实现, 适合 Live CD 引导装机, 小主机登录维持等场景.

## 使用指南

### 安装

```sh
make install # default to $HOME/.local
```

或者安装到自定义路径:

```sh
sudo make PREFIX=/usr/local install
```

### 命令

```sh
export TUNET_USERNAME=<your username>
export TUNET_PASSWORD=<your password>
export LOG_LEVEL=debug # default info
tunet_bash --login
```

或者, 也可以将用户名和密码写入 `$HOME/.cache/tunet_bash/passwd` 文件中, 这一过程可以通过以下命令完成:

```sh
tunet_bash --config
```

如果查询当前登入用户, 可以使用:

```sh
tunet_bash --whoami
```

## 功能

- [x] Auth 4
- [x] Auth 6
- [ ] Net

- [x] 登入登出
- [x] 当前用户查询
- [ ] 历史流量查询

## 依赖

- bash
- openssl
- curl

## 构建依赖

- make
- scdoc

## 参考

以下项目或博客为实现 bash 版本的认证逻辑提供了参考:

- [tunet-rust](https://github.com/Berrysoft/tunet-rust)
- [清华校园网自动连接脚本](https://github.com/WhymustIhaveaname/TsinghuaTunet)
- [某校园网认证api分析](https://www.ciduid.top/2022/0706/school-network-auth/)
- [tunet-python](https://github.com/yuantailing/tunet-python/)
- [GoAuthing](https://github.com/z4yx/GoAuthing)
- [Tiny Encryption Algorithm - Wikipedia](https://en.wikipedia.org/wiki/Tiny_Encryption_Algorithm)
- [Bash Bitwise Operators | Baeldung on Linux](https://www.baeldung.com/linux/bash-bitwise-operators)

## Change Log

### v1.0.1

- 合并 `tea.sh`, `tunet_bash.sh`
- 短选项支持

### v1.0.0

- 将 `tea.cpp` 部分换为 bash 实现

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
