"""PostgreSQL tranzaksiya ID'lari — pull'da "teshik"siz kursor uchun (sync-api.md "ChangeLog").

`seq` commit'dan oldin ajratiladi: kichik `seq` li tranzaksiya kattasidan keyin commit bo'lishi
mumkin. Shuning uchun yozuvga uni yozgan tranzaksiya ID'si (`txid`) qo'yiladi va pull faqat
barcha eski tranzaksiyalar tugagan (`txid < snapshot xmin`) yozuvlarni `(txid, seq)` tartibida
beradi — keyinroq bunday yozuv paydo bo'lishi mumkin emas.
"""

from django.db import models


class CurrentTxid(models.Func):
    template = "(pg_current_xact_id()::text::bigint)"
    output_field = models.BigIntegerField()


class SnapshotXmin(models.Func):
    """Hozirgi snapshot'dagi eng kichik tugamagan tranzaksiya ID'si."""

    template = "(pg_snapshot_xmin(pg_current_snapshot())::text::bigint)"
    output_field = models.BigIntegerField()


class OwnTxid(models.Func):
    """Joriy tranzaksiya ID'si (yozuv bo'lmasa NULL) — o'z yozuvlarini ko'rish uchun."""

    template = "(pg_current_xact_id_if_assigned()::text::bigint)"
    output_field = models.BigIntegerField()
