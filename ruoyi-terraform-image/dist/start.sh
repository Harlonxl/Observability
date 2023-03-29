#!/bin/bash

eval "cat <<EOF
$(</data/nginx/web/dist/index.html)
EOF
" 2> /dev/null > /data/nginx/web/dist/index.html

eval "cat <<EOF
$(</etc/nginx/dd-config.json)
EOF
" 2> /dev/null > /etc/nginx/dd-config.json

nginx -g "daemon off;"