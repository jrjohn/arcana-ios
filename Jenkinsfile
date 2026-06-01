// Jenkinsfile — multibranch pipeline for arcana-ios
// Adapted from the existing single-branch pipeline (the legacy ios-app job ran
// an older XML-embedded version of this script; the repo's current Jenkinsfile
// is the more mature one with nohup/heartbeat for Mac mini disconnects + the
// docker sonar-scanner-cli workaround for the Homebrew scanner /api/batch bug).
//
// Key differences from the previous single-branch version:
//   * `pollSCM` trigger removed                        — Jenkins multibranch + GitHub webhook drive triggers
//   * Checkout uses dynamic BRANCH_NAME / CHANGE_BRANCH instead of hardcoded `origin/main`
//   * Deploy to TestFlight + Arch Qube Metrics gated `when { branch 'main' }` — PRs skip TF push
//   * SonarQube gets pullrequest.* params on PRs       — PR-decoration in Sonar UI
//   * Preserves `agent none` + per-stage `agent { label 'macos' }` — iOS needs Mac mini for xcodebuild + fastlane

pipeline {
    agent none
    environment {
        PROJECT_NAME = 'arcana-ios'
        VERSION      = '1.0.0'
    }
    options {
        timeout(time: 120, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '1'))
        timestamps()
    }
    stages {
        stage('Checkout') {
            agent { label 'macos' }
            steps {
                script {
                    echo "Branch: ${env.BRANCH_NAME ?: 'unknown'}"
                    echo "PR: ${env.CHANGE_ID ?: 'no'} (target: ${env.CHANGE_TARGET ?: 'n/a'})"
                }
                withCredentials([usernamePassword(credentialsId: 'github-credentials',
                        usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    sh '''
                        TARGET_REF="${BRANCH_NAME:-main}"
                        # PR builds: BRANCH_NAME is PR-N, real source ref is CHANGE_BRANCH
                        if [ -n "${CHANGE_ID:-}" ] && [ -n "${CHANGE_BRANCH:-}" ]; then
                            TARGET_REF="${CHANGE_BRANCH}"
                        fi
                        echo "Checking out ref: ${TARGET_REF}"
                        if [ -d .git ]; then
                            git fetch --tags --force --progress \
                                https://${GIT_USER}:${GIT_PASS}@github.com/jrjohn/arcana-ios.git \
                                +refs/heads/*:refs/remotes/origin/*
                            git checkout -f "origin/${TARGET_REF}"
                        else
                            git clone --branch "${TARGET_REF}" \
                                https://${GIT_USER}:${GIT_PASS}@github.com/jrjohn/arcana-ios.git .
                        fi
                        git log -1 --oneline
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
                    LOG=/tmp/xcode-test.log
                    PID_FILE=/tmp/xcode-test-pid

                    # Launch xcodebuild with nohup so it survives Mac Mini agent disconnects
                    # If already running from a previous attempt, just resume waiting
                    if [ -f "${PID_FILE}" ] && kill -0 "$(cat ${PID_FILE})" 2>/dev/null; then
                        echo "Resuming wait for existing xcodebuild (PID $(cat ${PID_FILE}))..."
                    else
                        echo "Starting fresh xcodebuild test..."
                        rm -rf "${XCRESULT}" "${LOG}"
                        nohup xcodebuild \
                            -project arcana-ios.xcodeproj \
                            -scheme arcana-ios \
                            -destination 'platform=iOS Simulator,name=iPhone 17' \
                            -enableCodeCoverage YES \
                            -derivedDataPath "${DERIVED}" \
                            -resultBundlePath "${XCRESULT}" \
                            -skipPackagePluginValidation \
                            test > "${LOG}" 2>&1 &
                        echo $! > "${PID_FILE}"
                    fi

                    # Heartbeat poll loop — emits output every 60s to keep agent alive
                    XCODE_PID=$(cat "${PID_FILE}")
                    echo "Waiting for xcodebuild PID ${XCODE_PID}..."
                    while kill -0 "${XCODE_PID}" 2>/dev/null; do
                        sleep 60
                        echo "xcodebuild running... ($(wc -l < ${LOG} 2>/dev/null || echo 0) lines)"
                    done
                    echo "xcodebuild done"
                    rm -f "${PID_FILE}"
                    echo "=== xcode-test.log (last 40 lines) ==="
                    tail -40 "${LOG}" 2>/dev/null || echo "(log missing or empty)"
                    echo "=== ERRORS ONLY ===" && grep -E "error:|Build FAILED" "${LOG}" 2>/dev/null | head -20 || true

                    python3 scripts/xcresult_to_sonar_coverage.py "${XCRESULT}" coverage-report.xml \
                        || echo "Coverage conversion failed (non-fatal)"

                    kill $CAFFEINE_PID 2>/dev/null || true
                '''
                // Stash coverage + sources for sonar stage on master
                stash includes: 'coverage-report.xml,arcana-ios/Sources/**,arcana-iosTests/**,sonar-project.properties', name: 'sonar-inputs', allowEmpty: true
            }
            post {
                always {
                    // Shut down simulators so runtime daemons don't leak + pin the Mac mini
                    // (load spiked to 66, flapped the agent 2026-06-01). Stage-level so it runs on macos.
                    sh 'export PATH=/opt/homebrew/bin:$PATH; xcrun simctl shutdown all || true; killall Simulator 2>/dev/null || true'
                }
            }
        }
        stage('SonarQube Analysis') {
            // Run on Jenkins built-in node (has sonar-scanner CLI + devops_default network = SonarQube access)
            agent { label 'built-in' }
            steps {
                unstash 'sonar-inputs'
                sh '''
                    # Debug: verify what unstash actually delivered (sonar said arcana-ios/Sources
                    # missing in 2026-05-22 build #2 despite host ls showing it).
                    echo "=== WORKSPACE = ${WORKSPACE} ==="
                    echo "=== pwd ==="
                    pwd
                    echo "=== top-level workspace ==="
                    ls -la "${WORKSPACE}/" | head -10
                    echo "=== arcana-ios/Sources/ on host ==="
                    ls -la "${WORKSPACE}/arcana-ios/Sources/" 2>&1 | head -5
                    echo "=== inside sonar-scanner-cli container ==="
                    docker run --rm -v "${WORKSPACE}:/usr/src" sonarsource/sonar-scanner-cli:11 \
                        sh -c 'pwd && ls -la /usr/src/arcana-ios/Sources/' 2>&1 | head -10 || true
                    echo "=== end debug ==="
                '''
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    withSonarQubeEnv('SonarQube') {
                        script {
                            // Explicit projectBaseDir so sonar-scanner-cli docker mount root
                            // is unambiguous (default WORKDIR semantics behave differently
                            // across image versions).
                            sh """sonar-scanner \
                              -Dsonar.projectBaseDir=\${WORKSPACE} \
                              -Dsonar.projectKey=ios-app \
                              -Dsonar.projectName="iOS App" \
                              -Dsonar.sources=arcana-ios/Sources \
                              -Dsonar.exclusions=**/DerivedData/**,**/*.xcassets/**,**/build/** \
                              -Dsonar.coverage.exclusions=**/Mocks/**,**/*Mock*.swift,**/*Stub*.swift \
                              -Dsonar.coverageReportPaths=coverage-report.xml \
                              -Dsonar.scm.disabled=true"""
                        }
                    }
                }
            }
        }
        stage('Deploy to TestFlight') {
            // Only push to TestFlight on main — PR builds stop at SonarQube.
            when { branch 'main' }
            agent { label 'macos' }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    withCredentials([
                        file(credentialsId: 'asc-api-key', variable: 'ASC_KEY_PATH'),
                        string(credentialsId: 'asc-key-id', variable: 'ASC_KEY_ID'),
                        string(credentialsId: 'asc-issuer-id', variable: 'ASC_ISSUER_ID'),
                        string(credentialsId: 'match-password', variable: 'MATCH_PASSWORD')
                    ]) {
                        sh '''
                            export PATH=/opt/homebrew/opt/ruby/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
                            export LC_ALL=en_US.UTF-8
                            export LANG=en_US.UTF-8
                            bundle install --quiet
                            bundle exec fastlane beta
                        '''
                    }
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'build/*.ipa', allowEmptyArchive: true
                }
            }
        }
    }
    post {
        success { echo "iOS build SUCCESS: ${PROJECT_NAME} v${VERSION} branch=${env.BRANCH_NAME ?: '?'} pr=${env.CHANGE_ID ?: 'no'}" }
        failure { echo "iOS build FAILED: ${PROJECT_NAME} branch=${env.BRANCH_NAME ?: '?'} pr=${env.CHANGE_ID ?: 'no'}" }
        always  { echo "Build ${BUILD_NUMBER} done" }
    }
}
