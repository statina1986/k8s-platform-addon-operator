//This sould be SemVer and it goes both to docker image and helm chart
VERSION = "1.2.0-prerelease"

// Type of CI job
TYPE = "generic"
 
// The version of the CI Type that will be used
CI_VERSION = "3"

BITBUCKET_PROJECT = "cp"

// Used to determine build types, if sending feedback, deploying automatically
DELIVERY_BRANCHES = ["master", "experimental"]

// Used to enable/disable CVE to fail on new Critical severitys
CVE_FAIL_BUILD_ON_NEW = false

// The Docker image used as execution environment (contains tools needed in path) 
EXECUTION_ENV_DOCKER = "artifactory.qvantel.net/jenkins-ci-default:2.4.0.20220203130426_master_a204d90"

// custom variables
K8S_PLATFORM_NAME = 'k8s-platform-addon-operator'
TOOLS_NAME = 'k8s-platform-tools'
DB_TOOLS_NAME = 'platform-db-tools'
CHART_NAME = 'k8s-platform-addon-operator'
ARTIFACTORY_URL = 'artifactory.qvantel.net'
PROJECT_NAME = 'baseline'
 
// Other configuration options on "jenkins" branch in pipeline.config file
node ('static-agent') {
 
@Library('jenkins-pipeline-loader@master') _
 
// Do not add anything here - use beforePipeline()
qPipeline jenkinsfile:this
}

def createPackage() {

  if (env.BRANCH_NAME in DELIVERY_BRANCHES) {
    
    sh "docker build --build-arg BUILD_TAG=${imageVersion()} -t ${imageTag(K8S_PLATFORM_NAME)} ."

    sh "docker build -t ${imageTag(TOOLS_NAME)} -t ${imageTagLatest(TOOLS_NAME)} ./platform-tools-images --file ./platform-tools-images/${TOOLS_NAME}.Dockerfile"

    sh "docker build -t ${imageTag(DB_TOOLS_NAME)} -t ${imageTagLatest(DB_TOOLS_NAME)} ./platform-tools-images --file ./platform-tools-images/${DB_TOOLS_NAME}.Dockerfile"

    sh "docker push ${imageTag(K8S_PLATFORM_NAME)}"

    sh "docker push ${imageTag(TOOLS_NAME)}"

    sh "docker push ${imageTagLatest(TOOLS_NAME)}"

    sh "docker push ${imageTag(DB_TOOLS_NAME)}"

    sh "docker push ${imageTagLatest(DB_TOOLS_NAME)}"

    pipelineBase.addCreatedImage(imageTag(K8S_PLATFORM_NAME))

    pipelineBase.addCreatedImage(imageTag(TOOLS_NAME))

    pipelineBase.addCreatedImage(imageTagLatest(TOOLS_NAME))

    pipelineBase.addCreatedImage(imageTag(DB_TOOLS_NAME))

    pipelineBase.addCreatedImage(imageTagLatest(DB_TOOLS_NAME))

    sh "helm package --version ${VERSION} --app-version ${imageVersion()} ./chart"

    withCredentials([usernamePassword(credentialsId: 'jenkins-artifactory', passwordVariable: 'ARTIFACTORY_PASSWORD', usernameVariable: 'ARTIFACTORY_USERNAME')]) {
      sh """      
        curl -sSf -u "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" \
        -X PUT \
        -T ${CHART_NAME}-${VERSION}.tgz \
        https://${ARTIFACTORY_URL}/artifactory/helm-packages/${CHART_NAME}/${chartName()}
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
  return "${ARTIFACTORY_URL}/${name}:${VERSION}"
}

def chartName() {
  return "${CHART_NAME}-${VERSION}.tgz"
}

