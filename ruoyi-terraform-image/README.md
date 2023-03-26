# 观测云若依Demo镜像清单

### 构建 MySQL 镜像 
```shell
cd mysql
docker build -t ruoyi-mysql:v1.0 . 
```

### 构建 Redis 镜像
```shell
docker build -f DockerfileRedis -t ruoyi-mysql:v1.0 . 
```

### 构建 Nacos 镜像
```shell
cd nacos
docker build -t ruoyi-nacos:v1.0 . 
```

### 构建 web-service 镜像
```shell
docker build -f DockerfileWeb -t ruoyi-web:v1.0 . 
```

### 构建 system-service 镜像
```shell
docker build -f DockerfileSystem -t ruoyi-system:v1.0 . 
```

### 构建 gateway-service 镜像
```shell
docker build -f DockerfileSystem -t ruoyi-system:v1.0 . 
```

### 构建 auth-service 镜像
```shell
docker build -f DockerfileAuth -t ruoyi-auth:v1.0 . 
```

### 物料包下载
- [ruoyi-auth.jar](https://pan.baidu.com/s/1qewuuwrHGCTMVxlvJ5N_ug?pwd=1tdy)
- [ruoyi-gateway.jar](https://pan.baidu.com/s/19HEu5mVUTmb_nEhq6aEdmg?pwd=32h5)
- [ruoyi-modules-system.jar](https://pan.baidu.com/s/1tbkBlIF0mRZbVxlCfdSunQ?pwd=9qdy)

> github限制上传50M文件，相关物料包请自行下载