from rest_framework import exceptions

from apps.core.exceptions import DomainError, api_exception_handler


def _handle(exc):
    response = api_exception_handler(exc, {})
    assert response is not None
    return response


def test_validation_error_format():
    response = _handle(exceptions.ValidationError({"phone": ["This field is required."]}))
    assert response.status_code == 400
    assert response.data == {
        "error": {
            "code": "validation_error",
            "message": "Invalid input.",
            "details": {"phone": ["This field is required."]},
        }
    }


def test_not_authenticated_format():
    response = _handle(exceptions.NotAuthenticated())
    assert response.status_code == 401
    assert response.data["error"]["code"] == "not_authenticated"
    assert response.data["error"]["details"] == {}


def test_permission_denied_format():
    response = _handle(exceptions.PermissionDenied())
    assert response.status_code == 403
    assert response.data["error"]["code"] == "permission_denied"


def test_domain_error_with_custom_code_and_status():
    response = _handle(DomainError("device_limit_reached", "Limit reached.", status_code=409))
    assert response.status_code == 409
    assert response.data == {
        "error": {"code": "device_limit_reached", "message": "Limit reached.", "details": {}}
    }


def test_unhandled_exception_passes_through():
    assert api_exception_handler(RuntimeError("boom"), {}) is None
