"""Mavjud ma'lumot uchun boshlang'ich ChangeLog: yangi qurilma `cursor=0` dan hammasini oladi."""

from django.db import migrations

# (app, model, entity) — sync-api.md entitylari; yumshoq o'chirilganlar `delete`.
SOFT_DELETE_ENTITIES = [
    ("catalog", "Unit", "unit"),
    ("catalog", "Category", "category"),
    ("catalog", "Product", "product"),
    ("inventory", "Supplier", "supplier"),
    ("customers", "Customer", "customer"),
]


def backfill(apps, schema_editor):
    ChangeLog = apps.get_model("sync", "ChangeLog")
    rows = []

    def add(tenant_id, entity, entity_id, op="upsert"):
        rows.append(ChangeLog(tenant_id=tenant_id, entity=entity, entity_id=entity_id, op=op))

    for app_label, model_name, entity in SOFT_DELETE_ENTITIES:
        model = apps.get_model(app_label, model_name)
        for obj in model.objects.order_by("created_at").iterator():
            add(obj.tenant_id, entity, obj.pk, "delete" if obj.deleted_at else "upsert")

    for store in apps.get_model("tenants", "Store").objects.order_by("created_at").iterator():
        add(store.tenant_id, "store", store.pk)
    users = apps.get_model("accounts", "User").objects.filter(tenant__isnull=False)
    for user in users.order_by("created_at").iterator():
        add(user.tenant_id, "user", user.pk)
    entries = apps.get_model("customers", "DebtEntry").objects.order_by("at")
    for entry in entries.iterator():
        add(entry.tenant_id, "debt_entry", entry.pk)
    for stock in apps.get_model("inventory", "ProductStock").objects.iterator():
        add(stock.tenant_id, "stock", stock.product_id)

    ChangeLog.objects.bulk_create(rows, batch_size=1000)


class Migration(migrations.Migration):
    dependencies = [
        ("sync", "0001_initial"),
        ("accounts", "0001_initial"),
        ("catalog", "0002_standard_units_for_existing_tenants"),
        ("customers", "0002_debtentry_shift"),
        ("inventory", "0001_initial"),
        ("tenants", "0001_initial"),
    ]

    operations = [migrations.RunPython(backfill, migrations.RunPython.noop)]
