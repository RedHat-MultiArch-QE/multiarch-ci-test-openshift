properties(
  [
    pipelineTriggers(
      [
        [
          $class: 'CIBuildTrigger',
          noSquash: true,
          providerData:
            [
            $class: 'ActiveMQSubscriberProviderData',
            name: 'Red Hat UMB',
            overrides: [topic: 'Consumer.rh-jenkins-ci-plugin.767d7fe8-67ec-4151-a8c0-59d8e1a16576.VirtualTopic.eng.brew.>'],
            selector: 'name = \'atomic-openshift\' AND type = \'Tag\' AND tag LIKE \'rhaos-%-rhel-%-candidate\'',
            timeout: null
          ]
        ]
      ]
    ),
    parameters(
      [
        [$class: 'ValidatingStringParameterDefinition',
         defaultValue: 'x86_64,ppc64le',
         description: 'A comma separated list of architectures to run the test on. Valid values include [x86_64, ppc64le, aarch64, s390x].',
         failedValidationMessage: 'Invalid architecture. Valid values are [x86_64, ppc64le, aarch64, s390x].',
         name: 'ARCHES',
         regex: '^(?:x86_64|ppc64le|aarch64|s390x)(?:,\\s*(?:x86_64|ppc64le|aarch64|s390x))*$'
        ],
        string(
          defaultValue: 'https://github.com/redhat-multiarch-qe/multiarch-ci-libraries',
          description: 'Repo for shared libraries.',
          name: 'LIBRARIES_REPO'
        ),
        string(
          defaultValue: 'v1.2.1',
          description: 'Git reference to the branch or tag of shared libraries.',
          name: 'LIBRARIES_REF'
        ),
        string(
          defaultValue: '',
          description: 'Repo for tests to run. If left blank, the current repo is assumed (*note* this default will only work for multibranch pipelines).',
          name: 'TEST_REPO'
        ),
        string(
          defaultValue: '',
          description: 'Git reference to the branch or tag of the tests repo.',
          name: 'TEST_REF'
        ),
        string(
          defaultValue: 'tests',
          description: 'Directory containing tests to run. Should at least one of the follow: an ansible-playbooks directory containing one or more test directories each of which having a playbook.yml, a scripts directory containing one or more test directories each of which having a run-test.sh',
          name: 'TEST_DIR'
        ),
        string(
          defaultValue: '',
          description: 'Contains the CI_MESSAGE for a message bus triggered build.',
          name: 'CI_MESSAGE'
        ),
        string(
          name: 'ORIGIN_REPO',
          description: 'Origin repo',
          defaultValue: 'https://github.com/openshift/origin.git'
        ),
        string(
          name: 'ORIGIN_BRANCH',
          description: 'Origin branch',
          defaultValue: 'master'
        ),
        string(
          name: 'OS_BUILD_ENV_IMAGE',
          description: 'openshift-release image',
          defaultValue: 'openshiftmultiarch/origin-release:golang-1.8'
        ),
        string(
          defaultValue: '',
          description: 'Build NVR for which to run the pipeline',
          name: 'BUILD_NVR'
        ),
        string(
          defaultValue: '',
          description: 'Build task ID for which to run the pipeline',
          name: 'TASK_ID'
        ),
        booleanParam(
          name: 'USE_CTR',
          defaultValue: true,
          description: 'Switch between using createTaskRepo plugin (default) or brew/koji method to retrieve packages of a build.'
        )
      ]
    )
  ]
)

library(
  changelog: false,
  identifier: "multiarch-ci-libraries@${params.LIBRARIES_REF}",
  retriever: modernSCM([$class: 'GitSCMSource',remote: "${params.LIBRARIES_REPO}"])
)

List arches = params.ARCHES.tokenize(',')
def errorMessages = ''
def config = MAQEAPI.v1.getProvisioningConfig(this)
config.mode = 'JNLP'

