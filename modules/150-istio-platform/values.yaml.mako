# istioPlatformNamespace: istio-system
istioPlatform:
  global:
    proxy:
      % if 'containerRegistryBase' in values['global']:
      image: ${values['global']['containerRegistryBase']}/istio/proxyv2:1.23.2
      % endif
  base:
    global:
      istioNamespace: ${values['global']['platformNamespace']}
  istiod:
    % if values['global']['deployOperators'] == "true":
    enabled: true
    % else:
    enabled: false
    % endif
    pilot:
      % if 'containerRegistryBase' in values['global']:
      image: ${values['global']['containerRegistryBase']}/istio/pilot:1.23.2
      % endif
      tolerations:
        - key: "${values['global']['platformMastersKey']}"
          value: "${values['global']['platformMastersValue']}"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['multiZone']['enabled']:
      topologySpreadConstraints:
        - labelSelector:
            matchLabels:
              app: istiod
              istio: pilot
          maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
      % endif
      % if values['global']['platformMasters']:
      nodeSelector:
        ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
      % endif
      % if values['global']['configurationProfile'] in {'perf', 'prod'}:  ### In PERF, PROD we run with 2 replicas
      autoscaleMin: 2     
      replicaCount: 2
      % endif
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
    global:
      istioNamespace: ${values['global']['platformNamespace']}
      logAsJson: true
    meshConfig:
      defaultHttpRetryPolicy:
        retries:
          attempts: 0
      extensionProviders:
      - name: ingress-access-log
        envoyFileAccessLog:
          logFormat:
            labels:
              start_time: "%START_TIME%"
              method: "%REQ(:METHOD)%"
              path: "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%"
              protocol: "%PROTOCOL%"
              response_code: "%RESPONSE_CODE%"
              response_flags: "%RESPONSE_FLAGS%"
              response_code_details: "%RESPONSE_CODE_DETAILS%"
              duration: "%DURATION%"
              upstream_host: "%UPSTREAM_HOST%"
              upstream_service_time: "%REQ(X-ENVOY-UPSTREAM_SERVICE_TIME)%"
              upstream_local_address: "%UPSTREAM_LOCAL_ADDRESS%"
              upstream_cluster: "%UPSTREAM_CLUSTER%"
              upstream_transport_failure_reason: "%UPSTREAM_TRANSPORT_FAILURE_REASON%"
              route_name: "%ROUTE_NAME%"
              downstream_local_address: "%DOWNSTREAM_LOCAL_ADDRESS%"
              user_agent: "%REQ(USER-AGENT)%"
              request_id: "%REQ(X-REQUEST-ID)%"
              client_ip: "%REQ(TRUE-Client-IP)%"
              requested_server_name: "%REQUESTED_SERVER_NAME%"
              bytes_received: "%BYTES_RECEIVED%"
              bytes_sent: "%BYTES_SENT%"
              downstream_remote_address: "%DOWNSTREAM_REMOTE_ADDRESS%"
              downstream_peer_serial: "%DOWNSTREAM_PEER_SERIAL%"
              authority: "%REQ(:AUTHORITY)%"
              x_forwarded_for: "%REQ(X-FORWARDED-FOR)%"
              x_trace_token: "%REQ(X-TRACE-TOKEN)%"
              x_trace_token_resp: "%RESP(X-TRACE-TOKEN)%"
              request_headers: "%DYNAMIC_METADATA(envoy.lua:request_headers)%"
              request_body: "%DYNAMIC_METADATA(envoy.lua:request_body)%"
              response_headers: "%DYNAMIC_METADATA(envoy.lua:response_headers)%"
              response_body: "%DYNAMIC_METADATA(envoy.lua:response_body)%"


