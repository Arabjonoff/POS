import base64
import hashlib
import json
from pathlib import Path

import pytest

from apps.accounts.pins import PIN_ITERATIONS, hash_pin, validate_pin, verify_pin

VECTORS = json.loads(
    (Path(__file__).resolve().parents[4] / "testdata" / "pin_hash.json").read_text("utf-8")
)
CASES = VECTORS["cases"]


def test_vectors_use_current_iterations():
    assert VECTORS["iterations"] == PIN_ITERATIONS >= 100_000


@pytest.mark.parametrize("case", CASES, ids=lambda c: c["pin"])
def test_hash_matches_vector(case):
    assert hash_pin(case["pin"], case["salt"]) == case["encoded"]


@pytest.mark.parametrize("case", CASES, ids=lambda c: c["pin"])
def test_vector_is_plain_pbkdf2_sha256(case):
    # Dart tomoni Django'siz tekshiradi: format standart PBKDF2-HMAC-SHA256 bo'lishi shart.
    algorithm, iterations, salt, digest = case["encoded"].split("$")
    raw = hashlib.pbkdf2_hmac("sha256", case["pin"].encode(), salt.encode(), int(iterations))
    assert algorithm == "pbkdf2_sha256"
    assert base64.b64encode(raw).decode() == digest


@pytest.mark.parametrize("case", CASES, ids=lambda c: c["pin"])
def test_verify_vector(case):
    assert verify_pin(case["pin"], case["encoded"])


@pytest.mark.parametrize("wrong", VECTORS["wrong_pins"], ids=lambda w: w["pin"])
def test_wrong_pin_rejected(wrong):
    encoded = next(c["encoded"] for c in CASES if c["pin"] == wrong["encoded_of"])
    assert not verify_pin(wrong["pin"], encoded)


def test_random_salt_differs():
    first, second = hash_pin("1234"), hash_pin("1234")
    assert first != second
    assert verify_pin("1234", first)
    assert verify_pin("1234", second)


@pytest.mark.parametrize("pin", ["123", "1234567", "12a4", "", " 1234", "١٢٣٤"])
def test_invalid_pin_format(pin):
    with pytest.raises(ValueError, match="pin must"):
        validate_pin(pin)
    with pytest.raises(ValueError, match="pin must"):
        hash_pin(pin)


@pytest.mark.parametrize("encoded", ["", "md5$abc$def", "argon2$x"])
def test_verify_rejects_empty_or_foreign_hash(encoded):
    assert not verify_pin("1234", encoded)


def test_verify_rejects_bad_pin_input():
    encoded = CASES[0]["encoded"]
    assert not verify_pin(None, encoded)
    assert not verify_pin("12", encoded)
