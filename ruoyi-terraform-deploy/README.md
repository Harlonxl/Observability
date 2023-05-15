# 观测云若依Demo部署清单

### 部署资源
```shell
./deploy_ruoyi.sh \
    --applicationid=ruoyi_web \
    --allowedtracingorigins="['http://8.xx.xx.58:30000', 'http://8.xx.xx.26:30000']" \
    --dataway=https://openway.guance.com?token=tkn_5cxxxxxxxf2 \
    --prefix=ruoyi \
    --logsource=ruoyi-log \
    --version=1.0 \
    --env=prod
```

### 卸载资源
```shell
./undeploy_ruoyi.sh
```
