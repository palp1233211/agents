# 门控检查清单

## 每次响应前必须执行的检查

```
□ 1. Read STATE → 确认 allowed_next_action 值
□ 2. 匹配 allowed_next_action 到对应 Step
□ 3. Read 该 Step 的必读文件（见下表）
□ 4. 执行操作，生成交付物内容
□ 5. ⚡ Write 工具将产物写入 workspace/docs/（有产物的 Step 必须先落盘）
□ 6. 在对话中展示内容，以验收确认语结尾，等待用户"通过"
□ 7. 仅在用户"通过"后：更新 STATE 的 allowed_next_action
```

> **第 5 步是硬门控**：有产物的 Step（0/1/3/4），未调用 Write 工具保存文件，禁止进入第 6 步询问用户。

## Step 必读文件表

| Step | allowed_next_action | 必读文件 |
|------|-------------------|---------|
| 0 | `start_step_0` | `reference/scan-template.md` |
| 1 | `start_step_1` | `reference/migration-plan-template.md` |
| 2 | `start_step_2` / `start_step_2_substep_N` | `reference/migration-loop.md` |
| 3 | `start_step_3` | `reference/verify-template.md`、`reference/docker-containers.md` |
| 4 | `start_step_4` | `reference/retrospect-template.md` |

## 迁移铁律（贯穿全流程）

### 只复制不改写

- ✅ 允许：原样复制文件内容
- ✅ 允许：调整命名空间声明（namespace 行）以匹配项目结构
- ✅ 允许：更新引用路径（use/require/include 语句指向新位置）
- ❌ 禁止：修改业务逻辑
- ❌ 禁止：优化代码结构
- ❌ 禁止：重构方法/类
- ❌ 禁止：添加/删除功能
- ❌ 禁止：修改方法签名
- ❌ 禁止：修改返回值
- ❌ 禁止：修改异常处理逻辑

### 逻辑一致性验证

每个子步骤完成后，自检：
```
□ 源文件与目标文件 diff，仅命名空间声明和引用路径有差异
□ 所有引用点已更新
□ 无新增/删除任何代码行（命名空间和引用除外）
```

## 禁止行为清单

| 禁止行为 | 原因 |
|----------|------|
| 未读 STATE 就开始工作 | 可能执行错误步骤 |
| 未读必读文件就输出交付物 | 产出格式不规范，遗漏检查项 |
| allowed_next_action 为 X 时执行非 X | 破坏流程完整性 |
| 未收到"通过"就更新 STATE | 用户可能有修改意见 |
| 修改被迁移代码的业务逻辑 | 违反"只复制不改写"铁律 |
| 合并多个文件到一个子步骤 | 违反"不怕多就怕错"原则 |
| 跳过 Explore 阶段直接读项目代码 | 污染主上下文 |
| **未用 Write 工具落盘产物就询问用户"通过"** | 产物只在对话中不算完成，会话结束后丢失 |

## 验收确认语模板

```
"以上 {步骤名} 是否通过？通过后进入 {下一步骤}。"
```

示例：
- "以上依赖扫描结果是否通过？通过后进入 Step 1 迁移方案设计。"
- "以上子步骤 3 的迁移计划是否通过？通过后执行迁移。"
- "以上验证结果是否通过？通过后进入 Step 4 复盘闭环。"
