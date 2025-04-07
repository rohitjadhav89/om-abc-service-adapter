pipeline {
    agent any

    environment {
        // Define your Artifactory and Docker environment variables
        ARTIFACTORY_URL = 'https://trialn07m4a.jfrog.io/artifactory/'
        ARTIFACTORY_REPO = 'docker-local' // Your Artifactory Docker repo
        ARTIFACTORY_CREDS = 'artifactory-credentials' // Jenkins credentials ID for Artifactory
        DOCKER_IMAGE = 'om-abc-service-adapter'
        DOCKER_TAG = 'latest' // You can use git commit hash, or version tags as dynamic values
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout your GitHub repository
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build Docker image using Dockerfile in the root of the repo
                    sh """
                    docker build -t $ARTIFACTORY_URL/$ARTIFACTORY_REPO/$DOCKER_IMAGE:$DOCKER_TAG .
                    """
                }
            }
        }

        stage('Login to Artifactory') {
            steps {
                script {
                    // Login to JFrog Artifactory
                    withCredentials([usernamePassword(credentialsId: "$ARTIFACTORY_CREDS", usernameVariable: 'ARTIFACTORY_USER', passwordVariable: 'ARTIFACTORY_PASS')]) {
                        sh """
                        docker login -u $ARTIFACTORY_USER -p $ARTIFACTORY_PASS $ARTIFACTORY_URL
                        """
                    }
                }
            }
        }

        stage('Push Docker Image to Artifactory') {
            steps {
                script {
                    // Push the Docker image to Artifactory
                    sh """
                    docker push $ARTIFACTORY_URL/$ARTIFACTORY_REPO/$DOCKER_IMAGE:$DOCKER_TAG
                    """
                }
            }
        }
    }

    post {
        always {
            // Clean up docker images after the build is done
            sh 'docker system prune -f'
        }

        success {
            echo "Docker image pushed successfully to Artifactory!"
        }

        failure {
            echo "The pipeline failed. Please check the logs for details."
        }
    }
}
