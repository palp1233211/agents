# Step 3：验证检查模板

## 验证目标

确认三件事：
1. 项目中零 webcommon 残留引用
2. 项目在 Docker 环境中可正常构建和加载
3. 已有测试全部通过

## 验证步骤

### 1. 零引用检查

```bash
# 在 Docker 容器中执行
# 搜索所有 PHP 文件中对 webcommon 的引用（排除 webcommon 目录本身）
grep -rn "webcommon" --include="*.php" {项目路径} | grep -v "{webcommon目录}"

# 搜索配置文件中的 webcommon 引用
grep -rn "webcommon" --include="*.json" --include="*.yaml" --include="*.yml" --include="*.xml" --include="*.ini" {项目路径} | grep -v "{webcommon目录}"

# 搜索 composer.json 中的 webcommon 引用
grep -n "webcommon" {项目路径}/composer.json
```

**预期结果**：零匹配（或仅 webcommon 目录内部的自引用）

### 2. 构建验证

```bash
# 在 Docker 容器中执行
# 清除缓存
docker exec -it {php_container} php {项目路径}/artisan cache:clear  # Laravel
docker exec -it {php_container} composer dump-autoload -d {项目路径}  # 重新生成 autoload

# 验证 autoload
docker exec -it {php_container} php -r "require '{项目路径}/vendor/autoload.php'; echo 'Autoload OK';"

# 验证无 fatal error
docker exec -it {php_container} php {项目入口} 2>&1 | head -50
```

**预期结果**：无 class not found、file not found 错误

### 3. 测试验证

```bash
# 在 Docker 容器中执行
docker exec -it {php_container} php {项目路径}/vendor/bin/phpunit --configuration {phpunit配置路径}
```

**预期结果**：所有测试通过，或失败的测试与迁移无关（需说明原因）

## 产出格式

```
## 验证报告：{项目名}

### 验证时间：{YYYY-MM-DD HH:mm}

### 1. 零引用检查

| 检查项 | 结果 | 详情 |
|--------|------|------|
| PHP 文件 webcommon 引用 | ✅ 零残留 / ❌ 有残留 | {残留列表或"无"} |
| 配置文件 webcommon 引用 | ✅ 零残留 / ❌ 有残留 | {残留列表或"无"} |
| composer.json 引用 | ✅ 已清理 / ❌ 仍有引用 | {详情} |

### 2. 构建验证

| 检查项 | 结果 | 详情 |
|--------|------|------|
| Autoload 生成 | ✅ 成功 / ❌ 失败 | {错误信息或"正常"} |
| 项目加载 | ✅ 无错误 / ❌ 有错误 | {错误信息或"正常"} |
| Class not found | ✅ 无 / ❌ 有 | {缺失类列表或"无"} |

### 3. 测试验证

| 检查项 | 结果 | 详情 |
|--------|------|------|
| 测试执行 | ✅ 全部通过 / ⚠️ 部分失败 / ❌ 执行失败 | {通过数/失败数/跳过数} |
| 失败用例（如有） | - | {失败用例列表及原因分析} |

### 4. 总结

| 维度 | 状态 |
|------|------|
| 零引用 | ✅ / ❌ |
| 可构建 | ✅ / ❌ |
| 测试通过 | ✅ / ⚠️ / ❌ |
| **整体判定** | **通过 / 不通过** |

{如不通过，列出需要处理的问题}
```
