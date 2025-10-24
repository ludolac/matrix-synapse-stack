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
