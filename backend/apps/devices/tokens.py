import hashlib
import secrets

TOKEN_PREFIX = "dev_"  # noqa: S105 — prefiks, sir emas


def new_token() -> str:
    return TOKEN_PREFIX + secrets.token_urlsafe(32)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()
