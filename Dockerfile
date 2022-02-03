FROM sashaozz/addon-operator-base:latest
RUN apk --update --no-cache add python3=3.10.2-r0 py3-pip
RUN pip3 install kubernetes
RUN pip3 install "hvac[parser]"
ADD common /common
ADD modules /modules
ENV PYTHONPATH=/