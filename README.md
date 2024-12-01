# 清华大学校园网准入脚本自述文档

## 特点

-   主要功能通过 Bash 实现, 适合 Live CD 引导装机, 小主机登录维持等场景
-   因为 srun 的自定义签名算法用 Bash 实现较为困难, 所以这一部分使用 C++ 编写

## 使用指南

### 安装

```sh
make all
make install # default to $HOME/.tunet_bash
```

或者安装到自定义路径

```sh
make PREFIX=/usr/local/bin/tunet_bash install
```

注意, tunet_bash 需要在安装目录下创建临时文件, 请确保安装目录有写入权限.

### 命令

```sh
export TUNET_USERNAME=<your username>
export TUNET_PASSWORD=<your password>
export LOG_LEVEL=debug # default info
./tunet_bash.sh login
```

或者, 也可以将用户名和密码写入文件夹所在的 `.env` 文件中, 这一过程可以通过以下命令完成

```sh
./tunet_bash.sh config
```

如果查询当前登入用户, 可以使用

```sh
./tunet_bash.sh whoami
```

## 功能

-   [x] Auth 4
-   [ ] Auth 6
-   [ ] Net

-   [x] 登入登出
-   [x] 当前用户查询
-   [ ] 历史流量查询

## 依赖

-   bash
-   openssl
-   curl
-   make
-   clang++ 或 g++

## 参考与致谢

-   [tunet-rust](https://github.com/Berrysoft/tunet-rust)
-   [清华校园网自动连接脚本](https://github.com/WhymustIhaveaname/TsinghuaTunet)
-   [某校园网认证api分析](https://www.ciduid.top/2022/0706/school-network-auth/)
-   [tunet-python](https://github.com/yuantailing/tunet-python/)
-   [GoAuthing](https://github.com/z4yx/GoAuthing)
