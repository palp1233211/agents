## RESTful 接口开发设计规范

**重要规则：**
- 严格按照模版格式生成，不要主动发挥。

### 版本策略

**路由：** /api/Controller/Action

### HTTP 方法

- **读取** 数据用:GET
- **修改/新增** 数据用:POST

### 接口响应
**返回 `success`/ `error`** 不要使用中文。

- 响应成功案例
```php
$this->ajax_return('success', 1, $data);
```

- 响应失败案例
```php
$this->ajax_return('error', -1);
```


## 架构设计规范

###  1.Controller结构Action模版
所有Action必须有`try-catch`, **报错信息写入日志，不要返回给前端**
创建BLL对象必须设置lang属性。
```php
// Controller 中
public function getListAction()
{
    try {
        ...
        $bll = new BLL();
        $bll->lang = $this->lang;
        $this->ajax_return('ok', 1, $data);
    } catch (\Throwable $e) {
        $this->getDI()->get('logger')->write_log(
            "xxx失败原因可能是:" . $e->getMessage() . ' in file: ' . $e->getFile() . ' on line: ' . $e->getLine()
        );
        $this->ajax_return('error', -1);
    }
}
```
### 2.  BLL 结构 方法模版
如果方法含有 SQL 查询，报错中必须含有 SQL 语句。

```php
public function getPnoInfo(){
     try {
        $sql = "
            select * from table where 1=1
        ";
        return $this->getDI()->get('db_bi_center_r')->query($sql)->fetchAll(\Phalcon\Db::FETCH_ASSOC);
    }catch (\Throwable $e) {
        throw new \RuntimeException('xxx sql失败：'.$e->getMessage().' sql:'.$sql);
    }
}
```
### 3. Controller 与 BLL 职责分离

**验证参数和SQL查询，业务逻辑应放在 BLL 层**，Controller 只负责请求处理和调用：

错误做法：验证逻辑或SQL查询写在 Controller 中
```php
// Controller 中
if (count($attach) > 10) {
    $this->ajax_return('附件超过10张', -1, []);
}
```

正确做法：验证逻辑或SQL查询封装到 BLL 方法
```php
// BLL 中
public function validateContactAttach($contactAttach)
{
    if (count($contactAttach) > 10) {
        return ['valid' => false, 'error' => 'contact_attach_max_10'];
    }
    return ['valid' => true, 'error' => null];
}

// Controller 中
$validation = $bll->validateContactAttach($contactAttach);
```

**优点**：
- 代码复用：验证逻辑可在其他地方复用
- 易于测试：BLL 方法可独立单元测试
- 易于维护：验证规则变更只需修改一处

### 4.分页接口统一格式：
请求参数：page, page_size
返回字段：list, total, page, page_size。