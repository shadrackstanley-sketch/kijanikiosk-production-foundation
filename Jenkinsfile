pipeline {
    agent none

    parameters {
        string(
            name: 'NEXUS_URL',
            defaultValue: 'http://172.17.0.1:8081',
            description: 'Nexus Repository base URL reachable from the Docker agent'
        )
    }

    environment {
        PROJECT_DIR         = 'week5/friday'
        APP_NAME            = 'kijanikiosk-payments'
        BASE_VERSION        = '1.0.0'
        NEXUS_REPOSITORY    = 'kijanikiosk-npm-hosted'
        NEXUS_CREDENTIAL_ID = 'nexus-credentials'
        ARTIFACT_DIRECTORY  = 'artifacts'
        TEST_RESULT_FILE    = 'test-results/junit.xml'
        CI                  = 'true'

        STAGING_NAMESPACE   = 'kijani-staging'
        PROD_NAMESPACE      = 'kijani-production'
        STAGING_OVERLAY     = 'k8s/overlays/staging'
        PROD_OVERLAY        = 'k8s/overlays/production'
        STAGING_SERVICE     = 'kk-payments'
        PROD_SERVICE        = 'kk-payments'
        STAGING_PORT        = '3001'
        PROD_PORT           = '3001'
        CONTAINER_NAME      = 'kk-payments'
    }

    options {
        timeout(time: 20, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {
        stage('Lint') {
            agent {
                docker {
                    image 'node:20.18.1'
                    args '-e HOME=/tmp -e npm_config_cache=/tmp/.npm'
                    reuseNode true
                }
            }

            steps {
                dir("${PROJECT_DIR}") {
                    script {
                        env.GIT_SHORT_SHA = sh(
                            script: 'git rev-parse --short=8 HEAD',
                            returnStdout: true
                        ).trim()

                        env.PACKAGE_VERSION =
                            "${env.BASE_VERSION}-g${env.GIT_SHORT_SHA}"

                        env.NEXUS_REGISTRY =
                            "${params.NEXUS_URL}/repository/${env.NEXUS_REPOSITORY}/"

                        currentBuild.displayName =
                            "#${env.BUILD_NUMBER} ${env.PACKAGE_VERSION}"
                    }

                    sh '''
                        set -eu

                        echo "Node image: node:20.18.1"
                        echo "Package version: ${PACKAGE_VERSION}"

                        npm ci
                        npm run lint
                    '''
                }
            }
        }

        stage('Build') {
            agent {
                docker {
                    image 'node:20.18.1'
                    args '-e HOME=/tmp -e npm_config_cache=/tmp/.npm'
                    reuseNode true
                }
            }

            steps {
                dir("${PROJECT_DIR}") {
                    sh '''
                        set -eu

                        rm -rf dist artifacts
                        npm run build

                        test -f dist/index.js
                        test -f dist/package.json
                    '''
                }
            }
        }

        stage('Verify') {
            parallel {
                stage('Test') {
                    agent {
                        docker {
                            image 'node:20.18.1'
                            args '-e HOME=/tmp -e npm_config_cache=/tmp/.npm'
                            reuseNode true
                        }
                    }

                    steps {
                        dir("${PROJECT_DIR}") {
                            sh '''
                                set -eu
                                npm test
                            '''
                        }
                    }
                }

                stage('Security Audit') {
                    agent {
                        docker {
                            image 'node:20.18.1'
                            args '-e HOME=/tmp -e npm_config_cache=/tmp/.npm'
                            reuseNode true
                        }
                    }

                    steps {
                        dir("${PROJECT_DIR}") {
                            sh '''
                                set -eu
                                npm audit --omit=dev --audit-level=high
                            '''
                        }
                    }
                }
            }
        }

        stage('Archive') {
            agent {
                docker {
                    image 'node:20.18.1'
                    args '-e HOME=/tmp -e npm_config_cache=/tmp/.npm'
                    reuseNode true
                }
            }

            steps {
                dir("${PROJECT_DIR}") {
                    sh '''
                        set -eu

                        mkdir -p "${ARTIFACT_DIRECTORY}"

                        npm version "${PACKAGE_VERSION}" \
                          --no-git-tag-version \
                          --allow-same-version

                        npm pack \
                          --pack-destination "${ARTIFACT_DIRECTORY}"

                        tar -tzf "${ARTIFACT_DIRECTORY}/${APP_NAME}-${PACKAGE_VERSION}.tgz"

                        test -f \
                          "${ARTIFACT_DIRECTORY}/${APP_NAME}-${PACKAGE_VERSION}.tgz"
                    '''

                    archiveArtifacts(
                        artifacts: "${ARTIFACT_DIRECTORY}/*.tgz",
                        fingerprint: true,
                        onlyIfSuccessful: true
                    )
                }
            }
        }

        stage('Publish') {
            agent {
                docker {
                    image 'node:20.18.1'
                    args '-e HOME=/tmp -e npm_config_cache=/tmp/.npm'
                    reuseNode true
                }
            }

            steps {
                dir("${PROJECT_DIR}") {
                    withCredentials([
                        usernamePassword(
                            credentialsId: "${NEXUS_CREDENTIAL_ID}",
                            usernameVariable: 'NEXUS_USERNAME',
                            passwordVariable: 'NEXUS_PASSWORD'
                        )
                    ]) {
                        sh '''
                            set -eu
                            set +x

                            cleanup_npmrc() {
                                rm -f .npmrc
                            }

                            trap cleanup_npmrc EXIT

                            AUTH_SCOPE=$(
                                printf '%s' "${NEXUS_REGISTRY}" |
                                sed -E 's#^https?://##'
                            )

                            AUTH_TOKEN=$(
                                printf '%s:%s' \
                                  "${NEXUS_USERNAME}" \
                                  "${NEXUS_PASSWORD}" |
                                base64 |
                                tr -d '\\n'
                            )

                            cat > .npmrc <<NPMRC
registry=${NEXUS_REGISTRY}
//${AUTH_SCOPE}:_auth=${AUTH_TOKEN}
always-auth=true
email=ci@kijanikiosk.local
NPMRC

                            PACKAGE_FILE="./${ARTIFACT_DIRECTORY}/${APP_NAME}-${PACKAGE_VERSION}.tgz"

                            test -f "${PACKAGE_FILE}"

                            npm publish "${PACKAGE_FILE}" \
                              --registry "${NEXUS_REGISTRY}"

                            rm -f .npmrc
                            trap - EXIT
                        '''
                    }
                }
            }
        }

        stage('Build Container Image') {
            agent any

            steps {
                script {
                    env.CONTAINER_IMAGE =
                        "kijanikiosk-payments:${env.GIT_SHORT_SHA}"
                }

                sh '''
                    set -eu

                    echo "Building ${CONTAINER_IMAGE}"

                    docker build                       -f week8/deployment-pipeline/containers/Dockerfile.production                       -t "${CONTAINER_IMAGE}"                       "${PROJECT_DIR}"

                    echo "Loading ${CONTAINER_IMAGE} into Minikube"

                    docker save "${CONTAINER_IMAGE}" |
                    docker exec -i minikube docker load
                '''
            }
        }

        stage('Deploy Staging') {
            agent any

            steps {
                sh '''
                    set -eu

                    echo "Deploying to staging..."

                    kubectl apply -k "${STAGING_OVERLAY}"

                    kubectl set image                       deployment/kk-payments                       "${CONTAINER_NAME}=${CONTAINER_IMAGE}"                       -n "${STAGING_NAMESPACE}"

                    kubectl rollout status                       deployment/kk-payments                       -n "${STAGING_NAMESPACE}"                       --timeout=120s
                '''
            }
        }

        stage('Staging Smoke Test') {
            agent any

            steps {
                sh '''
                    set -eu

                    echo "Running staging smoke test..."

                    kubectl run                       "jenkins-smoke-${BUILD_NUMBER}"                       --rm                       -i                       --restart=Never                       --image=curlimages/curl                       -n "${STAGING_NAMESPACE}"                       -- curl -fsS                       "http://${STAGING_SERVICE}:${STAGING_PORT}/health"

                    echo "Staging smoke test passed."
                '''
            }
        }

        stage('Production Approval') {
            agent none

            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    input(
                        message: 'Staging passed. Deploy to production?',
                        ok: 'Deploy Production'
                    )
                }
            }
        }

        stage('Deploy Production') {
            agent any

            steps {
                sh '''
                    set -eu

                    echo "Deploying to production..."

                    kubectl apply -k "${PROD_OVERLAY}"

                    kubectl set image                       deployment/kk-payments                       "${CONTAINER_NAME}=${CONTAINER_IMAGE}"                       -n "${PROD_NAMESPACE}"

                    kubectl rollout status                       deployment/kk-payments                       -n "${PROD_NAMESPACE}"                       --timeout=120s
                '''
            }
        }

        stage('Production Verification') {
            agent any

            steps {
                sh '''
                    set -eu

                    echo "Running production verification..."

                    kubectl run                       "jenkins-prod-check-${BUILD_NUMBER}"                       --rm                       -i                       --restart=Never                       --image=curlimages/curl                       -n "${PROD_NAMESPACE}"                       -- curl -fsS                       "http://${PROD_SERVICE}:${PROD_PORT}/health"

                    echo "Production verification passed."
                '''
            }
        }
    }

    post {
        always {
            echo "Pipeline finished with status: ${currentBuild.currentResult}"

            node('built-in') {
                junit(
                    testResults: "${PROJECT_DIR}/${TEST_RESULT_FILE}",
                    allowEmptyResults: true
                )

                cleanWs(
                    deleteDirs: true,
                    notFailBuild: true
                )
            }
        }

        success {
            echo """
            Pipeline completed successfully.

            Version:
            ${PACKAGE_VERSION}

            Artifact:
            ${params.NEXUS_URL}/repository/${NEXUS_REPOSITORY}/${APP_NAME}/-/${APP_NAME}-${PACKAGE_VERSION}.tgz
            """
        }

        failure {
            echo """
            Pipeline failed.

            Build:
            ${BUILD_URL}

            Review the first failed stage before merging this change.
            """
        }

        changed {
            echo """
            Pipeline status changed from:
            ${currentBuild.previousBuild?.result ?: 'UNKNOWN'}

            To:
            ${currentBuild.currentResult}
            """
        }
    }
}
