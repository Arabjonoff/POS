"""UUIDv7 identifikatorlar — vaqt bo'yicha tartiblangan, klientda ham yaratiladi."""

import uuid

from uuid6 import uuid7


def new_id() -> uuid.UUID:
    """Yangi UUIDv7 (oddiy `uuid.UUID` sifatida)."""
    return uuid.UUID(int=uuid7().int)
