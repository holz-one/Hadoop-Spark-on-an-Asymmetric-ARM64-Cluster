#!/bin/bash
IF=$1
ip addr show | grep "^[0-9]: ${IF}*"| tr -d ' '| cut -d':' -f2