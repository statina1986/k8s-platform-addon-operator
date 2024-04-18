apiVersion: v2
name: cnpgPostgresPlatform
version: 0.0.1
dependencies:
  - name: cloudnative-pg
    version: 0.20.2
    repository: https://cloudnative-pg.github.io/charts
  % for key in values['cnpgPostgresPlatform'].keys():
    % if key.startswith("cluster-") and values['cnpgPostgresPlatform'][key]['enabled']:
  - name: cluster
    alias: ${key}    
    version: 0.0.7
    repository: https://cloudnative-pg.github.io/charts
    % endif  
  % endfor