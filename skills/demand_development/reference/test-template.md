## 测试策略模板（Step 3）

> 根据 Step 0 功能点和 Step 1 接口设计制定测试方案

---

## 测试方案选型说明

本项目使用**手写测试类**（非 PHPUnit），原因：

1. **Phalcon CLI 环境复杂**：PHPUnit 在 Phalcon 项目 CLI 模式下需要额外处理 DI 容器、环境变量、配置加载，配置成本高
2. **项目国家配置切换频繁**：测试常需切换 `.env.th` / `.env.ph` 等，手写类通过 `bootstrap.php` 显式控制加载顺序更直接
3. **测试脚本仅用于验收，不入库**：按项目规则（见 `reference/git.md`）`tests/` 目录不提交仓库，不需要 CI 集成，手写类足够

⛔ 不要擅自改为 PHPUnit 风格（引入 `PHPUnit\Framework\TestCase`、`@Test` 注解、`setUp/tearDown` 等）。如有强需求，先与用户确认。

---

## ⚠️ 前置条件：Docker 环境

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
| 单元测试 | 核心业务逻辑、数据转换、校验函数 | PHPUnit / PHP CLI |
| 集成测试 | API接口、数据库操作、外部服务调用 | PHPUnit / PHP CLI |

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

## 3.5 测试文件模板

**文件位置**：`tests/Unit/{需求号}/{类名}Test.php`

**示例**：`tests/Unit/23921/ParcelReweighAppealReviewTest.php`

```php
<?php
/**
 * 单元测试 - {ClassName}
 *
 * 需求编号: {需求号}
 * 测试用例：
 * - TC-001: 方法功能测试
 */

require_once __DIR__ . '/../../bootstrap.php';

use YourNamespace\YourBLL;

class YourBLLTest
{
    private $bll;
    private $db;
    private $passCount = 0;
    private $failCount = 0;

    public function __construct()
    {
        $di = Phalcon\Di::getDefault();
        $this->db = $di->get('db_bi_center_r');
        $this->bll = new YourBLL();  // 实例化被测类
    }

    /**
     * TC-001: 测试方法
     */
    public function testYourMethod()
    {
        echo "\n=== TC-001: testYourMethod ===\n";
        echo "调用方法: YourBLL::yourMethod()\n";

        // 准备测试数据
        $testId = 1;
        $this->db->execute("UPDATE your_table SET test_field = 'TEST_VALUE' WHERE id = {$testId}");

        try {
            // 调用实际方法（必须调用实际方法，禁止复制代码验证）
            $result = $this->bll->yourMethod($params);

            // 验证返回值
            $this->assert('返回值验证', !empty($result));
            $this->assert('字段存在', isset($result['expected_field']));
        } finally {
            // 清理测试数据
            $this->db->execute("UPDATE your_table SET test_field = '' WHERE id = {$testId}");
        }
    }

    private function assert($message, $condition)
    {
        if ($condition) {
            $this->passCount++;
            echo "  [PASS] {$message}\n";
        } else {
            $this->failCount++;
            echo "  [FAIL] {$message}\n";
        }
    }

    public function run()
    {
        echo "========================================\n";
        echo "YourBLL 单元测试\n";
        echo "需求编号: {需求编号}\n";
        echo "测试文件: tests/Unit/YourBLLTest.php\n";
        echo "========================================\n";

        $this->testYourMethod();
        // 添加更多测试方法...

        echo "\n========================================\n";
        echo "测试结果汇总\n";
        echo "========================================\n";
        echo "通过: {$this->passCount}\n";
        echo "失败: {$this->failCount}\n";
        $total = $this->passCount + $this->failCount;
        echo "总计: {$total}\n";
        if ($total > 0) {
            echo "通过率: " . round($this->passCount / $total * 100, 2) . "%\n";
        }

        return $this->failCount === 0;
    }
}

// 执行测试
$test = new YourBLLTest();
$success = $test->run();
exit($success ? 0 : 1);
```

