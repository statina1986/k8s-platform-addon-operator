upgrade procedure:

eck-operator to 3.1.0

add to configuration:

  elasticsearchPlatform:
    eck-operator:
      image:
        repository: docker.elastic.co/eck/eck-operator
        tag: 3.1.0
      nameOverride: "elastic-operator"
      fullnameOverride: "elastic-operator"

elasticsearch version upgrade to 7.17.29

          image: >-
            docker.elastic.co/elasticsearch/elasticsearch:7.17.29
  version: 7.17.29

to kind: Elasticsearch resource (elasticsearch logsearch in this case)

Do the same to kibana

Then check upgrade assistant in Kibana if anything is required, likely only warnings which do not stop from upgrading to 8.x

Then same edits but from 7.17.29 to 8.19.5

Now upgrade assistant shows that system index migration and reindexing is required

then finally 8.19.5 to 9.1.5 for kibana and elasticsearch

(maybe 7.17.29)

plan:
eck-operator to 3.1.0
default to 7.17.29 but also mako template upgrading to 8.19.5 and 9.1.5