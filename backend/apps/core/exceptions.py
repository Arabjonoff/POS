"""Yagona xato formati: `{"error": {"code", "message", "details"}}`.

Klient foydalanuvchiga matnni `code` bo'yicha o'z tarjima faylidan ko'rsatadi.
"""

from rest_framework import status
from rest_framework.exceptions import APIException, ValidationError
from rest_framework.views import exception_handler


class DomainError(APIException):
    """Biznes qoidasi buzilganda: aniq `code` bilan (default 400)."""

    status_code = status.HTTP_400_BAD_REQUEST
    default_code = "domain_error"
    default_detail = "Request violates a business rule."

    def __init__(
        self,
        code: str,
        message: str | None = None,
        status_code: int | None = None,
        details: dict | None = None,
    ):
        super().__init__(detail=message or self.default_detail, code=code)
        self.code = code
        self.details = details or {}
        if status_code is not None:
            self.status_code = status_code


def _first_code(codes) -> str | None:
    if isinstance(codes, str):
        return codes
    if isinstance(codes, list) and codes:
        return _first_code(codes[0])
    if isinstance(codes, dict) and codes:
        return _first_code(next(iter(codes.values())))
    return None


def api_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is None:
        return None

    if isinstance(exc, ValidationError):
        code = "validation_error"
        message = "Invalid input."
        details = response.data
    elif isinstance(exc, DomainError):
        code = exc.code
        message = str(exc.detail)
        details = exc.details
    else:
        detail = getattr(exc, "detail", None)
        code = _first_code(exc.get_codes()) if hasattr(exc, "get_codes") else None
        code = code or getattr(exc, "default_code", "error")
        message = str(detail) if detail is not None else str(exc)
        details = {}
    response.data = {"error": {"code": code, "message": message, "details": details}}
    return response
