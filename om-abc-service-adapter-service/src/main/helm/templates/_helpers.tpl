{{/*
Expand the name of the chart.
*/}}
{{- define "om.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "om.fullname" -}}
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
{{- define "om.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "om.labels" -}}
helm.sh/chart: {{ include "om.chart" . }}
{{ include "om.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "om.selectorLabels" -}}
app.kubernetes.io/name: {{ include "om.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "om.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "om.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "logback.logger" -}}
{{ range .Values.logback.logger }}
{{- if and (.name) (.loglevel) }}
{{ printf "<logger name=\"%s\" level=\"%s\" />" .name .loglevel }}
{{- end }}
{{- end }}
{{- end }}

{{- define "om.namingPrefix" -}}
{{- $namingSeparator := default "-" .Values.naming.separator }}
{{- $namingProduct := default "om" .Values.naming.productName }}
{{- $namingContext := .Release.Namespace }}
{{- $namingTenant := required "tenant is required" .Values.naming.tenant }}
{{- $namingEnv := required "env is required" .Values.naming.env }}
{{- printf "%s%s%s%s%s%s%s%s" $namingTenant $namingSeparator $namingProduct $namingSeparator $namingContext $namingSeparator $namingEnv $namingSeparator | lower -}}
{{- end }}