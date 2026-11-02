{{/*
Create a default name from the full name.
*/}}
{{- define "tck8s-iam.fullname" -}}
{{- if .Label -}}
  {{- .Label.app | trunc 63 | trimSuffix "-" -}}
{{- else -}}
  {{- if .Chart -}}
    {{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- .Values.appName | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a standard name for the app.
*/}}
{{- define "tck8s-iam.name" -}}
{{- if .Chart -}}
  {{- default .Chart.Name .Values.appName -}}
{{- else -}}
  {{- .Values.appName -}}
{{- end -}}
{{- end -}}
