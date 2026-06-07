# PostgreSQL AI Search 部署指南

## 1. 镜像构建与传输

### 构建镜像

```bash
docker build -t registry.cn-hangzhou.aliyuncs.com/aimode/postgres-ai-search:latest .
```

### 推送到阿里云镜像仓库

```bash
docker login --username=miracleblend registry.cn-hangzhou.aliyuncs.com
docker push registry.cn-hangzhou.aliyuncs.com/aimode/postgres-ai-search:latest
```

### 导出为 tar 文件（离线传输）

```bash
docker save registry.cn-hangzhou.aliyuncs.com/aimode/postgres-ai-search:latest -o pg-database.tar
```

### 目标机器导入并改名

```bash
docker load -i pg-database.tar
docker tag registry.cn-hangzhou.aliyuncs.com/aimode/postgres-ai-search:latest pg-database:latest
docker rmi registry.cn-hangzhou.aliyuncs.com/aimode/postgres-ai-search:latest
```

### 查看镜像架构

```bash
docker inspect pg-database:latest --format '{{.Architecture}}'
# amd64 = x86, arm64 = ARM
```

---

## 2. 启动服务

修改 `docker-compose.yml` 中的密码后启动：

```bash
docker compose up -d
```

停止服务：

```bash
docker compose down
```

查看日志：

```bash
docker logs pg-database
```

---

## 3. 创建用户和数据库

进入 PostgreSQL 命令行：

```bash
docker exec -it pg-database psql -U postgres
```

执行 SQL：

```sql
-- 创建用户
CREATE USER xmdda WITH PASSWORD 'your_password';

-- 创建数据库并指定 owner
CREATE DATABASE xmdda OWNER xmdda;

-- 授权
GRANT ALL PRIVILEGES ON DATABASE xmdda TO xmdda;

-- 退出
\q
```

---

## 4. 安装扩展（zhparser + pgvector）

在数据库中启用中文分词和向量搜索插件：

```bash
docker exec -it pg-database psql -U postgres -d xmdda_db -c \
  "CREATE EXTENSION zhparser; CREATE EXTENSION vector; CREATE TEXT SEARCH CONFIGURATION zhparsercfg (PARSER = zhparser); ALTER TEXT SEARCH CONFIGURATION zhparsercfg ADD MAPPING FOR n,v,i,j,a,l WITH simple;"
```

启用后即可使用中文全文搜索：

```sql
-- 中文分词全文检索
SELECT * FROM table_name WHERE to_tsvector('zhparsercfg', text_content) @@ to_tsquery('zhparsercfg', '搜索关键词');

-- 向量搜索（pgvector）
SELECT * FROM table_name ORDER BY embedding <=> '[0.1, 0.2, 0.3]' LIMIT 10;
```

---

## 5. 初始化表结构

将 SQL 脚本拷贝到容器并执行：

```bash
# 方式一：拷贝后执行
docker cp 00_init-new.sql pg-database:/tmp/00_init-new.sql
docker exec -it pg-database psql -U xmdda -d xmdda_db -f /tmp/00_init-new.sql

# 方式二：管道方式（无需拷贝）
cat 00_init-new.sql | docker exec -i pg-database psql -U xmdda -d xmdda
```

---

## 6. 连接数据库

```bash
# 容器内连接
docker exec -it pg-database psql -U xmdda -d xmdda

# 外部连接（端口映射为 15432）
psql -h <host_ip> -p 15432 -U xmdda -d xmdda
```

---

## 7. 常用运维

```bash
# 查看数据库列表
docker exec -it pg-database psql -U postgres -c '\l'

# 查看表列表
docker exec -it pg-database psql -U xmdda -d xmdda -c '\dt'

# 查看表结构
docker exec -it pg-database psql -U xmdda -d xmdda -c '\d table_name'

# 备份数据库
docker exec pg-database pg_dump -U xmdda xmdda > backup.sql

# 恢复数据库
cat backup.sql | docker exec -i pg-database psql -U xmdda -d xmdda
```
