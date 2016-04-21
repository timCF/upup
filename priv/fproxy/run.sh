#!/bin/bash
HIDEME80=$(phantomjs ./hideme.js 80)
echo $(phantomjs --web-security=no --proxy=$HIDEME80:80 ./spys.js $1)
