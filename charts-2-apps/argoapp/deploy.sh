#!/bin/bash
ENV=$1
helm upgrade --install argoapp-${ENV} . -f values.yaml -f env-values-${ENV}.yaml -n argoapp