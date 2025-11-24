{{/*
Generate a name for the app
*/}}
{{- define "vijay-app.name" -}}
vijay-app
{{- end }}

{{/*
Generate full name: <release-name>-<chart-name>
*/}}
{{- define "vijay-app.fullname" -}}
{{ .Release.Name }}-{{ include "vijay-app.name" . }}
{{- end }}

