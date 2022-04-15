{{/* vim: set filetype=mustache: */}}

{{/*
Define a common name prefix for all created objects.
*/}}
{{- define "iglu.prefix" -}}
{{ .Release.Name }}-iglu
{{- end -}}

{{/*
Define resource names for the CloudSQL proxy service.
*/}}
{{- define "iglu.cloudsqlproxy.name" -}}
{{ include "iglu.prefix" . }}-cloudsqlproxy
{{- end -}}
{{- define "iglu.cloudsqlproxy.host" -}}
{{ include "iglu.cloudsqlproxy.name" . }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/*
Define the name of the setup hooks.
*/}}
{{- define "iglu.hooks.name" -}}
{{ include "iglu.prefix" . }}-hooks
{{- end -}}

{{/*
Define resource names for the Iglu service.
*/}}
{{- define "iglu.app.name" -}}
{{ include "iglu.prefix" . }}-app
{{- end -}}
{{- define "iglu.app.secret.name" -}}
{{ include "iglu.prefix" . }}-secret
{{- end -}}
{{- define "iglu.app.config.name" -}}
{{ include "iglu.prefix" . }}-config
{{- end -}}

{{/*
Define default values for required values.
*/}}
{{- define "iglu.service.config.superApiKey" -}}
{{- default uuidv4 .Values.service.config.secrets.superApiKey | lower -}}
{{- end -}}
{{- define "iglu.service.config.database.type" -}}
{{- default "dummy" .Values.service.config.database.type | lower -}}
{{- end -}}
{{- define "iglu.service.targetCPUUtilizationPercentage" -}}
{{- mul .Values.service.targetCPUUtilizationPercentage .Values.service.minReplicas }}
{{- end -}}
{{- define "iglu.service.gcp.networkEndpointGroupName" -}}
{{- default .Release.Name .Values.service.gcp.networkEndpointGroupName -}}
{{- end -}}
{{- define "iglu.service.config.checksum" -}}
{{- printf "%s-%s-%s" (include "iglu.service.config.superApiKey" .) .Values.service.config.database.secrets.password .Values.service.config.database.secrets.username | sha256sum -}}
{{- end -}}
