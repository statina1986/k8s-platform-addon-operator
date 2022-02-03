//This sould be SemVer and it goes both to docker image and helm chart
VERSION = "0.1.1"

// Type of CI job
TYPE = "generic"
 
// The version of the CI Type that will be used
CI_VERSION = "3"

BITBUCKET_PROJECT = "cp"

// Used to determine build types, if sending feedback, deploying automatically
DELIVERY_BRANCHES = ["master"]

// Used to enable/disable CVE to fail on new Critical severitys
CVE_FAIL_BUILD_ON_NEW = false

// The Docker image used as execution environment (contains tools needed in path) 
EXECUTION_ENV_DOCKER = "artifactory.qvantel.net/jenkins-ci-default:2.4.0.20220203130426_master_a204d90"

// custom variables
DOCKER_NAME = 'k8s-platform-addon-operator'
CHART_NAME = 'k8s-platform-addon-operator'
ARTIFACTORY_URL = 'artifactory.qvantel.net'
DOCKER_REPOSITORY = "${ARTIFACTORY_URL}/${DOCKER_NAME}"
PROJECT_NAME = 'baseline'
 
// Other configuration options on "jenkins" branch in pipeline.config file
node ('static-agent') {
 
@Library('jenkins-pipeline-loader@master') _
 
// Do not add anything here - use beforePipeline()
qPipeline jenkinsfile:this
}

def createPackage() {

  if (env.BRANCH_NAME in DELIVERY_BRANCHES) {
    sh """
      docker build \
        -t ${imageName()} \
        .
    """
    sh "docker push ${imageName()}"    
    pipelineBase.addCreatedImage(imageName())

    sh "helm package --version ${VERSION} --app-version ${imageVersion()} ./chart"

    withCredentials([usernamePassword(credentialsId: 'jenkins-artifactory', passwordVariable: 'ARTIFACTORY_PASSWORD', usernameVariable: 'ARTIFACTORY_USERNAME')]) {
      sh """      
        curl -sSf -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" \
        -X PUT \
        -T ${CHART_NAME}-${VERSION}.tgz \
        https://${ARTIFACTORY_URL}/artifactory/helm-packages/${CHART_NAME}/${chartName()})
      """
    }
  }
}

def shortCommit() {
  return env.GIT_COMMIT_SHA1[0..8]
}

def imageVersion() {
  return "${VERSION}.${currentBuild.number}_${env.BRANCH_NAME}_${shortCommit()}"
}

def imageName() {
  return "${DOCKER_REPOSITORY}:${imageVersion()}"
}

def chartName() {
  return "${CHART_NAME}-${VERSION}.tgz"
}

