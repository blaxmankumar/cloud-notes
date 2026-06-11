pipeline {
    agent any

    environment {
        IMAGE_NAME = "blaxmankumar/cloud-notes"
        IMAGE_TAG  = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/blaxmankumar/cloud-notes.git'
            }
        }

        stage('Verify Sonar Scanner') {
            steps {
                script {
                    def scannerHome = tool 'sonar-scanner'
                    echo "Using Sonar Scanner from: ${scannerHome}"
                }
            }
        }

        stage('SonarQube Scan') {
            steps {
                script {
                    def scannerHome = tool 'sonar-scanner'

                    withSonarQubeEnv('Sonar') {
                        sh """
                        ${scannerHome}/bin/sonar-scanner \
                          -Dsonar.projectKey=cloud-notes \
                          -Dsonar.projectName=cloud-notes \
                          -Dsonar.sources=. \
                          -Dsonar.sourceEncoding=UTF-8
                        """
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh """
                    echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin

                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${IMAGE_NAME}:latest

                    docker logout
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                kubectl apply -f k8s/

                kubectl rollout restart deployment cloud-notes

                kubectl rollout status deployment/cloud-notes
                """
            }
        }
    }

    post {

        success {
            echo 'SUCCESS: Pipeline executed successfully.'
        }

        failure {
            echo 'FAILURE: Pipeline execution failed.'
        }

        always {
            cleanWs()
        }
    }
}
