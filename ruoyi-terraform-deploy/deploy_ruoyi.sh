#!/bin/bash

RUM_APPLICATION_ID=unset
ALLOWED_TRACING_ORIGINS=unset
DATAWAY=unset
PREFIX="ruoyi"
LOG_SOURCE="ruoyi-log"
VERSION="1.0"
ENV="prod"

usage()
{
  echo "Usage: deploy_ruoyi.sh [--applicationid] [--allowedtracingorigins] \
    [--dataway] [--prefix=ruoyi] [--logsource=ruoyi-log] [--env=prod] [--version=1.0]"
  exit 2
}

PARSED_ARGUMENTS=$(getopt -a -o i:a:t:p:s:v:e: --long \
    applicationid:,datakitorigin:,allowedtracingorigins:,dataway:,prefix:,logsource:,version:,env: -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
  usage
fi

eval set -- "$PARSED_ARGUMENTS"
while :
do
  case "$1" in
    -i | --applicationid) RUM_APPLICATION_ID="$2"; shift 2 ;;
    -a | --allowedtracingorigins) ALLOWED_TRACING_ORIGINS="$2"; shift 2 ;;
    -t | --dataway) DATAWAY="$2"; shift 2 ;;
    -p | --prefix) PREFIX="$2"; shift 2 ;;
    -s | --logsource) LOG_SOURCE="$2"; shift 2 ;;
    -v | --version) VERSION="$2"; shift 2 ;;
    -e | --env) ENV="$2"; shift 2 ;;
    --) shift; break ;;
    *) usage ;;
  esac
done

if [[ "$RUM_APPLICATION_ID" == "unset" || "$DATAKIT_ORIGIN" == "unset" \
      || "$ALLOWED_TRACING_ORIGINS" == "unset" || "$DATAWAY" == "unset" ]]; then
  usage
fi

echo "------------------------------"
echo "applicationId : $RUM_APPLICATION_ID"
echo "allowedTracingOrigins: $ALLOWED_TRACING_ORIGINS"
echo "dataway: $DATAWAY"
echo "prefix: $PREFIX"
echo "source: $LOG_SOURCE"
echo "version: $VERSION"
echo "env: $ENV"
echo "------------------------------"

echo "---- start deploy datakit ----"
eval "cat <<EOF
$(<./template/datakit.yaml)
EOF
" 2> /dev/null > ./deployment/datakit.yaml
kubectl apply -f ./deployment/datakit.yaml
sleep 10

echo "---- start deploy datakit operator ----"
kubectl apply -f ./deployment/datakit-operator.yaml
sleep 10

# datakit operator 会莫名其妙无法启动
while true; do
  status=`kubectl get deploy -n datakit | grep datakit-operato | awk '{print $2}'`;
  if [[ "$status" == "1/1" ]]; then echo "datakit-operator ready"; break; fi
  kubectl delete -f ./deployment/datakit-operator.yaml
  kubectl apply -f ./deployment/datakit-operator.yaml
  sleep 10;
done

echo "---- start deploy metric server ----"
kubectl apply -f ./deployment/components.yaml
sleep 10

echo "---- start deploy mysql ----"
kubectl create ns ruoyi
kubectl apply -f ./deployment/ruoyi-mysql.yaml

echo "---- start deploy redis ----"
kubectl apply -f ./deployment/ruoyi-redis.yaml
sleep 10

echo "---- start deploy nacos ----"
kubectl apply -f ./deployment/ruoyi-nacos.yaml
sleep 10

echo "---- start deploy system-service ----"
eval "cat <<EOF
$(<./template/system-deployment.yaml)
EOF
" 2> /dev/null > ./deployment/system-deployment.yaml
kubectl apply -f ./deployment/system-deployment.yaml

echo "---- start deploy gateway-service ----"
eval "cat <<EOF
$(<./template/gateway-deployment.yaml)
EOF
" 2> /dev/null > ./deployment/gateway-deployment.yaml
kubectl apply -f ./deployment/gateway-deployment.yaml

echo "---- start deploy auth-service ----"
eval "cat <<EOF
$(<./template/auth-deployment.yaml)
EOF
" 2> /dev/null > ./deployment/auth-deployment.yaml
kubectl apply -f ./deployment/auth-deployment.yaml
sleep 10

echo "---- start deploy web-service ----"
eval "cat <<EOF
$(<./template/web-deployment.yaml)
EOF
" 2> /dev/null > ./deployment/web-deployment.yaml
kubectl apply -f ./deployment/web-deployment.yaml
