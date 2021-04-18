#### 说明

* 软件不定期同步大神库更新，适合一键下载到package目录下，用于openwrt编译

* 两位L大库里都少了某软件，作为搬运工，passwall的依赖一并找齐了


 1、 lede/package$下运行 或者openwrt/package$下运行

```bash
 git clone https://github.com/kenzok8/small.git
```
 2、 或者添加下面代码到 openwrt 或lede源码根目录feeds.conf.default文件
 
```bash
 src-git small https://github.com/kenzok8/small
```

