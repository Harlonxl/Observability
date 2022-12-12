#!/bin/bash

java ${JAVA_OPTS} -jar profilingtest-1.0.jar ${PARAMS} 2>&1 > /dev/null &

profiling_interval=60
if [ -n "$PROFILING_INTERVAL" ]; then
    profiling_interval=$PROFILING_INTERVAL
fi

while [[ true ]]; do
    cd /usr/local/async-profiler && /bin/bash collect.sh >> ./profiling_cron.log 2>&1
    sleep $profiling_interval
done
