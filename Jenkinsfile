// Jenkins declarative pipeline for Node.js CI/CD
// This pipeline installs dependencies, runs tests, scans for vulnerabilities,
// builds a Docker image, and pushes it to a container registry.
// It uses Docker-in-Docker (DinD) with a shared named volume for workspace access.

pipeline {

  // ------------------------------
  // Use Node.js 16 Docker image as build environment
  // Mount jenkins-data volume so agent container can access Jenkins workspace
  agent {
    docker {
      image 'node:16'
      args '-v jenkins-data:/var/jenkins_home'
    }
  }

  // ------------------------------
  // Define environment variables for Docker image tagging and DinD connection
  environment {
    APP_IMAGE = "myapp:${env.BUILD_NUMBER}"   // Tag image with build number
    DOCKER_HOST = "tcp://docker:2376"         // Point Docker CLI to DinD service
    DOCKER_CERT_PATH = "/certs/client"        // TLS certs mounted from docker-certs-client
    DOCKER_TLS_VERIFY = "1"                   // Enforce TLS verification
  }

  stages {

    // ------------------------------
    stage('Install Dependencies') {
      steps {
        // Install all project dependencies from package.json
        sh 'npm install --save'
      }
    }
    // ------------------------------

    // ------------------------------
    stage('Run Tests') {
      steps {
        // Run test scripts defined in package.json
        sh 'npm test || (echo "Tests failed" && exit 1)'
      }
    }
    // ------------------------------

    // ------------------------------
    stage('Security Scan') {
      environment {
        // Inject Snyk token securely from Jenkins credentials
        SNYK_TOKEN = credentials('SNYK_TOKEN')
      }
      steps {
        // Install Snyk CLI globally and run scan
        sh '''
          npm install -g snyk
          snyk auth $SNYK_TOKEN
          snyk test --severity-threshold=high || (echo "Snyk found high/critical issues" && exit 1)
        '''
      }
    }
    // ------------------------------

    // ------------------------------
    stage('Build Docker Image') {
      agent none // Run this stage on Jenkins host (not inside node:16 agent)
      steps {
        script {
          // Run docker commands using PATH (no hard-coded path)
          sh "docker info"
          sh "docker build -t ${APP_IMAGE} ."
          sh "docker images | grep myapp || true"
        }
      }
    }
    // ------------------------------

    // ------------------------------
    stage('Push Image') {
      agent none // Run this stage on Jenkins host
      steps {
        withCredentials([usernamePassword(credentialsId: 'DOCKER_CREDENTIALS', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          // Authenticate to DockerHub and push image
          sh '''
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker tag ${APP_IMAGE} $DOCKER_USER/myapp:latest
            docker push $DOCKER_USER/myapp:latest
          '''
        }
      }
    }
    // ------------------------------

    // ------------------------------
    stage('Archive Logs') {
      steps {
        // Archive build logs for assignment submission
        archiveArtifacts artifacts: '/build.log', allowEmptyArchive: true
      }
    }
    // ------------------------------
  }

  post {
    always {
      // List all Docker images after pipeline completion
      sh 'docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" || true'
    }
  }
}
