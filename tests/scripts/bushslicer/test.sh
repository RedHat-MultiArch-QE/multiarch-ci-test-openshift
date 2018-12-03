#!/bin/bash
. scripts/openshift_prerequisites.sh &&
. scripts/deploy_openshift_cluster.sh &&
. scripts/install_bushslicer.sh &&
. scripts/run_bushslicer.sh
