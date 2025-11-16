#!/bin/bash

# 실습: Minimal Image 보안 분석 자동화 스크립트

set -e  # 에러 발생 시 중단

echo "🚀 실습 시작!"
echo "================================"

# 결과 디렉토리 생성
mkdir -p results

# 1️⃣ 이미지 다운로드
echo ""
echo "📥 1단계: Docker 이미지 다운로드 중..."
docker pull nginx:latest
docker pull nginx:alpine

# 취약점 예시용 이미지 (vulhub/nginx:1.13.2로 고정)
VULN_IMAGE="vulhub/nginx:1.13.2"
echo "  취약점 예시 이미지: $VULN_IMAGE"
docker pull "$VULN_IMAGE"

echo ""
echo "📊 이미지 크기 비교:"
echo "  nginx:latest:        $(docker images nginx:latest --format '{{.Size}}' | head -1)"
echo "  nginx:alpine:        $(docker images nginx:alpine --format '{{.Size}}' | head -1)"
echo "  vulhub/nginx:1.13.2: $(docker images vulhub/nginx:1.13.2 --format '{{.Size}}' | head -1)"

# 2️⃣ Trivy 취약점 스캔
echo ""
echo "🔍 2단계: Trivy 취약점 스캔 중..."
TRIVY_TIMEOUT=${TRIVY_TIMEOUT:-"10m"}  # 기본 타임아웃 10분

echo "  - nginx:latest 스캔 중... (이 작업은 몇 분이 걸릴 수 있습니다)"
if trivy image --timeout "$TRIVY_TIMEOUT" nginx:latest > results/latest-report.txt 2>&1; then
    echo "    ✅ nginx:latest 스캔 완료"
else
    echo "    ⚠️  nginx:latest 스캔 중 오류 발생 (결과 파일 확인 필요)"
fi

echo "  - nginx:alpine 스캔 중..."
if trivy image --timeout "$TRIVY_TIMEOUT" nginx:alpine > results/alpine-report.txt 2>&1; then
    echo "    ✅ nginx:alpine 스캔 완료"
else
    echo "    ⚠️  nginx:alpine 스캔 중 오류 발생 (결과 파일 확인 필요)"
fi

echo "  - $VULN_IMAGE 스캔 중... (오래된 버전 - 취약점 예시)"
if trivy image --timeout "$TRIVY_TIMEOUT" "$VULN_IMAGE" > results/old-version-report.txt 2>&1; then
    echo "    ✅ $VULN_IMAGE 스캔 완료"
else
    echo "    ⚠️  $VULN_IMAGE 스캔 중 오류 발생 (결과 파일 확인 필요)"
fi

# 스캔 결과 검증 및 취약점 개수 추출
echo ""
echo "📊 스캔 결과 검증 중..."

# nginx:latest 결과 확인
# "Total:" 또는 "Report Summary"가 있으면 완전한 스캔으로 간주
if grep -qE "(Total:|Report Summary)" results/latest-report.txt 2>/dev/null; then
    # 취약점 개수는 요약줄의 "CRITICAL: N"에서 정확히 파싱 (요약줄이 없으면 0)
    if grep -q "^Total:" results/latest-report.txt 2>/dev/null; then
        LATEST_CRITICAL=$(grep -m1 -o 'CRITICAL: [0-9]\+' results/latest-report.txt 2>/dev/null | awk '{print $2}')
        LATEST_CRITICAL=${LATEST_CRITICAL:-0}
    else
        LATEST_CRITICAL="0"
    fi
    echo "  ✅ nginx:latest 스캔 결과 확인됨"
else
    LATEST_CRITICAL="0"
    echo "  ⚠️  nginx:latest 스캔 결과가 불완전할 수 있습니다"
fi

