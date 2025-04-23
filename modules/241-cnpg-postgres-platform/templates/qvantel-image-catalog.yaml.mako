apiVersion: postgresql.cnpg.io/v1
kind: ImageCatalog
metadata:
  name: qvantel-base-cnpg-images
  namespace: ${values['global']['platformNamespace']}
spec:
  images:
    % if 'containerRegistryBase' in values['global']:
    - major: 13
      image: ${values['global']['containerRegistryBase']}/cloudnative-pg/q-cnpg-timescale:13.18-33_1.2.1_202503141111_master_facc7d5c
    - major: 15
      image: ${values['global']['containerRegistryBase']}/cloudnative-pg/q-cnpg-timescale:15.10-32_1.2.1_202503141111_master_facc7d5c
    - major: 16
      image: ${values['global']['containerRegistryBase']}/cloudnative-pg/q-cnpg-timescale:16.6-32_1.2.1_202503141111_master_facc7d5c
    - major: 17
      image: ${values['global']['containerRegistryBase']}/cloudnative-pg/q-cnpg-timescale:17.2-32_1.2.1_202503141111_master_facc7d5c
    % else:
    - major: 13
      image: platform.artifactory.qvantel.net/cloudnative-pg/q-cnpg-timescale:13.18-33_1.2.1_202503141111_master_facc7d5c
    - major: 15
      image: platform.artifactory.qvantel.net/cloudnative-pg/q-cnpg-timescale:15.10-32_1.2.1_202503141111_master_facc7d5c
    - major: 16
      image: platform.artifactory.qvantel.net/cloudnative-pg/q-cnpg-timescale:16.6-32_1.2.1_202503141111_master_facc7d5c
    - major: 17
      image: platform.artifactory.qvantel.net/cloudnative-pg/q-cnpg-timescale:17.2-32_1.2.1_202503141111_master_facc7d5c
    % endif