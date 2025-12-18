//This sould be SemVer and it goes both to docker image and helm chart
VERSION = "1.3.0-rc1"

// Type of CI job
TYPE = "generic"
 
// The version of the CI Type that will be used
CI_VERSION = "3"

BITBUCKET_PROJECT = "cp"
// Set long build timeout to give enough time to full images relocation
BUILD_TIMEOUT = 500

// Used to determine build types, if sending feedback, deploying automatically
DELIVERY_BRANCHES = ["master", "experimental"]

// Used to enable/disable CVE to fail on new Critical severitys
CVE_FAIL_BUILD_ON_NEW = false

// The Docker image used as execution environment (contains tools needed in path) 
EXECUTION_ENV_DOCKER = "artifactory.qvantel.net/jenkins-ci-default:2.4.0.20220203130426_master_a204d90"

// custom variables
K8S_PLATFORM_NAME = 'platform/k8s-platform-addon-operator'
CHART_NAME = 'k8s-platform-addon-operator'
ARTIFACTORY_URL = 'platform.artifactory.qvantel.net'
IMAGES_RELOCATE_URL = 'platform.artifactory.qvantel.net/k8s-platform-1-3-rc1'
PROJECT_NAME = 'baseline'
 
// Other configuration options on "jenkins" branch in pipeline.config file
node ('static-agent') {
 
@Library('jenkins-pipeline-loader@master') _
 
// Do not add anything here - use beforePipeline()
qPipeline jenkinsfile:this
}

def createPackage() {

  if (env.BRANCH_NAME in DELIVERY_BRANCHES) {

    // This will re-generate Images.lock file for the chart to ensure correct list of images
    sh "./generate-image-lock.sh"
    
    // This will push changed images to target (release specific) registry like 'platform.artifactory.qvantel.net/k8s-platform-1-3'
    sh "./push-images-after-build.sh $IMAGES_RELOCATE_URL"

    // This will relocate images in the chart Images.lock file to the target (release specific) registry like 'platform.artifactory.qvantel.net/k8s-platform-1-3'.
    // This way generated chart will contain correct list of images with release specific registry as the source.
    sh "./utils/dt --plain charts relocate chart $IMAGES_RELOCATE_URL"


    sh "docker buildx create --use"
    sh "docker buildx build --push --platform linux/arm64,linux/amd64 --build-arg='BUILD_TAG=${imageVersion()}' -t ${imageTag(K8S_PLATFORM_NAME)} ."

    sh "helm package --version ${VERSION} --app-version ${imageVersion()} ./chart"

    withCredentials([usernamePassword(credentialsId: 'jenkins-artifactory', passwordVariable: 'ARTIFACTORY_PASSWORD', usernameVariable: 'ARTIFACTORY_USERNAME')]) {
      sh """      
        curl -sSf -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" \
        -X PUT \
        -T ${CHART_NAME}-${VERSION}.tgz \
        https://artifactory.qvantel.net/artifactory/helm-packages/${CHART_NAME}/${chartName()}
      """
    }
  }
}

def shortCommit() {
  return env.GIT_COMMIT_SHA1[0..8]
}

def imageVersion() {
  return "${VERSION}_${currentBuild.number}_${env.BRANCH_NAME}_${shortCommit()}"
}

def imageTag(name) {
  return "${ARTIFACTORY_URL}/${name}:${imageVersion()}"
}

def imageTagLatest(name) {
  return "${ARTIFACTORY_URL}/${name}:latest"
}

def chartName() {
  return "${CHART_NAME}-${VERSION}.tgz"
}

