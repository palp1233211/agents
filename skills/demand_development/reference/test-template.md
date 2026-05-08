## 测试策略模板（Step 3）

> 根据 Step 0 功能点和 Step 1 接口设计制定测试方案

### 章节地图

| 分组 | 章节 |
|------|------|
| 前置 | 3.0.1 选型 / 3.0.2 Docker |
| 脚手架 | 3.1 类型 / 3.2 目录 / 3.3 bootstrap / 3.4 国家配置 |
| 编写测试 | 3.5 文件模板 / 3.7 FAQ / 3.8 数据管理 |
| 防伪三件套 | **3.9 对照实验 / 3.10 主动构造 / 3.12 空结果防伪** |
| 专项 | 3.11 ETL 备份还原 |
| 执行验收 | 3.6 执行命令 / **3.13 自检中心** |

> 新写测试**必读**：3.5（模板）→ 3.9 + 3.10 + 3.12（三件套）→ 3.13（提交前自检）。

---

## 3.0.1 测试方案选型说明

**项目标准：PHPUnit 8.5（已安装并配置）**

| 项 | 实际值 |
|---|---|
| PHP | 7.2.34 |
| Phalcon | 3.3.2 |
| PHPUnit | 8.5.52（`vendor/bin/phpunit`） |
| 配置文件 | `phpunit.xml`（已配 testsuites = `Unit` + `Feature`，bootstrap = `tests/bootstrap.php`） |
| 启动方式 | `docker exec {container} ./vendor/bin/phpunit` |

### 强制规范

1. **新测试一律 `extends PHPUnit\Framework\TestCase`** — 使用标准断言 `assertSame / assertEquals / assertCount / assertContains` 等，禁止手写 `$passCount / $failCount` 计数器
2. **测试目录与命名遵循 `phpunit.xml`** — Unit 测试放 `tests/Unit/{需求号}/`，类名以 `Test.php` 结尾
3. **bootstrap 不重复** — `tests/bootstrap.php` 已由 `phpunit.xml` 自动加载（无需在测试文件 `require_once`），自定义命名空间在测试类内部用 `\Phalcon\Loader` 注册即可
4. **遗留手写风格用例**（如 `tests/Unit/23972/AbnormalBLLComplaintsFilterTest.php` 这种自己维护 `passCount/failCount` 的）— 后续触动时迁移到 PHPUnit，不再新增此风格

### 关于 PHPUnit 8.5 而非 9+

PHP 7.2 锁定了 PHPUnit 上限，**不要升级**。这意味着：
- 用 `assertEquals` 而非 `assertEqualsCanonicalizing`（9+ 才有）
- 用 `expectException` 替代 `@expectedException` 注解
- `phpunit.xml` 的 `<coverage>` 是 PHPUnit 9+ 语法，8.5 会报 warning（功能不影响），项目里如果有该写法应迁回 `<filter><whitelist>` 但属于配置修复，与本模板无关

---

## 3.0.2 前置条件：Docker 环境 ⚠️

**所有测试必须在 Docker 容器中执行，本机环境不可用。**

### 执行前必须检查

```bash
# 1. 确认容器运行状态
docker ps

# 2. 进入容器
docker exec -it {container_name} bash

# 3. 确认国家配置正确
docker exec {container} cat /mnt/www/.env | grep country_code
```

**详见：** [docker-containers.md](docker-containers.md)

---

## 3.1 测试类型划分

| 类型 | 覆盖范围 | 框架 |
|------|----------|------|
| 单元测试 | 核心业务逻辑、数据转换、校验函数 | PHP CLI（手写测试类，见选型说明） |
| 集成测试 | API接口、数据库操作、外部服务调用 | PHP CLI（手写测试类，见选型说明） |

### 覆盖目标
- 最低覆盖率：**80%**
- 核心模块覆盖率：**90%+**

### 测试优先级定义
- **P0 必测**：核心业务路径、安全相关
- **P1 重点测**：主要功能分支、边界条件
- **P2 边界测**：异常场景、极端输入

---

## 3.2 测试目录结构

