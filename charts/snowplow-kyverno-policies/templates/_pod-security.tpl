{{/*
Pod Security Standards "restricted" controls, one define per control, each
rendering that control's ValidatingPolicy validations. Rendered by
templates/generic/pod-security-restricted.yaml, which supplies these variables:

  allContainers     containers + initContainers + ephemeralContainers
  securityContexts  the Pod securityContext plus every container's, for checks
                    that treat pod and container level the same way
  isWindows         spec.os.name is windows
  userNamespace     spec.hostUsers is false

Each control mirrors the named check in k8s.io/pod-security-admission/policy
at Kubernetes 1.35. Optional chaining (.?field.orValue(default)) is used
throughout: a missing field is a CEL evaluation error, and under
failurePolicy Ignore an error admits the Pod.
*/}}

{{/* windowsHostProcess (baseline) */}}
{{- define "snowplow-kyverno-policies.pss.disallow-host-process" -}}
- expression: >-
    variables.securityContexts.all(sc,
      !sc.?windowsOptions.?hostProcess.orValue(false))
  message: >-
    HostProcess containers are disallowed. securityContext.windowsOptions.hostProcess
    must be unset or false on the Pod and every container.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* hostNamespaces (baseline) */}}
{{- define "snowplow-kyverno-policies.pss.disallow-host-namespaces" -}}
- expression: >-
    !object.spec.?hostNetwork.orValue(false) &&
    !object.spec.?hostPID.orValue(false) &&
    !object.spec.?hostIPC.orValue(false)
  message: >-
    Sharing the host namespaces is disallowed. spec.hostNetwork, spec.hostPID
    and spec.hostIPC must be unset or false.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* privileged (baseline) */}}
{{- define "snowplow-kyverno-policies.pss.disallow-privileged-containers" -}}
- expression: >-
    variables.allContainers.all(c,
      !c.?securityContext.?privileged.orValue(false))
  message: >-
    Privileged containers are disallowed. securityContext.privileged must be
    unset or false on every container.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* hostPorts (baseline) */}}
{{- define "snowplow-kyverno-policies.pss.disallow-host-ports" -}}
- expression: >-
    variables.allContainers.all(c,
      c.?ports.orValue([]).all(p, p.?hostPort.orValue(0) == 0))
  message: >-
    Host ports are disallowed. ports[*].hostPort must be unset or 0 on every
    container.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* hostProbesAndHostLifecycle (baseline) */}}
{{- define "snowplow-kyverno-policies.pss.disallow-host-probes" -}}
- expression: >-
    variables.allContainers.all(c,
      [c.?livenessProbe, c.?readinessProbe, c.?startupProbe,
       c.?lifecycle.?postStart, c.?lifecycle.?preStop].all(h,
        h.?httpGet.?host.orValue('') == '' &&
        h.?tcpSocket.?host.orValue('') == ''))
  message: >-
    Probe and lifecycle handler hosts are disallowed. httpGet.host and
    tcpSocket.host must be unset in every probe and lifecycle handler.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* appArmorProfile (baseline) */}}
{{- define "snowplow-kyverno-policies.pss.restrict-apparmor" -}}
- expression: >-
    variables.securityContexts.all(sc,
      !has(sc.appArmorProfile) ||
      sc.appArmorProfile.?type.orValue('') in ['RuntimeDefault', 'Localhost']) &&
    object.metadata.?annotations.orValue({}).all(k,
      !k.startsWith('container.apparmor.security.beta.kubernetes.io/') ||
      object.metadata.annotations[k] == '' ||
      object.metadata.annotations[k] == 'runtime/default' ||
      object.metadata.annotations[k].startsWith('localhost/'))
  message: >-
    Unconfined AppArmor profiles are disallowed. securityContext.appArmorProfile.type
    must be unset, RuntimeDefault or Localhost, and AppArmor annotations must be
    runtime/default or localhost/*.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* seLinuxOptions (baseline) */}}
{{- define "snowplow-kyverno-policies.pss.restrict-selinux" -}}
- expression: >-
    variables.securityContexts.all(sc,
      !has(sc.seLinuxOptions) || (
        sc.seLinuxOptions.?type.orValue('') in
          ['', 'container_t', 'container_init_t', 'container_kvm_t', 'container_engine_t'] &&
        sc.seLinuxOptions.?user.orValue('') == '' &&
        sc.seLinuxOptions.?role.orValue('') == ''))
  message: >-
    Custom SELinux options are disallowed. seLinuxOptions.type must be unset or
    one of container_t, container_init_t, container_kvm_t, container_engine_t,
    and seLinuxOptions.user and role must be unset.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* sysctls (baseline), allowlist as of Kubernetes 1.32 */}}
{{- define "snowplow-kyverno-policies.pss.restrict-sysctls" -}}
- expression: >-
    object.spec.?securityContext.?sysctls.orValue([]).all(s, s.name in [
      'kernel.shm_rmid_forced', 'net.ipv4.ip_local_port_range',
      'net.ipv4.tcp_syncookies', 'net.ipv4.ping_group_range',
      'net.ipv4.ip_unprivileged_port_start', 'net.ipv4.ip_local_reserved_ports',
      'net.ipv4.tcp_keepalive_time', 'net.ipv4.tcp_fin_timeout',
      'net.ipv4.tcp_keepalive_intvl', 'net.ipv4.tcp_keepalive_probes',
      'net.ipv4.tcp_rmem', 'net.ipv4.tcp_wmem'])
  message: >-
    Unsafe sysctls are disallowed. spec.securityContext.sysctls may only set the
    Pod Security Standards safe set.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* restrictedVolumes (restricted; supersedes hostPathVolumes) */}}
{{- define "snowplow-kyverno-policies.pss.restrict-volume-types" -}}
- expression: >-
    object.spec.?volumes.orValue([]).all(v,
      has(v.configMap) || has(v.csi) || has(v.downwardAPI) || has(v.emptyDir) ||
      has(v.ephemeral) || has(v.image) || has(v.persistentVolumeClaim) ||
      has(v.projected) || has(v.secret))
  message: >-
    Only configMap, csi, downwardAPI, emptyDir, ephemeral, image,
    persistentVolumeClaim, projected and secret volumes are allowed.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* allowPrivilegeEscalation (restricted) */}}
{{- define "snowplow-kyverno-policies.pss.disallow-privilege-escalation" -}}
- expression: >-
    variables.isWindows ||
    variables.allContainers.all(c,
      c.?securityContext.?allowPrivilegeEscalation.orValue(true) == false)
  message: >-
    Privilege escalation is disallowed. Every container must set
    securityContext.allowPrivilegeEscalation to false.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* runAsNonRoot (restricted) */}}
{{- define "snowplow-kyverno-policies.pss.require-run-as-non-root" -}}
- expression: >-
    variables.userNamespace || (
      object.spec.?securityContext.?runAsNonRoot.orValue(true) == true &&
      variables.allContainers.all(c,
        c.?securityContext.?runAsNonRoot.orValue(
          object.spec.?securityContext.?runAsNonRoot.orValue(false)) == true))
  message: >-
    Running as root is disallowed. Set securityContext.runAsNonRoot to true on
    the Pod, or on every container, and do not set it to false anywhere.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* runAsUser (restricted) */}}
{{- define "snowplow-kyverno-policies.pss.disallow-run-as-root-user" -}}
- expression: >-
    variables.userNamespace ||
    variables.securityContexts.all(sc, sc.?runAsUser.orValue(1) != 0)
  message: >-
    Running as UID 0 is disallowed. securityContext.runAsUser must be unset or
    non-zero on the Pod and every container.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* seccompProfile_restricted (restricted; supersedes seccompProfile_baseline) */}}
{{- define "snowplow-kyverno-policies.pss.restrict-seccomp" -}}
- expression: >-
    variables.isWindows || (
      variables.securityContexts.all(sc,
        !has(sc.seccompProfile) ||
        sc.seccompProfile.?type.orValue('') in ['RuntimeDefault', 'Localhost']) &&
      (object.spec.?securityContext.?seccompProfile.hasValue() ||
       variables.allContainers.all(c, c.?securityContext.?seccompProfile.hasValue())))
  message: >-
    securityContext.seccompProfile.type must be set to RuntimeDefault or
    Localhost, on the Pod or on every container.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* capabilities_restricted (restricted; supersedes capabilities_baseline) */}}
{{- define "snowplow-kyverno-policies.pss.restrict-capabilities" -}}
- expression: >-
    variables.isWindows ||
    variables.allContainers.all(c,
      c.?securityContext.?capabilities.?drop.orValue([]).exists(x, x == 'ALL') &&
      c.?securityContext.?capabilities.?add.orValue([]).all(x, x == 'NET_BIND_SERVICE'))
  message: >-
    Every container must drop ALL capabilities, and may add back only
    NET_BIND_SERVICE.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/* procMount_restricted (restricted; supersedes procMount) */}}
{{- define "snowplow-kyverno-policies.pss.disallow-proc-mount" -}}
- expression: >-
    variables.allContainers.all(c,
      c.?securityContext.?procMount.orValue('Default') == 'Default')
  message: >-
    Non-default /proc mounts are disallowed. securityContext.procMount must be
    unset or Default on every container.
    {{- include "snowplow-kyverno-policies.pss.exemptionHint" . }}
{{- end -}}

{{/*
Exemption hint appended to every control's message, matching the other curated
policies. Renders nothing when exemptionLabel is empty.
*/}}
{{- define "snowplow-kyverno-policies.pss.exemptionHint" -}}
{{- with .Values.policies.podSecurityRestricted.exemptionLabel }} Label the Pod {{ . }}: "true" to exempt it.{{ end }}
{{- end -}}
