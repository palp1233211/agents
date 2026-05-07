## Step 2 子步骤节拍模板

> 按 Step 1 的 `开发拆分与验收点` **逐个子步骤**推进，每子步骤三阶段循环。

---

### 代码设计
参考 `php-developer` skill 的规范（通过 Skill tool 调用查看），包含：
- 路由定义
- 请求/响应结构
- 错误码定义
- 鉴权机制
- 幂等设计

**约束：** 阶段 2 实现时**必须**调用 `php-developer` skill 根据本设计生成代码，生成的代码必须符合 `php-developer` 规范。

---
### 四阶段循环

| 阶段 | 动作 | 输出 | 等待 |
|------|------|------|------|
| **0. 探索** | 调用 Explore subagent 探索涉及文件的当前实现 | 代码摘要（仅回到主上下文） | 无需确认，直接进入计划 |
| **1. 计划** | 基于探索结果写本子步骤范围 + 最小验证点 | 计划文档 | 用户确认 |
| **2. 实现** | 调用 `php-developer` skill 根据代码设计生成代码 + 自检 | 代码 + 证据 | 用户确认 |
| **3. CodeReview** | 调用 code-reviewer agent | Review 报告 | 用户确认 |

---

### 阶段 0：代码探索（新增）

**目的**：在主上下文中不直接 Read 项目代码，避免大量无用内容留存。

调用方式：
```
使用 Agent tool：
- subagent_type: Explore
- description: "探索 {子步骤名称} 涉及代码"
- prompt: 需要包含：
  1. 子步骤目标（要实现什么功能）
  2. 建议探索起点（如：app/tasks/XX/、app/BLL/YY.php、已知的相关类名）
  3. 要回答的问题（如：现有实现在哪、有哪些调用方、数据库表结构如何）
  4. 返回格式：文件路径+行号+一句话描述，不贴原始代码
```

探索完成后，将 Explore 返回的摘要作为阶段 1 计划的输入。

---

### 阶段 1：计划输出模板

```markdown
## 子步骤计划：{子步骤名称}

### 范围
- 文件：[涉及文件列表]
- 功能：[具体功能点]

### 最小验证点
- 验证方法：[手动验证/单元测试]
- 验证命令：docker exec -it {container} {command}

### 风险点
- [可能的问题]

> "以上计划是否通过？通过后开始实现。"
```

---

### 阶段 2：实现

**必须使用 Skill tool 调用 `php-developer` skill 根据阶段 1「代码设计」生成代码**，不要自行手写代码。

调用方式：
```
使用 Skill tool：
- skill: php-developer
- args: 需要传递：
  1. 子步骤目标（要实现的功能点）
  2. 阶段 1 输出的代码设计（路由/请求响应/错误码/鉴权/幂等）
  3. 阶段 0 探索得到的现有代码上下文（涉及文件、相关类、调用方）
  4. 项目约束（PSR 规范、禁用 exit()、Task/Controller 不写 SQL 等，见 CLAUDE.md）
```

生成代码后必须**逐项核对**是否符合 `php-developer` 规范，未达标的项必须修正后再进入下一阶段。

#### 阶段 2 输出模板

```markdown
## 实现完成：{子步骤名称}

### 调用记录
- Skill: php-developer
- 输入：[代码设计要点 + 现有代码上下文]

### 变更摘要
- 文件：[已修改文件]
- 关键改动：[改动要点]

### 完成证据
- 命令：docker exec -it {container} {验证命令}
- 输出：[关键输出截图/日志]

### 自检清单（必须全部 ✓）
□ 代码由 `php-developer` skill 生成
□ 符合 `php-developer` 规范（PSR / 命名 / 分层 / 错误码）
□ 路由/请求响应/错误码与阶段 1 设计一致
□ 无硬编码配置
□ 错误处理完整
□ 无安全漏洞
□ Task/Controller 未直接写 SQL

> "以上实现是否通过？通过后进入 CodeReview。"
```

---

### 阶段 3：CodeReview 调用方式

**必须使用 Agent tool 调用 `code-reviewer` 子代理**，而不是自己扮演代码审查者。

调用方式（示例）：
```
使用 Agent tool：
- subagent_type: code-reviewer
- description: "Review {子步骤名称}"
- prompt: 需要给 code-reviewer 足够上下文，至少包括：
  1. 本子步骤范围（文件列表 + 功能点）
  2. 变更摘要（改了什么、为什么）
  3. 关注点（性能 / 安全 / 业务规则命中 / 边界 / 并发）
  4. 本项目约束（PSR 规范、禁用 exit()、Task/Controller 不写 SQL 等，见 CLAUDE.md）
```

调用后把 agent 返回的结果按下方模板整理，不要直接贴原文。

---

### 阶段 3：CodeReview 输出模板

```markdown
## CodeReview 结果：{子步骤名称}

### Agent: code-reviewer

### 发现问题
| 级别 | 问题 | 文件:行号 | 修复建议 |
|------|------|-----------|----------|
| CRITICAL | [问题] | file:123 | [建议] |
| HIGH | [问题] | file:456 | [建议] |

### 已修复
- [修复项列表]

### Review 结论
- [通过/需修复]

> "CodeReview 是否通过？通过后进入下一个子步骤。"
```

---

### 子步骤切换规则

```
当前子步骤通过 → 更新 STATE 的 current_substep → 进入下一子步骤
所有子步骤完成 → 更新 STATE 为 Step 2 完成 → 进入 Step 3
```