# 基础镜像
FROM mysql:5.7
# author
MAINTAINER Harlon

# 执行sql脚本
ADD ./sql/*.sql /opt/sql/
ADD ./db/*.sql /docker-entrypoint-initdb.d/