```
project/
├── tests/
│   ├── bootstrap.php                    # 测试引导文件
│   ├── Unit/                            # 单元测试
│   │   └── 23921/                       # {需求号}/
│   │       └── ExampleBLLTest.php       # {类名}Test.php
│   └── Integration/                     # 集成测试
│       └── 23921/
│           └── ExampleAPITest.php
```

> **命名规范**：测试文件按需求号分目录存放，类名不以数字开头。

---

## 3.3 Phalcon 项目测试引导文件模板

**文件位置**：`tests/bootstrap.php`

```php
<?php
/**
 * Phalcon 项目测试引导文件
 */

define('BASE_PATH', '/mnt/www');
define('APP_PATH', BASE_PATH . '/app');
define('RUNTIME', 'dev');

require BASE_PATH . '/vendor/autoload.php';

// CLI 环境变量预设（解决 CLI 模式缺少 Web 变量问题）
$_SERVER['REQUEST_METHOD'] = $_SERVER['REQUEST_METHOD'] ?? 'CLI';
$_SERVER['REQUEST_URI'] = $_SERVER['REQUEST_URI'] ?? '/test';
$_SERVER['HTTP_HOST'] = $_SERVER['HTTP_HOST'] ?? 'localhost';

// 按国家代码加载对应环境配置
$countryCode = getenv('country_code') ?: 'Th';
$envFile = 'env.' . strtolower($countryCode);

if (file_exists(BASE_PATH . '/' . $envFile)) {
    $dotenv = new Dotenv\Dotenv(BASE_PATH, $envFile);
} else {
    $dotenv = new Dotenv\Dotenv(BASE_PATH);
}
$dotenv->load();

// 初始化 DI
$di = new Phalcon\Di\FactoryDefault();

// 加载服务配置
include APP_PATH . '/config/services.php';

// 加载自动加载器
include APP_PATH . '/config/loader.php';

// 设置全局 DI
Phalcon\Di::setDefault($di);

return $di;
```

---

## 3.4 数据库配置获取规范

Phalcon 项目按国家区分配置文件：

| 文件 | 说明 |
|------|------|
| `env.th` | 泰国环境配置 |
| `env.ph` | 菲律宾环境配置 |
| `env.my` | 马来西亚环境配置 |
| `.env` | 当前生效配置 |

### 测试前必须确认

```bash
# 1. 检查当前国家配置
docker exec {container} cat /mnt/www/.env | grep country_code

# 2. 切换到目标国家配置（如泰国）
docker exec {container} cp /mnt/www/env.th /mnt/www/.env

# 3. 验证数据库配置
docker exec {container} cat /mnt/www/.env | grep database
```

---

## 3.5 测试文件模板（PHPUnit 风格）

**文件位置**：`tests/Unit/{需求号}/{类名}Test.php`
**示例**：`tests/Unit/23921/ParcelReweighAppealReviewTest.php`

PHPUnit 8.5 + Phalcon 3.3 推荐模板：

