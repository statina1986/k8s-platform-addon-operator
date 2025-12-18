corednsPlatformNamespace: kube-system
corednsPlatform:
  # -- Configuration for underlying coredns helm-chart. See https://github.com/coredns/helm/tree/master/charts/coredns
  coredns:
    # -- Label selector for the pod, used by the the original coredns service.
    k8sAppLabelOverride: "kube-dns"
    image:
      % if 'containerRegistryBase' in values['global']:
      repository: ${values['global']['containerRegistryBase']}/coredns/coredns
      % endif
      tag: "1.13.1"
    autoscaler:
      image:
        % if 'containerRegistryBase' in values['global']:
        repository: ${values['global']['containerRegistryBase']}/cpa/cluster-proportional-autoscaler
        % endif
        tag: "v1.9.0"
    replicaCount: 2
    resources:
      limits:
        cpu: 200m
        memory: 256Mi
      requests:
        cpu: 100m
        memory: 128Mi
    # -- List of zones. Default zone only applied when no zones are configured.
    servers:
    - name: default
      zones:
      - zone: .
        use_tcp: true
      port: 53
      plugins:
      - name: errors
      - name: health
        configBlock: |-
          lameduck 10s
      - name: ready
      - name: kubernetes
        parameters: cluster.local in-addr.arpa ip6.arpa
        configBlock: |-
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
          ttl 30
      - name: prometheus
        parameters: 0.0.0.0:9153
      - name: forward
        parameters: . /etc/resolv.conf
      - name: cache
        parameters: 30
      - name: loop
      - name: reload
      - name: loadbalance

