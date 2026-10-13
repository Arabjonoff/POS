# POS monorepo — asosiy buyruqlar. Ro'yxat: `make help`.
SHELL := sh
.DEFAULT_GOAL := help

BACKEND := backend
POS := apps/pos
UI := packages/ui
ADMIN := apps/admin
API_DART := packages/api_client_dart
SCHEMA := $(BACKEND)/openapi.yaml

.PHONY: help up down logs ps \
	backend-install backend-lint backend-format backend-test migrate makemigrations \
	pos-get pos-analyze pos-test ui-test widgetbook \
	admin-install admin-lint admin-test admin-e2e admin-build \
	schema api-clients lint test

help: ## Buyruqlar ro'yxati
	@grep -E '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# --- Docker ---
up: ## Hamma servislarni ishga tushirish (postgres, redis, backend, admin)
	docker compose up -d

down: ## Servislarni to'xtatish (volume'lar saqlanadi)
	docker compose down

logs: ## Servis loglari
	docker compose logs -f --tail=100

ps: ## Servislar holati
	docker compose ps

# --- Backend ---
backend-install: ## Backend bog'liqliklarini o'rnatish (uv)
	cd $(BACKEND) && uv sync

backend-lint: ## Backend lint: ruff check + format --check
	cd $(BACKEND) && uv run ruff check . && uv run ruff format --check .

backend-format: ## Backend kodini formatlash
	cd $(BACKEND) && uv run ruff check --fix . && uv run ruff format .

backend-test: ## Backend testlari (pytest)
	cd $(BACKEND) && uv run pytest

migrate: ## Django migratsiyalari
	cd $(BACKEND) && uv run python manage.py migrate

makemigrations: ## Yangi migratsiya yaratish
	cd $(BACKEND) && uv run python manage.py makemigrations

# --- Flutter ---
pos-get: ## Dart workspace bog'liqliklari (flutter pub get)
	flutter pub get

pos-analyze: ## Kassa ilovasi va paketlar: flutter analyze
	cd $(POS) && flutter analyze
	cd $(UI) && flutter analyze
	cd $(UI)/widgetbook && flutter analyze

pos-test: ## Kassa ilovasi testlari
	cd $(POS) && flutter test

ui-test: ## Dizayn tizimi testlari (golden)
	cd $(UI) && flutter test

widgetbook: ## Widgetbook (dizayn tizimi katalogi) ni Windows'da ochish
	cd $(UI)/widgetbook && flutter run -d windows

# --- Admin ---
admin-install: ## Admin bog'liqliklari (npm ci)
	cd $(ADMIN) && npm ci

admin-lint: ## Admin lint + typecheck
	cd $(ADMIN) && npm run lint && npm run typecheck

admin-test: ## Admin unit testlari (Vitest)
	cd $(ADMIN) && npm test

admin-e2e: ## Admin Playwright testlari
	cd $(ADMIN) && npx playwright test

admin-build: ## Admin production build
	cd $(ADMIN) && npm run build

# --- API ---
schema: ## OpenAPI sxemasini backend/openapi.yaml ga yozish
	cd $(BACKEND) && uv run python manage.py spectacular --file openapi.yaml --validate

api-clients: schema ## OpenAPI'dan Dart va TypeScript klientlarni generatsiya qilish
	cd $(ADMIN) && npm run api:generate
	cd $(API_DART) && dart run swagger_parser

# --- Hammasi ---
lint: backend-lint pos-analyze admin-lint ## Barcha lint tekshiruvlari

test: backend-test ui-test pos-test admin-test ## Barcha testlar