```php
<?php
/**
 * 单元测试 - {ClassName}
 *
 * 需求编号: {需求号}
 * 测试用例：
 * - TC-001 [P0] 主路径功能验证
 * - TC-002 [P1] 边界条件
 *
 * 编写规则：
 * - 必须 extends TestCase（项目标准，见 3.0.1）
 * - 断言用具体值（assertSame / assertEquals / assertCount），禁止 !empty / count > 0 这类弱断言
 * - 条件类规则按 3.9 对照实验，空结果按 3.12 防伪
 */

use PHPUnit\Framework\TestCase;
use FlashExpress\bi\App\Modules\Th\BLL\YourBLL;   // 按真实命名空间替换

class YourBLLTest extends TestCase
{
    /** @var YourBLL */
    private $bll;
    /** @var \Phalcon\Db\Adapter\Pdo */
    private $db;

    /**
     * 注册被测模块命名空间（Phalcon 项目按 Country/Module 分目录加载）
     * setUpBeforeClass 只跑一次，比每个测试都注册更经济
     */
    public static function setUpBeforeClass(): void
    {
        $loader = new \Phalcon\Loader();
        $loader->registerNamespaces([
            'FlashExpress\bi\App\Modules\Th\BLL'    => APP_PATH . '/modules/Th/BLL/',
            'FlashExpress\bi\App\Modules\Th\Models' => APP_PATH . '/modules/Th/models/',
        ])->register();
    }

    protected function setUp(): void
    {
        $di        = \Phalcon\Di::getDefault();
        $this->db  = $di->get('db_bi_center_r');
        $this->bll = new YourBLL();
    }

    /**
     * TC-001: 主路径功能验证
     */
    public function testYourMethod_HappyPath(): void
    {
        // 准备测试数据（$testId 推荐使用不冲突的特定 ID，详见 3.8）
        $testId = 99999;
        $params = ['id' => $testId];

        // 先 SELECT 真实原值备份，禁止硬编码（见 3.10）
        $orig = $this->db->fetchOne(
            "SELECT test_field FROM your_table WHERE id = ?",
            \Phalcon\Db::FETCH_ASSOC,
            [$testId]
        );
        $this->assertNotEmpty($orig, '前置：测试基础数据存在（不存在则按 3.10 主动构造）');

        $this->db->execute(
            "UPDATE your_table SET test_field = ? WHERE id = ?",
            ['TEST_VALUE', $testId]
        );

        try {
            // 调用实际方法（禁止复制代码验证）
            $result = $this->bll->yourMethod($params);

            // ✅ 用具体值断言
            $this->assertIsArray($result, '返回值类型为数组');
            $this->assertArrayHasKey('expected_field', $result);
            $this->assertSame('EXPECTED_VALUE', $result['expected_field'], 'expected_field 等于期望值');
        } finally {
            // 还原真实原值
            $this->db->execute(
                "UPDATE your_table SET test_field = ? WHERE id = ?",
                [$orig['test_field'], $testId]
            );
        }
    }
}
```

> **不需要 `require_once bootstrap.php`** — `phpunit.xml` 已声明 `bootstrap="tests/bootstrap.php"`，运行 `vendor/bin/phpunit` 时自动加载。
> **不需要 `exit($success ? 0 : 1)`** — PHPUnit 自己按 fail/error 数量给退出码。
> **不需要自己写 `assert()` / `passCount` / `failCount`** — 一律使用 PHPUnit 内置断言。

---

## 3.6 测试执行命令

PHPUnit 已通过 `phpunit.xml` 配好 testsuites（`Unit` / `Feature`），统一用 `vendor/bin/phpunit` 执行。

```bash
# 跑指定需求所有用例（推荐，最常用）
docker exec {container} ./vendor/bin/phpunit tests/Unit/{需求号}

# 跑指定文件
docker exec {container} ./vendor/bin/phpunit tests/Unit/{需求号}/YourBLLTest.php

# 跑指定方法（按测试方法名过滤）
docker exec {container} ./vendor/bin/phpunit --filter testYourMethod_HappyPath tests/Unit/{需求号}

# 跑整个 Unit testsuite
docker exec {container} ./vendor/bin/phpunit --testsuite Unit

# 输出更详细信息
docker exec {container} ./vendor/bin/phpunit --testdox tests/Unit/{需求号}
```

> **退出码**：PHPUnit 自动汇总，0 = 全部通过，>0 = 有失败/错误。脚本里直接 `if ! ./vendor/bin/phpunit ...; then ...` 即可，无需手动聚合。
>
> **首次运行**：若新增了测试目录，确认 `phpunit.xml` 的 `<testsuite>` 路径已覆盖（默认是 `tests/Unit` 和 `tests/Feature` 下所有 `*Test.php`，按需求号分子目录会自动收录）。

> **注意**：Docker 容器已挂载整个项目目录，测试文件修改后直接生效，无需同步。

---

## 3.7 常见问题及解决方案

> 涉及"测试脚本位置"和"Phalcon 类找不到（bootstrap 加载顺序）"参见 3.2 和 3.3，本节不再重复。

### 问题 1：复制代码而非调用实际方法

**错误做法**：
```php
// ❌ 复制代码片段进行"模拟验证"
$effective_weight = ($weight == 0) ? 1 : $weight;
// 然后自己验证这个逻辑...
```

**正确做法**：
```php
// ✅ 调用实际方法验证行为
$bll = new YourBLL();
$result = $bll->yourMethod($params);
$this->assert('返回值等于期望值', $result === $expected);
```

---

### 问题 2：CLI 模式缺少 Web 环境变量

