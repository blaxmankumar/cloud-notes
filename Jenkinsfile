pipeline {
    agent any

    environment {
        BACKEND_IMAGE  = "battulalaxmankumar04/cloud-notes-backend"
        FRONTEND_IMAGE = "battulalaxmankumar04/cloud-notes-frontend"
        IMAGE_TAG      = "${BUILD_NUMBER}"
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

        stage('Build Backend Image') {
            steps {
                sh """
                docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} ./backend
                docker tag ${BACKEND_IMAGE}:${IMAGE_TAG} ${BACKEND_IMAGE}:latest
                """
            }
        }

        stage('Build Frontend Image') {
            steps {
                sh """
                docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} ./frontend
                docker tag ${FRONTEND_IMAGE}:${IMAGE_TAG} ${FRONTEND_IMAGE}:latest
                """
            }
        }

        stage('Push Docker Images') {
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

                    docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                    docker push ${BACKEND_IMAGE}:latest

                    docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
                    docker push ${FRONTEND_IMAGE}:latest

                    docker logout
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                kubectl apply -f deploy/

                kubectl rollout restart deployment/cloud-notes-backend
                kubectl rollout restart deployment/cloud-notes-frontend

                kubectl rollout status deployment/cloud-notes-backend
                kubectl rollout status deployment/cloud-notes-frontend
                """
            }
        }
    }

    post {

        success {
            echo 'SUCCESS: Backend and Frontend deployed successfully!'
        }

        failure {
            echo 'FAILURE: Pipeline execution failed.'
        }

        always {
            cleanWs()
        }
    }
}
