import uuid

from apps.core.ids import new_id


def test_new_id_is_uuid_v7():
    value = new_id()
    assert type(value) is uuid.UUID
    assert value.version == 7


def test_new_ids_are_unique_and_time_ordered():
    ids = [new_id() for _ in range(1000)]
    assert len(set(ids)) == len(ids)
    assert ids == sorted(ids)
