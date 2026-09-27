{{/*
Create a default name from the full name.
*/}}
{{- define "tck8s-iam.fullname" -}}
{{- default .Name .Label.app -}}
{{- end -}}

{{/*
Create a standard name for the app.
*/}}
{{- define "tck8s-iam.name" -}}
{{- default .Chart.Name .Values.appName -}}
{{- end -}}