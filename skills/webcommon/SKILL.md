---
name: webcommon
description: webcommon 依赖移除——从项目中彻底剥离 webcommon，将所有依赖代码迁移到项目本地。只复制不改写，逻辑必须一致。
---

## 核心原则（最高优先级）

1. **只复制，不改写**：迁移 = 原样复制代码到项目本地，禁止优化、重构、修改任何逻辑
2. **逻辑必须一致**：迁移前后的行为必须完全相同，任何差异都是 bug
3. **不怕多，就怕错**：宁可多拆子步骤，也不能合并导致出错
4. **按文件拆分**：每个文件是一个独立的迁移子步骤

## 门控规则（优先于用户请求）

当前 STATE 的 `allowed_next_action` 值决定唯一允许的操作。用户要求执行其他步骤时，不执行，说明当前状态并引导回正确路径。

### allowed_next_action 对照表

| allowed_next_action      | 唯一允许的操作                          |
|--------------------------|----------------------------------------|
| `start_step_0`           | Step 0：扫描项目对 webcommon 的依赖情况  |
| `start_step_1`           | Step 1：设计迁移方案                     |
| `start_step_2`           | Step 2：开始迁移执行（进入第一个子步骤）  |
| `start_step_2_substep_N` | Step 2：执行子步骤 N 的迁移循环          |
| `start_step_3`           | Step 3：验证迁移结果                     |
| `start_step_4`           | Step 4：复盘闭环                         |
| `completed`              | 已完成，无需操作                         |

---

## 激活后第一步（必须按顺序执行）

1. **读规则**：用 Read 工具读 `reference/checklist.md`，获取门控规则和各 Step 必读文件表
2. **定位 STATE**：扫描 `~/.claude/skills/webcommon/workspace/states/` 目录
   - **有进行中的 STATE 文件** → 读取该文件，确认 `allowed_next_action`
   - **只有 archive 子目录或空目录** → 等待用户提供项目信息；收到后，从 `~/.claude/skills/webcommon/workspace/states/STATE-TEMPLATE.md` 复制创建 `STATE-{项目名}.md`
   - **有多个进行中 STATE** → 列出让用户选择
3. **按门控执行**：根据 `allowed_next_action` 的值，读对应 Step 的必读文件（见 checklist.md），然后执行该 Step

⛔ 严禁行为：
- 未读 STATE 就开始工作
- 未读 Step 必读文件就输出交付物
- `allowed_next_action` 为 X 时执行非 X 的操作
- 未收到用户"通过"就更新 STATE
- 修改、优化、重构被迁移的代码逻辑
- **未用 Write 工具将产物保存到 `workspace/docs/` 就询问用户"通过"**（产物必须先落盘，再问用户）

---

## 流程概览

| Step | 动作 | 核心产出 |
|------|------|---------|
| 0 | 依赖扫描 | 依赖清单（每个文件对 webcommon 的引用详情） |
| 1 | 迁移方案设计 | 迁移计划（文件级拆分、目标路径、迁移顺序） |
| 2 | 分步迁移执行 | 按文件逐步迁移，三阶段循环 |
| 3 | 验证检查 | 零 webcommon 引用 + Docker 测试通过 |
| 4 | 复盘闭环 | 迁移决策记录、问题和可复用模式 |

每步完成后必须获得用户明确"通过"确认才能更新 STATE 并进入下一步。

---

## Step 详细说明

### Step 0：依赖扫描

**必读文件**：`reference/scan-template.md`

**目标**：完整梳理项目中所有对 webcommon 的依赖关系

**执行方式**：
1. 使用 `Agent(subagent_type: Explore)` 扫描项目目录，不在主上下文加载项目代码
2. 扫描内容：
   - `require`/`include`/`require_once`/`include_once` 引用 webcommon 路径的文件
   - `use` 语句引用 webcommon 命名空间的文件
   - `extends`/`implements` 继承或实现 webcommon 类的文件
   - 配置文件中对 webcommon 的加载/注册（autoload、bootstrap、config 等）
   - composer.json 或其他依赖管理对 webcommon 的引用
3. 对每个依赖文件，记录：依赖文件路径、被依赖的 webcommon 文件、依赖方式（use/require/extends 等）、依赖的具体类/函数/常量
4. 按产出模板输出依赖清单

**分类输出**：
- **A 类 - webcommon 自有代码依赖**：项目直接使用的 webcommon 类/函数/常量
- **B 类 - SDK 依赖**：webcommon 中封装的第三方 SDK 调用
- **C 类 - 加载入口**：autoload、bootstrap、config 等加载 webcommon 的配置

**完成标志**（必须按顺序）：
1. ⚡ **先用 Write 工具**将依赖清单保存到 `workspace/docs/{项目名}-依赖清单.md`
2. 在对话中输出清单内容给用户查阅
3. 问用户"以上依赖扫描结果是否通过？通过后进入 Step 1 迁移方案设计。"

> ⛔ 禁止跳过第 1 步直接问用户——文件未落盘不算完成。

---

### Step 1：迁移方案设计

**必读文件**：`reference/migration-plan-template.md`

**目标**：为每个依赖文件制定迁移计划，确定复制目标路径和迁移顺序

