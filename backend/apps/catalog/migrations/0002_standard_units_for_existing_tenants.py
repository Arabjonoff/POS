"""Mavjud tenantlarga standart birliklar (yangilari signal orqali oladi)."""

from django.db import migrations

# Migratsiya vaqtidagi nusxa (models.STANDARD_UNITS keyin o'zgarsa ham bu o'zgarmaydi).
STANDARD_UNITS = (
    ("pcs", False),
    ("kg", True),
    ("g", False),
    ("l", True),
    ("m", True),
    ("pack", False),
)


def add_units(apps, schema_editor):
    from apps.core.ids import new_id

    Tenant = apps.get_model("tenants", "Tenant")
    Unit = apps.get_model("catalog", "Unit")
    for tenant in Tenant.objects.all():
        existing = set(Unit.objects.filter(tenant=tenant).values_list("code", flat=True))
        Unit.objects.bulk_create(
            Unit(id=new_id(), tenant=tenant, code=code, is_fractional=fractional)
            for code, fractional in STANDARD_UNITS
            if code not in existing
        )


class Migration(migrations.Migration):
    dependencies = [
        ("catalog", "0001_initial"),
        ("tenants", "0001_initial"),
    ]

    operations = [migrations.RunPython(add_units, migrations.RunPython.noop)]
