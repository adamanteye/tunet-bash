# 清华大学校园网准入脚本自述文档

## 特点

-   Bash 编写, 适合 Live CD 引导装机, 小主机登录维持等场景

## 使用

```sh
export TUNET_USERNAME=<your username>
export TUNET_PASSWORD=<your password>
export LOG_LEVEL=debug # default info
./tunet_bash.sh login
```

## 功能

-   [x] Auth 4
-   [ ] Auth 6
-   [ ] Net

-   [x] 登入登出
-   [ ] 流量查询

## 依赖

-   bash
-   openssl
-   curl
-   clang 或 gcc

## 参考

-   [tunet-rust](https://github.com/Berrysoft/tunet-rust)
-   [tunet-python](https://github.com/yuantailing/tunet-python/)
-   [某校园网认证api分析](https://www.ciduid.top/2022/0706/school-network-auth/)
