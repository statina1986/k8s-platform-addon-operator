apiVersion: postgresql.cnpg.io/v1
kind: ImageCatalog
metadata:
  name: qvantel-base-cnpg-images
  namespace: ${values['global']['platformNamespace']}
spec:
  images:
    % if 'containerRegistryBase' in values['global']:
    - major: 15
      image: ${values['global']['containerRegistryBase']}/cloudnative-pg/q-cnpg-timescale:15.10-32_1.3.0_202512172101_master_2123be80
    - major: 16
      image: ${values['global']['containerRegistryBase']}/cloudnative-pg/q-cnpg-timescale:16.6-32_1.3.0_202512172101_master_2123be80
    - major: 17
      image: ${values['global']['containerRegistryBase']}/cloudnative-pg/q-cnpg-timescale:17.2-32_1.3.0_202512172101_master_2123be80
    - major: 18
      image: ${values['global']['containerRegistryBase']}/cloudnative-pg/q-cnpg-timescale:18.1-standard-trixie_1.3.0_202512172101_master_2123be80
    % else:    
    - major: 15
      image: platform.artifactory.qvantel.net/cloudnative-pg/q-cnpg-timescale:15.10-32_1.3.0_202512172101_master_2123be80
    - major: 16
      image: platform.artifactory.qvantel.net/cloudnative-pg/q-cnpg-timescale:16.6-32_1.3.0_202512172101_master_2123be80
    - major: 17
      image: platform.artifactory.qvantel.net/cloudnative-pg/q-cnpg-timescale:17.2-32_1.3.0_202512172101_master_2123be80
    - major: 18
      image: platform.artifactory.qvantel.net/cloudnative-pg/q-cnpg-timescale:18.1-standard-trixie_1.3.0_202512172101_master_2123be80
    % endif