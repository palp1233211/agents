# Agents

Claude Code 自定义 Agents 与 Skills 配置仓库，沉淀个人在日常 PHP / BI 业务开发、代码审查、文档协作等场景下的可复用工作流。

## 目录结构

```
agents/
├── .claude/
│   ├── agents/                # 项目级 Sub-agents 定义
│   │   ├── novel_Andersen.md
│   │   └── novel_Fairy_Tales.md
│   ├── skills/                # 项目级 Skills（由 Agent 调用）
│   │   └── novel/
│   ├── scheduled_tasks.json
│   └── settings.local.json
└── skills/                    # 通用业务 Skills
    ├── CodeReview/            # 代码审查
    ├── bi-iteration-docs/     # BI 迭代上线文档与分支创建
    ├── demand_development/    # 需求开发强状态门控流程
    ├── php-developer/         # PHP 开发规范
    ├── pua/                   # 高压问题解决模式
    ├── yunxiao/               # 云效分支操作规范
    └── learned/               # 学习沉淀
```

## Skills 一览

| Skill | 用途 | 触发场景 |
|-------|------|---------|
| `CodeReview` | 当前分支未合并代码的专业审查 | 代码合入前的 review |
| `bi-iteration-docs` | 创建 BI 周迭代上线文档套件并联动云效建分支 | "创建迭代文档"、"上线文档" |
| `demand_development` | 强状态门控的需求开发流程（拆解→设计→实现→测试→Yapi→复盘） | PHP 项目需求开发、功能迁移 |
| `php-developer` | PHP 项目开发规范（SQL 参数绑定、PSR、命名空间、RESTful） | Phalcon、bi-common、fbi、ard-* 等项目 |
| `pua` | 高 agency 穷尽式问题解决，触发企业文化压力 | 重复失败、被动行为、用户不满 |
| `yunxiao` | 云效 MCP 分支创建与命名规范 | `feature/YYYYMMDD/trunk\|common` |

## Agents 一览

| Agent | 风格 | 模型 |
|-------|------|------|
| `novel_Andersen` | 安徒生故事风（≤100 字儿童故事） | sonnet |
| `novel_Fairy_Tales` | 格林童话故事风 | sonnet |

由 `.claude/skills/novel`（opus 模型）作为编排入口，通过 Agent tool 调用对应子代理。

## 核心约定

### 需求开发流程（`demand_development`）

强状态门控，每个需求一个独立 STATE 文件：

```
~/.claude/skills/demand_development/workspace/states/STATE-{需求编号}.md
```

`allowed_next_action` 字段决定当前唯一可执行的操作，未获用户"通过"严禁更新 STATE 或跳步。

### 执行环境

⚠️ 所有 PHP 任务必须在 Docker 容器中执行，本机环境不可用。

```bash
docker ps
docker exec -it {php_container} {command}
```

### 云效分支命名

```
feature/YYYYMMDD/trunk    # 测试分支
feature/YYYYMMDD/common   # 线上分支
```

分支必须从 `master` 创建，组织 ID ``。

## 维护

- 修改 Skill 后无需重启，Claude Code 下次激活时自动加载。
- Skill 触发条件写在 frontmatter 的 `description` 中，关键词要尽量覆盖真实场景。
- 新增 Skill 推荐沿用现有目录结构：`SKILL.md` 主入口 + `references/` 详细规范 + `workspace/`（如需）运行时状态。
