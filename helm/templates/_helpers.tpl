{{- define "intellisec.name" -}}
intellisec
{{- end -}}

{{- define "intellisec.fullname" -}}
{{- printf "%s" (include "intellisec.name" .) -}}
{{- end -}}
