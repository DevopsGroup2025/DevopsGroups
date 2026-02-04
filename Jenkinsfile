pipeline {
    agent { label 'jenkinsagent' }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
    }

    tools {
        nodejs 'node'
    }

    environment {
        DOCKER_IMAGE_BACKEND = 'devops-backend'
        DOCKER_IMAGE_FRONTEND = 'devops-frontend'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Backend') {
            steps {
                dir('apps/backend') {
                    sh 'npm ci'
                    sh 'npm run build'
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('apps/frontend') {
                    sh 'npm ci'
                    sh 'npm run build'
                }
            }
        }

        stage('Containerize Backend') {
            steps {
                dir('apps/backend') {
                    sh "docker build -t ${DOCKER_IMAGE_BACKEND}:${BUILD_NUMBER} -t ${DOCKER_IMAGE_BACKEND}:latest ."
                }
            }
        }

        stage('Containerize Frontend') {
            steps {
                dir('apps/frontend') {
                    sh "docker build -t ${DOCKER_IMAGE_FRONTEND}:${BUILD_NUMBER} -t ${DOCKER_IMAGE_FRONTEND}:latest ."
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Build and containerization completed successfully!'
        }
        failure {
            echo 'Build or containerization failed!'
        }
    }
}
