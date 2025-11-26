# 使用官方 PostgreSQL 15 镜像作为基础
FROM postgres:15

# 设置构建参数（可选）
ENV SCWS_VERSION=1.2.3
ENV PGVECTOR_VERSION=v0.7.4
ENV AGE_VERSION=1.5.0

# 修改 Debian 源为阿里云
#RUN sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources
#RUN sed -i 's|security.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources

# 安装编译依赖和工具
RUN apt-get update && apt install -y \
    build-essential \
    flex \
    bison \
    libreadline-dev \
    zlib1g-dev \
    git \
    cmake \
    libicu-dev \
    postgresql-server-dev-15 \
    postgresql-15-pg-bestmatch \
    && rm -rf /var/lib/apt/lists/*

# ==============================
# 1. 安装 SCWS（zhparser 依赖）
# ==============================
WORKDIR /tmp
COPY scws-${SCWS_VERSION}.tar.bz2 .
RUN tar -xjf scws-${SCWS_VERSION}.tar.bz2 && \
    cd scws-${SCWS_VERSION} && \
    ./configure --prefix=/usr/local/scws && \
    make && make install && \
    ln -sf /usr/local/scws/bin/scws /usr/bin/scws

# 安装中文词典
COPY scws-dict-chs-utf8.tar.bz2 /tmp/scws-dict-chs-utf8.tar.bz2
RUN mkdir -p /usr/local/scws/etc && \
    cp /tmp/scws-dict-chs-utf8.tar.bz2 /usr/local/scws/etc/dict.utf8.xdb && \
    cd /usr/local/scws/etc && \
    tar -xjf dict.utf8.xdb && \
    rm -f dict.utf8.xdb

# 设置动态库路径（确保 scws 能被找到）
RUN echo '/usr/local/scws/lib' > /etc/ld.so.conf.d/scws.conf && \
    ldconfig


# ==============================
# 2. 安装 zhparser
# ==============================
RUN git clone https://github.com/amutu/zhparser.git &&  \
    cd zhparser && \
    SCWS_HOME=/usr/local/scws make && \
    make install
# ==============================
# 3. 安装 pgvector
# ==============================
RUN git clone --branch ${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git && \
   cd pgvector && \
   make && make install

# ==============================
# 4. 安装 Apache AGE
# ==============================
RUN git clone --branch release/PG15/1.5.0 https://github.com/apache/age.git && \
   cd age && \
   make && make install

COPY docker-entrypoint-initdb.d/00-create-extension-age.sql /docker-entrypoint-initdb.d/00-create-extension-age.sql

# 设置 PostgreSQL 配置
ENV PATH="/usr/lib/postgresql/15/bin:$PATH"
ENV PGDATA="/var/lib/postgresql/data"
ENV POSTGRES_USER=postgres
# Use absolute path to postgres binary to avoid PATH/resolution issues in the entrypoint
CMD ["postgres", "-c", "shared_preload_libraries=age,pg_bestmatch"]