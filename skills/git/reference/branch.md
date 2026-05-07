# 分支创建与命名规范

## 命名格式

```
feature/YYYYMMDD/{type_or_owner}
```

### YYYYMMDD（日期段）

- 用户**未指定星期几** → 默认取**本周或下周最近的星期四**（即 weekday=4）
- 用户指定星期几（如"周三""周五"）→ 取**未来最近一个**该星期几
- 已经过了当天的截止时间，往后推一周

> 不允许使用过去日期。生成后必须显式告知用户「该日期对应 YYYY 年 MM 月 DD 日 星期X」并等待确认。

### {type_or_owner}（用途段）

| 取值              | 用途        | 示例                            |
|-------------------|-------------|---------------------------------|
| `trunk`           | 测试分支     | `feature/20260430/trunk`        |
| `common`          | 线上分支     | `feature/20260430/common`       |
| `{owner}_{需求号}` | 需求开发分支 | `feature/20260430/lwc_12345`    |

## 创建流程（必须按顺序）

```bash
R=~/sites/{project}   # 项目本地路径

# 0. 记录原分支（用于最后切回）
ORIG=$(git -C "$R" rev-parse --abbrev-ref HEAD)

# 1. 切到 master 并拉取最新
git -C "$R" checkout master
git -C "$R" pull --ff-only origin master

# 2. 检查工作区（区分两类脏文件）
#    ?? 未跟踪文件 → 不影响 checkout，无需处理，直接继续
#    M/A/D/R/C tracked 改动 → 必须暂停，与用户确认 stash 还是 commit
git -C "$R" status --porcelain | grep -E '^\s*[MARDC]' && echo "有 tracked 改动，停止！" || true

# 3. 从 master 创建新分支
git -C "$R" checkout -b feature/YYYYMMDD/xxx

# 4. 推送并设置上游
git -C "$R" push -u origin feature/YYYYMMDD/xxx

# 5. 切回原分支
git -C "$R" checkout "$ORIG"
```

> **强制约束**：
> - 分支必须从最新的 `master` 创建，不允许从其他 feature 分支派生
> - 执行完毕后**默认切回操作前的原分支**，不停留在新分支

## 多项目批量创建

当用户要求在多个项目同时创建同名分支：

1. 在每个项目仓库内**串行**执行上述流程（用函数封装，**不要用 `for p in $VAR` 字符串分词**，直接内联列表：`for p in fbi bi-common ...`）
2. 用 `git -C $DIR` 操作各仓库，**不要 cd 切换目录**
3. 任一项目失败必须立即报告，不要继续静默执行剩余项目
4. 全部完成后输出汇总表：`项目 | 分支名 | 远端推送 | 切回分支`

## 校验规则

执行前必须校验：

- [ ] 格式匹配 `^feature/\d{8}/[a-z][a-z0-9_]*$`
- [ ] 日期不在过去
- [ ] `type_or_owner` 段为 `trunk` / `common` / `{owner}_{number}` 之一
- [ ] 当前所在仓库在 SKILL.md 的 7 项目列表内

任一不通过 → 拒绝执行并向用户说明原因。
