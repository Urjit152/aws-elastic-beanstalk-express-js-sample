// Jenkins declarative pipeline for Node.js CI/CD
// This pipeline installs dependencies, runs tests, scans for vulnerabilities,
// builds a Docker image, and pushes it to a container registry.
// It uses Docker-in-Docker (DinD) with a shared named volume for workspace access.

pipeline {

  // ------------------------------
  // Default agent: Node.js 16 container for npm and snyk
  // Mounts jenkins-data volume so agent container can access Jenkins workspace
  agent {
    docker {
      image 'node:16'
      args '-v jenkins-data:/var/jenkins_home'
    }
  }

  // ------------------------------
  // Define environment variables for Docker image tag and DinD connection
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
        // If tests fail, print "Tests failed" and exit with error
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
        // Install Snyk CLI globally
        // Authenticate using token and run scan with high severity threshold
        // Fail pipeline if high/critical vulnerabilities are found
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
      // Run this stage on Jenkins controller (where Docker CLI is installed)
      agent any
      steps {
        // Build Docker image for the Node.js app
        // Tag image using build number for traceability
        sh "docker build -t ${APP_IMAGE} ."
        // List images to confirm build
        sh "docker images | grep myapp || true"
      }
    }
    // ------------------------------

    // ------------------------------
    stage('Push Image') {
      // Run this stage on Jenkins controller (where Docker CLI is installed)
      agent any
      steps {
        withCredentials([usernamePassword(credentialsId: 'DOCKER_CREDENTIALS', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          // Authenticate to DockerHub using Jenkins credentials
          // Tag and push the built image to DockerHub
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
        // Allow empty archive to avoid pipeline failure if log is missing
        archiveArtifacts artifacts: '/build.log', allowEmptyArchive: true
      }
    }
    // ------------------------------
  }

  post {
    always {
      // List all Docker images after pipeline completion
      // Helps verify image creation and tag
      sh 'docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" || true'
    }
  }
}
