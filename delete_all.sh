#!/bin/bash
alias ku="kubectl"


for ns in istio-system kube-node-lease kube-system kube-public; do \
    ku delete svc --all --namespace=$ns
    ku delete deployment --all --namespace=$ns
    ku delete job --all --namespace=$ns
    ku delete pod --all --namespace=$ns
