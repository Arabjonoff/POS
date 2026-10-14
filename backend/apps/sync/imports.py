"""Kassadan tovar importi (T-051, `product-import.md`) — qurilma tokeni bilan."""

import io
from datetime import timedelta

from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.catalog import importing
from apps.catalog.models import ProductImport
from apps.core.exceptions import DomainError
from apps.devices.authentication import DeviceTokenAuthentication
from apps.devices.permissions import IsDevice
from apps.sales.services.common import tenant_user

LIFETIME = timedelta(hours=24)
TEMPLATE_HEADER = ["Nomi", "Shtrix-kod", "Kategoriya", "Birlik", "Narx", "Tannarx", "Qoldiq"]
TEMPLATE_SAMPLE = ["Non issiq", "4780000000014", "Non", "dona", "4000", "3000", "20"]


class MappingSerializer(serializers.Serializer):
    name = serializers.IntegerField(allow_null=True, required=False, min_value=0)
    barcode = serializers.IntegerField(allow_null=True, required=False, min_value=0)
    category = serializers.IntegerField(allow_null=True, required=False, min_value=0)
    unit = serializers.IntegerField(allow_null=True, required=False, min_value=0)
    sell_price = serializers.IntegerField(allow_null=True, required=False, min_value=0)
    cost_price = serializers.IntegerField(allow_null=True, required=False, min_value=0)
    stock = serializers.IntegerField(allow_null=True, required=False, min_value=0)


class UploadSerializer(serializers.Serializer):
    file = serializers.FileField()


class UploadResponseSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    columns = serializers.ListField(child=serializers.CharField(allow_blank=True))
    sample = serializers.ListField(
        child=serializers.ListField(child=serializers.CharField(allow_blank=True))
    )
    total_rows = serializers.IntegerField()
    mapping = MappingSerializer()


class RowErrorSerializer(serializers.Serializer):
    row = serializers.IntegerField()
    field = serializers.CharField()
    code = serializers.CharField()


class CheckRequestSerializer(serializers.Serializer):
    mapping = MappingSerializer()


class CheckResponseSerializer(serializers.Serializer):
    creates = serializers.IntegerField()
    updates = serializers.IntegerField()
    error_count = serializers.IntegerField()
    errors = RowErrorSerializer(many=True)


class ApplyRequestSerializer(CheckRequestSerializer):
    by = serializers.UUIDField()


class ApplyResponseSerializer(serializers.Serializer):
    created = serializers.IntegerField()
    updated = serializers.IntegerField()
    skipped = serializers.IntegerField()
    error_count = serializers.IntegerField()
    errors = RowErrorSerializer(many=True)
    receipt = serializers.IntegerField(allow_null=True)


class _DeviceView(APIView):
    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsDevice]

    def _import(self, request, pk) -> ProductImport:
        return get_object_or_404(
            ProductImport.objects.filter(
                tenant_id=request.auth.tenant_id,
                device=request.auth,
                created_at__gte=timezone.now() - LIFETIME,
            ),
            pk=pk,
        )

    def _mapping(self, request, product_import, serializer_class):
        body = serializer_class(data=request.data)
        body.is_valid(raise_exception=True)
        width = len(product_import.rows[0]) if product_import.rows else 0
        mapping = importing.clean_mapping(dict(body.validated_data["mapping"]), width)
        return body.validated_data, mapping


class ImportTemplateView(_DeviceView):
    @extend_schema(
        responses={(200, "application/octet-stream"): OpenApiTypes.BINARY}, tags=["sync"]
    )
    def get(self, request):
        from openpyxl import Workbook

        workbook = Workbook()
        sheet = workbook.active
        sheet.title = "Tovarlar"
        sheet.append(TEMPLATE_HEADER)
        sheet.append(TEMPLATE_SAMPLE)
        for column in "ABCDEFG":
            sheet.column_dimensions[column].width = 18
            # Matn katak — shtrix-kodning boshidagi nollar saqlansin.
            for cell in sheet[column]:
                cell.number_format = "@"
        buffer = io.BytesIO()
        workbook.save(buffer)
        return HttpResponse(
            buffer.getvalue(),
            content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            headers={"Content-Disposition": 'attachment; filename="tovarlar-shablon.xlsx"'},
        )


class ImportUploadView(_DeviceView):
    parser_classes = [MultiPartParser]

    @extend_schema(request=UploadSerializer, responses=UploadResponseSerializer, tags=["sync"])
    def post(self, request):
        body = UploadSerializer(data=request.data)
        body.is_valid(raise_exception=True)
        upload = body.validated_data["file"]
        if upload.size > importing.MAX_BYTES:
            raise DomainError("file_too_large", "File is larger than 10 MB.")
        rows = importing.read_table(upload.read(), upload.name or "")
        product_import = ProductImport.objects.create(
            tenant_id=request.auth.tenant_id,
            device=request.auth,
            filename=(upload.name or "")[:255],
            rows=rows,
        )
        data = {
            "id": product_import.pk,
            "columns": rows[0],
            "sample": rows[1 : 1 + importing.SAMPLE_ROWS],
            "total_rows": len(rows) - 1,
            "mapping": importing.suggest_mapping(rows[0]),
        }
        return Response(UploadResponseSerializer(data).data, status=status.HTTP_201_CREATED)


class ImportCheckView(_DeviceView):
    @extend_schema(request=CheckRequestSerializer, responses=CheckResponseSerializer, tags=["sync"])
    def post(self, request, pk):
        product_import = self._import(request, pk)
        _, mapping = self._mapping(request, product_import, CheckRequestSerializer)
        summary = importing.analyze(product_import, mapping).summary()
        return Response(CheckResponseSerializer(summary).data)


class ImportApplyView(_DeviceView):
    @extend_schema(request=ApplyRequestSerializer, responses=ApplyResponseSerializer, tags=["sync"])
    def post(self, request, pk):
        product_import = self._import(request, pk)
        data, mapping = self._mapping(request, product_import, ApplyRequestSerializer)
        user = tenant_user(
            request.auth.tenant_id, data["by"], code="invalid_import", managers_only=True
        )
        result = importing.apply_import(product_import, mapping, user=user)
        return Response(ApplyResponseSerializer(result).data)
