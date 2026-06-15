pipeline {
    agent any

    environment {
        IMAGE_TAG = "${BUILD_NUMBER}"

        BACKEND_IMAGE  = "battulalaxmankumar04/cloud-notes-backend"
        FRONTEND_IMAGE = "battulalaxmankumar04/cloud-notes-frontend"
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
                    echo "===== Monitoring Status ====="

                    docker ps | grep prometheus
                    docker ps | grep grafana
                    docker ps | grep node-exporter

                    echo "Monitoring Containers Running"
                '''
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('sonarqube') {

                    sh '''
                    /var/lib/jenkins/tools/hudson.plugins.sonar.SonarRunnerInstallation/sonar-scanner/bin/sonar-scanner \
                    -Dsonar.projectKey=cloud-notes \
                    -Dsonar.projectName=cloud-notes \
                    -Dsonar.sources=.
                    '''
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

        stage('DockerHub Login') {
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
                    '''
                }
            }
        }

        stage('Push Backend Image') {
            steps {

                sh """
                docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                docker push ${BACKEND_IMAGE}:latest
                """
            }
        }

        stage('Push Frontend Image') {
            steps {

                sh """
                docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
                docker push ${FRONTEND_IMAGE}:latest
                """
            }
        }

        stage('Show Monitoring URLs') {
            steps {

                echo "Prometheus : http://44.202.212.111:9090"
                echo "Grafana    : http://44.202.212.111:3000"
                echo "SonarQube  : http://44.202.212.111:9000"
            }
        }
    }

    post {

        success {

            echo "Pipeline Executed Successfully"

            echo "Backend Image : ${BACKEND_IMAGE}:${IMAGE_TAG}"
            echo "Frontend Image: ${FRONTEND_IMAGE}:${IMAGE_TAG}"
        }

        failure {

            echo "Pipeline Failed"
        }

        always {

            cleanWs()
        }
    }
}