**报错**：
```
Undefined index: REQUEST_METHOD
Undefined index: REQUEST_URI
```

**解决方案**：在 `bootstrap.php` 中预设：
```php
$_SERVER['REQUEST_METHOD'] = $_SERVER['REQUEST_METHOD'] ?? 'CLI';
$_SERVER['REQUEST_URI'] = $_SERVER['REQUEST_URI'] ?? '/test';
$_SERVER['HTTP_HOST'] = $_SERVER['HTTP_HOST'] ?? 'localhost';
```

---

### 问题 3：数据库连接指向错误环境

**报错**：
```
Table 'wrong_db.your_table' doesn't exist
```

**解决方案**：
1. 确认当前国家配置：`cat .env | grep country_code`
2. 切换到正确的国家配置：`cp env.th .env`
3. 在 bootstrap.php 中按国家代码加载配置

---

### 问题 4：PHPUnit 找不到被测类（命名空间未注册）

**报错**：
```
Error: Class 'FlashExpress\bi\App\Modules\Th\BLL\YourBLL' not found
```

**原因**：`tests/bootstrap.php` 只注册了 Phalcon 的全局自动加载，没有按国家/模块注册子命名空间。

**解决方案**：在测试类的 `setUpBeforeClass()` 中显式注册（见 3.5 模板），不要去改全局 bootstrap：

```php
public static function setUpBeforeClass(): void
{
    $loader = new \Phalcon\Loader();
    $loader->registerNamespaces([
        'FlashExpress\bi\App\Modules\Th\BLL'    => APP_PATH . '/modules/Th/BLL/',
        'FlashExpress\bi\App\Modules\Th\Models' => APP_PATH . '/modules/Th/models/',
    ])->register();
}
```

---

### 问题 5：phpunit.xml `<coverage>` 配置导致 warning

**报错**（不影响测试结果）：
```
Warning - The configuration file did not pass validation!
Element 'coverage': This element is not expected.
```

**原因**：`<coverage>` 是 PHPUnit 9+ 语法，本项目使用 8.5。

**解决方案**：把 `phpunit.xml` 里的 `<coverage>` 改回 8.5 风格的 `<filter><whitelist>`（属于项目配置修复，不在测试模板范围内，由 OPS 同学统一处理）。

---

### 问题 6：测试间状态污染

**现象**：单跑某个测试通过，整套跑就有用例失败。

**原因**：上一个测试改了源数据未还原，或全局 DI 状态被污染。

**解决方案**：
- 数据修改一律 try-finally 还原（见 3.8 / 3.10）
- ETL 类用 `setUpBeforeClass` + `tearDownAfterClass` 做全套备份还原（见 3.11）
- 不在测试中用 `\Phalcon\Di::setDefault(...)` 替换全局 DI（会污染后续测试）

---

## 3.8 测试数据管理规范

1. **每个测试方法负责准备和清理自己的数据**
2. **使用 try-finally 确保清理执行**
3. **标记测试数据**（如 `TEST_` 前缀）便于识别
4. **优先使用不存在的 ID 或特定测试记录**

```php
public function testMethod(): void
{
    $testId = 99999;  // 使用特定测试 ID

    // SELECT 原值备份
    $orig = $this->db->fetchColumn("SELECT field FROM table WHERE id = ?", [$testId]);
    $this->assertNotFalse($orig, '前置：目标记录存在');

    $this->db->execute("UPDATE table SET field = ? WHERE id = ?", ['TEST_VALUE', $testId]);

    try {
        $result = $this->bll->method($params);
        $this->assertSame('EXPECTED', $result);
    } finally {
        // 还原真实原值
        $this->db->execute("UPDATE table SET field = ? WHERE id = ?", [$orig, $testId]);
    }
}
```

---

## 3.9 对照实验测试规范

> 适用范围：任何"条件生效"类规则 —— 剔除/过滤、权限校验、黑白名单、开关、降级路由、计次规则等。
> "剔除规则"是最常见的一种，但模式通用，不要被名字框死。

### ⛔ 禁止只验证"条件触发后的结果"

只断言"触发剔除 → count=0"是**伪测试**：count=0 可能是规则生效，也可能是数据本来就不存在、或被其它字段过滤掉了。

