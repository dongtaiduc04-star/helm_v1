{{- define "getlink-dtd.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "getlink-dtd.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "getlink-dtd.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- define "getlink-dtd.labels" -}}
app.kubernetes.io/name: {{ include "getlink-dtd.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end }}

{{- define "getlink-dtd.selectorLabels" -}}
app.kubernetes.io/name: {{ include "getlink-dtd.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "getlink-dtd.secretName" -}}
{{- required "existingSecret must name a Kubernetes Secret" .Values.existingSecret }}
{{- end }}

{{- define "getlink-dtd.imagePullSecrets" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
