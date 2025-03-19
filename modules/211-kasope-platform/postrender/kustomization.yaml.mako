resources:
  - all.yaml
% if values['global']['clusterwideResources'] == "false":
patches:  
  - target:
      kind: ClusterRole
    patch: |
      $patch: delete
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRole
      metadata:
        name: DOES NOT MATTER
  - target:
      kind: ClusterRoleBinding
    patch: |
      $patch: delete
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRoleBinding
      metadata:
        name: DOES NOT MATTER
% endif

patches:
  - path: rolebinding-patch.yaml
    target:
      kind: RoleBinding
      name: ${values['global']['helmReleaseNamePrefix']}kasope-platform-cass-operator-leader