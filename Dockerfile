FROM flant/addon-operator:latest
RUN apk --update --no-cache add python3=3.10.1-r0
RUN apk --no-cache add py3-pip
RUN pip3 install kubernetes
RUN pip3 install "hvac[parser]"
ADD common /common
ADD modules /modules
ENV PYTHONPATH=/