---

## 3.6 测试执行命令

### 基础执行

```bash
# 进入容器
docker exec -it {container} bash

# 运行指定需求测试
php /mnt/www/tests/Unit/23921/YourBLLTest.php

# 运行指定需求所有测试
for f in /mnt/www/tests/Unit/23921/*Test.php; do php "$f"; done

# 运行所有测试
for f in /mnt/www/tests/Unit/*/*Test.php; do php "$f"; done
```

> **注意**：Docker 容器已挂载整个项目目录，测试文件修改后直接生效，无需同步。

---

## 3.7 常见问题及解决方案

### 问题 1：测试脚本位置不规范

**错误做法**：测试脚本写到 `/tmp/` 临时目录

**正确做法**：
- 测试文件放入 `tests/Unit/` 目录
- 引导文件放入 `tests/bootstrap.php`

---

### 问题 2：复制代码而非调用实际方法

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
$this->assert('返回值验证', $result === $expected);
```

---

### 问题 3：CLI 模式缺少 Web 环境变量

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

### 问题 4：数据库连接指向错误环境

**报错**：
```
Table 'wrong_db.your_table' doesn't exist
```

**解决方案**：
1. 确认当前国家配置：`cat .env | grep country_code`
2. 切换到正确的国家配置：`cp .env.th .env`
3. 在 bootstrap.php 中按国家代码加载配置

---

### 问题 5：Phalcon 类找不到

**报错**：
```
Class 'FlashExpress\bi\App\Models\xxx' not found
```

**解决方案**：确保 bootstrap.php 按顺序加载：
```php
// 1. autoload.php
require BASE_PATH . '/vendor/autoload.php';

// 2. services.php（初始化 DI）
include APP_PATH . '/config/services.php';

