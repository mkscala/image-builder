#!/bin/bash

node -e "require('docker-mock').listen(5354)" &
echo $! > mock.pid