每条规则的测试用例**必须同时包含对照组与实验组**，并锁定同一条目标记录做增量断言：

| 阶段 | 操作 | 预期 | 证明 |
|------|------|------|------|
| 基线 | 规则执行前读取 count | `baseline` | 记录初始状态 |
| 对照组 | 目标记录**不触发**规则条件 | `count == baseline + 1` | 该条记录在正常情况下被计次 |
| 实验组 | 目标记录**触发**规则条件 | `count == baseline`（差值正好 1） | 规则生效且只影响了这一条 |

### ❌ 反例（常见伪测试）

```php
// ❌ 只有实验组，没有对照组
$this->db->execute("UPDATE t SET field = 'EXCLUDED' WHERE id = {$id}");
$this->runBll();
$this->assertSame(0, $this->getCount(), '被剔除');
// 问题：count=0 可能只是因为 id 根本不满足其它 WHERE 条件，规则是否生效不可知。
```

```php
// ❌ 对照组断言太弱（count > 0）
$this->assertGreaterThan(0, $this->getCount(), '正常数据被计次');
// 问题：表里任意一条命中的记录都能让断言通过，无法证明"目标 id"被计次。
```

### ✅ 正确写法

```php
public function testExclusionRule(): void
{
    // 1. 挑选/构造目标记录（如无满足条件的数据，参见 3.10 主动构造）
    $id = $this->pickTargetId();

    // 2. 先查出原值（⚠️ 不要硬编码 ORIGINAL_VALUE）
    $origField = $this->db->fetchColumn("SELECT field FROM t WHERE id = ?", [$id]);
    $this->assertNotFalse($origField, '前置：目标记录存在');

    // 3. 若被测 BLL 是写入型（ETL/聚合入库），实验前后必须清理结果表，见 3.11
    try {
        // ---- 基线 ----
        $this->resetResult();
        $baseline = $this->getCount();

        // ---- 对照组：确保目标记录不触发剔除条件 ----
        $this->db->execute("UPDATE t SET field = ? WHERE id = ?", ['NORMAL_VALUE', $id]);
        $this->resetResult();
        $this->runBll();
        $this->assertSame($baseline + 1, $this->getCount(), '对照组：目标记录被计次');

        // ---- 实验组：触发剔除条件 ----
        $this->db->execute("UPDATE t SET field = ? WHERE id = ?", ['EXCLUDED_VALUE', $id]);
        $this->resetResult();
        $this->runBll();
        $this->assertSame($baseline, $this->getCount(), '实验组：剔除规则生效');

    } finally {
        // 还原真实原值，而非硬编码字面量
        $this->db->execute("UPDATE t SET field = ? WHERE id = ?", [$origField, $id]);
    }
}
```

### 复合条件必须拆项

真实剔除规则通常是 `WHERE A AND B AND C`。只测"整条规则命中"会漏掉单条件写错的场景。对每个条件各起一个 TC：

| TC | A | B | C | 预期 |
|----|---|---|---|------|
| TC-only-A | ✔ | ✘ | ✘ | 被计次 |
| TC-A-B | ✔ | ✔ | ✘ | 被计次 |
| TC-all | ✔ | ✔ | ✔ | 被剔除 |

**边界值单独测**：条件是 `>=` 还是 `>`？临界点（如 `= N`）必须有独立 TC，用以区分两种写法。

### 自检：反向失败校验

> 自检清单已统一到 3.13，本节只需关注"注释规则代码 → 实验组必须 FAIL"这一项；写完所有测试后到 3.13 一并核对。

---

## 3.10 数据不存在时的处理规范

### ⛔ 禁止因数据不存在就 SKIP

当查询不到满足条件的数据时，**不能直接跳过（SKIP）测试用例**。SKIP 等同于没有测试，无法证明功能正确。

**正确做法**：主动构造或修改已有数据来满足测试条件。