# nginx:alpine 결과 확인
# "Total:" 또는 "Report Summary"가 있으면 완전한 스캔으로 간주
if grep -qE "(Total:|Report Summary)" results/alpine-report.txt 2>/dev/null; then
    # 취약점 개수는 요약줄의 "CRITICAL: N"에서 정확히 파싱 (요약줄이 없으면 0)
    if grep -q "^Total:" results/alpine-report.txt 2>/dev/null; then
        ALPINE_CRITICAL=$(grep -m1 -o 'CRITICAL: [0-9]\+' results/alpine-report.txt 2>/dev/null | awk '{print $2}')
        ALPINE_CRITICAL=${ALPINE_CRITICAL:-0}
    else
        ALPINE_CRITICAL="0"
    fi
    echo "  ✅ nginx:alpine 스캔 결과 확인됨"
else
    ALPINE_CRITICAL="0"
    echo "  ⚠️  nginx:alpine 스캔 결과가 불완전할 수 있습니다"
fi

# 오래된 버전 결과 확인
# "Total:" 또는 "Report Summary"가 있으면 완전한 스캔으로 간주
if grep -qE "(Total:|Report Summary)" results/old-version-report.txt 2>/dev/null; then
    # 취약점 개수는 요약줄의 "CRITICAL: N"에서 정확히 파싱 (요약줄이 없으면 0)
    if grep -q "^Total:" results/old-version-report.txt 2>/dev/null; then
        OLD_CRITICAL=$(grep -m1 -o 'CRITICAL: [0-9]\+' results/old-version-report.txt 2>/dev/null | awk '{print $2}')
        OLD_CRITICAL=${OLD_CRITICAL:-0}
    else
        OLD_CRITICAL="0"
    fi
    echo "  ✅ $VULN_IMAGE 스캔 결과 확인됨"
else
    OLD_CRITICAL="0"
    echo "  ⚠️  $VULN_IMAGE 스캔 결과가 불완전할 수 있습니다"
fi

echo ""
echo "📈 Critical 취약점 개수:"
echo "  - nginx:latest: ${LATEST_CRITICAL}개"
echo "  - nginx:alpine: ${ALPINE_CRITICAL}개"
echo "  - $VULN_IMAGE:   ${OLD_CRITICAL}개 (오래된 버전)"

# 3️⃣ SBOM 생성
echo ""
echo "📦 3단계: SBOM 생성 중..."
echo "  - nginx:latest SBOM 생성 (JSON)..."
syft nginx:latest -o json > results/sbom-nginx-latest.json 2>&1 || echo "⚠️  syft가 설치되지 않았습니다."

echo "  - nginx:alpine SBOM 생성 (JSON)..."
syft nginx:alpine -o json > results/sbom-nginx-alpine.json 2>&1 || echo "⚠️  syft가 설치되지 않았습니다."

echo "  - vulhub/nginx:1.13.2 SBOM 생성 (JSON)..."
syft vulhub/nginx:1.13.2 -o json > results/sbom-vulhub-nginx.json 2>&1 || echo "⚠️  syft가 설치되지 않았습니다."

echo "  - nginx:latest SBOM 생성 (Table)..."
syft nginx:latest -o table > results/sbom-nginx-latest-table.txt 2>&1 || echo "⚠️  syft가 설치되지 않았습니다."

echo "  - nginx:alpine SBOM 생성 (Table)..."
syft nginx:alpine -o table > results/sbom-nginx-alpine-table.txt 2>&1 || echo "⚠️  syft가 설치되지 않았습니다."

echo "  - vulhub/nginx:1.13.2 SBOM 생성 (Table)..."
syft vulhub/nginx:1.13.2 -o table > results/sbom-vulhub-nginx-table.txt 2>&1 || echo "⚠️  syft가 설치되지 않았습니다."

# 4️⃣ SBOM 기반 취약점 분석
echo ""
echo "🔎 4단계: SBOM 기반 취약점 분석 중..."
if [ -f results/sbom-nginx-latest.json ]; then
    echo "  - nginx:latest SBOM 기반 취약점 분석..."
    grype sbom:results/sbom-nginx-latest.json > results/vulns-from-sbom-latest.txt 2>&1 || echo "⚠️  grype가 설치되지 않았습니다."
