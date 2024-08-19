apiVersion: v2
name: redisPlatform
version: 0.0.1
dependencies:
  % for key in values['redisPlatform'].keys():
    % if values['redisPlatform'][key]:
  - name: redis
    alias: ${key}    
    version: 19.6.4
    repository: https://charts.bitnami.com/bitnami
    % endif  
  % endfor
  