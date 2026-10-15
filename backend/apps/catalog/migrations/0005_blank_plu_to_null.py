from django.db import migrations


def blank_plu_to_null(apps, schema_editor):
    # Bo'sh PLU — "PLU yo'q" (audit P2-13). Ma'lumot yo'qolmaydi: "" va NULL bir ma'noda.
    Product = apps.get_model("catalog", "Product")
    Product.objects.filter(plu_code="").update(plu_code=None)


class Migration(migrations.Migration):
    dependencies = [
        ("catalog", "0004_product_images"),
    ]

    operations = [
        migrations.RunPython(blank_plu_to_null, migrations.RunPython.noop),
    ]
