#!/bin/bash

cd ${VOLUME_DATA_DIR}/netdata/config/go.d

# Kubernetes系
echo "enabled: no" | sudo tee k8s_apiserver.conf k8s_kubelet.conf k8s_kubeproxy.conf k8s_state.conf

# 使っていないDB系
echo "enabled: no" | sudo tee cassandra.conf couchdb.conf couchbase.conf mongodb.conf mssql.conf oracledb.conf yugabytedb.conf

# メッセージキュー系
echo "enabled: no" | sudo tee activemq.conf rabbitmq.conf beanstalk.conf pulsar.conf nats.conf

# GPU系
echo "enabled: no" | sudo tee nvidia_smi.conf dcgm.conf

# VMware系
echo "enabled: no" | sudo tee vsphere.conf scaleio.conf

# その他明らかに不要そうなもの
echo "enabled: no" | sudo tee hadoop.conf hdfs.conf
