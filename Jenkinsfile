// Jenkins declarative pipeline for Node.js CI/CD
// This pipeline installs dependencies, runs tests, scans for vulnerabilities,
// builds a Docker image, and pushes it to a container registry.
// It uses Docker-in-Docker (DinD) with a shared named volume for workspace access.

pipeline {

  // Use Node.js 16 Docker image as build environment
  // Mount jenkins-data volume so agent container can access Jenkins workspace
  agent {
    docker {
      image 'node:16'
      args '-v jenkins-data:/var/jenkins_home'
    }
  }

  // Define environment variable for Docker image tag
  environment {
    APP_IMAGE = "myapp:${env.BUILD_NUMBER}"
  }

  stages {

    // ------------------------------
    stage('Install Dependencies') {
      steps {
        // Install all project dependencies from package.json
        // The --save flag ensures packages are added to dependencies list if needed
        sh 'npm install --save'
      }
    }
    // ------------------------------

    // ------------------------------
    stage('Run Tests') {
      steps {
        // Run test scripts defined in package.json
        // If tests fail or are missing, print "Tests failed" and exit with error
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
      agent none // Run this stage on Jenkins host (not inside node:16 agent)
      steps {
        script {
          // Build Docker image for the Node.js app
          // Tag image using build number for traceability
          sh "docker build -t ${APP_IMAGE} ."
        }
      }
    }
    // ------------------------------

    // ------------------------------
    stage('Push Image') {
      agent none // Run this stage on Jenkins host
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
      node {
        // List all Docker images after pipeline completion
        // Helps verify image creation and tag
        sh 'docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" || true'
      }
    }
  }
}

