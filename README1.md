![Anurag's GitHub stats](https://github-readme-stats.vercel.app/api?username=kenzok8&show_icons=true&theme=radical)
<div align="center">
<h1 align="center"openwrt-packages</h1>
<img src="https://img.shields.io/github/issues/kenzok8/openwrt-packages?color=green">
<img src="https://img.shields.io/github/stars/kenzok8/openwrt-packages?color=yellow">
<img src="https://img.shields.io/github/forks/kenzok8/openwrt-packages?color=orange">
<img src="https://img.shields.io/github/languages/code-size/kenzok8/openwrt-packages?color=blueviolet">
</div>

<img src="https://v2.jinrishici.com/one.svg?font-size=24&spacing=2&color=Black">

#### 说明 

<br>中文

* 把openwrt-packages与small仓库重新归类，ssr、passwall、vssr以及依赖合并small

#### 使用方式
```yaml
文件说明 🎈:

默认ssr与passwall的插件与依赖整合包

使用方法：将整合包上传到openwrt设备的tmp目录，输入命令 opkg install *.ipk

默认压缩包里包含ssr passwall bypass passwall2 插件

如果单独安装ssr与依赖，rm -rf {*passwall*,*bypass*,*vssr*}
```

* 喜欢追新的可以去下载small-package，该仓库每天自动同步更新

* [small-package仓库地址](https://github.com/kenzok8/small-package) 

* 软件不定期同步大神库更新，适合一键下载用于openwrt编译


##### 插件每日更新下载:
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/kenzok8/small?style=for-the-badge&label=插件下载)](https://github.com/kenzok8/small/releases/latest)

+ [ssr+passwall依赖仓库](https://github.com/kenzok8/small)

+ [openwrt固件与插件下载](https://op.dllkids.xyz/)

#### 使用
一键命令
```yaml
sed -i '$a src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '$a src-git small https://github.com/kenzok8/small' feeds.conf.default
git pull
./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig
```


