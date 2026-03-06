pipeline {
    agent none
    environment {
        PROJECT_NAME = 'arcana-ios'
        VERSION      = '1.0.0'
        SQ_URL       = 'http://sonarqube:9000/sonarqube'
        SQ_TOKEN     = 'squ_5ce2319b9d8ca2b1db4e0f5bdf36b34249561f18'
    }
    options {
        timeout(time: 90, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    stages {
        stage('Checkout') {
            agent { label 'macos' }
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
            agent { label 'macos' }
            steps {
                sh '''
                    export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
                    set -o pipefail
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
            agent { label 'macos' }
            steps {
                sh '''
                    export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
                    caffeinate -i &
                    CAFFEINE_PID=$!

                    DERIVED=${HOME}/jenkins-agent/DerivedData/arcana-ios

                    SIM_ID=$(xcrun simctl list devices available | grep "iPhone 17" | grep -v unavailable | head -1 | grep -oE '[0-9A-F-]{36}' | head -1)
                    if [ -n "$SIM_ID" ]; then
                        xcrun simctl boot "$SIM_ID" 2>/dev/null || true
                    fi

                    # Use explicit result bundle path so python script always gets a fresh xcresult
                    XCRESULT=/tmp/arcana-ios-tests.xcresult
                    rm -rf "${XCRESULT}"
                    # Note: macOS has no GNU timeout; use perl alarm instead (40min max)
                    xcodebuild \
                        -project arcana-ios.xcodeproj \
                        -scheme arcana-ios \
                        -destination 'platform=iOS Simulator,name=iPhone 17' \
                        -enableCodeCoverage YES \
                        -derivedDataPath "${DERIVED}" \
                        -resultBundlePath "${XCRESULT}" \
                        -skipPackagePluginValidation \
                        test > /tmp/xcode-test.log 2>&1 || true
                    echo "=== xcode-test.log (last 40 lines) ==="
                    tail -40 /tmp/xcode-test.log 2>/dev/null || echo "(log missing or empty)"
                    echo "=== ERRORS ONLY ===" && grep -E "error:|Build FAILED" /tmp/xcode-test.log 2>/dev/null | head -20 || true

                    python3 scripts/xcresult_to_sonar_coverage.py "${XCRESULT}" coverage-report.xml \
                        || echo "Coverage conversion failed (non-fatal)"

                    kill $CAFFEINE_PID 2>/dev/null || true
                '''
                // Stash coverage + sources for sonar stage on master
                stash includes: 'coverage-report.xml,arcana-ios/Sources/**,arcana-iosTests/**,sonar-project.properties', name: 'sonar-inputs', allowEmpty: true
            }
        }
        stage('SonarQube Analysis') {
            // Run on Jenkins built-in node (has Docker + devops_default network = SonarQube access)
            agent { label 'built-in' }
            steps {
                unstash 'sonar-inputs'
                // Use official sonar-scanner Docker image v6 on devops_default network
                // This bypasses /api/batch/project bug in Homebrew sonar-scanner 8.0.1
                sh '''
                    echo "=== Workspace contents ===" && ls -la "${WORKSPACE}/" | head -20 || true
                    echo "=== Sources dir ===" && ls "${WORKSPACE}/arcana-ios/Sources/" 2>/dev/null || echo "MISSING"
                    docker run --rm \
                        --network devops_default \
                        -e SONAR_HOST_URL=http://sonarqube:9000/sonarqube \
                        -e SONAR_TOKEN="${SQ_TOKEN}" \
                        -v "${WORKSPACE}:/usr/src" \
                        sonarsource/sonar-scanner-cli:11 \
                        -Dsonar.projectKey=ios-app \
                        "-Dsonar.projectName=iOS App" \
                        -Dsonar.sources=arcana-ios/Sources \
                        "-Dsonar.exclusions=**/DerivedData/**,**/*.xcassets/**,**/build/**" \
                        "-Dsonar.coverage.exclusions=**/Mocks/**,**/*Mock*.swift,**/*Stub*.swift" \
                        -Dsonar.coverageReportPaths=coverage-report.xml \
                        -Dsonar.scm.disabled=true
                '''
            }
        }
    }
    post {
        success { echo "iOS build OK: ${PROJECT_NAME} v${VERSION}" }
        failure { echo "iOS build FAILED: ${PROJECT_NAME}" }
        always  { echo "Build ${BUILD_NUMBER} done" }
    }
}
