Module ships with 7.17.29

Version can be set with 

```
  elasticsearchPlatform:
    coreStackVersion: 8.19.5
```

Upgrade to 8.19.5 should be relatively painless.

Upgrade to 9.1.5 when initial indices are from 7.x or older is less trivial, upgrade assistant is highly recommended - even in local environment with no data system index migration and reindexing is required.