// 3. loader.php（注册自动加载）
include APP_PATH . '/config/loader.php';
```

---

## 3.8 测试数据管理规范

1. **每个测试方法负责准备和清理自己的数据**
2. **使用 try-finally 确保清理执行**
3. **标记测试数据**（如 `TEST_` 前缀）便于识别
4. **优先使用不存在的 ID 或特定测试记录**

```php
public function testMethod()
{
    $testId = 99999;  // 使用特定测试 ID

    $this->db->execute("UPDATE table SET field = 'TEST_VALUE' WHERE id = {$testId}");

    try {
        $result = $this->bll->method($params);
        $this->assert('验证', $condition);
    } finally {
        // 确保清理
        $this->db->execute("UPDATE table SET field = '' WHERE id = {$testId}");
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
$this->assert('被剔除', $this->getCount() === 0);
// 问题：count=0 可能只是因为 id 根本不满足其它 WHERE 条件，规则是否生效不可知。
```

```php
// ❌ 对照组断言太弱（count > 0）
$this->assert('正常数据被计次', $this->getCount() > 0);
// 问题：表里任意一条命中的记录都能让断言通过，无法证明"目标 id"被计次。
```

### ✅ 正确写法

```php
public function testExclusionRule()
{
    // 1. 挑选/构造目标记录（如无满足条件的数据，参见 3.10 主动构造）
    $id = $this->pickTargetId();

    // 2. 先查出原值（⚠️ 不要硬编码 ORIGINAL_VALUE）
    $origField = $this->db->fetchColumn("SELECT field FROM t WHERE id = ?", [$id]);

    // 3. 若被测 BLL 是写入型（ETL/聚合入库），实验前后必须清理结果表，见 3.11
    try {
        // ---- 基线 ----
        $this->resetResult();
        $baseline = $this->getCount();

        // ---- 对照组：确保目标记录不触发剔除条件 ----
        $this->db->execute("UPDATE t SET field = ? WHERE id = ?", ['NORMAL_VALUE', $id]);
        $this->resetResult();
        $this->runBll();
        $this->assert('对照组：目标记录被计次', $this->getCount() === $baseline + 1);

        // ---- 实验组：触发剔除条件 ----
        $this->db->execute("UPDATE t SET field = ? WHERE id = ?", ['EXCLUDED_VALUE', $id]);
        $this->resetResult();
        $this->runBll();
        $this->assert('实验组：剔除规则生效', $this->getCount() === $baseline);

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

编写完测试后，做一次"破坏性自检"以确认测试**真的能发现 regression**：

1. 临时注释掉 BLL 中的剔除判断
2. 重跑此测试
3. **实验组必须 FAIL**（对照组仍应 PASS）

如果两组都还能通过，说明测试没有触达规则代码路径，必须重写。自检通过后再还原 BLL。

---

## 3.10 数据不存在时的处理规范

### ⛔ 禁止因数据不存在就 SKIP

当查询不到满足条件的数据时，**不能直接跳过（SKIP）测试用例**。SKIP 等同于没有测试，无法证明功能正确。

**正确做法**：主动构造或修改已有数据来满足测试条件。

```php
// ❌ 错误：数据不存在就跳过
$record = $db->fetchOne($sql);
if (empty($record)) {
    echo "  [SKIP] 无数据，跳过\n";
    return;
}

// ✅ 正确：找到可用记录，临时修改使其满足测试条件
$record = $db->fetchOne("SELECT id FROM table WHERE ... LIMIT 1");
// 临时将该记录改成需要测试的状态
$db->execute("UPDATE table SET field = 'TEST_STATE' WHERE id = {$record['id']}");
try {
    // 执行测试...
} finally {
    // 还原原始值
    $db->execute("UPDATE table SET field = '{$record['original_value']}' WHERE id = {$record['id']}");
}
```

**构造数据的优先级**：
1. 修改已有记录的某个字段（最简单，try-finally 还原）
2. 插入新测试记录（需要了解完整表结构，finally 中 DELETE 清理）

---

## 3.11 ETL 任务测试专项规范

ETL 任务调用 `run()` 方法时会对结果表执行 DELETE + INSERT（幂等写入），可能覆盖已有的真实统计数据。测试前必须备份，测试后必须还原。

```php
class EtlBLLTest
{
    private $statsBackup = [];

    private function backupStats(string $statMonth): void
    {
        $this->statsBackup = $this->dbResult->fetchAll(
            "SELECT * FROM result_table WHERE stat_month = '{$statMonth}'",
            \Phalcon\Db::FETCH_ASSOC
        );
    }

    private function restoreStats(string $statMonth): void
    {
        $this->dbResult->execute(
            "DELETE FROM result_table WHERE stat_month = '{$statMonth}'"
        );
        foreach ($this->statsBackup as $row) {
            $cols = implode(',', array_keys($row));
            $vals = implode(',', array_map(function ($v) {
                return $v === null ? 'NULL' : "'" . addslashes($v) . "'";
            }, array_values($row)));
            $this->dbResult->execute("INSERT INTO result_table ({$cols}) VALUES ({$vals})");
        }
    }

    public function run()
    {
        $this->backupStats('2025-08');
        try {
            $this->testCase1();
            $this->testCase2();
            // ...
        } finally {
            $this->restoreStats('2025-08');  // 无论测试成败，都还原真实数据
        }
    }
}
```

**关键规则**：
- `backupStats` 在所有测试开始前调用一次
- `restoreStats` 必须在 `finally` 块中执行，确保测试失败时也能还原
- 每个 TC 的源数据修改用各自的 try-finally 还原，结果表由最外层 finally 统一还原

---

## 3.12 验收输出结构

```markdown
## 测试用例清单
- 已编写用例：N 个
- 覆盖功能点：[功能点列表]

## 测试结果汇总
| 用例数 | 通过 | 失败 | 通过率 |
|--------|------|------|--------|
| N | N | 0 | 100% |

## 验收结论
✅ 全部通过 / ❌ 存在失败用例
```

---

## 每步验收确认语

> "以上测试是否通过？通过后进入 Step 4（Yapi 文档同步）。"