## SQL 查询规范

### 1. 参数绑定语法

在 Phalcon/PHP 中使用参数绑定时，**不要使用双冒号**：

错误写法：

```php
$where .= ' AND menu_id = :menu_id:';
$bind['menu_id'] = $value;
```

正确写法：

```php
$where .= ' AND menu_id = :menu_id';
$bind['menu_id'] = $value;
```

### 2.执行方法使用
- 查询
```php
// 多条记录 fetchAll
$this->getDI()->get('db_bi_center_r')->fetchAll($sql, \Phalcon\Db::FETCH_ASSOC, $bind);

// 单条记录
$this->getDI()->get('db_bi_center_r')->fetchOne($sql, \Phalcon\Db::FETCH_ASSOC, $bind);

// 获取单列值：如获取总条数
$this->getDI()->get('db_bi_center_r')->fetchColumn($sql, \Phalcon\Db::FETCH_ASSOC, $bind);

```
- 修改
```php
$this->getDI()->get('db_bi_center')->updateAsDict(
    'table',
    ['status' => $status],
    [
        'conditions' => 'id = ?',
        'bind'       => [$id],
    ]
);
```
-  删除
```php
$this->getDI()->get('db_bi_center')->delete('table', $where, $bind);
```
### 3.所有 SQL 查询必须使用 `try-catch` 
在catch中通过RuntimeException上抛错误 **必须将 SQL 语句拼接到错误内容中**：
上抛内容应包含：
- 异常消息 (`$e->getMessage()`)
- SQL 语句 (`$sql`)
- 绑定参数（可选，便于调试）

```php
try {
    $sql = "SELECT * FROM table WHERE id = :id";
    $result = $this->getDI()->get('db_bi_center_r')->fetchAll(
        $sql,
        \Phalcon\Db::FETCH_ASSOC,
        ['id' => $id]
    );
} catch (\Throwable $e) {
    throw new \RuntimeException($e->getMessage() . ' sql:' . ($sql ?? ''));
}
```

### 4.安全相关规范
- 所有外部输入必须经过过滤/校验。
- 返回给前端的字符串需要考虑 XSS（特别是富文本/HTML 场景）。
- 禁止在日志中记录敏感信息（密码、token 等）。