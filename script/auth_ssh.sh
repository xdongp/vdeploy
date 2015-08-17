#!/usr/bin/env bash
source ./install_openstack_lib.sh
keygen
auto_ssh 10.0.0.1 111111
auto_ssh 10.0.0.2 111111
auto_ssh 10.0.0.3 111111