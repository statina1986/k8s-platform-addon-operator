FROM platform.artifactory.qvantel.net/platform/qvantel-addon-operator:1.0.5.14_qvantel-master_92ab5f6e5

ARG TARGETARCH

RUN apk --update --no-cache add python3 py3-pip curl aws-cli py3-mysqlclient py3-psycopg2
RUN pip3 install kubernetes
RUN pip3 install "hvac[parser]"
RUN pip3 install boto3
RUN pip3 install python-json-logger
RUN pip3 install pyyaml
RUN pip3 install mako
RUN pip3 install py-consul

RUN curl -fvSL -o /usr/bin/yq https://github.com/mikefarah/yq/releases/download/v4.44.2/yq_linux_${TARGETARCH} && \    
    chmod +x /usr/bin/yq

RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash 
RUN mv kustomize /usr/bin/kustomize

ENV PYTHONPATH=/
ARG BUILD_TAG=latest
ENV BUILD_TAG=${BUILD_TAG}

RUN mkdir /var/run/addon-operator
RUN chown -R 1001:0 /var/run/addon-operator

USER 1001

ADD --chown=1001:0 resources /resources
ADD --chown=1001:0 common /common
RUN chmod -R 775 /common /common
ADD --chown=1001:0 global-hooks /global-hooks
RUN chmod -R 775 global-hooks /global-hooks
ADD --chown=1001:0 modules /modules
RUN chmod -R 775 modules /modules
