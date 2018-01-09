properties(
  [
    pipelineTriggers(
      [
        [
          $class: 'CIBuildTrigger',
          checks: [],
          overrides: [topic: "Consumer.rh-jenkins-ci-plugin.cc2a6550-87f8-4030-8454-e221e27c48f7.VirtualTopic.qe.ci.>"],
          providerName: 'Red Hat UMB',
          selector: 'name = \'atomic-openshift\' AND CI_TYPE = \'brew-tag\' AND tag LIKE \'rhaos-%-rhel-%-newarches-candidate\''
        ]
      ]
    ),
    parameters(
      [
        string(
          defaultValue: 'x86_64,ppc64le',
          description: 'A comma separated list of architectures to run the test on. Valid values include [x86_64, ppc64le, aarch64, s390x].',
          name: 'ARCHES'
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
        )
      ]
    )
  ]
)

@Library('multiarch-ci-libraries') _

import com.redhat.multiarch.ci.Slave

def List arches = params.ARCHES.tokenize(',')
def Boolean runOnProvisionedHosts = true;
def Boolean installAnsible = true;

parallelMultiArchTest(
  arches,
  runOnProvisionedHosts,
  installAnsible,
  { Slave slave ->
    /******************************************************************/
    /* TEST BODY                                                      */
    /* @param provisionedSlave    Name of the provisioned host.       */
    /* @param arch                Architeture of the provisioned host */
    /******************************************************************/

    try {
      stage ("Install dependencies") {
        sh """
        sudo yum-config-manager --add-repo https://download.fedoraproject.org/pub/epel/7/${arch};
        sudo yum-config-manager --add-repo http://download-node-02.eng.bos.redhat.com/composes/nightly/EXTRAS-RHEL-7.4/latest-EXTRAS-7-RHEL-7/compose/Server/${arch}/os;
        sudo rpm --import http://download.eng.bos.redhat.com/composes/nightly/EXTRAS-RHEL-7.4/latest-EXTRAS-7-RHEL-7/compose/Server/${arch}/os/RPM-GPG-KEY-redhat-beta;
        sudo rpm --import http://download.eng.bos.redhat.com/composes/nightly/EXTRAS-RHEL-7.4/latest-EXTRAS-7-RHEL-7/compose/Server/${arch}/os/RPM-GPG-KEY-redhat-release;
        sudo rpm --import https://getfedora.org/static/352C64E5.txt;
        sudo yum install -y bc git make golang docker jq bind-utils;
        echo 'insecure_registries:' | sudo tee --append /etc/containers/registries.conf > /dev/null;
        echo '  - 172.30.0.0/16' | sudo tee --append /etc/containers/registries.conf > /dev/null;
        sudo systemctl enable docker
        """
      }

      def gopath = "${pwd(tmp: true)}/go"
      def failed_stages = []
      withEnv(["GOPATH=${gopath}", "PATH=${PATH}:${gopath}/bin"]) {
        stage('Prep') {
          sh 'git config --global user.email "jpoulin@redhat.com" && git config --global user.name "Jeremy Poulin"'
          git(url: params.ORIGIN_REPO, branch: params.ORIGIN_BRANCH)
          sh '''
          #!/bin/bash -xeu
          git remote add detiber https://github.com/detiber/origin.git || true
          git fetch detiber
          git merge detiber/multiarch
          '''
        }
        try {
          stage('Pre-release Tests') {
            sh '''
            #!/bin/bash -xeu
            hack/env JUNIT_REPORT=true DETECT_RACES=false TIMEOUT=300s make check -k
            '''
          }
        } catch (exc) {
          failed_stages+='Pre-release Tests'
          currentBuild.result = 'UNSTABLE'
        }
        stage('Locally build release') {
          try {
            sh '''
            #!/bin/bash -xeu
            hack/env hack/build-base-images.sh
            hack/env JUNIT_REPORT=true make release
            '''
          } catch (e) {
            currentBuild.result = 'FAILURE'
            throw e
          }
        }
        try {
          stage('Integration Tests') {
            sh '''
            #!/bin/bash -xeu
            hack/env JUNIT_REPORT='true' make test-tools test-integration
            '''
          }
        } catch (e) {
          failed_stages+='Integration Tests'
          currentBuild.result = 'UNSTABLE'
        }
        try {
          stage('End to End tests') {
            sh '''
            #!/bin/bash -xeu
            arch=$(go env GOHOSTARCH)
            OS_BUILD_ENV_PRESERVE=_output/local/bin/linux/${arch}/end-to-end.test hack/env make build-router-e2e-test
            OS_BUILD_ENV_PRESERVE=_output/local/bin/linux/${arch}/etcdhelper hack/env make build WHAT=tools/etcdhelper
            OPENSHIFT_SKIP_BUILD='true' JUNIT_REPORT='true' make test-end-to-end -o build
            '''
          }
        } catch (e) {
          failed_stages+='End to End Tests'
          currentBuild.result = 'UNSTABLE'
        }
      }
    } catch (e) {
      echo e
    } finally {
      stage ('Archive Test Output') {
        archiveArtifacts '_output/scripts/**/*'
        junit '_output/scripts/**/*.xml'
      }
    }

    /*****************************************************************/
    /* END TEST BODY                                                 */
    /* Do not edit beyond this point                                 */
    /*****************************************************************/
  },
  { exception, arch ->
    echo "Exception ${exception} occured on ${arch}"
    if (arch.equals("x86_64") || arch.equals("ppc64le")) {
      currentBuild.result = 'FAILURE'
    }
  }
}
