pipeline {
    agent any

    environment {
        // Artifactory Configuration
        ARTIFACTORY_REGISTRY = 'trialn07m4a.jfrog.io'
        ARTIFACTORY_REPO = 'docker-local'
        ARTIFACTORY_CREDS = credentials('artifactory-credentials')  // Direct credential binding

        // Image Configuration
        DOCKER_IMAGE = 'om-abc-service-adapter'
        DOCKER_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"  // Build number + git commit

        // Dynamic Paths
        PROJECT_DIR = 'om-abc-service-adapter-service'  // Your subdirectory
    }

    stages {
        stage('Validate Environment') {
            steps {
                script {
                    echo "Workspace: ${env.WORKSPACE}"
                    echo "Project Directory: ${env.PROJECT_DIR}"
                    dir(env.PROJECT_DIR) {
                        if (!fileExists('Dockerfile')) {
                            error("Dockerfile not found in ${env.PROJECT_DIR}")
                        }
                        sh 'ls -la'  // Debug directory contents
                    }
                }
            }
        }

        stage('Docker Login') {
            steps {
                sh """
                docker login ${env.ARTIFACTORY_REGISTRY} \
                    -u ${env.ARTIFACTORY_CREDS_USR} \
                    -p ${env.ARTIFACTORY_CREDS_PSW}
                """
            }
        }

        stage('Build Image') {
            steps {
                dir(env.PROJECT_DIR) {
                    sh """
                    docker build \
                        -t ${env.ARTIFACTORY_REGISTRY}/${env.ARTIFACTORY_REPO}/${env.DOCKER_IMAGE}:${env.DOCKER_TAG} \
                        -t ${env.ARTIFACTORY_REGISTRY}/${env.ARTIFACTORY_REPO}/${env.DOCKER_IMAGE}:latest \
                        .
                    """
                }
            }
        }

        stage('Push Image') {
            steps {
                sh """
                docker push ${env.ARTIFACTORY_REGISTRY}/${env.ARTIFACTORY_REPO}/${env.DOCKER_IMAGE}:${env.DOCKER_TAG}
                docker push ${env.ARTIFACTORY_REGISTRY}/${env.ARTIFACTORY_REPO}/${env.DOCKER_IMAGE}:latest
                """
            }
        }
    }

    post {
        always {
            sh 'docker logout ${env.ARTIFACTORY_REGISTRY} || true'
            sh 'docker system prune -af || true'
        }
        success {
            echo "Successfully built and pushed image"
            echo "Image: ${env.ARTIFACTORY_REGISTRY}/${env.ARTIFACTORY_REPO}/${env.DOCKER_IMAGE}:${env.DOCKER_TAG}"
        }
        failure {
            echo "Pipeline failed - check console output"
        }
    }
}