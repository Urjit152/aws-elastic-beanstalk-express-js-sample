// Jenkins declarative pipeline for Node.js CI/CD
// Installs dependencies, runs tests, scans for vulnerabilities,
// builds a Docker image, and pushes it to a container registry.
// Uses Docker-in-Docker (DinD) with shared named volume.

pipeline {

  agent {
    docker {
      image 'node:16'
      args '-v jenkins-data:/var/jenkins_home'
    }
  }

  environment {
    APP_IMAGE = "myapp:${env.BUILD_NUMBER}"   // Tag image with build number
    DOCKER_HOST = "tcp://docker:2376"         // Point Docker CLI to DinD service
    DOCKER_CERT_PATH = "/certs/client"        // TLS certs mounted from docker-certs-client
    DOCKER_TLS_VERIFY = "1"                   // Enforce TLS verification
    PATH = "/usr/local/bin:/usr/bin:/bin"     // Ensure docker is visible in pipeline sh steps
  }

  stages {

    stage('Install Dependencies') {
      steps {
        sh 'npm install --save'
      }
    }

    stage('Run Tests') {
      steps {
        sh 'npm test || (echo "Tests failed" && exit 1)'
      }
    }

    stage('Security Scan') {
      environment {
        SNYK_TOKEN = credentials('SNYK_TOKEN')
      }
      steps {
        sh '''
          npm install -g snyk
          snyk auth $SNYK_TOKEN
          snyk test --severity-threshold=high || (echo "Snyk found high/critical issues" && exit 1)
        '''
      }
    }

    stage('Build Docker Image') {
      agent none
      steps {
        script {
          sh "docker info"
          sh "docker build -t ${APP_IMAGE} ."
          sh "docker images | grep myapp || true"
        }
      }
    }

    stage('Push Image') {
      agent none
      steps {
        withCredentials([usernamePassword(credentialsId: 'DOCKER_CREDENTIALS', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker tag ${APP_IMAGE} $DOCKER_USER/myapp:latest
            docker push $DOCKER_USER/myapp:latest
          '''
        }
      }
    }

    stage('Archive Logs') {
      steps {
        archiveArtifacts artifacts: '/build.log', allowEmptyArchive: true
      }
    }
  }

  post {
    always {
      sh 'docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" || true'
    }
  }
}
