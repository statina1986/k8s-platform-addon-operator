FROM artifactory.qvantel.net/qvantel-addon-operator:1.0.3.6_qvantel-master_b01c52af2
RUN apk --update --no-cache add python3 py3-pip curl aws-cli py3-mysqlclient py3-psycopg2
RUN pip3 install kubernetes
RUN pip3 install "hvac[parser]"
RUN pip3 install boto3
RUN pip3 install python-json-logger
RUN pip3 install pyyaml
RUN pip3 install mako
ADD common /common
ADD modules /modules
ADD global-hooks /global-hooks
ADD resources /resources
ENV PYTHONPATH=/
