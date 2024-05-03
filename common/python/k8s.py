import datetime
import http
import logging
from os import environ
from kubernetes import client, config
from kubernetes.client.rest import ApiException
from common.python.logger import logger

k8s = None
k8s_crd = None
k8s_apps = None


def get_k8s_crd_client():
    global k8s_crd
    if k8s_crd is None:
        if environ.get("INSIDE_CLUSTER", "false") == "true":
            config.load_incluster_config()
        else:
            config.load_kube_config()
        k8s_crd = client.CustomObjectsApi()
    return k8s_crd


def get_k8s_client():
    global k8s
    if k8s is None:
        if environ.get("INSIDE_CLUSTER", "false") == "true":
            config.load_incluster_config()
        else:
            config.load_kube_config()
        k8s = client.CoreV1Api()
    return k8s


def get_k8s_apps_client():
    global k8s_apps
    if k8s_apps is None:
        if environ.get("INSIDE_CLUSTER", "false") == "true":
            config.load_incluster_config()
        else:
            config.load_kube_config()
        k8s_apps = client.AppsV1Api()
    return k8s_apps


def get_config_map(namespace, name):
    k8s = get_k8s_client()
    response = k8s.read_namespaced_config_map(name, namespace, pretty=False)
    return response


def get_or_create_crd(group, version, namespace, plural, name, init):
    k8s_crd = get_k8s_crd_client()
    try:
        response = k8s_crd.get_namespaced_custom_object(
            group=group, version=version, name=name, namespace=namespace, plural=plural
        )
        return response
    except ApiException as e:
        if e.status == http.client.NOT_FOUND:
            response = k8s_crd.create_namespaced_custom_object(
                group=group,
                version=version,
                namespace=namespace,
                plural=plural,
                body=init,
            )
            return response
        else:
            raise


def update_crd(group, version, namespace, plural, name, update):
    k8s_crd = get_k8s_crd_client()
    response = k8s_crd.get_namespaced_custom_object(
        group=group, version=version, name=name, namespace=namespace, plural=plural
    )

    patch = update(response)

    k8s_crd.patch_namespaced_custom_object(
        group=group,
        version=version,
        name=name,
        namespace=namespace,
        plural=plural,
        body=patch,
    )


def update_crd_status(group, version, namespace, plural, name, update):
    k8s_crd = get_k8s_crd_client()
    response = k8s_crd.get_namespaced_custom_object_status(
        group=group, version=version, name=name, namespace=namespace, plural=plural
    )

    response = update(response)

    patch = {"status": response["status"]}

    k8s_crd.patch_namespaced_custom_object_status(
        group=group,
        version=version,
        name=name,
        namespace=namespace,
        plural=plural,
        body=patch,
    )


def updateCrdStatusCondition(response, type, status, reason, message=""):
    if "status" in response:
        if "conditions" in response["status"]:
            pass
        else:
            response["status"]["conditions"] = []
    else:
        response["status"] = {"conditions": []}
    conditions = response["status"]["conditions"]
    for idx, item in enumerate(conditions):
        if item["type"] == type:
            conditions.pop(idx)
            break
    conditions.append(
        {
            "lastTransitionTime": datetime.datetime.utcnow().astimezone().isoformat(),
            "status": status,
            "type": type,
            "reason": reason,
            "message": message,
        }
    )
    return response
