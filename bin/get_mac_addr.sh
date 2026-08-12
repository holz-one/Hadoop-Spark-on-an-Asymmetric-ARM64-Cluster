#!/bin/bash
ETH=$1
ip addr show ${ETH} | grep 'ether'| tr -s ' ' | cut -f3 -d' '