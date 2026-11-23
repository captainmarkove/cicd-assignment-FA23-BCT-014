pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        IMAGE   = 'cicd-site'
        TESTER  = 'cicd-site-tests'
        NETWORK = 'cicd-net'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Package') {
            steps {
                sh 'docker build -t ${IMAGE}:${BUILD_NUMBER} -t ${IMAGE}:latest .'
            }
        }

        stage('Start Staging') {
            steps {
                sh '''
                    docker network create ${NETWORK} || true
                    docker rm -f staging || true
                    docker run -d --name staging --network ${NETWORK} -p 8081:80 ${IMAGE}:${BUILD_NUMBER}
                    sleep 3
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    rm -rf results && mkdir -p results
                    docker build -t ${TESTER} tests
                    docker run --rm --network ${NETWORK} \
                        --user $(id -u):$(id -g) \
                        -e BASE_URL=http://staging \
                        -v "$WORKSPACE/results:/results" \
                        ${TESTER}
                '''
            }
            post {
                always {
                    junit 'results/results.xml'
                    archiveArtifacts artifacts: 'results/*.png', allowEmptyArchive: true
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    docker rm -f site-live || true
                    docker run -d --name site-live --restart unless-stopped -p 80:80 ${IMAGE}:${BUILD_NUMBER}
                '''
            }
        }
    }

    post {
        always {
            sh 'docker rm -f staging || true'
        }
    }
}
