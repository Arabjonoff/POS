import pytest


@pytest.mark.django_db
def test_health_ok(api_client):
    response = api_client.get("/api/health/")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


@pytest.mark.django_db
def test_schema_is_openapi(api_client):
    response = api_client.get("/api/schema/", HTTP_ACCEPT="application/vnd.oai.openapi+json")
    assert response.status_code == 200
    assert response.json()["openapi"].startswith("3.")


@pytest.mark.django_db
def test_docs_page_opens(api_client):
    response = api_client.get("/api/docs/")
    assert response.status_code == 200
    assert b"swagger" in response.content.lower()
