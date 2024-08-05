# certPlatformNamespace: cert-manager
certPlatform:
  cert-manager:
    image:
      registry: ${values['global']['containerRegistryBase']}
      repository: jetstack/cert-manager-controller
    cainjector:
      image:
        registry: ${values['global']['containerRegistryBase']}
        repository: jetstack/cert-manager-cainjector
    webhook:
      image:
        registry: ${values['global']['containerRegistryBase']}
        repository: jetstack/cert-manager-webhook
    startupapicheck:
      image:
        registry: ${values['global']['containerRegistryBase']}
        repository: jetstack/cert-manager-ctl
    acmesolver:
      image:
        registry: ${values['global']['containerRegistryBase']}
        repository: jetstack/cert-manager-acmesolver
    serviceAccount:
      create: false
      name: platform
    global:
      tolerations:
        - key: "dedicated-nodes"
          value: "platform-masters"
          operator: "Equal"
          effect: "NoSchedule"
      % if values['global']['platformMasters']:
      nodeSelector:
        dedicated-nodes: platform-masters
      % endif
  issuers: []
  clusterIssuers:
    # This issuer is used to generate self-signed certificate for Simple Qvantel CA
    qvantel-selfsigned-issuer:
      enabled: true
      spec:
        selfSigned: {}
    # This issuer is Simple Qvantel CA issuer
    qvantel-ca-issuer:
      enabled: true
      spec:
        ca:
          secretName: qvantel-root-ca
    # This issuer is used for *.qvantel.systems certificates issuing with letsencrypt
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
      # This issuer is used for *.qvantel.solutions certificates issuing with letsencrypt
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
  certificates:
    # This is the root CA certificate for Simple Qvantel CA
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
          kind: ClusterIssuer
          group: cert-manager.io
    # This is the wildcard certificate issued for *.qvantel.systems name
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
          kind: ClusterIssuer
          group: cert-manager.io
        renewBefore: 720h
    # This is the wildcard certificate issued for *.qvantel.solutions name
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
          kind: ClusterIssuer
          group: cert-manager.io
        renewBefore: 720h
