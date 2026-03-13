## 브랜치 구조

- `main`: 항상 안정적인 코드만 유지
- `develop`: 개발 통합 브랜치
- `feature/*`: 기능 개발 브랜치
- `fix/*`: 버그 수정 브랜치

## 브랜치 흐름

```text
feature/* → develop → main
브랜치 생성 규칙

새 작업은 항상 develop에서 최신 코드를 pull 받은 뒤 생성합니다.

예시:

feature/ai-classification

feature/backend-diagnosis-history

feature/app-dashboard-screen

작업 규칙

작업 단위별로 feature 브랜치를 생성합니다.

기능 구현이 끝나면 develop으로 merge 합니다.

merge 후 feature 브랜치는 삭제합니다.

발표 가능 수준의 안정 버전만 main으로 merge 합니다.

커밋 메시지 규칙

feat: 기능 추가

fix: 버그 수정

docs: 문서 수정

refactor: 코드 구조 개선

test: 테스트 추가

예시:

feat: add diagnosis screen UI

fix: resolve image upload error

주의사항

main 브랜치에 직접 push 하지 않습니다.

작업 시작 전 반드시 develop 최신 버전을 pull 합니다.

하나의 브랜치에는 하나의 기능만 작업합니다.
```
