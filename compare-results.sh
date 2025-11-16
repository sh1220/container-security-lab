#!/bin/bash

# 결과 비교 및 분석 스크립트

echo "📊 실습 결과 비교"
echo "================================"
echo ""

# 결과 디렉토리 확인
if [ ! -d "results" ]; then
    echo "❌ results 디렉토리가 없습니다. 먼저 ./run-experiment.sh를 실행하세요."
    exit 1
fi

# 1. 이미지 크기 비교
echo "1️⃣ 이미지 크기 비교"
echo "-------------------"
echo "  nginx:latest:        $(docker images nginx:latest --format '{{.Size}}' | head -1)"
echo "  nginx:alpine:        $(docker images nginx:alpine --format '{{.Size}}' | head -1)"
echo "  vulhub/nginx:1.13.2: $(docker images vulhub/nginx:1.13.2 --format '{{.Size}}' | head -1)"
echo ""

# 2. Critical 취약점 비교
echo "2️⃣ Critical 취약점 개수 비교"
echo "-------------------"
if [ -f results/latest-report.txt ]; then
    if grep -q "^Total:" results/latest-report.txt 2>/dev/null; then
        LATEST_CRITICAL=$(grep -m1 -o 'CRITICAL: [0-9]\+' results/latest-report.txt 2>/dev/null | awk '{print $2}')
        LATEST_CRITICAL=${LATEST_CRITICAL:-0}
    else
        LATEST_CRITICAL="0"
    fi
    echo "  nginx:latest:  ${LATEST_CRITICAL}개"
else
    echo "  nginx:latest:  리포트 없음"
fi

if [ -f results/alpine-report.txt ]; then
    if grep -q "^Total:" results/alpine-report.txt 2>/dev/null; then
        ALPINE_CRITICAL=$(grep -m1 -o 'CRITICAL: [0-9]\+' results/alpine-report.txt 2>/dev/null | awk '{print $2}')
        ALPINE_CRITICAL=${ALPINE_CRITICAL:-0}
    else
        ALPINE_CRITICAL="0"
    fi
    echo "  nginx:alpine:  ${ALPINE_CRITICAL}개"
else
    echo "  nginx:alpine:  리포트 없음"
fi

if [ -f results/old-version-report.txt ]; then
    if grep -q "^Total:" results/old-version-report.txt 2>/dev/null; then
        OLD_CRITICAL=$(grep -m1 -o 'CRITICAL: [0-9]\+' results/old-version-report.txt 2>/dev/null | awk '{print $2}')
        OLD_CRITICAL=${OLD_CRITICAL:-0}
    else
        OLD_CRITICAL="0"
    fi
    echo "  vulhub/nginx:1.13.2:    ${OLD_CRITICAL}개 ⚠️  (취약점 예시 이미지)"
else
    echo "  오래된 버전:    리포트 없음"
fi
echo ""

# 3. High 취약점 비교
echo "3️⃣ High 취약점 개수 비교"
echo "-------------------"
if [ -f results/latest-report.txt ]; then
    if grep -q "^Total:" results/latest-report.txt 2>/dev/null; then
        LATEST_HIGH=$(grep -m1 -o 'HIGH: [0-9]\+' results/latest-report.txt 2>/dev/null | awk '{print $2}')
        LATEST_HIGH=${LATEST_HIGH:-0}
    else
        LATEST_HIGH="0"
    fi
    echo "  nginx:latest:  ${LATEST_HIGH}개"
else
    echo "  nginx:latest:  리포트 없음"
fi

if [ -f results/alpine-report.txt ]; then
    if grep -q "^Total:" results/alpine-report.txt 2>/dev/null; then
        ALPINE_HIGH=$(grep -m1 -o 'HIGH: [0-9]\+' results/alpine-report.txt 2>/dev/null | awk '{print $2}')
        ALPINE_HIGH=${ALPINE_HIGH:-0}
    else
        ALPINE_HIGH="0"
    fi
    echo "  nginx:alpine:  ${ALPINE_HIGH}개"
else
    echo "  nginx:alpine:  리포트 없음"
fi

if [ -f results/old-version-report.txt ]; then
    if grep -q "^Total:" results/old-version-report.txt 2>/dev/null; then
        OLD_HIGH=$(grep -m1 -o 'HIGH: [0-9]\+' results/old-version-report.txt 2>/dev/null | awk '{print $2}')
        OLD_HIGH=${OLD_HIGH:-0}
    else
        OLD_HIGH="0"
    fi
    echo "  vulhub/nginx:1.13.2:    ${OLD_HIGH}개 ⚠️  (취약점 예시 이미지)"
else
    echo "  오래된 버전:    리포트 없음"
fi
echo ""

