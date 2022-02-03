---
title: "Aurora Mysql DB module"
---
**Aurora Mysql DB** module is respondisle for exposing of preprovisioned AWS Aurora DB in the Platform, i.e.
- Configure needed Vault stuff (db plugin, secret engine, etc);
- Expose DB as k8s Service in Platfrom

Depends on:
- Vault

Expects:
- *aurora-mysql-db-admin* (username, password) secret with Aurora DB credentials exist in the platform namespace 