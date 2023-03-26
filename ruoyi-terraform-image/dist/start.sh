#!/bin/bash

eval "cat <<EOF
$(</data/nginx/web/dist/index.html)
EOF
" 2> /dev/null > /data/nginx/web/dist/index.html

nginx -g "daemon off;"