```php
// ❌ 错误：数据不存在就跳过 / SKIP
$record = $this->db->fetchOne($sql);
if (empty($record)) {
    $this->markTestSkipped('无数据，跳过');   // SKIP 等同于没测试
    return;
}

// ✅ 正确：找到可用记录，先取出原值，再临时修改，finally 还原
$record = $this->db->fetchOne(
    "SELECT id, field FROM table WHERE ... LIMIT 1",
    \Phalcon\Db::FETCH_ASSOC
);
$this->assertNotEmpty($record, '前置：找到可用记录（找不到则按下方优先级主动构造）');

$origField = $record['field'];   // ⚠️ 必须先备份真实原值，禁止硬编码
$this->db->execute(
    "UPDATE table SET field = ? WHERE id = ?",
    ['TEST_STATE', $record['id']]
);
try {
    // 执行测试...
} finally {
    // 还原真实原值
    $this->db->execute(
        "UPDATE table SET field = ? WHERE id = ?",
        [$origField, $record['id']]
    );
}
```

**构造数据的优先级**：
1. 修改已有记录的某个字段（最简单，try-finally 还原）
2. 插入新测试记录（需要了解完整表结构，finally 中 DELETE 清理）

---

## 3.11 ETL 任务测试专项规范

ETL 任务调用 `run()` 方法时会对结果表执行 DELETE + INSERT（幂等写入），可能覆盖已有的真实统计数据。测试前必须备份，测试后必须还原。

```php
use PHPUnit\Framework\TestCase;

class EtlBLLTest extends TestCase
{
    private const STAT_MONTH = '2025-08';

    /** @var \Phalcon\Db\Adapter\Pdo */
    private static $dbResult;
    /** @var array */
    private static $statsBackup = [];

    public static function setUpBeforeClass(): void
    {
        $di = \Phalcon\Di::getDefault();
        self::$dbResult = $di->get('db_bi_result_w');

        // 备份 — 整个 TestCase 跑完才还原
        self::$statsBackup = self::$dbResult->fetchAll(
            "SELECT * FROM result_table WHERE stat_month = ?",
            \Phalcon\Db::FETCH_ASSOC,
            [self::STAT_MONTH]
        );
    }

    public static function tearDownAfterClass(): void
    {
        // 即使测试 fail/error，PHPUnit 也会执行 tearDownAfterClass，等价 try-finally
        self::$dbResult->execute(
            "DELETE FROM result_table WHERE stat_month = ?",
            [self::STAT_MONTH]
        );
        foreach (self::$statsBackup as $row) {
            $cols = array_keys($row);
            $placeholders = implode(',', array_fill(0, count($cols), '?'));
            self::$dbResult->execute(
                "INSERT INTO result_table (" . implode(',', $cols) . ") VALUES ({$placeholders})",
                array_values($row)
            );
        }
    }

    public function testCase1(): void { /* ... */ }
    public function testCase2(): void { /* ... */ }
}
```

**关键规则**：
- `setUpBeforeClass` 整套测试前调一次，备份结果表
- `tearDownAfterClass` 整套结束后无论成败都还原（PHPUnit 保证执行）
- 每个 TC 内的源数据修改仍用 setUp/tearDown 或 try-finally 还原
- 用**预编译参数**（`?` + 参数数组）写回，不要 `addslashes` 拼接（防注入也防 NULL/二进制丢失）

---

## 3.12 空结果伪通过反模式（必须杜绝）

### ⛔ 禁止：把"查不到数据 / 结果集为空"当作测试通过

最常见的伪测试形态有三种，全部禁用：

```php
// ❌ 反模式 A：fetch 为空直接 PASS / SKIP
$rows = $this->db->fetchAll($sql);
if (empty($rows)) {
    $this->markTestSkipped('无异常数据');   // 可能是规则生效，也可能 SQL 写错了
    return;
}

// ❌ 反模式 B：断言"非法数据为空"，但样本本身可能为空
$bad = array_filter($all, fn ($x) => $this->isInvalid($x));
$this->assertEmpty($bad);   // $all 为空时永远 PASS

// ❌ 反模式 C：用 count == 0 断言"全部被剔除"，没确认基线数据存在
$this->runBll();
$this->assertSame(0, $this->getCount(), '剔除生效');   // 输入压根没有候选数据时也是 0
```

这三种写法都会让"数据没准备好 / SQL 写错 / 表结构改了"被错误地标记成通过，是最危险的 false-positive。

### ✅ 强制规则

**1. 任何"空 → 通过"分支必须改为"空 → FAIL 或主动构造"**

