# Release 1.3 migration guide

## Kafka 

In this version migration to NodePools and KRaft should be performed.

TODO: describe migration to nodepools and KRaft, e.g.

For deployments which already have kafka in Zookeeper mode:
1. Prepare you config files assuming broker nodepools (e.g. copy all storage configs properly to broker nodepool section)
2. Deploy new configuration (will we have rolling restart here?)
3. Migrate to KRadt manually by annotating something
4. Prepare configuration for migrated Kafka (add annotations, enable controllers nodepool, what else?)
5. Deploy to have a final state aligned

For new Kafka deployments:
1. Configure clusters with KRaft from the beginning. 

