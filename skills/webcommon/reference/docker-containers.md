# Docker 容器执行环境

## 铁律

> **所有验证命令必须在 Docker 容器中执行，本机环境不可用。**

## 执行前必须检查

```bash
# 确认容器运行中
docker ps
```

## 命令执行格式

```bash
docker exec -it {php_container} {command}
```

## 常用操作

```bash
# 进入容器
docker exec -it {php_container} bash

# 执行 PHP 命令
docker exec -it {php_container} php {script_path}

# 执行 Composer
docker exec -it {php_container} composer {command} -d {project_path}

# 执行 PHPUnit
docker exec -it {php_container} php {project_path}/vendor/bin/phpunit --configuration {phpunit_config}

# 查看错误日志
docker exec -it {php_container} tail -f {log_path}
```

## 注意事项

1. **首次使用前**：执行 `docker ps` 确认容器名和状态
2. **路径映射**：容器内路径可能与本机路径不同，注意确认
3. **权限问题**：如遇权限错误，检查容器内用户和文件权限
4. **容器重启后**：需重新检查容器状态
