resources:
  - all.yaml

patches:
  - path: rolebinding-patch.yaml
    target:
      kind: RoleBinding
      name: ${values['global']['helmReleaseNamePrefix']}kasope-platform-cass-operator-leader
% if values['global']['clusterwideResources'] == "false":
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