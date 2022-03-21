FROM alpine:latest
RUN apk --update --no-cache add bash curl jq

RUN wget https://storage.googleapis.com/kubernetes-release/release/v1.19.11/bin/linux/amd64/kubectl -O /bin/kubectl && \
    chmod +x /bin/kubectl && \
    helmArch="linux-amd64" && \
    wget https://get.helm.sh/helm-v3.4.1-${helmArch}.tar.gz -O /helm.tgz && \
    tar -z -x -C /bin -f /helm.tgz --strip-components=1 ${helmArch}/helm && \
rm -f /helm.tgz

CMD ["/bin/sh"]