<h1 align="center">openwrt-daede</h1>

<p align="center">OpenWrt 一体包：<b>dae</b> 内核 + <b>daed</b> 配套 + <b>luci-app-daede</b> 管理界面。</p>

<p align="center">
  <code>dae/</code> 与 <code>daed/</code> Makefile 来自上游 <a href="https://github.com/kenzok8/wall">kenzok8/wall</a>，本仓库仅做打包与 LuCI 前端开发。改包请改 wall。
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/kenzok8/kenzok8/main/screenshot/daede/dae-logo.png" height="88" alt="dae">
  &nbsp;&nbsp;&nbsp;
  <img src="https://raw.githubusercontent.com/daeuniverse/daed/main/apps/web/public/logo-rounded.png" height="88" alt="daed">
</p>

## 固件支持

需要用于支持 `dae` / `daed` 的固件，可使用
[`kenzok8/imagebuilder`](https://github.com/kenzok8/imagebuilder) 构建。

## 界面预览

<details open>
<summary><b>Desktop Screenshots</b></summary>
<br>
<table>
<tr>
<td align="center"><b>dae Config</b><br><img width="400" src="https://raw.githubusercontent.com/kenzok8/kenzok8/main/screenshot/daede/dae-config.png"></td>
<td align="center"><b>daed Config</b><br><img width="400" src="https://raw.githubusercontent.com/kenzok8/kenzok8/main/screenshot/daede/daed-config.png"></td>
</tr>
<tr>
<td align="center"><b>Updates</b><br><img width="400" src="https://raw.githubusercontent.com/kenzok8/kenzok8/main/screenshot/daede/daede-updates.png"></td>
<td align="center"><b>Log</b><br><img width="400" src="https://raw.githubusercontent.com/kenzok8/kenzok8/main/screenshot/daede/daede-log.png"></td>
</tr>
</table>
</details>

<details>
<summary><b>Mobile Screenshots</b></summary>
<br>
<table>
<tr>
<td align="center"><b>Config</b><br><img width="200" src="https://raw.githubusercontent.com/kenzok8/kenzok8/main/screenshot/daede/mobile-daede-config.png"></td>
<td align="center"><b>Updates</b><br><img width="200" src="https://raw.githubusercontent.com/kenzok8/kenzok8/main/screenshot/daede/mobile-daede-updates.png"></td>
<td align="center"><b>Log</b><br><img width="200" src="https://raw.githubusercontent.com/kenzok8/kenzok8/main/screenshot/daede/mobile-daede-log.png"></td>
</tr>
</table>
</details>

## 安装

### 一键安装

```bash
wget -O - https://raw.githubusercontent.com/kenzok8/openwrt-daede/refs/heads/main/scripts/install.sh | ash
```

大陆网络加速：

```bash
wget --no-check-certificate -O - https://ghfast.top/https://raw.githubusercontent.com/kenzok8/openwrt-daede/refs/heads/main/scripts/install.sh | ash
```

### Release 手动安装

在 OpenWrt 路由器上执行以下命令：

```bash
wget -qO- https://down.dllkids.xyz/openwrt-feed/openwrt-feed-setup.sh | sh
```

脚本自动完成：

- ✅ 检测 SDK 版本（24.10 / 25.12）与处理器架构
- ✅ 检测该架构 feed 是否存在（覆盖 `Packages.gz` / `APKINDEX.tar.gz` / `packages.adb` 三类索引），缺则回退 `all`
- ✅ 下载对应公钥，opkg → `opkg-key add`；apk → 放入 `/etc/apk/keys/`
- ✅ 写入/更新源配置（`customfeeds.conf` 或 `/etc/apk/repositories`），不会重复堆积
- ✅ 执行 `opkg update` / `apk update`，签名校验失败时自动回退 `--allow-untrusted`
- ✅ `apk update && apk add dae daed luci-app-daede`

### 卸载

```bash
wget -O - https://raw.githubusercontent.com/kenzok8/openwrt-daede/refs/heads/main/scripts/uninstall.sh | ash
```

## 使用

1. 安装后进入 LuCI「服务 → daede」
2. 选择后端（dae 或 daed）
3. 导入配置文件并启动

📖 **新手教程**：[dae 后端使用指南](https://github.com/kenzok8/openwrt-daede/wiki) —— 订阅、节点、分组、路由、DNS 怎么填，常见问题一篇讲清。

## 依赖

| 包名 | 说明 |
|------|------|
| `ca-bundle` | CA 证书包 |
| `kmod-sched-core` | eBPF 调度核心 |
| `kmod-sched-bpf` | eBPF 流量分类 |
| `kmod-veth` | 虚拟以太网设备 |
| `kmod-xdp-sockets-diag` | XDP socket 诊断 |
| `kmod-nft-tproxy` | nftables TPROXY 支持 |

dae / daed 二进制由用户按需安装，luci-app-daede 的 Makefile 会自动拉取对应后端包。

## 系统要求

- OpenWrt 24.10+（推荐 25.x）

## 致谢

- [dae](https://github.com/daeuniverse/dae) — 高性能透明代理
- [daed](https://github.com/daeuniverse/daed) — dae 的 Dashboard 增强版

## 许可证

见仓库内 LICENSE 文件。
