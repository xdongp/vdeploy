#!/usr/bin/env bash

source ./config.sh

host=$1

function install_compute(){
    host=$1
    curl "http://127.0.0.1:22222/api/host/progress?progress=10&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=20&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=30&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=40&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=50&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=60&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=70&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=80&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=90&ip=$host"
    sleep 3
    curl "http://127.0.0.1:22222/api/host/progress?progress=100&ip=$host"
}

install_compute $host;



