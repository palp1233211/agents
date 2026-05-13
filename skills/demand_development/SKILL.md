---
name: demand_development
description: PHP 项目开发与维护 需求开发，功能优化、功能迁移、阅读需求文档 等 相关问题。
---

## 本 skill 的工作方式

这是一个**强状态门控**的需求开发流程。每个需求有独立的 STATE 文件，STATE 中的 `allowed_next_action` 字段决定当前唯一允许的操作。AI 必须严格按门控执行，不得跳步。

---

## 激活后第一步（必须按顺序执行）

1. **读规则**：用 Read 工具读 `reference/checklist.md`，获取门控规则和各 Step 必读文件表
2. **定位 STATE**：扫描 `~/.claude/skills/demand_development/workspace/states/` 目录
   - **有进行中的 STATE 文件** → 读取该文件，确认 `allowed_next_action`
   - **只有 archive 子目录或空目录** → 等待用户提供需求文档；收到需求后，从 `~/.claude/skills/demand_development/workspace/states/STATE-TEMPLATE.md` 复制创建 `STATE-{需求编号}.md`
   - **有多个进行中 STATE** → 列出让用户选择
3. **按门控执行**：根据 `allowed_next_action` 的值，读对应 Step 的必读文件（见 checklist.md 中的强制阅读表），然后执行该 Step

⛔ 严禁行为：
- 未读 STATE 就开始工作
- 未读 Step 必读文件就输出交付物
- `allowed_next_action` 为 X 时执行非 X 的操作
- 未收到用户"通过"就更新 STATE

---

## 流程概览（详细规则见 reference/checklist.md）

| Step | 动作 |
|------|------|
| 0 | 需求拆解 |
| 1 | 开发方案设计 |
| 2 | 分步实现（每子步骤三阶段循环） |
| 3 | 测试验证（Docker 容器内） |
| 4 | Yapi 文档同步（仅接口改动时） |
| 5 | 复盘闭环 |
| 6 | 测试验收信息整理 |

每步完成后必须获得用户明确"通过"确认才能更新 STATE 并进入下一步。**各 Step 的必读文件见 `reference/checklist.md` 中的"Step 必读文件表"。**

---

## 产物位置

| 类型 | 路径 |
|------|------|
| STATE 文件 | `~/.claude/skills/demand_development/workspace/states/STATE-{需求编号}.md` |
| STATE 归档 | `~/.claude/skills/demand_development/workspace/states/archive/` |
| 方案/测试/复盘/验收文档 | `~/.claude/skills/demand_development/workspace/docs/` |
