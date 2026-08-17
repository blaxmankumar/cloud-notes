pipeline {
agent any

environment {
    REPO_URL = "https://github.com/blaxmankumar/cloud-notes.git"
    BRANCH = "main"
    MONITORING_COMPOSE = "monitoring-stack/docker-compose.yml"
}

stages {

    stage('Checkout') {
        steps {
            git branch: "${BRANCH}",
                url: "${REPO_URL}"
        }
    }

    stage('Check Files') {
        steps {
            sh '''
            pwd
            ls -la
            '''
        }
    }

    stage('SonarQube Scan') {
        steps {
            script {
                def scannerHome = tool 'SonarScanner'

                withSonarQubeEnv('SonarQube') {
                    withCredentials([
                        string(credentialsId: 'sonar-token',
                               variable: 'SONAR_TOKEN')
                    ]) {

                        sh """
                        ${scannerHome}/bin/sonar-scanner \
                          -Dsonar.projectKey=cloud-notes \
                          -Dsonar.projectName=cloud-notes \
                          -Dsonar.sources=. \
                          -Dsonar.token=$SONAR_TOKEN
                        """
                    }
                }
            }
        }
    }

    stage('Create .env') {
        steps {
            withCredentials([
                string(credentialsId: 'db-password',
                       variable: 'DB_PASS')
            ]) {

                sh '''
                cat > .env <<EOF
```

DB_HOST=YOUR_RDS_ENDPOINT
DB_PORT=3306
DB_USER=admin
DB_PASSWORD=$DB_PASS
DB_NAME=cloudnotes
EOF
'''
}
}
}

```
    stage('Deploy Cloud Notes') {
        steps {
            sh '''
            docker compose down || true
            docker compose up -d --build
            '''
        }
    }

    stage('Deploy Monitoring Stack') {
        steps {
            sh """
            docker compose -f ${MONITORING_COMPOSE} down || true
            docker compose -f ${MONITORING_COMPOSE} up -d
            """
        }
    }

    stage('Verify Deployment') {
        steps {
            sh '''
            docker ps
            '''
        }
    }
}

post {
    success {
        echo 'Cloud Notes deployed successfully.'
    }

    failure {
        echo 'Pipeline failed.'
    }
}


}
