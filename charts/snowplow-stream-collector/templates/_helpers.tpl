{{/* vim: set filetype=mustache: */}}
{{/*
Define default values for required values.
*/}}

{{- define "service.targetCPUUtilizationPercentage" -}}
{{- mul .Values.service.targetCPUUtilizationPercentage .Values.service.minReplicas }}
{{- end -}}

{{- define "service.gcp.networkEndpointGroupName" -}}
{{- default .Release.Name .Values.service.gcp.networkEndpointGroupName -}}
{{- end -}}

{{- define "service.config.hoconBase64" -}}
{{- if eq .Values.service.config.hoconBase64 "" }}
{{- tpl (.Files.Get "examples/stdout.hocon") . | b64enc -}}
{{- else -}}
{{- .Values.service.config.hoconBase64 -}}
{{- end -}}
{{- end -}}

{{- define "collector.port" -}}
{{- if .Values.service.nginx.deploy }}
{{- add .Values.service.port 1 -}}
{{- else -}}
{{- .Values.service.port -}}
{{- end -}}
{{- end -}}
