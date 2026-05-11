# Step 0：依赖扫描产出模板

## 扫描方式

**必须使用 `Agent(subagent_type: Explore)` 执行扫描**，不在主上下文加载项目代码。

### 扫描命令参考

```bash
# 1. 查找所有引用 webcommon 的 PHP 文件
grep -rn "webcommon" --include="*.php" {项目路径}

# 2. 查找 use 语句中引用 webcommon 命名空间的
grep -rn "^use.*webcommon" --include="*.php" {项目路径}

# 3. 查找 require/include 引用 webcommon 路径的
grep -rn "require\|include" --include="*.php" {项目路径} | grep "webcommon"

# 4. 查找 extends/implements webcommon 类的
grep -rn "extends\|implements" --include="*.php" {项目路径} | grep "webcommon"

# 5. 查找配置文件中的 webcommon 引用
grep -rn "webcommon" --include="*.json" --include="*.yaml" --include="*.yml" --include="*.xml" --include="*.ini" {项目路径}

# 6. 查看 webcommon 目录结构
find {webcommon路径} -name "*.php" -type f
```

## 产出格式

### 1. webcommon 目录结构概览

```
{webcommon路径}/
├── src/
│   ├── ...
├── sdk/
│   ├── ...
├── ...
```

### 2. A 类 - webcommon 自有代码依赖

| 序号 | 项目文件 | 依赖的 webcommon 文件 | 依赖方式 | 依赖的具体类/函数/常量 |
|------|---------|---------------------|---------|----------------------|
| 1 | `{项目文件路径}` | `{webcommon文件路径}` | use/require/extends | `{具体符号}` |

### 3. B 类 - SDK 依赖

| 序号 | 项目文件 | 依赖的 SDK 文件 | 依赖方式 | SDK 名称 |
|------|---------|----------------|---------|---------|
| 1 | `{项目文件路径}` | `{SDK文件路径}` | use/require | `{SDK名}` |

### 4. C 类 - 加载入口

| 序号 | 配置文件 | 加载方式 | 说明 |
|------|---------|---------|------|
| 1 | `{配置文件路径}` | autoload/bootstrap/config | `{说明}` |

### 5. 依赖链分析

```
被依赖层（底层，无其他 webcommon 依赖）：
  - {文件1}
  - {文件2}

中间层（依赖底层 webcommon 文件）：
  - {文件3} → 依赖 {文件1}

上层（依赖中间层）：
  - {文件4} → 依赖 {文件3}
```

### 6. 统计汇总

| 分类 | 文件数 | 引用点数 |
|------|--------|---------|
| A 类 - 自有代码 | - | - |
| B 类 - SDK | - | - |
| C 类 - 加载入口 | - | - |
| **总计** | - | - |
