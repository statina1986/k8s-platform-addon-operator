FROM artifactory.qvantel.net/qvantel-addon-operator:1.0.2.5_qvantel-master_5ab130fef
RUN apk --update --no-cache add python3 py3-pip curl aws-cli py3-mysqlclient py3-psycopg2
RUN pip3 install kubernetes
RUN pip3 install "hvac[parser]"
RUN pip3 install boto3
RUN pip3 install python-json-logger
ADD common /common
ADD modules /modules
ADD global-hooks /global-hooks
ADD resources /resources
ENV PYTHONPATH=/
