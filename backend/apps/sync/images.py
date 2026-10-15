"""Kassa uchun tovar rasmlari (T-105): qurilma tokeni bilan, faqat o'z tenanti.

Rasm fayllari ochiq URL orqali berilmaydi — bu view tenantni tekshiradi."""

from django.http import FileResponse, Http404
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers, status
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.catalog.images import attach_image, remove_image
from apps.catalog.models import ProductImage
from apps.devices.authentication import DeviceTokenAuthentication
from apps.devices.permissions import IsDevice
from apps.sales.services.common import tenant_user


class ImageUploadSerializer(serializers.Serializer):
    file = serializers.FileField()
    product = serializers.UUIDField()
    by = serializers.UUIDField()


class ImageDeleteSerializer(serializers.Serializer):
    by = serializers.UUIDField()


class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ["id", "product", "sha256", "width", "height", "bytes"]


class ProductImageView(APIView):
    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsDevice]

    def get_parsers(self):
        if self.request is not None and self.request.method == "PUT":
            return [MultiPartParser()]
        return super().get_parsers()

    @extend_schema(
        request={"multipart/form-data": ImageUploadSerializer},
        responses={200: ProductImageSerializer, 201: ProductImageSerializer},
        tags=["sync"],
    )
    def put(self, request, pk):
        body = ImageUploadSerializer(data=request.data)
        body.is_valid(raise_exception=True)
        tenant_id = request.auth.tenant_id
        user = tenant_user(
            tenant_id, body.validated_data["by"], code="invalid_image", managers_only=True
        )
        image, created = attach_image(
            tenant_id=tenant_id,
            product_id=body.validated_data["product"],
            image_id=pk,
            data=body.validated_data["file"].read(),
            user=user,
        )
        return Response(
            ProductImageSerializer(image).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )

    @extend_schema(
        parameters=[
            OpenApiParameter("size", str, enum=["full", "thumb"], required=False),
        ],
        responses={(200, "image/jpeg"): OpenApiTypes.BINARY},
        tags=["sync"],
    )
    def get(self, request, pk):
        image = ProductImage.objects.filter(
            tenant_id=request.auth.tenant_id, pk=pk, deleted_at__isnull=True
        ).first()
        if image is None:
            raise Http404
        field = image.thumb if request.query_params.get("size") == "thumb" else image.file
        response = FileResponse(field.open("rb"), content_type="image/jpeg")
        # Rasm o'zgarmas (yangi rasm — yangi id): abadiy keshlanadi.
        response["Cache-Control"] = "private, max-age=31536000, immutable"
        response["ETag"] = f'"{image.sha256}"'
        return response

    @extend_schema(request=ImageDeleteSerializer, responses={204: None}, tags=["sync"])
    def delete(self, request, pk):
        body = ImageDeleteSerializer(data=request.data)
        body.is_valid(raise_exception=True)
        tenant_id = request.auth.tenant_id
        tenant_user(tenant_id, body.validated_data["by"], code="invalid_image", managers_only=True)
        remove_image(tenant_id=tenant_id, image_id=pk)
        return Response(status=status.HTTP_204_NO_CONTENT)
