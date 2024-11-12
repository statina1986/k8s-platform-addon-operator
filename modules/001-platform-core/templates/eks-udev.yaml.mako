{{- if .Values.platformCore.eksUdevEnabled }}
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: udev-rule-writer
  namespace: platform
spec:
  selector:
    matchLabels:
      app: udev-rule-writer
  template:
    metadata:
      labels:
        app: udev-rule-writer
    spec:
      # Ensures this runs only on nodes with the "dedicated-nodes=local-storage" label
      tolerations: 
        - key: "${values['global']['localStorageKey']}"
          value: "${values['global']['localStorageValue']}"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['localStorage']:
      nodeSelector:
        ${values['global']['localStorageKey']}: ${values['global']['localStorageValue']}
      % endif
      hostNetwork: true  # Enables access to the host's network namespace
      hostPID: true      # Enables access to the host's PID namespace
      hostIPC: true      # Enables access to the host's IPC namespace
      priorityClassName: system-node-critical  # High priority for node-critical tasks
      terminationGracePeriodSeconds: 0         # Immediate termination for quick cleanup
      initContainers:
      - name: init-udev-rule
         % if 'containerRegistryBase' in values['global']:
        image: ${values['global']['containerRegistryBase']}/alpine:3.15
        % else:
        image: alpine:3.15
        % endif
        command:
          - sh
          - -c
          - |
            FILE_PATH="/host/etc/udev/rules.d/90-kubernetes-discovery.rules"
            if [ ! -f "$FILE_PATH" ]; then
              echo "File $FILE_PATH does not exist. Creating file and adding rule."
              mkdir -p /host/etc/udev/rules.d
              echo 'KERNEL=="nvme[0-9]*n[0-9]*", ENV{DEVTYPE}=="disk", ATTRS{model}=="Amazon EC2 NVMe Instance Storage", ATTRS{serial}=="?*", SYMLINK+="disk/kubernetes/nvme-$attr{model}_$attr{serial}", OPTIONS="string_escape=replace"' > "$FILE_PATH"
              echo "Udev rule added to $FILE_PATH."
            else
              echo "File $FILE_PATH already exists. No action needed."
            fi

            echo "Reloading & re-triggering udev on the host."
            nsenter -t 1 -m -u -i -n -p -- /usr/bin/udevadm control --reload && nsenter -t 1 -m -u -i -n -p -- /usr/bin/udevadm trigger
        securityContext:
          privileged: true  # Required to access the host filesystem
        volumeMounts:
        - name: host-root
          mountPath: /host
      containers:
      - name: dummy-container
        % if 'containerRegistryBase' in values['global']:
        image: ${values['global']['containerRegistryBase']}/alpine:3.15
        % else:
        image: alpine:3.15
        % endif
        command: ["sh", "-c", "sleep infinity"]
        securityContext:
          privileged: false
          readOnlyRootFilesystem: true
          runAsUser: 65534   # Use a non-root user
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]  # Drops all capabilities
        volumeMounts: []     # No volume mounts to host system
      volumes:
      - name: host-root
        hostPath:
          path: /
---
{{- end }}