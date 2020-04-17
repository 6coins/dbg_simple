#!/bin/sh

# 追踪用-sname 启动的节点
ERL="erl -sname local_node -s dbg_simple"

# 追踪用-name 启动的节点(要修改127.0.0.1和远程节点一个网段
# ERL="erl -name local_node@127.0.0.1 -s dbg_simple"

erlc dbg_simple.erl
echo $ERL
$ERL

