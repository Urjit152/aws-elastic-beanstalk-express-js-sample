pipeline {
  agent {
    docker {
      image 'node:16'
      args '-v jenkins-data:/var/jenkins_home'
    }
  }

  environment {
    APP_IMAGE = "myapp:${env.BUILD_NUMBER}"
    DOCKER_HOST = "tcp://docker:2376"
    DOCKER_CERT_PATH = "/certs/client"
    DOCKER_TLS_VERIFY = "1"
    PATH = "/usr/local/bin:/usr/bin:/bin"
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

    // Run inside Jenkins container
    stage('Build Docker Image') {
      steps {
        script {
          sh "docker info"
          sh "docker build -t ${APP_IMAGE} ."
          sh "docker images | grep myapp || true"
        }
      }
    }

    // ✅ Run inside Jenkins container (not agent none)
    stage('Push Image') {
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
