FROM platform.artifactory.qvantel.net/platform/qvantel-addon-operator:1.0.4.10_qvantel-master_be55cad85
RUN apk --update --no-cache add python3 py3-pip curl aws-cli py3-mysqlclient py3-psycopg2
RUN pip3 install kubernetes
RUN pip3 install "hvac[parser]"
RUN pip3 install boto3
RUN pip3 install python-json-logger
RUN pip3 install pyyaml
RUN pip3 install mako
RUN pip3 install py-consul

ENV PYTHONPATH=/
ARG BUILD_TAG=latest
ENV BUILD_TAG=${BUILD_TAG}

RUN mkdir /var/run/addon-operator
RUN chown -R 1001:0 /var/run/addon-operator

USER 1001

ADD --chown=1001:0 common /common
ADD --chown=1001:0 global-hooks /global-hooks
ADD --chown=1001:0 resources /resources
ADD --chown=1001:0 modules /modules


