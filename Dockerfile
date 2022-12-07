FROM artifactory.qvantel.net/qvantel-addon-operator:1.0.0.2_master_9f15486ba
RUN apk --update --no-cache add python3 py3-pip curl aws-cli py3-mysqlclient
RUN pip3 install kubernetes
RUN pip3 install "hvac[parser]"
RUN pip3 install boto3
RUN pip3 install psycopg[binary]
ADD common /common
ADD modules /modules
ENV PYTHONPATH=/