```php
$rows = $this->db->fetchAll($sql);
if (empty($rows)) {
    // 选项 1：算失败（数据是测试前提）
    $this->fail('查询到候选数据为空，测试前提不成立');

    // 选项 2：按 3.10 主动构造满足条件的数据，再继续
}
```

> ⛔ 禁止用 `markTestSkipped` 当兜底 — SKIP 等同于没测试，详见 3.10。

**2. 任何过滤/筛选类断言，必须先断言"样本非空"**

```php
$all = $this->db->fetchAll($sql);
$this->assertNotEmpty($all, '前置：样本非空');

$bad = array_filter($all, fn ($x) => $this->isInvalid($x));
$this->assertEmpty($bad, '无非法数据');
```

**3. 任何 count/数量类断言必须有"基线 + 实验"两点，不能孤立断言 `count == 0`**

参见 3.9 对照实验：必须先证明"对照组下目标记录被计入"，再证明"实验组下被剔除"。孤立的 `assertSame(0, $count)` 一律视为伪测试。

**4. 写入型 BLL（ETL/聚合）测试，必须验证"实际写入行数 > 0 且包含目标记录"**

```php
$this->runBll();
$written = $this->dbResult->fetchAll(
    "SELECT * FROM result_table WHERE stat_month = ?",
    \Phalcon\Db::FETCH_ASSOC,
    [$month]
);
$this->assertNotEmpty($written, '结果表实际写入数据');
$this->assertTrue(
    $this->containsTargetId($written, $targetId),
    '目标记录在结果中'
);
```

### 自检：空表反向校验

> 自检清单统一到 3.13。本节关键原则：
> - 临时把源表 WHERE 条件改成 `WHERE 1=0` 重跑测试，**必须 FAIL**
> - 否则用例落入本节反模式之一，必须重写

---

## 3.13 验收输出结构（统一自检中心）

> 3.9 / 3.10 / 3.12 散落的自检项**全部汇总在这里**，提交前必须逐项勾选。

```markdown
## 测试用例清单
- 已编写用例：N 个
- 覆盖功能点：[功能点列表]
- 测试文件：[路径列表]

## 测试结果汇总
| 用例数 | 通过 | 失败 | 通过率 |
|--------|------|------|--------|
| N | N | 0 | 100% |

## 反伪通过自检（必填）

### A. 用例编写规范（对应 3.5 / 3.7）
- [ ] 调用实际方法验证（无复制代码片段自我验证）
- [ ] 断言均为具体值/具体结构，无 `!empty` / `count > 0` 这类弱断言
- [ ] 测试 ID 使用不冲突的特定值（如 99999），不污染真实数据

### B. 数据管理（对应 3.8 / 3.10 / 3.11）
- [ ] 测试数据准备 + 清理均在同一 try-finally 内
- [ ] 数据不存在时主动构造或 FAIL，无 SKIP 分支
- [ ] 修改记录前已 SELECT 真实原值备份，finally 还原真实值（无硬编码字面量）
- [ ] ETL 类测试结果表已用 backupStats / restoreStats 备份还原

### C. 对照实验（对应 3.9）
- [ ] 每条规则均有 baseline + 对照组 + 实验组三段
- [ ] 复合条件 (A AND B AND C) 已按单条件拆 TC
- [ ] 边界值（>=  vs >）有独立 TC

### D. 空结果防伪（对应 3.12）
- [ ] 没有 `if (empty($rows)) { PASS; return; }` 分支
- [ ] 所有"无 X"类断言前都有"样本非空"前置断言
- [ ] 所有 `count === 0` 断言都配套"对照组 count > baseline"
- [ ] 写入型 BLL 测试断言了"结果表实际有数据"且"包含目标记录"

### E. 反向破坏性自检（最重要，写完必跑）
- [ ] 注释规则代码 → 实验组 FAIL（证明用例真的触达规则）
- [ ] 源表 `WHERE 1=0` → 用例 FAIL（证明空数据不会被误判通过）

## 验收结论
✅ 全部通过 / ❌ 存在失败用例
```

---

## 每步验收确认语

> "以上测试是否通过？通过后进入 Step 4（Yapi 文档同步）。"