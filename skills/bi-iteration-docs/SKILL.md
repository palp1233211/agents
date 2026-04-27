---
name: bi-iteration-docs
description: 创建 BI 迭代上线文档套件并通过云效创建上线分支。触发场景：(1) 用户说"创建迭代文档"、"上线文档"、"周迭代"、"下周文档" (2) 用户提到 BI 迭代、上线 SQL、上线任务 (3) 用户要求创建多国家任务文档模板
---

# BI 迭代上线文档与分支创建

## 固定配置

| 配置项 | 值                             |
|--------|-------------------------------|
| 迭代日期 | 下一个周四                         |
| 目标文件夹 | `UrcNfhwkalLeaKd1GRqcfKcSnvh` |
| 国家列表 |          泰国和菲律宾               |

## 模板文档

| 模板 | Token | 用途 |
|------|-------|------|
| 汇总文档 | `Nzoxd1LrPoCwQaxFOAdcXMm4nMh` | 迭代上线汇总 |
| 任务文档 | `Ou8tdObXMolH8VxQ0yzcd5K6nQh` | 各国家 SQL 及任务 |



## 文档命名规范

- 汇总：`BI YYYYMMDD 迭代上线文档`
- 任务：`BI YYYYMMDD 迭代上线SQL及任务 -- XX国家`

## 分支命名规范

- 格式：`feature/{日期}/common`，日期为步骤 1 计算值
- 示例：`feature/20260418/common`

---

## 操作步骤

### 步骤 1：计算日期

下一个周四，格式 `YYYYMMDD`

### 步骤 2：通过 飞书cli 读取模板内容

```bash
# 任务文档模板
https://flashexpress.feishu.cn/docx/Ou8tdObXMolH8VxQ0yzcd5K6nQh

# 汇总文档模板  
https://flashexpress.feishu.cn/docx/Nzoxd1LrPoCwQaxFOAdcXMm4nMh
```

### 步骤 3：创建任务文档（泰国、菲律宾）

> **注意**：`+fetch` 获取模板内容时会丢失 callout 的 `background-color` 等样式属性，创建文档时需手动补充。

替换模板中的 `YYYYxxxx` → 实际日期

```bash
lark-cli docs +create \
  --title "BI YYYYMMDD 迭代上线SQL及任务 -- XX国家" \
  --folder-token "UrcNfhwkalLeaKd1GRqcfKcSnvh" \
  --markdown "<替换后的内容>"
```

### 步骤 4：创建汇总文档

替换模板中的：
- `YYYYxxxx` → 实际日期
- 任务文档链接 → 新创建的文档链接

**汇总文档 callout 固定样式**（模板 fetch 会丢失，必须手动写入）：

```markdown
<callout emoji="writing_hand" background-color="light-orange">

<text color="red">**注意事项**</text>**：请大家每天合并mastr分支到自己的开发分支，并确保合并周分支之前合并过最新的master分支代码**
</callout>
```


[//]: # ()
[//]: # ()
[//]: # (### 步骤 5：云效创建分支)

[//]: # ()
[//]: # ()
[//]: # (使用步骤 1 计算的具体日期值创建分支，分支格式为 `feature/{实际日期}/common`。)

[//]: # ()
[//]: # ()
[//]: # (**示例：** 若日期为 20260418，则创建 `feature/20260418/common`)

[//]: # ()
[//]: # ()
[//]: # (**调用云效工具：**)

[//]: # ()
[//]: # (- `yunxiao_list_repositories` - 查找仓库)

[//]: # ()
[//]: # (- `yunxiao_create_branch` - 创建分支)

[//]: # ()
[//]: # ()
[//]: # (**操作流程：**)

[//]: # ()
[//]: # (1. 依次搜索云效项目列表中的 6 个仓库（fbi、bi-common、ard-api、ard-etl、message、nl-data）)

[//]: # ()
[//]: # (2. 从 `master` 创建 `feature/{实际日期}/common` 分支)

### 步骤 6：输出结果

| 类型 | 链接/分支名 |
|------|------------|
| 汇总文档 | https://www.feishu.cn/docx/xxx |
| 泰国任务文档 | https://www.feishu.cn/docx/xxx |
| ... | ... |
| fbi 分支 | feature/{实际日期}/common |
| bi-common 分支 | feature/{实际日期}/common |
| ... | ... |

---

## 注意事项

- 模板必须是新版 docx 格式
- 云效创建分支需确认仓库存在
- 分支从 master 创建
- 、