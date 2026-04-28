{{/*
Expand the name of the chart.
*/}}
{{- define "matrix-synapse.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "matrix-synapse.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "matrix-synapse.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "matrix-synapse.labels" -}}
helm.sh/chart: {{ include "matrix-synapse.chart" . }}
{{ include "matrix-synapse.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "matrix-synapse.selectorLabels" -}}
app.kubernetes.io/name: {{ include "matrix-synapse.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "matrix-synapse.serviceAccountName" -}}
{{- if .Values.synapse.serviceAccount.create }}
{{- default (include "matrix-synapse.fullname" .) .Values.synapse.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.synapse.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Element labels
*/}}
{{- define "matrix-synapse.element.labels" -}}
helm.sh/chart: {{ include "matrix-synapse.chart" . }}
{{ include "matrix-synapse.element.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Element selector labels
*/}}
{{- define "matrix-synapse.element.selectorLabels" -}}
app.kubernetes.io/name: {{ include "matrix-synapse.name" . }}-element
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: element-web
{{- end }}

{{/*
PostgreSQL labels
*/}}
{{- define "matrix-synapse.postgresql.labels" -}}
helm.sh/chart: {{ include "matrix-synapse.chart" . }}
{{ include "matrix-synapse.postgresql.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
PostgreSQL selector labels
*/}}
{{- define "matrix-synapse.postgresql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "matrix-synapse.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: postgresql
{{- end }}

{{/*
Name of the CNPG Cluster resource (used when postgresql.mode == "cnpg").
*/}}
{{- define "matrix-synapse.postgresql.cnpgClusterName" -}}
{{- printf "%s-cnpg" (include "matrix-synapse.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Database hostname (read/write endpoint) resolved according to postgresql.mode.
- cnpg:       <cluster>-rw (primary, managed by CNPG)
- standalone: <fullname>-postgresql
- external:   user-supplied host
*/}}
{{- define "matrix-synapse.postgresql.host" -}}
{{- $mode := .Values.postgresql.mode | default "cnpg" -}}
{{- if eq $mode "cnpg" -}}
{{ printf "%s-rw" (include "matrix-synapse.postgresql.cnpgClusterName" .) }}
{{- else if eq $mode "standalone" -}}
{{ printf "%s-postgresql" (include "matrix-synapse.fullname" .) }}
{{- else if eq $mode "external" -}}
{{ required "postgresql.external.host is required when postgresql.mode=external" .Values.postgresql.external.host }}
{{- else -}}
{{ fail (printf "postgresql.mode must be one of: cnpg, standalone, external (got %q)" $mode) }}
{{- end -}}
{{- end }}

{{/*
Database port, same for all modes by default (5432), override via external.port.
*/}}
{{- define "matrix-synapse.postgresql.port" -}}
{{- if eq (.Values.postgresql.mode | default "cnpg") "external" -}}
{{ .Values.postgresql.external.port | default 5432 }}
{{- else -}}
5432
{{- end -}}
{{- end }}

{{/*
Name of the secret containing the PostgreSQL password.
- cnpg:       <cluster>-app (created by the CNPG operator, keys: username/password/...)
- standalone: <fullname>-postgresql (key: postgres-password)
- external:   user-supplied existingSecret.name
*/}}
{{- define "matrix-synapse.postgresql.secretName" -}}
{{- $mode := .Values.postgresql.mode | default "cnpg" -}}
{{- if eq $mode "cnpg" -}}
{{ printf "%s-app" (include "matrix-synapse.postgresql.cnpgClusterName" .) }}
{{- else if eq $mode "standalone" -}}
{{ printf "%s-postgresql" (include "matrix-synapse.fullname" .) }}
{{- else if eq $mode "external" -}}
{{ required "postgresql.external.existingSecret.name is required when postgresql.mode=external" .Values.postgresql.external.existingSecret.name }}
{{- end -}}
{{- end }}

{{/*
Secret key holding the PostgreSQL password.
*/}}
{{- define "matrix-synapse.postgresql.secretPasswordKey" -}}
{{- $mode := .Values.postgresql.mode | default "cnpg" -}}
{{- if eq $mode "cnpg" -}}
password
{{- else if eq $mode "standalone" -}}
postgres-password
{{- else if eq $mode "external" -}}
{{ .Values.postgresql.external.existingSecret.passwordKey | default "password" }}
{{- end -}}
{{- end }}

{{/*
Former helper matrix-synapse.mas.envSecrets was removed in chart 2.0.x — MAS
now loads secrets via a render-config init container that substitutes ${VAR}
placeholders in the config YAML (MAS does not apply Tera to config.yaml,
only to HTML templates). See templates/mas-deployment.yaml.
*/}}
