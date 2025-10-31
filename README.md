# PostgreSQL AI Search 镜像

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

这是一个预配置的 PostgreSQL 15 镜像，集成了多种扩展，专门用于支持中文全文检索和 AI 向量搜索功能。该镜像包含了中文分词、向量搜索和图数据库功能，适用于需要结合文本检索与向量相似度搜索的 AI 应用场景。

## 功能特点

### 中文全文检索
- 集成 [zhparser](https://github.com/amutu/zhparser) 中文全文检索插件
- 使用 [SCWS](http://www.xunsearch.com/scws/) 中文分词引擎
- 内置中文词典，支持开箱即用的中文处理能力

### 向量搜索
- 集成 [pgvector](https://github.com/pgvector/pgvector) 向量相似度搜索扩展
- 支持向量存储和相似性查询
- 适用于 AI 应用中的语义搜索场景

### 图数据库
- 集成 [Apache AGE](https://age.apache.org/) 图数据库扩展
- 支持图数据存储和查询
- 兼容 openCypher 图查询语言

## 快速开始

### 构建镜像

```bash
docker build -t postgres-ai-search .
```

### 运行容器

```bash
docker run -d \
  --name postgres-ai \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -p 5432:5432 \
  postgres-ai-search
```

### 连接数据库

使用任何 PostgreSQL 客户端连接到数据库：

```bash
psql -h localhost -p 5432 -U postgres
```

默认密码由 `POSTGRES_PASSWORD` 环境变量指定。

## 使用示例

### 中文全文检索

```sql
-- 测试中文分词
SELECT to_tsvector('zhparser', '这是一个简单的测试');

-- 创建带有中文全文索引的表
CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    title TEXT,
    content TEXT,
    tsv TSVECTOR
);

-- 创建触发器自动更新 tsvector 字段
CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE ON articles
FOR EACH ROW EXECUTE FUNCTION tsvector_update_trigger(tsv, 'pg_catalog.chinese_zh', content);

-- 插入测试数据
INSERT INTO articles (title, content) VALUES 
('标题一', '这是一篇关于人工智能的文章'),
('标题二', '这篇文章讨论机器学习算法');

-- 执行中文全文搜索
SELECT * FROM articles WHERE tsv @@ to_tsquery('zhparser', '人工智能');
```

### 向量搜索

```sql
-- 创建向量表
CREATE TABLE items (
    id bigserial PRIMARY KEY,
    embedding vector(3)
);

-- 插入向量数据
INSERT INTO items (embedding) VALUES 
('[1,2,3]'),
('[4,5,6]');

-- 执行向量相似度查询
SELECT * FROM items ORDER BY embedding <-> '[3,1,2]' LIMIT 5;
```

### 图数据库操作

```sql
-- 创建图
SELECT create_graph('mygraph');

-- 创建顶点和边
SELECT * FROM cypher('mygraph', $$
    CREATE (a:Person {name: 'Alice', age: 30})
    CREATE (b:Person {name: 'Bob', age: 25})
    CREATE (a)-[:KNOWS {since: 2020}]->(b)
    RETURN a, b
$$) AS (a agtype, b agtype);
```

## 技术架构

### 核心组件

1. **PostgreSQL 15**: 关系型数据库基础
2. **zhparser**: 基于 SCWS 的中文分词全文检索插件
3. **pgvector**: 向量相似度搜索扩展
4. **Apache AGE**: 图数据库扩展

### 构建流程

1. 基于官方 PostgreSQL 15 镜像
2. 安装编译依赖和工具链
3. 编译安装 SCWS 中文分词库
4. 安装中文词典
5. 编译安装 zhparser 全文检索插件
6. 编译安装 pgvector 向量搜索扩展
7. 编译安装 Apache AGE 图数据库扩展
8. 复制初始化脚本到 `/docker-entrypoint-initdb.d/` 目录

## 配置选项

### 环境变量

| 变量 | 默认值 | 描述 |
|------|--------|------|
| `POSTGRES_PASSWORD` | 无默认值 | 数据库超级用户密码 |
| `POSTGRES_USER` | postgres | 数据库超级用户名 |
| `POSTGRES_DB` | postgres | 默认数据库名 |

更多环境变量请参考 [PostgreSQL Docker 官方文档](https://hub.docker.com/_/postgres)。

### 版本控制

| 组件 | 版本 |
|------|------|
| PostgreSQL | 15 |
| SCWS | 1.2.3 |
| zhparser | 最新主分支 |
| pgvector | v0.7.4 |
| Apache AGE | 1.5.0 |

## 数据持久化

为了防止数据丢失，建议将 PostgreSQL 数据目录挂载到本地卷：

```bash
docker run -d \
  --name postgres-ai \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -v /path/to/local/data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres-ai-search
```

## 故障排除

### 查看日志

```bash
docker logs postgres-ai
```

### 连接问题

如果遇到连接问题，请确保：
1. 容器正在运行 (`docker ps`)
2. 端口映射正确 (`-p 5432:5432`)
3. 密码设置正确

## 许可证

本项目采用 MIT 许可证发布。详情请见 [LICENSE](LICENSE) 文件。

## 致谢

感谢以下开源项目：

- [PostgreSQL](https://www.postgresql.org/)
- [zhparser](https://github.com/amutu/zhparser)
- [SCWS](http://www.xunsearch.com/scws/)
- [pgvector](https://github.com/pgvector/pgvector)
- [Apache AGE](https://age.apache.org/)