apiVersion: v2
name: redisPlatform
version: 0.0.1
dependencies:
#  - name: redis
#    version: 17.3.17
#    repository: https://charts.bitnami.com/bitnami
  % for key in values['redisPlatform'].keys():
    % if values['redisPlatform'][key]:
  - name: redis
    alias: ${key}    
    version: 18.1.2
    repository: https://artifactory.qvantel.net/artifactory/helm-platform/
    % endif  
  % endfor
  