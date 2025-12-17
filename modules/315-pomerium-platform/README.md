# pomerium-platform module
<!-- BRIEF -->
This module is responsible for deployment of [Pomerium](https://www.pomerium.com/)

## Depends on modules:
- [cert-platform](/modules/110-cert-platform/README.md) which is needed to manage certificates

## Provides:
- Pomerium secure access proxy

## Design Considerations:
Pomerium Gateway is mainly used to protect HTTP endpoints which do not have built-in authentication and authorization (like Consul UI, Prometheus UI, etc).
Those are operational UIs which are not used continuously and do not have high load/traffic. Due to this we do not run Pomerium in HA fashion with persistent storage backend like postgresql or redis.
If some HTTP endpoint is critical part of BSS stack, it should properly implement Authentication and Authorization inside product itself.
Of course Pomerium HA configuration is totally possible, but it will be just a waste of resources at the moment.
