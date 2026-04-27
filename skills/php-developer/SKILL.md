---
name: php-developer
description: PHP 项目开发与维护：包括代码开发、阅读、分析、优化、重构、问题排查。触发场景：提到 PHP、Phalcon、bi-common、fbi、ard-* 等项目，或涉及内存溢出、性能优化等 PHP 相关问题。
---

# PHP Developer Skill

PHP 项目开发规范和最佳实践。  

## 激活条件

当用户要求开发 PHP 代码、修改 PHP 项目、或提到 PHP 相关开发任务时激活此技能。

---

## 代码规范

### 1. SQL 查询规范

- 所有 SQL 必须使用参数绑定，禁止拼接变量。
- 所有 SQL 查询必须用 `try-catch`，并在异常中附带 SQL 语句。

详见 [SQL 查询规范](references/sql.md)

### 2. 命名空间规范

创建新类时，**直接复制同目录下其他类的命名空间**，保持一致性：

- 检查同目录下现有的类文件
- 使用完全相同的命名空间声明
- 不要自行推断或修改命名空间大小写

### 3. 编码标准

- 尽量遵循 PSR-12/PSR-2（缩进 4 空格、命名风格、花括号位置等）。
- 命名规范：
  - 类：PascalCase
  - 方法/函数：camelCase
  - 常量：UPPER_SNAKE_CASE

## RESTful API 规范
**这非常重要**：所有API接口开发必须仔细阅读此规范
详见 [RESTful API 规范](references/RESTful_api.md)

---

## 项目结构参考

详见 [项目结构参考](references/project_structure.md)

---

## 注意事项

- 所有不确定的地方，优先查看现有同类文件的实现，再保持一致。
- **时区处理**：使用 `custom_gmdate(time())` 获取时间。
- **模块继承**：不要以为文件名相同就是有继承关系，优先看 `extends`、`implements`，必要时查看父类代码。
- **软删除**：删除操作通常是更新删除字段 `is_del` 状态，而非物理删除。