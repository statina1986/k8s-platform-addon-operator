from kubernetes import client
from kubernetes.stream import stream
import base64


def exec_vault_command(v1: client.CoreV1Api, command):
    secret = v1.read_namespaced_secret("vault-dev-keys", "platform").data
    token = base64.b64decode(secret["vault-dev-root-token"]).decode('utf-8')

    exec_command = [
        '/bin/sh',
        '-c',
        'vault login -no-print ' + token + ' && ',
        command]
    resp = stream(v1.connect_get_namespaced_pod_exec,
                  'vault-0',
                  'platform',
                  command=exec_command,
                  stderr=True, stdin=False,
                  stdout=True, tty=False)
    print("Vault Result: " + resp)