**执行方式**：
1. 基于 Step 0 的依赖清单，为每个 webcommon 文件确定：
   - **源路径**：webcommon 中的原始文件路径
   - **目标路径**：复制到项目本地的目标路径
   - **命名空间调整**：如需调整命名空间以匹配项目结构（这是唯一允许的"修改"，且仅限命名空间声明）
   - **引用更新**：哪些文件的 use/require 语句需要更新指向
2. 确定迁移顺序（按依赖链，被依赖的先迁移）：
   - **Phase 1**：A 类 - webcommon 自有代码（按依赖链从底层到上层）
   - **Phase 2**：B 类 - SDK 依赖
   - **Phase 3**：C 类 - 移除 webcommon 加载入口
3. 拆分子步骤（每个文件一个子步骤），编号 substep_1 到 substep_N
4. 按模板将迁移方案文档写入 `workspace/docs/{项目名}-迁移方案.md`

**完成标志**（必须按顺序）：
1. ⚡ **先用 Write 工具**将迁移方案保存到 `workspace/docs/{项目名}-迁移方案.md`
2. 在对话中输出方案内容给用户查阅
3. 问用户"以上迁移方案是否通过？通过后进入 Step 2 分步迁移执行。"

> ⛔ 禁止跳过第 1 步直接问用户——文件未落盘不算完成。

---

### Step 2：分步迁移执行

**必读文件**：`reference/migration-loop.md`（每个子步骤开始前都要重新读）

**目标**：按文件逐步完成代码迁移，每个子步骤走三阶段循环

**迁移顺序**（严格遵守）：
1. Phase 1 - A 类：webcommon 自有代码，按依赖链从底层到上层
2. Phase 2 - B 类：SDK 依赖
3. Phase 3 - C 类：移除 webcommon 加载入口

**每个子步骤的三阶段循环**：

#### 阶段 0：探索（Explore）
- 使用 `Agent(subagent_type: Explore)` 读取当前要迁移的 webcommon 源文件
- 读取目标项目中所有引用该文件的位置
- 产出：源文件内容摘要、所有引用点列表

#### 阶段 1：计划（Plan）
- 明确本子步骤的操作清单：
  - 复制哪个文件到哪个路径
  - 是否需要调整命名空间声明
  - 哪些文件的引用需要更新（use/require 指向变更）
- 产出：操作计划，等待用户"通过"

#### 阶段 2：执行 + 验证（Execute & Verify）
- **复制文件**：将 webcommon 源文件内容原样复制到目标路径
- **调整命名空间**（仅限命名空间声明行，如有必要）
- **更新引用**：将所有引用点的 use/require 更新为新路径
- **自检清单**：
  - [ ] 源文件和目标文件逻辑完全一致（仅命名空间声明可能不同）
  - [ ] 所有引用点已更新指向新路径
  - [ ] 无遗漏的引用点
  - [ ] 未引入任何逻辑变更
- 产出：变更摘要 + 自检结果，等待用户"通过"

**子步骤完成标志**：用户对阶段 2 确认"通过" → 更新 STATE 为下一个子步骤，或所有子步骤完成后更新为 `start_step_3`

---

### Step 3：验证检查

**必读文件**：`reference/verify-template.md`、`reference/docker-containers.md`

**目标**：确认迁移完整性，在 Docker 环境中验证功能正常

**执行方式**：
1. **零引用检查**：全局搜索项目中是否还有对 webcommon 路径/命名空间的引用
2. **构建验证**（Docker 环境）：确认 autoload 正常，无 class/file not found
3. **功能回归验证**（Docker 环境）：运行已有的单元测试
4. **按模板输出验证报告**

**完成标志**（必须按顺序）：
1. ⚡ **先用 Write 工具**将验证报告保存到 `workspace/docs/{项目名}-验证报告.md`
2. 在对话中输出报告内容给用户查阅
3. 问用户"以上验证结果是否通过？通过后进入 Step 4 复盘闭环。"

> ⛔ 禁止跳过第 1 步直接问用户——文件未落盘不算完成。

---

### Step 4：复盘闭环

**必读文件**：`reference/retrospect-template.md`

**目标**：记录迁移过程中的决策、问题和可复用模式

**执行方式**：
1. 按四要素模板输出：目标、结果、问题与决策、可复用模式
2. 保存到 `workspace/docs/{项目名}-复盘.md`

**完成标志**（必须按顺序）：
1. ⚡ **先用 Write 工具**将复盘文档保存到 `workspace/docs/{项目名}-复盘.md`
2. 在对话中输出复盘内容给用户查阅
3. 问用户"以上复盘是否通过？通过后标记为已完成。"
4. 用户"通过"后：更新 STATE 为 `completed`，移至 `states/archive/`

> ⛔ 禁止跳过第 1 步直接问用户——文件未落盘不算完成。

---

## 产物位置

| 类型 | 路径 |
|------|------|
| STATE 文件 | `~/.claude/skills/webcommon/workspace/states/STATE-{项目名}.md` |
| STATE 归档 | `~/.claude/skills/webcommon/workspace/states/archive/` |
| 依赖清单 | `~/.claude/skills/webcommon/workspace/docs/{项目名}-依赖清单.md` |
| 迁移方案 | `~/.claude/skills/webcommon/workspace/docs/{项目名}-迁移方案.md` |
| 验证报告 | `~/.claude/skills/webcommon/workspace/docs/{项目名}-验证报告.md` |
| 复盘文档 | `~/.claude/skills/webcommon/workspace/docs/{项目名}-复盘.md` |