# 4. SBOM 패키지 정보
echo "4️⃣ SBOM 패키지 수 비교"
echo "-------------------"
if [ -f results/sbom-nginx-latest.json ]; then
    LATEST_PACKAGES=$(cat results/sbom-nginx-latest.json | grep -o '"name"' | wc -l | xargs || echo "0")
    LATEST_PACKAGES=${LATEST_PACKAGES:-0}
    echo "  nginx:latest:        ${LATEST_PACKAGES}개"
else
    echo "  nginx:latest:        SBOM 없음"
fi

if [ -f results/sbom-nginx-alpine.json ]; then
    ALPINE_PACKAGES=$(cat results/sbom-nginx-alpine.json | grep -o '"name"' | wc -l | xargs || echo "0")
    ALPINE_PACKAGES=${ALPINE_PACKAGES:-0}
    echo "  nginx:alpine:        ${ALPINE_PACKAGES}개"
else
    echo "  nginx:alpine:        SBOM 없음"
fi

if [ -f results/sbom-vulhub-nginx.json ]; then
    VULHUB_PACKAGES=$(cat results/sbom-vulhub-nginx.json | grep -o '"name"' | wc -l | xargs || echo "0")
    VULHUB_PACKAGES=${VULHUB_PACKAGES:-0}
    echo "  vulhub/nginx:1.13.2: ${VULHUB_PACKAGES}개"
else
    echo "  vulhub/nginx:1.13.2: SBOM 없음"
fi
echo ""

# 4-1. SBOM 기반 취약점 분석 (Grype)
echo "4-1️⃣ SBOM 기반 분석 (Grype) - Critical 취약점 개수"
echo "-------------------"
if [ -f results/vulns-from-sbom-latest.txt ]; then
    LATEST_SBOM_CRITICAL=$(grep -c "Critical" results/vulns-from-sbom-latest.txt 2>/dev/null | xargs || echo "0")
    LATEST_SBOM_CRITICAL=${LATEST_SBOM_CRITICAL:-0}
    echo "  nginx:latest:        ${LATEST_SBOM_CRITICAL}개"
else
    echo "  nginx:latest:        분석 결과 없음"
fi

if [ -f results/vulns-from-sbom-alpine.txt ]; then
    ALPINE_SBOM_CRITICAL=$(grep -c "Critical" results/vulns-from-sbom-alpine.txt 2>/dev/null | xargs || echo "0")
    ALPINE_SBOM_CRITICAL=${ALPINE_SBOM_CRITICAL:-0}
    echo "  nginx:alpine:        ${ALPINE_SBOM_CRITICAL}개"
else
    echo "  nginx:alpine:        분석 결과 없음"
fi

if [ -f results/vulns-from-sbom-vulhub.txt ]; then
    VULHUB_SBOM_CRITICAL=$(grep -c "Critical" results/vulns-from-sbom-vulhub.txt 2>/dev/null | xargs || echo "0")
    VULHUB_SBOM_CRITICAL=${VULHUB_SBOM_CRITICAL:-0}
    echo "  vulhub/nginx:1.13.2: ${VULHUB_SBOM_CRITICAL}개"
else
    echo "  vulhub/nginx:1.13.2: 분석 결과 없음"
fi
echo ""

echo "4-2️⃣ SBOM 기반 분석 (Grype) - High 취약점 개수"
echo "-------------------"
if [ -f results/vulns-from-sbom-latest.txt ]; then
    LATEST_SBOM_HIGH=$(grep -c "High" results/vulns-from-sbom-latest.txt 2>/dev/null | xargs || echo "0")
    LATEST_SBOM_HIGH=${LATEST_SBOM_HIGH:-0}
    echo "  nginx:latest:        ${LATEST_SBOM_HIGH}개"
else
    echo "  nginx:latest:        분석 결과 없음"
fi

if [ -f results/vulns-from-sbom-alpine.txt ]; then
    ALPINE_SBOM_HIGH=$(grep -c "High" results/vulns-from-sbom-alpine.txt 2>/dev/null | xargs || echo "0")
    ALPINE_SBOM_HIGH=${ALPINE_SBOM_HIGH:-0}
    echo "  nginx:alpine:        ${ALPINE_SBOM_HIGH}개"
else
    echo "  nginx:alpine:        분석 결과 없음"
fi

if [ -f results/vulns-from-sbom-vulhub.txt ]; then
    VULHUB_SBOM_HIGH=$(grep -c "High" results/vulns-from-sbom-vulhub.txt 2>/dev/null | xargs || echo "0")
    VULHUB_SBOM_HIGH=${VULHUB_SBOM_HIGH:-0}
    echo "  vulhub/nginx:1.13.2: ${VULHUB_SBOM_HIGH}개"
else
    echo "  vulhub/nginx:1.13.2: 분석 결과 없음"
fi
echo ""

