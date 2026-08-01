

# README del Script de Autenticación de Red de la Universidad de Tsinghua

## Características

Implementado en Bash, ideal para escenarios como instalación desde Live CD, mantenimiento de sesión en mini PCs, etc.

## Guía de Uso

### Instalación desde el Gestor de Paquetes

#### Arch

```
paru -S tunet-bash
```

#### Debian

```sh
sudo curl -fsS https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x744233565e837dd4b918d9ef53d64eb719901bd8 -o /etc/apt/keyrings/debian.adamanteye.cc.asc

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

### Instalación desde el Código Fuente

```sh
make install
```

O instalar en una ruta personalizada:

```sh
sudo make prefix=/usr/local install
```

Para desinstalar:

```sh
make uninstall
```

Nota: La instalación desde código fuente **no copia por defecto** las tareas programadas de `systemd`. Si es necesario, modifique los archivos en el directorio de `systemd`, cambie `/usr/bin/tunet-bash` por la ruta real e instale los archivos en `/etc/systemd/system/tunet-bash.service` y `/etc/systemd/system/tunet-bash.timer`.

### Ejemplos

Configure el nombre de usuario y la contraseña; se guardarán en `$HOME/.cache/tunet-bash/passwd`:

```sh
tunet-bash --config
username: qingxiaohua
password:
```

Iniciar sesión con auth4

```sh
tunet-bash --login --auth 4
INFO auth4 login
INFO login_ok
```

Consultar el usuario actualmente conectado:

```sh
tunet-bash --whoami
qingxiaohua
```

```sh
tunet-bash --whoami --verbose
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

Usar [pass](https://www.passwordstore.org/) para almacenar la contraseña:

```sh
tunet-bash --config --pass
username: qingxiaohua
passname: tsinghua/qingxiaohua
```

Para más información sobre los parámetros, consulte la página de manual.

### systemd

**Este soporte aún no está completo y pueden existir problemas desconocidos**

Habilitar la tarea programada:

```sh
sudo systemd enable --now tunet-bash.timer
```

Ver el registro (si no hay salida, intente cambiar el nivel de registro a `LogLevelMax=info`):

```sh
sudo journalctl -u tunet-bash.service
```

Modificar la tarea programada:

```sh
sudo systemctl edit tunet-bash.service
```

```
# 首先赋空 `ExecStart`, 然后指定新命令:
[Service]
ExecStart=
ExecStart=/usr/bin/tunet-bash --assert --curl-extra-args '--interface' --curl-extra-args 'tunet'
```

## Funcionalidades

- [x] Auth 4
- [x] Auth 6

- [x] Inicio y cierre de sesión
- [x] Consulta de usuario actual
- [x] Consulta de tiempo de conexión y tráfico
- [x] Consulta de saldo
- [x] Consulta de dispositivos en línea

- [x] Salida en formato JSON

- [ ] Desconectar IP específica
- [ ] Autenticación delegada de acceso

- [ ] Compatibilidad con macOS

## Dependencias

- bash
- openssl
- curl
- coreutils

## Dependencias Opcionales

- [pass](https://www.passwordstore.org/)
- jq

## Dependencias de Construcción

- make
- [scdoc](https://git.sr.ht/~sircmpwn/scdoc)

## Referencias

Los siguientes proyectos o blogs sirvieron de referencia para implementar la lógica de autenticación en Bash:

- [tunet-rust](https://github.com/Berrysoft/tunet-rust)
- [清华校园网自动连接脚本](https://github.com/WhymustIhaveaname/TsinghuaTunet)
- [某校园网认证 api 分析](https://www.ciduid.top/2022/0706/school-network-auth/)
- [tunet-python](https://github.com/yuantailing/tunet-python/)
- [GoAuthing](https://github.com/z4yx/GoAuthing)
- [Tiny Encryption Algorithm - Wikipedia](https://en.wikipedia.org/wiki/Tiny_Encryption_Algorithm)
- [Bash Bitwise Operators | Baeldung on Linux](https://www.baeldung.com/linux/bash-bitwise-operators)

## Problemas Conocidos

### La red cableada del edificio Jianhua anuncia simultáneamente SLAAC y DHCPv6 para IPv6

La dirección IPv6 para la autenticación de acceso a la red campus (portal srun) debe ser asignada por DHCPv6.
Sin embargo, debido a una configuración incorrecta en la red cableada del edificio Jianhua, los dispositivos pueden obtener erróneamente una dirección SLAAC.

## [Registro de Cambios](./CHANGELOG.md)
