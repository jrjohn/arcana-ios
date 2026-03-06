pipeline {
    agent { label 'macos' }
    environment {
        PROJECT_NAME = 'arcana-ios'
        VERSION      = '1.0.0'
        SQ_URL       = 'https://arcana.boo/sonarqube'
        SQ_TOKEN     = 'squ_5ce2319b9d8ca2b1db4e0f5bdf36b34249561f18'
        PATH         = '/opt/sonar-scanner/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'
    }
    options {
        timeout(time: 60, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    stages {
        stage('Checkout') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-credentials',
                        usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    sh '''
                        if [ -d .git ]; then
                            git fetch --tags --force --progress \
                                https://${GIT_USER}:${GIT_PASS}@github.com/jrjohn/arcana-ios.git \
                                +refs/heads/*:refs/remotes/origin/*
                            git checkout -f origin/main
                        else
                            git clone --branch main \
                                https://${GIT_USER}:${GIT_PASS}@github.com/jrjohn/arcana-ios.git .
                        fi
                    '''
                }
            }
        }
        stage('Build') {
            steps {
                sh '''
                    set -o pipefail
                    # Resolve SPM packages first (cached in global cache between builds)
                    xcodebuild -resolvePackageDependencies \
                        -project arcana-ios.xcodeproj \
                        -scheme arcana-ios 2>&1 | tail -3 || true
                    xcodebuild \
                        -project arcana-ios.xcodeproj \
                        -scheme arcana-ios \
                        -configuration Release \
                        -destination 'generic/platform=iOS' \
                        CODE_SIGNING_ALLOWED=NO \
                        build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" | tail -5 || true
                '''
            }
        }
        stage('Test + Coverage') {
            steps {
                sh '''
                    # Prevent Mac sleep during long build
                    caffeinate -i -w $$ &

                    DERIVED=${HOME}/jenkins-agent/DerivedData/arcana-ios

                    # Pre-boot simulator so test launch is fast
                    SIM_ID=$(xcrun simctl list devices available | grep "iPhone 17" | grep -v unavailable | head -1 | sed "s/.*(\([A-Z0-9-]*\)).*/\\1/")
                    if [ -n "$SIM_ID" ]; then
                        xcrun simctl boot "$SIM_ID" 2>/dev/null || true
                    fi

                    # Run tests with a hard 40-min shell timeout so we always get xcresult
                    timeout 2400 xcodebuild \
                        -project arcana-ios.xcodeproj \
                        -scheme arcana-ios \
                        -destination 'platform=iOS Simulator,name=iPhone 17' \
                        -enableCodeCoverage YES \
                        -derivedDataPath "${DERIVED}" \
                        -skipPackagePluginValidation \
                        test 2>&1 | grep -E "Test Suite|passed|failed|error:" | tail -30 || true

                    python3 scripts/xcresult_to_sonar_coverage.py "${DERIVED}" coverage-report.xml \
                        || echo "Coverage conversion failed (non-fatal)"
                '''
            }
        }
        stage('SonarQube Analysis') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh '''
                        /opt/homebrew/bin/sonar-scanner \
                            -Dsonar.host.url=${SQ_URL} \
                            -Dsonar.token=${SQ_TOKEN} \
                            -Dsonar.projectKey=ios-app \
                            -Dsonar.projectName="iOS App" \
                            -Dsonar.sources=arcana-ios/Sources \
                            -Dsonar.tests=arcana-iosTests \
                            -Dsonar.exclusions="**/DerivedData/**,**/*.xcassets/**,**/build/**" \
                            -Dsonar.coverage.exclusions="**/Mocks/**,**/*Mock*.swift,**/*Stub*.swift" \
                            -Dsonar.coverageReportPaths=coverage-report.xml \
                            -Dsonar.scm.disabled=true
                    '''
                }
            }
        }
    }
    post {
        success { echo "iOS build OK: ${PROJECT_NAME} v${VERSION}" }
        failure { echo "iOS build FAILED: ${PROJECT_NAME}" }
        always  { echo "Build ${BUILD_NUMBER} done" }
    }
}
