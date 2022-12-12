set -e

LIBRARY_VERSION=2.8.3

if [ -n "$PROFILING_ENABLED" ]; then
   if [ $PROFILING_ENABLED -eq 0 ]; then
    exit 0
   fi
fi

# 允许上传至 DataKit 的 jfr 文件大小 (6 M)，请勿修改
MAX_JFR_FILE_SIZE=6000000

# DataKit 服务地址
datakit_url=http://datakit-service.datakit:9529
if [ -n "$DATAKIT_URL" ]; then
    datakit_url=$DATAKIT_URL
fi

# 上传 profiling 数据的完整地址
datakit_profiling_url=$datakit_url/profiling/v1/input

# 应用的环境
app_env=dev
if [ -n "$APP_ENV" ]; then
    app_env=$APP_ENV
fi

# 应用的版本
app_version=0.0.0
if [ -n "$APP_VERSION" ]; then
    app_version=$APP_VERSION
fi

# 主机名称
host_name=$(hostname)
if [ -n "$HOST_NAME" ]; then
    host_name=$HOST_NAME
fi

# 服务名称
service_name=
if [ -n "$SERVICE_NAME" ]; then
  service_name=$SERVICE_NAME
fi

# profiling duration, in seconds
profiling_duration=10
if [ -n "$PROFILING_DURATION" ]; then
    profiling_duration=$PROFILING_DURATION
fi

# profiling event
profiling_event=cpu
if [ -n "$PROFILING_EVENT" ]; then
    profiling_event=$PROFILING_EVENT
fi

# 采集的 java 应用进程 ID，此处可以自定义需要采集的 java 进程，比如可以根据进程名称过滤
java_process_ids=$(jps -q -J-XX:+PerfDisableSharedMem)
if [ -n "$PROCESS_ID" ]; then
    java_process_ids=`echo $PROCESS_ID | tr "," " "`
fi

if [[ $java_process_ids == "" ]]; then
    printf "Warning: no java program found, exit now\n"
    exit 1
fi

is_valid_process_id() {
    if [ -n "$1" ]; then
        if [[ $1 =~ ^[0-9]+$ ]]; then
            return 1
        fi
    fi
    return 0
}

profile_collect() {
    # disable -e
    set +e

    process_id=$1
    is_valid_process_id $process_id
    if [[ $? == 0 ]]; then
        printf "Warning: invalid process_id: $process_id, ignore"
        return 1
    fi

    uuid=
    jfr_file=$runtime_dir/profiler_$uuid.jfr
    event_json_file=$runtime_dir/event_$uuid.json

    process_name=$(jps | grep $process_id | awk '{print $2}')


    start_time=$(date +%FT%T.%N%:z)
    ./profiler.sh -d $profiling_duration --fdtransfer -e $profiling_event -o jfr -f $jfr_file $process_id
    end_time=$(date +%FT%T.%N%:z)

  if [ ! -f $jfr_file ]; then
    printf "Warning: generating profiling file failed for %s, pid %d\n" $process_name $process_id
    return
  else
    printf "generate profiling file successfully for %s, pid %d\n" $process_name $process_id
  fi

  jfr_zip_file=$jfr_file
  if hash zip 2>/dev/null; then
      jfr_zip_file=$jfr_file.zip
      zip -q $jfr_zip_file $jfr_file
  fi

    zip_file_size=`ls -la $jfr_zip_file | awk '{print $5}'`

  if [ -z "$service_name" ]; then
    service_name=$process_name
  fi

    if [ $zip_file_size -gt $MAX_JFR_FILE_SIZE ]; then
        printf "Warning: the size of the jfr file generated is bigger than $MAX_JFR_FILE_SIZE bytes, now is $zip_file_size bytes\n"
    else
        cat >$event_json_file <<END
{
    "tags_profiler": "library_version:$LIBRARY_VERSION,library_type:async_profiler,process_id:$process_id,process_name:$process_name,service:$service_name,host:$host_name,env:$app_env,version:$app_version",
    "start": "$start_time",
    "end": "$end_time",
    "family": "java",
    "format": "jfr"
}
END
        res=$(curl $datakit_profiling_url \
            -F "main=@$jfr_zip_file;filename=main.jfr" \
            -F "event=@$event_json_file;filename=event.json;type=application/json"  )

        if [[ $res != *ProfileID* ]]; then
            printf "Warning: send profile file to datakit failed\n"
            printf "$res"
        else
            printf "Info: send profile file to datakit successfully\n"
            rm -rf $event_json_file $jfr_file $jfr_zip_file
        fi
    fi

    set -e
}

runtime_dir=runtime
if [ ! -d $runtime_dir ]; then
  mkdir $runtime_dir
fi

# 并行采集 profiling 数据
for process_id in $java_process_ids; do
  printf "profiling process %d\n" $process_id
  profile_collect $process_id > $runtime_dir/$process_id.log 2>&1 &
done

# 等待所有任务结束
wait

# 输出任务执行日志
for process_id in $java_process_ids; do
  log_file=$runtime_dir/$process_id.log
  if [ -f $log_file ]; then
    echo
    cat $log_file
    rm $log_file
  fi
done
