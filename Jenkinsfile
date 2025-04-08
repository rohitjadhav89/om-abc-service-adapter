parameters {
    string(name: 'GITHUB_BRANCH', defaultValue: 'branch', description: 'Enter the branch name')
    booleanParam(name: 'RELEASE_VERSION', defaultValue: false, description: 'Check this box to create release image.(Suffix will be removed from tag. e.g. -SNAPSHOT)')
    booleanParam(name: 'TRIVY_SCAN', defaultValue: true, description: 'Check this box to create Trivy Vulnerability Scan report')
    booleanParam(name: 'SONARQUBE_SCAN', defaultValue: true, description: 'Check this box to create SonarQube Scan report')
    booleanParam(name: 'PUSH_IMAGE_HELM_CHART_AND_INCREMENT_POM', defaultValue: true, description: 'Check this box to you want push image and helm charts to jfrog and increment pom version by 1')
}
pipeline {
    agent {
        label 'PS_Ant_Node'
    }
    tools {
        maven 'Maven 3.3.3'
        jdk 'JDK 17'
    }
    options {
        // This is required if you want to clean before build
        skipDefaultCheckout(true)
    }
    environment {
        ADAPTER_NAME = "abc-adapter-service"
        GIT_URL = "https://github.com/rohitjadhav89/om-abc-service-adapter.git"
        JFROG_REGISTRY = "trialn07m4a.jfrog.io"
        JFROG_NAMESPACE = "docker-local"
        CRED_ID = "artifactory-credentials"
        BUCKET_NAME = "presales-om-helm"

        IMAGE_VERSION_TO_BE_PUSHED = ""
        POM_VERSION_TO_BE_USED = ""
        SUFFIX = ""
        ORIGINAL_POM_VERSION = ""
        TRIVY_POM_VERSION = ""
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: params.GITHUB_BRANCH, url: GIT_URL
            }
        }
        stage('Set Environment Variables') {
            steps {
                script {
                    ORIGINAL_POM_VERSION = readMavenPom().getVersion()
                    IMAGE_VERSION_TO_BE_PUSHED = readMavenPom().getVersion()
                    env.IMAGE = "$JFROG_REGISTRY/${JFROG_NAMESPACE}/${ADAPTER_NAME}:${IMAGE_VERSION_TO_BE_PUSHED}"
                    env.HELM_CHART = "${ADAPTER_NAME}/target/${ADAPTER_NAME}-${IMAGE_VERSION_TO_BE_PUSHED}"
                    echo "TAG: ${IMAGE_VERSION_TO_BE_PUSHED}"
                    POM_VERSION_TO_BE_USED = readMavenPom().getVersion()
                    echo "POM_VERSION_TO_BE_USED: ${env.POM_VERSION_TO_BE_USED}"
                    SUFFIX = IMAGE_VERSION_TO_BE_PUSHED.tokenize('-').size() > 1 ? '-' + IMAGE_VERSION_TO_BE_PUSHED.tokenize('-')[1] : ''

                }
            }
        }
        stage('Docker Login') {
            steps {
                //Required for pulling base images from hansen Jfrog cloud
                sh 'docker login trialn07m4a.jfrog.io -u rohitnarayanaboy@gmail.com -p cmVmdGtuOjAxOjE3NzU1Mzk5NzY6NVE3NFFUOWc5bG1JajFobFZSWmJDdlF3UlY1'
            }
        }
        // New stage to handle suffix removal
        stage('Prepare Release Version') {
            when {
                expression { return params.RELEASE_VERSION }
            }
            steps {
                script {
                    // Remove suffix if RELEASE_VERSION is true
                    IMAGE_VERSION_TO_BE_PUSHED = removeSuffix(IMAGE_VERSION_TO_BE_PUSHED)
                    env.IMAGE = "$JFROG_REGISTRY/${JFROG_NAMESPACE}/${ADAPTER_NAME}:${IMAGE_VERSION_TO_BE_PUSHED}"
                    env.HELM_CHART = "${ADAPTER_NAME}/target/${ADAPTER_NAME}-${IMAGE_VERSION_TO_BE_PUSHED}"
                    echo "Updated TAG for release: ${IMAGE_VERSION_TO_BE_PUSHED}"
                }
            }
        }
