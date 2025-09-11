#!/usr/bin/env bash

source "${0%/*}/../../../common/shell/functions.sh"
source "${0%/*}/../../../common/shell/variables.sh"

ISTIO_MIN_BASE_VERSION="${ISTIO_MIN_BASE_VERSION:-1.24.0}" ## 1.24 is the first to have the new templated CRDs, ref: https://istio.io/latest/news/releases/1.24.x/announcing-1.24/upgrade-notes/#istio-crds-are-templated-by-default-and-can-be-installed-and-upgraded-via-helm-install-istio-base

hook::config() {
  ## We must run this before any CRDs are applied
  echo '{"configVersion":"v1", "onStartup": 1}'
}

hook::trigger() {
  qlog "Checking Istio CRDs for helm.sh/chart >= base-${ISTIO_MIN_BASE_VERSION}"

  # Collect CRDs with chart=istio or app.kubernetes.io/part-of=istio
  mapfile -t CRDS < <(
    {
      kubectl get crds -l chart=istio -o name 2>/dev/null || true
      kubectl get crds -l app.kubernetes.io/part-of=istio -o name 2>/dev/null || true
    } | sort -u
  )


  if [[ ${#CRDS[@]} -eq 0 ]]; then
    qlog "No Istio CRDs found. Nothing to do."
    return 0
  else
    qlog "Found ${#CRDS[@]} Istio CRD(s):"
    printf '  - %s\n' "${CRDS[@]}"
  fi

  # Extract helm.sh/chart labels from already gathered CRDs
  mapfile -t BASE_LABELS < <(
    if [[ ${#CRDS[@]} -gt 0 ]]; then
      kubectl get "${CRDS[@]}" -o json \
        | jq -r '.items[] | .metadata.labels["helm.sh/chart"]? // empty' \
        | grep '^base-' || true
    fi
  )

  if [[ ${#BASE_LABELS[@]} -gt 0 ]]; then
    # Get the highest version using sort -V
    max_version=$(printf '%s\n' "${BASE_LABELS[@]}" | sed 's/^base-//' | sort -V | tail -n1)
    if [[ "$(printf '%s\n%s\n' "$ISTIO_MIN_BASE_VERSION" "$max_version" | sort -V | head -n1)" == "$ISTIO_MIN_BASE_VERSION" ]]; then
      qlog "Found base-${max_version} (>= ${ISTIO_MIN_BASE_VERSION}) -> skipping hook"
      return 0
    else
      qlog "Found base-${max_version} (< ${ISTIO_MIN_BASE_VERSION}) -> running hook"
    fi
  fi

  qlog "Labeling legacy Istio CRDs"
  kubectl label "${CRDS[@]}" "app.kubernetes.io/managed-by=Helm"
  qlog "Annotating legacy Istio CRDs"
  kubectl annotate "${CRDS[@]}" \
    "meta.helm.sh/release-name=${ISTIO_RELEASE_NAME}" \
    "meta.helm.sh/release-namespace=${ISTIO_RELEASE_NAMESPACE}"

  qlog "Istio CRDs successfully prepared for Helm adoption"
}

common::run_hook "$@"

