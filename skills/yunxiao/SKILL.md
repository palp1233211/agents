---
trigger: model_decision
description: "yunxiao分支操作规范：命名格式feature/YYYYMMDD/trunk|common，测试分支用trunk，线上分支用common，创建前必须让用户确认"
---
# yunxiao MCP 操作规范

## 组织信息
- **organizationId**: `5ea86562f89c9700014a671f`

## 可操作项目列表

| 项目名称 | Repository ID | 说明 |
|---------|---------------|------|
| bi-common | 1845658 | FBI&HBI基础公用项目 |
| fbi | 1608139 | 商业智能化分析系统 |
| ard-api | 3641904 | 接口服务系统 |
| ard-etl | 3865544 | 数据清洗系统 |
| message | 552854 | KIT端API系统 |
| nl-data | 552870 | 实时数据系统 |
| report | 552872 | 客户端API系统 |

## 项目操作规则

### 默认行为
- 当用户未指定具体项目时，默认是 fbi 项目
- 用户明确说"全部"时，在上述 7 个项目执行操作
- **重要**："全部" ≠ 云效平台所有项目

### 项目指定方式
- 单个项目：`fbi`、`ard-etl`
- 多个项目：`fbi, ard-api, message`
- 全部项目：`全部`

## 分支管理规则

**分支必须从 `master` 分支创建**

### 分支命名规范
```
feature/YYYYMMDD/name_number
```
- `YYYYMMDD`: 下一个星期的星期四
- 测试分支用：`trunk`
- 线上分支用：`common`

示例：
- `feature/20260402/trunk` (测试分支)
- `feature/20260402/common` (线上分支)
- `feature/20260402/lwc_12345`

**创建分支时**，自动生成规范名称，让用户确认后执行。

### 规范检查
- 不符合命名规则时提醒用户
- 拒绝不符合格式的分支操作