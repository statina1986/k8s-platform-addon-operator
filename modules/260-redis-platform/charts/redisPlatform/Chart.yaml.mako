apiVersion: v2
name: redisPlatform
version: 0.0.1
dependencies:
  % for key in values['redisPlatform'].keys():
    % if values['redisPlatform'][key]:
  - name: redis
    alias: ${key}    
    version: 23.1.7
    repository: https://charts.bitnami.com/bitnami
    % endif  
  % endfor
  