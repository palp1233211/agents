# Docker 容器使用指引

> **所有开发/测试任务必须在 Docker 容器中执行，本机环境不可用。**

---

## 如何确定当前项目容器

AI **必须通过命令动态确认**，不得硬编码或假设容器名。

### 步骤 1：查看运行中容器

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
```

### 步骤 2：匹配当前项目

按以下优先级匹配：
1. 容器名与项目目录名相同（如当前项目 `ard-etl` → 容器名 `ard-etl`）
2. 容器名与项目 Image 或挂载目录相关
3. 若有多个候选，**列出让用户确认**，不要自行选择

### 步骤 3：若目标容器未运行

```bash
# 查看所有容器（含已停止）
docker ps -a --format "table {{.Names}}\t{{.Status}}"

# 启动容器
docker start {container_name}

# 确认启动成功
docker ps | grep {container_name}
```

---

## 容器内常用操作

```bash
# 进入容器交互式 shell
docker exec -it {container} bash

# 直接执行单条命令
docker exec {container} {command}

# 示例：执行 PHP 脚本
docker exec {container} php /mnt/www/app/cli.php TaskName ActionName
```

---

## 容器挂载说明

- 项目目录挂载到容器内 `/mnt/www`
- 本机修改代码后容器内**自动生效**，无需重建或同步
- 测试文件放入本机的 `tests/` 目录，在容器内用 `/mnt/www/tests/` 路径访问

---

## 前置检查清单

执行测试前必须确认：

```
□ docker ps 显示目标容器为 Up 状态
□ docker exec {container} cat /mnt/www/.env 显示正确的 country_code
□ 数据库配置指向目标国家环境
```

若任何一项失败，停止执行并向用户报告，不要尝试猜测或绕过。