else
    echo "  ⚠️  nginx:latest SBOM 파일이 없어 grype 분석을 건너뜁니다."
fi

if [ -f results/sbom-nginx-alpine.json ]; then
    echo "  - nginx:alpine SBOM 기반 취약점 분석..."
    grype sbom:results/sbom-nginx-alpine.json > results/vulns-from-sbom-alpine.txt 2>&1 || echo "⚠️  grype가 설치되지 않았습니다."
else
    echo "  ⚠️  nginx:alpine SBOM 파일이 없어 grype 분석을 건너뜁니다."
fi

if [ -f results/sbom-vulhub-nginx.json ]; then
    echo "  - vulhub/nginx:1.13.2 SBOM 기반 취약점 분석..."
    grype sbom:results/sbom-vulhub-nginx.json > results/vulns-from-sbom-vulhub.txt 2>&1 || echo "⚠️  grype가 설치되지 않았습니다."
else
    echo "  ⚠️  vulhub/nginx:1.13.2 SBOM 파일이 없어 grype 분석을 건너뜁니다."
fi

# 5️⃣ 결과 비교 요약 생성
echo ""
echo "📋 5단계: 결과 요약 생성 중..."

# 이미지 크기 추출 (공백 제거)
LATEST_SIZE=$(docker images nginx:latest --format "{{.Size}}" | head -1 | xargs || echo "N/A")
ALPINE_SIZE=$(docker images nginx:alpine --format "{{.Size}}" | head -1 | xargs || echo "N/A")
OLD_SIZE=$(docker images "$VULN_IMAGE" --format "{{.Size}}" | head -1 | xargs || echo "N/A")

# SBOM 패키지 수 추출 (JSON이 있는 경우)
if [ -f results/sbom-nginx-latest.json ]; then
    LATEST_PACKAGES=$(cat results/sbom-nginx-latest.json | grep -o '"name"' | wc -l | xargs || echo "0")
    LATEST_PACKAGES=${LATEST_PACKAGES:-0}
else
    LATEST_PACKAGES="N/A"
fi

if [ -f results/sbom-nginx-alpine.json ]; then
    ALPINE_PACKAGES=$(cat results/sbom-nginx-alpine.json | grep -o '"name"' | wc -l | xargs || echo "0")
    ALPINE_PACKAGES=${ALPINE_PACKAGES:-0}
else
    ALPINE_PACKAGES="N/A"
fi

if [ -f results/sbom-vulhub-nginx.json ]; then
    VULHUB_PACKAGES=$(cat results/sbom-vulhub-nginx.json | grep -o '"name"' | wc -l | xargs || echo "0")
    VULHUB_PACKAGES=${VULHUB_PACKAGES:-0}
else
    VULHUB_PACKAGES="N/A"
fi

# SBOM 기반 취약점 분석 결과 추출 (Grype)
# Critical 취약점 개수
if [ -f results/vulns-from-sbom-latest.txt ]; then
    LATEST_SBOM_CRITICAL=$(grep -c "Critical" results/vulns-from-sbom-latest.txt 2>/dev/null | xargs || echo "0")
    LATEST_SBOM_CRITICAL=${LATEST_SBOM_CRITICAL:-0}
    LATEST_SBOM_HIGH=$(grep -c "High" results/vulns-from-sbom-latest.txt 2>/dev/null | xargs || echo "0")
    LATEST_SBOM_HIGH=${LATEST_SBOM_HIGH:-0}
else
    LATEST_SBOM_CRITICAL="N/A"
    LATEST_SBOM_HIGH="N/A"
fi

