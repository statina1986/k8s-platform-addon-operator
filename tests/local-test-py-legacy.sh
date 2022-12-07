#!/usr/bin/env bash

export BINDING_CONTEXT_PATH=$2
PYTHONPATH=./ \
VAULT_SECRET_NAME=vault-dev-keys \
VAULT_SECRET_NAMESPACE=platform \
VAULT_SECRET_ROOT_TOKEN=vault-dev-root-token $1 $2