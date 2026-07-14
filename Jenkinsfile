pipeline {
    agent {
        docker {
            image 'node:20.18.1'
            args '-e HOME=/tmp -e npm_config_cache=/tmp/.npm'
            reuseNode true
        }
    }

    parameters {
        string(
            name: 'NEXUS_URL',
            defaultValue: 'http://192.168.100.6:8081',
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
    }

    options {
        timeout(time: 10, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {
        stage('Lint') {
            steps {
                dir("${PROJECT_DIR}") {
                    script {
                        env.GIT_SHORT_SHA = sh(
                            script: 'git rev-parse --short=8 HEAD',
                            returnStdout: true
                        ).trim()

                        env.PACKAGE_VERSION =
                            "${env.BASE_VERSION}-${env.GIT_SHORT_SHA}"

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
    }

    post {
        always {
            junit(
                testResults: "${PROJECT_DIR}/${TEST_RESULT_FILE}",
                allowEmptyResults: true
            )

            echo "Pipeline finished with status: ${currentBuild.currentResult}"

            cleanWs(
                deleteDirs: true,
                notFailBuild: true
            )
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
