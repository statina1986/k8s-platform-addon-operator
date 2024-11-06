# certPlatformNamespace: cert-manager
certPlatform:

  # -- Configuration for underlying cert-manager helm-chart. See https://artifacthub.io/packages/helm/cert-manager/cert-manager/1.12.13#configuration
  cert-manager:
    % if values['global']['deployOperators'] == "true":
    enabled: true
    % else:
    enabled: false
    % endif
    global:
      leaderElection:
        namespace: "${values['global']['platformNamespace']}"
      % if values['global']['clusterwideResources'] == "false":
      rbac:
        create: false
      % endif
    extraArgs:
      - --issuer-ambient-credentials
    image:
      % if 'containerRegistryBase' in values['global']:
      registry: ${values['global']['containerRegistryBase']}
      repository: jetstack/cert-manager-controller
      % endif
    cainjector:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        repository: jetstack/cert-manager-cainjector
        % endif
      serviceAccount:
        create: false
        name: "platform"
    webhook:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        repository: jetstack/cert-manager-webhook
        % endif
      serviceAccount:
        create: false
        name: "platform"
    startupapicheck:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        repository: jetstack/cert-manager-ctl
        % endif
    acmesolver:
      image:
        % if 'containerRegistryBase' in values['global']:
        registry: ${values['global']['containerRegistryBase']}
        repository: jetstack/cert-manager-acmesolver
        % endif   
    serviceAccount:
      create: false
      name: platform
    tolerations:
      - key: "${values['global']['platformMastersKey']}"
        value: "${values['global']['platformMastersValue']}"
        operator: "Equal"
        effect: "NoSchedule"
    % if values['global']['platformMasters']:
    nodeSelector:
      ${values['global']['platformMastersKey']}: ${values['global']['platformMastersValue']}
    % endif

  # -- List of Issuers to provision. See https://cert-manager.io/docs/concepts/issuer/ for `Issuer` resource details.
  issuers:
    # -- Example Issuer used for documentation
    example-issuer:
      # -- If Issuer is enabled and hence will be deployed to the cluster.
      enabled: false
      # -- Configure `spec` property of `Issuer` resource.
      spec: {}
    # -- This issuer is used to generate self-signed certificate for Simple Qvantel CA
    qvantel-selfsigned-issuer:
      enabled: true
      spec:
        selfSigned: {}
    # -- This issuer is Simple Qvantel CA issuer
    qvantel-ca-issuer:
      enabled: true
      spec:
        ca:
          secretName: qvantel-root-ca
    # -- This issuer is used for *.qvantel.systems certificates issued with letsencrypt
    qvantel-dot-systems:
      enabled: false
      spec:
        acme:
          server: https://acme-v02.api.letsencrypt.org/directory
          email: infra.finland@qvantel.com
          privateKeySecretRef:
            name: letsencrypt-platform-dns
          solvers:
            - selector:
                dnsZones:
                  - "qvantel.systems"
              dns01:
                route53:
                  region: eu-central-1
                  hostedZoneID: ZJ7W7ERY57J33
                  role: "arn:aws:iam::067412573140:role/Qvantel-Update-DNS-From-Development-Account"
    # -- This issuer is used for *.qvantel.solutions certificates issued with letsencrypt
    qvantel-dot-solutions:
      enabled: false
      spec:
        acme:
          server: https://acme-v02.api.letsencrypt.org/directory
          email: infra.finland@qvantel.com
          privateKeySecretRef:
            name: qvantel-dot-solutions-private-key-letsencrypt
          solvers:
            - selector:
                dnsZones:
                  - "qvantel.solutions"
              dns01:
                route53:
                  region: eu-central-1
                  hostedZoneID: ZPXWBK7RK86EX
                  role: "arn:aws:iam::067412573140:role/Update-Qvantel-Solutions-DNS-From-Prod-Accounts"
  # -- List of ClusterIssuers to provision. See https://cert-manager.io/docs/concepts/issuer/ for `ClusterIssuer` resource details.
  clusterIssuers:
    # -- Example ClusterIssuer used for documentation
    example-cluster-issuer:
      # -- If ClusterIssuers is enabled and hence will be deployed to the cluster.
      enabled: false
      # -- Configure `spec` property of `ClusterIssuers` resource.
      spec: {}
  # -- List of Certificates to provision. See https://cert-manager.io/docs/usage/certificate/ for `Certificate` resource details.
  certificates:
    # -- This is the root CA certificate for Simple Qvantel CA
    qvantel-ca:
      enabled: true
      spec:
        isCA: true
        commonName: qvantel.com
        duration: 87660h # 10 years
        renewBefore: 360h # 15d
        subject:
          organizations:
            - "Qvantel Oy"
        secretName: qvantel-root-ca
        privateKey:
          algorithm: ECDSA
          size: 256
        issuerRef:
          name: qvantel-selfsigned-issuer
          kind: Issuer
          group: cert-manager.io
    # -- This is the wildcard certificate issued for *.qvantel.systems name
    qvantel-dot-systems-wildcard:
      enabled: false
      spec:
        secretName: qvantel-wildcard
        privateKey:
          rotationPolicy: Always
        dnsNames:
          - "*.qvantel.systems"
          - qvantel.systems
        issuerRef:
          name: qvantel-dot-systems
          kind: Issuer
          group: cert-manager.io
        renewBefore: 720h
    # -- This is the wildcard certificate issued for *.qvantel.solutions name
    qvantel-dot-solutions-wildcard:
      enabled: false
      spec:
        secretName: qvantel-wildcard
        privateKey:
          rotationPolicy: Always
        dnsNames:
          - "*.qvantel.solutions"
          - qvantel.solutions
        issuerRef:
          name: qvantel-dot-solutions
          kind: Issuer
          group: cert-manager.io
        renewBefore: 720h
