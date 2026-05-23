#!/bin/bash

export SPARK_LOG_DIR=/tmp
export SPARK_NO_DAEMONIZE=true

exec /opt/spark/sbin/start-thriftserver.sh \
  "--master=k8s://https://{{ .Values.spark.k8sApiServerHost }}:{{ .Values.spark.k8sApiServerPort }}" \
  "--conf=spark.driver.host=$POD_IP" \
  "--conf=spark.dynamicAllocation.enabled=true" \
  "--conf=spark.dynamicAllocation.minExecutors=1" \{{/* TODO make configurable */}}
  "--conf=spark.dynamicAllocation.shuffleTracking.enabled=true" \
  "--conf=spark.kubernetes.container.image={{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}" \
  "--conf=spark.kubernetes.executor.podNamePrefix=$POD_NAME-$RANDOM" \
  "--conf=spark.kubernetes.driver.pod.name=$POD_NAME" \
  "--conf=spark.kubernetes.executor.request.cores=400m" \{{/* TODO make configurable */}}
  "--conf=spark.kubernetes.namespace={{ .Release.Namespace }}" \
  "--conf=spark.jars.ivy=/tmp/ivy" \
  "--conf=spark.jars.packages={{ include "spark-thrift-server.sparkPackages" . }}" \
  "--conf=spark.ui.enabled={{ .Values.spark.enableWebUi | ternary "true" "false" }}" \
  {{- if .Values.spark.enableDelta }}
  "--conf=spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension" \
  "--conf=spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog" \
  {{- end }}

