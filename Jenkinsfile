// --------------------------------------------------------------------
// Jenkins declarative pipeline for Node.js CI/CD
// Purpose:
//   - Clean workspace, detect Node app + Dockerfile
//   - Build + test app in isolated Node container
//   - Perform npm audit (quick security check)
//   - Build and push Docker image to Docker Hub
// --------------------------------------------------------------------

pipeline {
  agent any 

  environment {
    
    IMAGE_NAME = "urjit21838321/node-app"   
    IMAGE_TAG  = "build-${env.BUILD_NUMBER}" // each build uniquely
  }

  options {
    timestamps()                             // timestamp logs
    buildDiscarder(logRotator(numToKeepStr: '10')) // keep only last 10 builds
  }

  stages {

    // -----------------------------
    stage('Checkout (clean)') {
      steps {
        cleanWs()        // start fresh
        checkout scm     // pull latest code
      }
    }

    // -----------------------------
    stage('Detect app & Dockerfile') {
      steps {
        // Detect where package.json and Dockerfile exist
        sh '''
          set -eu
          PKG="$( [ -f package.json ] && echo package.json || find . -maxdepth 2 -type f -name package.json -print -quit )"
          [ -n "$PKG" ] || { echo "No package.json found"; exit 1; }
          APP_DIR="$(dirname "$PKG")"; [ "$APP_DIR" = "." ] && APP_DIR="."
          DF=""
          [ -f "$APP_DIR/Dockerfile" ] && DF="$APP_DIR/Dockerfile"
          [ -z "$DF" ] && [ -f Dockerfile ] && DF="Dockerfile"
          [ -n "$DF" ] || { echo "No Dockerfile found in $APP_DIR or repo root"; exit 1; }
          printf "APP_DIR=%s\nDOCKERFILE_PATH=%s\n" "$APP_DIR" "$DF" > .envfile
          cat .envfile
        '''
      }
    }

    // -----------------------------
    stage('Detect Docker TLS & IP') {
      steps {
        // Find certs and DinD IP, prepare Docker client env
        sh '''
          set -eu
          if [ -f /certs/client/cert.pem ] && [ -f /certs/client/key.pem ] && [ -f /certs/client/ca.pem ]; then
            CERT_DIR="/certs/client"
          elif [ -f /certs/client/client/cert.pem ]; then
            CERT_DIR="/certs/client/client"
          else
            echo "ERROR: Docker client certs not found"
            exit 1
          fi

          DIND_IP="$(getent hosts dind | awk '{print $1}' | head -n1 || true)"
          [ -n "$DIND_IP" ] || DIND_IP="dind"

          cat > docker-env.sh <<EOF
export DOCKER_HOST=tcp://$DIND_IP:2376
export DOCKER_TLS_VERIFY=1
export DOCKER_CERT_PATH=$CERT_DIR
export DOCKER_TLS_SERVER_NAME=docker
EOF

          . ./docker-env.sh
          docker version
        '''
      }
    }

    // -----------------------------
    stage('Install Node modules (Dockerized)') {
      steps {
        // Run npm install inside a Node container
        sh '''
          set -eu
          . ./docker-env.sh
          . ./.envfile

          docker run --rm \
            -v "$PWD":/app -w /app \
            node:20-alpine sh -lc "node -v && npm -v && (npm ci || npm install)"
          echo "npm install finished"
        '''
      }
    }

    // -----------------------------
    stage('Unit tests (Dockerized)') {
      steps {
        // Run npm test if test script exists
        sh '''
          set -eu
          . ./docker-env.sh

          if grep -q '"test"[[:space:]]*:' package.json; then
            docker run --rm -v "$PWD":/app -w /app node:20-alpine sh -lc "npm test"
          else
            echo "No test script defined. Skipping tests."
          fi
        '''
      }
      post {
        always {
          junit allowEmptyResults: true, testResults: '**/junit.xml'
        }
      }
    }

    // -----------------------------
    stage('Quick security check (npm audit)') {
      steps {
        // Basic security scan; logs any high vulnerabilities
        sh '''
          set -eu
          . ./docker-env.sh
          docker run --rm -v "$PWD":/app -w /app node:20-alpine sh -lc "npm audit --audit-level=high || true"
        '''
      }
    }


    // -----------------------------
    stage('Security Scan (Snyk)') {
      steps {
        withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          sh '''
            set -eu
            . ./docker-env.sh
            docker run --rm \
              -e SNYK_TOKEN="$SNYK_TOKEN" \
              -v "$PWD":/app -w /app \
              node:20-alpine sh -lc "npm install -g snyk && snyk auth $SNYK_TOKEN && snyk test || exit 1"
          '''
        }
      }
    }

    // -----------------------------
    stage('Docker build & push') {
      steps {
        // Build and push image to Docker Hub using Jenkins credentials
        withCredentials([usernamePassword(
          credentialsId: 'DOCKER_CREDENTIALS', 
          usernameVariable: 'DH_USER',
          passwordVariable: 'DH_PASS'
        )]) {
          sh '''
            set -eu
            . ./docker-env.sh
            . ./.envfile

            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
            docker build -f "$DOCKERFILE_PATH" -t "${IMAGE_NAME}:${IMAGE_TAG}" "$APP_DIR"
            docker push "${IMAGE_NAME}:${IMAGE_TAG}"
            docker tag  "${IMAGE_NAME}:${IMAGE_TAG}" "${IMAGE_NAME}:latest"
            docker push "${IMAGE_NAME}:latest"
          '''
        }
      }
    }
  }

  post {
    always {
      cleanWs() // cleanup workspace after every run
    }
  }
}
