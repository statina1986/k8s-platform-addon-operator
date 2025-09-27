FROM platform.artifactory.qvantel.net/platform/qvantel-addon-operator:1.0.7.17_qvantel-master_abc243f6a

ARG TARGETARCH

ENV PIP_BREAK_SYSTEM_PACKAGES=1

RUN apk --update --no-cache add python3 py3-pip curl aws-cli py3-mysqlclient py3-psycopg2 py3-kubernetes
RUN pip3 install "hvac[parser]"
RUN pip3 install boto3
RUN pip3 install python-json-logger
RUN pip3 install pyyaml
RUN pip3 install mako
RUN pip3 install py-consul
RUN pip3 install cassandra-driver

RUN curl -fvSL -o /usr/bin/yq https://github.com/mikefarah/yq/releases/download/v4.44.2/yq_linux_${TARGETARCH} && \    
    chmod +x /usr/bin/yq

RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash 
RUN mv kustomize /usr/bin/kustomize

ENV PYTHONPATH=/
ARG BUILD_TAG=latest
ENV BUILD_TAG=${BUILD_TAG}

RUN mkdir /var/run/addon-operator
RUN chown -R 1001:0 /var/run/addon-operator

ADD --chown=1001:0 common /common
RUN chmod -R 775 /common

ADD --chown=1001:0 resources /resources
RUN chmod -R 775 /resources

ADD --chown=1001:0 global-hooks /global-hooks
RUN chmod -R 775 /global-hooks 

ADD --chown=1001:0 modules /modules
RUN chmod -R 775 /modules