# 5. 상세 리포트 위치 안내
echo "5️⃣ 상세 리포트 위치"
echo "-------------------"
echo "  📄 nginx:latest 취약점:        results/latest-report.txt"
echo "  📄 nginx:alpine 취약점:        results/alpine-report.txt"
echo "  📄 vulhub/nginx:1.13.2 취약점: results/old-version-report.txt"
echo ""
echo "  📄 SBOM (JSON):"
echo "    - nginx:latest:        results/sbom-nginx-latest.json"
echo "    - nginx:alpine:         results/sbom-nginx-alpine.json"
echo "    - vulhub/nginx:1.13.2:  results/sbom-vulhub-nginx.json"
echo "  📄 SBOM (Table):               results/sbom-nginx-alpine-table.txt"
echo ""
echo "  📄 SBOM 기반 취약점:"
echo "    - nginx:latest:        results/vulns-from-sbom-latest.txt"
echo "    - nginx:alpine:         results/vulns-from-sbom-alpine.txt"
echo "    - vulhub/nginx:1.13.2:  results/vulns-from-sbom-vulhub.txt"
echo "  📄 비교 요약:                  results/comparison-summary.txt"
echo ""

# 6. 주요 취약점 샘플
echo "6️⃣ 주요 Critical 취약점 샘플"
echo "-------------------"

# nginx:latest 취약점
if [ -f results/latest-report.txt ]; then
    # 요약줄 제외, 표에서 CRITICAL 행만 샘플로 표기
    LATEST_CRITICAL_COUNT=$(grep -c "^Total:" results/latest-report.txt 2>/dev/null | xargs || echo "0")
    if grep -q "^Total:" results/latest-report.txt 2>/dev/null; then
        LATEST_CRITICAL_COUNT=$(grep -m1 -o 'CRITICAL: [0-9]\+' results/latest-report.txt 2>/dev/null | awk '{print $2}')
    else
        LATEST_CRITICAL_COUNT="0"
    fi
    
    if [ "$LATEST_CRITICAL_COUNT" -gt 0 ]; then
        echo "  [nginx:latest] ⚠️  Critical 취약점 발견:"
        grep -E '│.*CRITICAL.*│' results/latest-report.txt | head -3 | while read line; do
            echo "    ⚠️  $line"
        done
        if [ "$LATEST_CRITICAL_COUNT" -gt 3 ]; then
            echo "    ... 외 ${LATEST_CRITICAL_COUNT}개 더"
        fi
    else
        echo "  [nginx:latest] ✅ Critical 취약점이 없습니다!"
    fi
else
    echo "  [nginx:latest] 리포트 파일이 없습니다."
fi

echo ""

# nginx:alpine 취약점
if [ -f results/alpine-report.txt ]; then
    if grep -q "^Total:" results/alpine-report.txt 2>/dev/null; then
        ALPINE_CRITICAL_COUNT=$(grep -m1 -o 'CRITICAL: [0-9]\+' results/alpine-report.txt 2>/dev/null | awk '{print $2}')
        ALPINE_CRITICAL_COUNT=${ALPINE_CRITICAL_COUNT:-0}
    else
        ALPINE_CRITICAL_COUNT="0"
    fi
    
    if [ "$ALPINE_CRITICAL_COUNT" -gt 0 ]; then
        echo "  [nginx:alpine] ⚠️  Critical 취약점 발견:"
        grep -E '│.*CRITICAL.*│' results/alpine-report.txt | head -3 | while read line; do
            echo "    ⚠️  $line"
        done
        if [ "$ALPINE_CRITICAL_COUNT" -gt 3 ]; then
            echo "    ... 외 ${ALPINE_CRITICAL_COUNT}개 더"
        fi
    else
        echo "  [nginx:alpine] ✅ Critical 취약점이 없습니다!"
    fi
else
    echo "  [nginx:alpine] 리포트 파일이 없습니다."
fi

echo ""

# 오래된 버전 취약점 (예시)
if [ -f results/old-version-report.txt ]; then
    if grep -q "^Total:" results/old-version-report.txt 2>/dev/null; then
        OLD_CRITICAL_COUNT=$(grep -m1 -o 'CRITICAL: [0-9]\+' results/old-version-report.txt 2>/dev/null | awk '{print $2}')
        OLD_CRITICAL_COUNT=${OLD_CRITICAL_COUNT:-0}
    else
        OLD_CRITICAL_COUNT="0"
    fi
    
    if [ "$OLD_CRITICAL_COUNT" -gt 0 ]; then
        echo "  [vulhub/nginx:1.13.2] ⚠️  Critical 취약점 발견 (취약점 예시 이미지):"
        grep -E '│.*CRITICAL.*│' results/old-version-report.txt | head -5 | while read line; do
            echo "    ⚠️  $line"
        done
        if [ "$OLD_CRITICAL_COUNT" -gt 5 ]; then
            echo "    ... 외 ${OLD_CRITICAL_COUNT}개 더"
        fi
    else
        echo "  [vulhub/nginx:1.13.2] Critical 취약점이 없습니다."
    fi
else
    echo "  [오래된 버전] 리포트 파일이 없습니다."
fi
echo ""

echo "================================"
echo "✅ 비교 완료!"
