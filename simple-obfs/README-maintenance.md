# simple-obfs 维护说明（维护模式）

## 当前定位

simple-obfs 已长期停更。当前仓库策略是：

- 以 **兼容性维护** 为主（保证新工具链可编译）
- 不做大规模功能迭代
- 优先保证打包可复现、构建稳定

## 关键设计

### 1) 版本来源

- 上游基础：`simple-obfs v0.0.7`
- 本仓库发布：`v0.0.9`（仅做构建可复现增强）

### 2) libcork 处理

历史问题：`v0.0.7` 的 `libcork` 是 submodule gitlink，tarball 不含子模块内容，导致构建中 autoreconf/Makefile 链路失败。

当前方案：

- 在 `kenzok8/simple-obfs v0.0.9` 中直接 **vendor libcork 源码**
- 打包阶段不再在线 `git clone` libcork
- OpenWrt 包仅使用固定 tarball + hash

收益：

- 构建可复现
- 减少 CI 网络依赖
- 降低“偶发失败”概率

## 打包规范

`Makefile` 关键字段：

- `PKG_VERSION:=0.0.9`
- `PKG_SOURCE_URL:=https://codeload.github.com/kenzok8/simple-obfs/tar.gz/v$(PKG_VERSION)?`
- `PKG_HASH:=f9c05de42608691dad77c707504ad855191cd26ccd7095a0b3d4be939055111e`
- `PKG_FIXUP:=autoreconf`

## 排错要点

1. 先看 `logs/package/feeds/packages_ci/simple-obfs/compile.txt`
2. 常见失败关键词：
   - `No targets specified and no makefile found`
   - `required file 'libcork/Makefile.in' not found`
3. 优先确认：
   - 版本和 hash 是否一致
   - 是否误回退到旧版（v0.0.7）

## 未来路线（建议）

- simple-obfs 保持兼容包定位
- 新能力优先放到更活跃的替代方案
- 若要继续维护，仅做最小兼容补丁（工具链/警告）
