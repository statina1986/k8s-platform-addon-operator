FROM artifactory.qvantel.net/qvantel-addon-operator:1.0.0.1_master_9371124fc
RUN apk --update --no-cache add python3=3.10.3-r1 py3-pip curl
RUN pip3 install kubernetes
RUN pip3 install "hvac[parser]"
ADD common /common
ADD modules /modules
ENV PYTHONPATH=/