![Anurag's GitHub stats](https://github-readme-stats.vercel.app/api?username=kenzok8&show_icons=true&&theme=transparent)
<div align="center">
<h1 align="center"small</h1>
<img src="https://img.shields.io/github/issues/kenzok8/small?color=green">
<img src="https://img.shields.io/github/stars/kenzok8/small?color=yellow">
<img src="https://img.shields.io/github/forks/kenzok8/small?color=orange">
<img src="https://img.shields.io/github/languages/code-size/kenzok8/small?color=blueviolet">
</div>

<img src="https://v2.jinrishici.com/one.svg?font-size=24&spacing=2&color=Black">


* small仓库不定期添加主流代理软件，ssr、passwall、homeproxy、mihomo等

#### 使用方式
```yaml

默认ssr与passwall的插件与依赖整合包

使用方法：将整合包上传到openwrt设备的tmp目录，输入命令 opkg install *.ipk

默认压缩包里包含ssr passwall bypass passwall2 homeproxy mihomo插件

如果单独安装ssr与依赖，rm -rf {*passwall*,*bypass*,*homeproxy*,*mihomo*}
```

* 喜欢追新的可以去下载small-package，该仓库每天自动同步更新

* [small-package仓库地址](https://github.com/kenzok8/small-package) 


##### 插件每日更新下载:
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/kenzok8/small?style=for-the-badge&label=插件下载)](https://github.com/kenzok8/small/releases/latest)

+ [ssr+passwall依赖仓库](https://github.com/kenzok8/small)

+ [openwrt固件与插件下载](https://op.dllkids.xyz/)

#### 使用
一键命令(防止插件冲突，删除重复)
```yaml
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default
./scripts/feeds update -a && rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,v2ray*,sing*,smartdns}
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/packages/lang/golang
git clone https://github.com/kenzok8/golang feeds/packages/lang/golang
./scripts/feeds install -a 
make menuconfig
```

#### 注意
编译新版Sing-box和hysteria，尽量使用golang版本1.22以上版本 ，可以用以下命令
```yaml
rm -rf feeds/packages/lang/golang
git clone https://github.com/kenzok8/golang feeds/packages/lang/golang
```