/*         stage('Check Next Unique Tag') {
            steps {
                script {
                    def TAG = IMAGE_VERSION_TO_BE_PUSHED
                    def IMAGE
                    def REPOSITORY_NAME = "om/${ADAPTER_NAME}"
                    def uniqueVersionFound = false
                    while (!uniqueVersionFound) {
                        IMAGE = "$JFROG_REGISTRY/${JFROG_NAMESPACE}/${ADAPTER_NAME}:$TAG"
                        docker.withRegistry("https://trialn07m4a.jfrog.io", "Cloud_Artifactory_User") {
                            def imageExists = sh(
                                    script: "docker pull ${IMAGE} || exit 1",
                                    returnStatus: true
                            ) == 0

                            if (imageExists) {
                                echo "Image with tag ${TAG} already exists in JFrog. Incrementing version."
                                TAG = incrementVersion(TAG)
                            } else {
                                echo "Image tag ${TAG} is unique. Proceeding with push."
                                uniqueVersionFound = true
                            }
                        }
                    }
                    // Assign the unique TAG value to IMAGE_VERSION_TO_BE_PUSHED
                    IMAGE_VERSION_TO_BE_PUSHED = TAG
                    echo "Unique version to be pushed: ${IMAGE_VERSION_TO_BE_PUSHED}"
                }
            }
        } */

        stage('Build and Test') {
            steps {
                script {
                    // Use IMAGE_VERSION_TO_BE_PUSHED for setting the new version
                    def newVersion = IMAGE_VERSION_TO_BE_PUSHED
                    sh "mvn versions:set -DnewVersion=${newVersion}"
                    sh "mvn versions:set-property -Dproperty=project.version -DnewVersion=${newVersion}"
                    sh "mvn versions:set-property -Dproperty=docker.registry -DnewVersion=${JFROG_REGISTRY}"
                    sh 'mvn clean install -P generateDocker'
                    echo "build completed"
                }
            }
        }
        /* stage('Trivy Vulnerability Scan') {
            when {
                expression { return params.RELEASE_VERSION || params.TRIVY_SCAN }
            }
            steps {
                script {
                    def TAG = readMavenPom().getVersion()
                    TRIVY_POM_VERSION = readMavenPom().getVersion()
                    def IMAGE = "${JFROG_REGISTRY}/${JFROG_NAMESPACE}/${ADAPTER_NAME}:${TAG}"
                    def REPORT_DIR = "/tmp/trivy-scan/${ADAPTER_NAME}/"
                    def REPORT_FILE = "${TAG}.html"

                    sh "mkdir -p ${REPORT_DIR}"

                    // Check if the container exists, stop and remove it if necessary
                    def containerId = sh(
                            script: "docker ps -a -q -f name=${ADAPTER_NAME}-${TAG}",
                            returnStdout: true
                    ).trim()

                    if (containerId) {
                        sh "docker stop ${containerId}"
                        sh "docker rm ${containerId}"
                    }
                    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.56.2 clean --all"

                    def exitCode = sh(
                            script: """
                                docker run -v /var/run/docker.sock:/var/run/docker.sock --name ${ADAPTER_NAME}-${TAG} docker.io/aquasec/trivy:0.56.2 image --format template --template \"@contrib/html.tpl\" -o /tmp/${REPORT_FILE} --exit-code 0 --severity HIGH,CRITICAL ${IMAGE} --db-repository public.ecr.aws/aquasecurity/trivy-db --java-db-repository public.ecr.aws/aquasecurity/trivy-java-db --scanners vuln  || echo \$
                            """,
                            returnStatus: true
                    )

                    sh "docker cp ${ADAPTER_NAME}-${TAG}:/tmp/${REPORT_FILE} ${REPORT_DIR}${REPORT_FILE}"
                    sh "docker container rm -f ${ADAPTER_NAME}-${TAG}"

                    if (exitCode == 0) {
                        currentBuild.result = 'SUCCESS'
                    } else {
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
            post {
                always {
                    publishHTML(
                            target: [
                                    allowMissing         : false,
                                    alwaysLinkToLastBuild: true,
                                    keepAll              : true,
                                    includes             : "** /* *//*.html",
                                    reportDir            : "/tmp/trivy-scan/${ADAPTER_NAME}/",
                                    reportFiles          : "${TRIVY_POM_VERSION}.html",
                                    reportName           : "Vulnerability Scan Report",
                                    reportTitles         : "Trivy Scan Vulnerability Report"
                            ]
                    )
                }
            }
        }
        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'Sonar Scanner'
                    withSonarQubeEnv('SonarQube 8.1') {
                        sh 'mvn clean package sonar:sonar ' +
                                '-Dorg.xml.sax.driver=com.sun.org.apache.xerces.internal.parsers.SAXParser ' +
                                '-Dsonar.exclusions="**  *//* *//*  *//*.json,**  *//* *//*  *//*pojo*,**//*  *//* errorhandling *//*  *//**" '
                    }
                }
            }
        } */
        stage('Build and Test After Scan') {
            when {
                expression { return params.RELEASE_VERSION || params.TRIVY_SCAN || params.SONARQUBE_SCAN }
            }
            steps {
                script {
                    // Use IMAGE_VERSION_TO_BE_PUSHED for setting the new version
                    def newVersion = IMAGE_VERSION_TO_BE_PUSHED
                    sh "mvn versions:set -DnewVersion=${newVersion}"
                    sh "mvn versions:set-property -Dproperty=project.version -DnewVersion=${newVersion}"
                    sh "mvn versions:set-property -Dproperty=docker.registry -DnewVersion=${JFROG_REGISTRY}"
                    sh 'mvn clean install -P generateDocker'
                    echo "build completed"
                }
            }
        }
        stage('Push Image to JFrog Artifactory') {
            when {
                expression { return params.RELEASE_VERSION || params.PUSH_IMAGE_HELM_CHART_AND_INCREMENT_POM }
            }
            steps {
                script {
                    def TAG = IMAGE_VERSION_TO_BE_PUSHED
                    def JFROG_IMAGE = "$JFROG_REGISTRY/$JFROG_NAMESPACE/${ADAPTER_NAME}:$TAG"
                    echo 'Pushing into JFrog'
                    withCredentials([usernamePassword(credentialsId: 'artifactory-credentials', passwordVariable: 'password', usernameVariable: 'username')]) {
                        sh 'docker login trialn07m4a.jfrog.io -u "${username}" -p "${password}"'
                        sh "docker push $JFROG_IMAGE"
                    }
                    // Set the image version in the build description
                    currentBuild.description = "Image Version: ${TAG}"
                }
            }
        }
        stage('Upload Helm Chart to JFrog Artifactory') {
            when {
                expression { return params.RELEASE_VERSION || params.PUSH_IMAGE_HELM_CHART_AND_INCREMENT_POM }
            }
            steps {
                script {
                    def TAG = IMAGE_VERSION_TO_BE_PUSHED
                    def HELM_CHART = "${ADAPTER_NAME}/target/${ADAPTER_NAME}-${TAG}.tgz"
                    def JFROG_REPO_PATH = "docker-local/presales-om-abc/${ADAPTER_NAME}/${ADAPTER_NAME}-${TAG}.tgz"
                    echo HELM_CHART
                    echo JFROG_REPO_PATH
                    withCredentials([usernamePassword(credentialsId: 'artifactory-credentials', passwordVariable: 'password', usernameVariable: 'username')]) {
                        sh """
                        curl -u ${username}:${password} -T ${HELM_CHART} \
                        https://trialn07m4a.jfrog.io/artifactory/${JFROG_REPO_PATH}
                    """
                        echo "upload completed"
                    }

                }
            }
        }
        stage('Increment POM Version') {
            when {
                expression { return params.RELEASE_VERSION || params.PUSH_IMAGE_HELM_CHART_AND_INCREMENT_POM }
            }
            steps {
                script {
                    // Reset the POM version to the original version
                    if (params.RELEASE_VERSION) {
                        IMAGE_VERSION_TO_BE_PUSHED = IMAGE_VERSION_TO_BE_PUSHED + SUFFIX
                    }
                    sh "mvn versions:set -DnewVersion=${IMAGE_VERSION_TO_BE_PUSHED}"
                    sh "mvn versions:set-property -Dproperty=project.version -DnewVersion=${IMAGE_VERSION_TO_BE_PUSHED}"
                    // Read the current version from the main POM
                    def pom = readMavenPom file: 'pom.xml'
                    def currentVersion = IMAGE_VERSION_TO_BE_PUSHED
                    env.CURRENT_POM_VERSION = IMAGE_VERSION_TO_BE_PUSHED

                    // Increment the version
                    POM_VERSION_TO_BE_USED = incrementVersion(IMAGE_VERSION_TO_BE_PUSHED)
                    echo "Incrementing POM Version, here currentVersion is ${IMAGE_VERSION_TO_BE_PUSHED} and POM_VERSION_TO_BE_USED is ${POM_VERSION_TO_BE_USED}"
                    // Update the version in the main POM and submodules
                    sh "mvn versions:set -DnewVersion=${POM_VERSION_TO_BE_USED}"
                    sh "mvn versions:update-child-modules"
                    // Update the <project.version> property in pom.xml
                    sh "mvn versions:set-property -Dproperty=project.version -DnewVersion=${POM_VERSION_TO_BE_USED}"
                    sh "mvn versions:commit"
                }
            }
        }
        stage('Commit and Push POM Version Changes') {
            when {
                expression { return params.RELEASE_VERSION || params.PUSH_IMAGE_HELM_CHART_AND_INCREMENT_POM }
            }
            steps {
                script {
                    echo "ORIGINAL_POM_VERSION is ${ORIGINAL_POM_VERSION} and POM_VERSION_TO_BE_USED is ${POM_VERSION_TO_BE_USED}"
                    def branchName = params.GITHUB_BRANCH ?: 'master'
                    // Commit the updated versions to Git
                    //sh "git add -- pom.xml **//* pom.xml"
                    sh("git config user.email rohitnarayanaboy@gmail.com")
                    sh("git config user.name rohitjadhav89")
                    sh "git remote set-url origin $GIT_URL"
                    sh "git add pom.xml */pom.xml"
                    sh "git commit -m 'Updated POM version to ${POM_VERSION_TO_BE_USED}'"
                    sh "git push origin ${branchName}"
                }
            }
        }
    }
    post {
        success {
            emailext mimeType: 'text/html',
                    body: "<h2>Pipeline completed</h2><br>Project: ${env.JOB_NAME} <br>Build Number: " +
                            "${env.BUILD_NUMBER}<br> Version: $IMAGE_VERSION_TO_BE_PUSHED <br> Helm chart: s3://$BUCKET_NAME/${ADAPTER_NAME}-$IMAGE_VERSION_TO_BE_PUSHED" +
                            ".tgz <br> URL: ${env.BUILD_URL}",
                    subject: "Pipeline >> #${env.BUILD_NUMBER} : ${env.JOB_NAME}",
                    from: 'noreply@hansencx.com',
                    to: "Rohit.Jadhav@hansencx.com";
        }
        failure {
            emailext mimeType: 'text/html',
                    body: "<h2>Pipeline failed</h2><br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER}" +
                            "<br> URL: ${env.BUILD_URL} <br> Kindly check console logs on above URL.",
                    subject: "Pipeline >> #${env.BUILD_NUMBER} : ${env.JOB_NAME}",
                    from: 'noreply@hansencx.com',
                    to: "Rohit.Jadhav@hansencx.com";
            }
    }
}

def incrementVersion(String version) {
    echo "Current version is :  ${version}"
    def versionParts = version.tokenize('-')
    def baseVersion = versionParts[0]
    def suffix = versionParts.size() > 1 ? '-' + versionParts[1] : ''

    def versionNumbers = baseVersion.tokenize('.')
    versionNumbers[-1] = (versionNumbers[-1].toInteger() + 1).toString()
    def updatedVersion = versionNumbers.join('.') + suffix
    echo "Updated version is :  ${updatedVersion}"
    return updatedVersion
}
def removeSuffix(String version) {
    def versionParts = version.tokenize('-')
    def baseVersion = versionParts[0]
    return baseVersion
}

