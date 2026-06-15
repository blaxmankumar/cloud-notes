pipeline {
    agent any

    environment {
        BACKEND_IMAGE = "battulalaxmankumar04/cloud-notes-backend"
        FRONTEND_IMAGE = "battulalaxmankumar04/cloud-notes-frontend"
        IMAGE_TAG = "${BUILD_NUMBER}"
        SONAR_SCANNER = tool 'sonar-scanner'
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/blaxmankumar/cloud-notes.git'
            }
        }

        stage('Verify Monitoring') {
            steps {
                sh '''
                echo "Checking Prometheus..."
                docker ps | grep prometheus

                echo "Checking Grafana..."
                docker ps | grep grafana

                echo "Checking Node Exporter..."
                docker ps | grep node-exporter
                '''
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh """
                    ${SONAR_SCANNER}/bin/sonar-scanner \
                    -Dsonar.projectKey=cloud-notes \
                    -Dsonar.projectName=cloud-notes \
                    -Dsonar.sources=.
                    """
                }
            }
        }

        stage('Build Backend Image') {
            steps {
                dir('backend') {
                    sh """
                    docker build \
                    -t ${BACKEND_IMAGE}:${IMAGE_TAG} \
                    -t ${BACKEND_IMAGE}:latest .
                    """
                }
            }
        }

        stage('Build Frontend Image') {
            steps {
                dir('frontend') {
                    sh """
                    docker build \
                    -t ${FRONTEND_IMAGE}:${IMAGE_TAG} \
                    -t ${FRONTEND_IMAGE}:latest .
                    """
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {

                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                    docker push '${BACKEND_IMAGE}':'${IMAGE_TAG}'
                    docker push '${BACKEND_IMAGE}':latest

                    docker push '${FRONTEND_IMAGE}':'${IMAGE_TAG}'
                    docker push '${FRONTEND_IMAGE}':latest
                    '''
                }
            }
        }

        stage('Show Monitoring URLs') {
            steps {
                echo '''
==========================================
Monitoring URLs

Prometheus:
http://44.202.212.111:9090

Grafana:
http://44.202.212.111:3000

SonarQube:
http://44.202.212.111:9000

Jenkins:
http://44.202.212.111:8080
==========================================
'''
            }
        }
    }

    post {
        success {
            echo "SUCCESS: Build completed successfully."
        }

        failure {
            echo "FAILURE: Pipeline execution failed."
        }

        always {
            cleanWs()
        }
    }
}
