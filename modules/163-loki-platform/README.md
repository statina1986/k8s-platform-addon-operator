# Deployment Models

Loki deployment can be done in High Availability mode or in a single node mode, which creates a single instance of Loki using local filesystem. Loki module is configured, with premade configurations so the deployment can be easily deployed using either way. 

globalConfig.configurationProfile values explained below:
* dev
    * Single Node deployment
    * Replica Factor 1
    * Local filesystem
* test
    * HA mode
    * Replica Factor 3
    * S3
* perf, prod
    * Similar to test, but with dedicated platform-masters nodes


The forementioned replica factor copies the log data in to multiple copies protecting against hardware failures.

# Retention setup

Retention period is by default 31 days, which is defined by retention_period, but we have configured our Loki in such a manner that DEBUG and TRACE logs are going to be stored only for 2 days. Configuration example found below:
```markdown
limits_config:
  retention_period: 744h # 31 days
    retention_stream:
      - selector: '{log_level="DEBUG"}' # keep DEBUG logs only for 2 days
        priority: 1
        period: 48h
      - selector: '{log_level="TRACE"}' # keep TRACE logs only for 2 days
        priority: 1
        period: 48h
```