MAQEAPI.v1.runParallelMultiArchTest(
  this,
  arches,
  config,
  { host ->
    /*********************************************************/
    /* TEST BODY                                             */
    /* @param host               Provisioned host details.   */
    /*********************************************************/
    try {
      stage ("Install dependencies") {
        sh """
          sudo yum install -y yum-utils
          sudo yum-config-manager --add-repo http://download.devel.redhat.com/rel-eng/RCMTOOLS/rcm-tools-rhel-7-server.repo;
          sudo yum-config-manager --add-repo http://download-node-02.eng.bos.redhat.com/composes/nightly/EXTRAS-RHEL-7.5/latest-EXTRAS-7.5-RHEL-7/compose/Server/${host.arch}/os;
          sudo yum-config-manager --add-repo http://download-node-02.eng.bos.redhat.com/rel-eng/updates/RHEL-7.5/latest-RHEL-7/compose/Server/${host.arch}/os/;
          sudo yum-config-manager --add-repo http://download-node-02.eng.bos.redhat.com/nightly/EXTRAS-RHEL-7.5/latest-EXTRAS-7.5-RHEL-7/compose/Server/${host.arch}/os/;
          sudo yum-config-manager --add-repo http://download-node-02.eng.bos.redhat.com/rel-eng/updates/RHEL-7.5/latest-RHEL-7/compose/Server-optional/${host.arch}/os/;
          sudo yum-config-manager --add-repo http://download-node-02.eng.bos.redhat.com/rcm-guest/puddles/OpenStack/12.0-RHEL-7/latest/RH7-RHOS-12.0/${host.arch}/os/;
          sudo rpm --import http://download.eng.bos.redhat.com/composes/nightly/EXTRAS-RHEL-7.5/latest-EXTRAS-7.5-RHEL-7/compose/Server/${host.arch}/os/RPM-GPG-KEY-redhat-beta;
          sudo rpm --import http://download.eng.bos.redhat.com/composes/nightly/EXTRAS-RHEL-7.5/latest-EXTRAS-7.5-RHEL-7/compose/Server/${host.arch}/os/RPM-GPG-KEY-redhat-release;
          sudo yum install -y bc git make golang docker jq bind-utils koji brewkoji openvswitch;
          echo "[registries.search]" | sudo tee /etc/containers/registries.conf >/dev/null;
          echo "registries = ['registry.access.redhat.com']" | sudo tee --append /etc/containers/registries.conf >/dev/null;
          echo "" | sudo tee --append /etc/containers/registries.conf >/dev/null;
          echo "[registries.insecure]" | sudo tee --append /etc/containers/registries.conf >/dev/null;
          echo "registries = ['172.30.0.0/16']" | sudo tee --append /etc/containers/registries.conf >/dev/null;
          echo "" | sudo tee --append /etc/containers/registries.conf >/dev/null;
          echo "[registries.block]" | sudo tee --append /etc/containers/registries.conf >/dev/null;
          echo "registries = []" | sudo tee --append /etc/containers/registries.conf >/dev/null;
          sudo rm -rf /var/lib/docker;
          echo 'STORAGE_DRIVER=overlay2' | sudo tee /etc/sysconfig/docker-storage-setup > /dev/null;
          sudo systemctl enable docker;
          sudo systemctl start docker;
          sudo docker info
          env | sort
        """
        if (params.USE_CTR) {
          if (params.CI_MESSAGE != '') {
            tid = getTaskId(params.CI_MESSAGE)
            createTaskRepo taskIds: tid
          } else if (params.BUILD_NVR != '') {
            try {
              tid = sh (
                script: """brew buildinfo ${params.BUILD_NVR} | grep Task | cut -f2 -d' '""",
                returnStdout: true
              ).trim()
              createTaskRepo taskIds: tid
            } catch (exc) {
              println "No brew build info found for NVR ${params.BUILD_NVR}."
            }
          } else if (params.TASK_ID != '') {
            createTaskRepo taskIds: params.TASK_ID
          }
          try {
            sh """
              cat task-repo.properties
              URL=\$(cat task-repo.properties | grep TASK_REPO_URLS= | sed 's/TASK_REPO_URLS=//' | sed 's/;/\\n/g' | grep ${host.arch})
              sudo yum-config-manager --add-repo \${URL}
              REPO=\$(sudo yum repolist | grep atomic-openshift | cut -f1 -d" ")
              PKGS=\$(sudo yum --disablerepo="*" --enablerepo="\${REPO}" list available | grep atomic | cut -f1 -d" " | paste -sd " " -)
              sudo yum --nogpgcheck install -y \$(echo \${PKGS})
            """
          } catch (exc) {
            println "Failed to download and install brew build packages."
          }
        } else {
          if (params.BUILD_NVR != '') {
            try {
              sh """
                #!/bin/sh -e
                RPMS=\$(brew buildinfo ${params.BUILD_NVR} | grep ${host.arch} | cut -d '/' -f10);
                for p in \${RPMS}; do echo \${p}; brew download-build --rpm \${p} >/dev/null; done;
                ls *.rpm;
                sudo yum --nogpgcheck localinstall -y *.rpm;
              """
            } catch (exc) {
              println "No brew build packages found for NVR ${params.BUILD_NVR}."
            }
          } else if (params.TASK_ID != '') {
            try {
              sh """
                #!/bin/sh -e
                NVR=\$(brew taskinfo ${params.TASK_ID} | grep "Build:" | cut -d" " -f2);
                RPMS=\$(brew buildinfo \${NVR} | grep ${host.arch} | cut -d '/' -f10);
                for p in \${RPMS}; do echo \${p}; brew download-build --rpm \${p} >/dev/null; done;
                ls *.rpm;
                sudo yum --nogpgcheck localinstall -y *.rpm;
              """
            } catch (exc) {
              println "No brew build packages found for TASK_ID ${params.TASK_ID}."
            }
          }
        }
      }
      stage ("Start Cluster") {
        withCredentials([file(credentialsId: 'redhat-multiarch-qe-registrycrt', variable: 'REGISTRY_CRT')]) {
          sh """
            sudo mkdir -p /etc/docker/certs.d/kernelci-06.khw.lab.eng.bos.redhat.com
            sudo cp ${REGISTRY_CRT} /etc/docker/certs.d/kernelci-06.khw.lab.eng.bos.redhat.com/
            sudo oc cluster up --image='kernelci-06.khw.lab.eng.bos.redhat.com/multi-arch/ppc64le-openshift3-ose-\${component}:\${version}' --enable=-web-console
            sudo oc version
          """
        }
      }

      def failed_stages = []
      try {
        stage ("End to End Tests") {
          sh """
            mkdir _out
            sudo KUBECONFIG=/var/lib/jenkins/workspace/multiarch-qe/multiarch-ci-test-openshift/openshift.local.clusterup/kube-apiserver/admin.kubeconfig TEST_REPORT_DIR=./_out /usr/libexec/atomic-openshift/extended.test --ginkgo.v=true --ginkgo.focus="k8s" --ginkgo.skip="Spark|Cassandra|Redis|Downward API|Storm|RethinkDB|Hazelcast|should support subPath|Secret"
          """
        }
      } catch (e) {
        failed_stages+='End to End Tests'
        currentBuild.result = 'UNSTABLE'
      }
    } catch (e) {
      println(e)
    } finally {
      stage ('Archive Test Output') {
        archiveArtifacts '_out/*'
        junit '_out/*.xml'
      }
    }

    /*****************************************************************/
    /* END TEST BODY                                                 */
    /* Do not edit beyond this point                                 */
    /*****************************************************************/
  },
  { Exception exception, def host ->
    def error = "Exception ${exception} occured on ${host.arch}\n"
    errorMessages += error
    if (host.arch.equals("x86_64") || host.arch.equals("ppc64le")) {
      currentBuild.result = 'FAILURE'
    }
  },
  {
    echo(errorMessages)
  }
)