if [ -f results/vulns-from-sbom-alpine.txt ]; then
    ALPINE_SBOM_CRITICAL=$(grep -c "Critical" results/vulns-from-sbom-alpine.txt 2>/dev/null | xargs || echo "0")
    ALPINE_SBOM_CRITICAL=${ALPINE_SBOM_CRITICAL:-0}
    ALPINE_SBOM_HIGH=$(grep -c "High" results/vulns-from-sbom-alpine.txt 2>/dev/null | xargs || echo "0")
    ALPINE_SBOM_HIGH=${ALPINE_SBOM_HIGH:-0}
else
    ALPINE_SBOM_CRITICAL="N/A"
    ALPINE_SBOM_HIGH="N/A"
fi

if [ -f results/vulns-from-sbom-vulhub.txt ]; then
    VULHUB_SBOM_CRITICAL=$(grep -c "Critical" results/vulns-from-sbom-vulhub.txt 2>/dev/null | xargs || echo "0")
    VULHUB_SBOM_CRITICAL=${VULHUB_SBOM_CRITICAL:-0}
    VULHUB_SBOM_HIGH=$(grep -c "High" results/vulns-from-sbom-vulhub.txt 2>/dev/null | xargs || echo "0")
    VULHUB_SBOM_HIGH=${VULHUB_SBOM_HIGH:-0}
else
    VULHUB_SBOM_CRITICAL="N/A"
    VULHUB_SBOM_HIGH="N/A"
fi

cat > results/comparison-summary.txt << EOF
========================================
실습 결과 요약
========================================

📦 이미지 크기 비교
  nginx:latest:        ${LATEST_SIZE}
  nginx:alpine:        ${ALPINE_SIZE}
  vulhub/nginx:1.13.2: ${OLD_SIZE} (취약점 예시 이미지)

🔍 Trivy 스캔 - Critical 취약점 개수
  nginx:latest:        ${LATEST_CRITICAL}개
  nginx:alpine:        ${ALPINE_CRITICAL}개
  vulhub/nginx:1.13.2: ${OLD_CRITICAL}개 (취약점 예시 이미지)

📊 SBOM 패키지 수
  nginx:latest:        ${LATEST_PACKAGES}개
  nginx:alpine:        ${ALPINE_PACKAGES}개
  vulhub/nginx:1.13.2: ${VULHUB_PACKAGES}개

🔎 SBOM 기반 분석 (Grype) - Critical 취약점 개수
  nginx:latest:        ${LATEST_SBOM_CRITICAL}개
  nginx:alpine:        ${ALPINE_SBOM_CRITICAL}개
  vulhub/nginx:1.13.2: ${VULHUB_SBOM_CRITICAL}개

🔎 SBOM 기반 분석 (Grype) - High 취약점 개수
  nginx:latest:        ${LATEST_SBOM_HIGH}개
  nginx:alpine:        ${ALPINE_SBOM_HIGH}개
  vulhub/nginx:1.13.2: ${VULHUB_SBOM_HIGH}개

========================================
결론
========================================
Minimal Image (Alpine) 사용 시:
- 이미지 크기 감소로 빌드/배포 속도 향상
- 공격 표면 감소로 보안 취약점 감소
- SBOM을 통한 공급망 가시성 확보

⚠️  취약점이 포함된 이미지 예시:
- vulhub/nginx:1.13.2는 vulhub 프로젝트의 취약점 테스트 이미지로 의도적으로 취약점이 포함되어 있음
- 실제 프로덕션에서는 최신 버전 사용 및 정기적인 업데이트가 중요함

📦 SBOM 비교:
- 세 이미지 모두에 대해 SBOM을 생성하여 공급망 가시성을 확보
- SBOM 기반 취약점 분석을 통해 패키지별 취약점 추적 가능

========================================
EOF

cat results/comparison-summary.txt

echo ""
echo "✅ 실습 완료! 결과는 results/ 디렉토리에 저장되었습니다."
echo ""
echo "📁 생성된 파일:"
ls -lh results/

echo ""
echo "💡 결과 비교 스크립트 실행: ./compare-results.sh"
