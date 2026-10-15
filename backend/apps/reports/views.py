from drf_spectacular.utils import extend_schema
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsManagerOrOwner
from apps.devices.authentication import DeviceTokenAuthentication
from apps.devices.permissions import IsDevice
from apps.tenants.models import Tenant

from . import services
from .serializers import (
    CashierRowSerializer,
    DayRowSerializer,
    DebtsSerializer,
    DeviceReportSerializer,
    HourRowSerializer,
    LimitQuerySerializer,
    PeriodQuerySerializer,
    ProductRowSerializer,
    StockReportSerializer,
    SummarySerializer,
    TopProductsQuerySerializer,
)


class ReportView(APIView):
    """Hisobot bazasi: ega va menejer, faqat o'z tenanti."""

    permission_classes = [IsManagerOrOwner]
    query_serializer = PeriodQuerySerializer

    def query(self) -> dict:
        query = self.query_serializer(data=self.request.query_params)
        query.is_valid(raise_exception=True)
        return dict(query.validated_data)

    def tenant(self) -> Tenant:
        return Tenant.objects.get(pk=self.request.user.tenant_id)

    def period(self, query: dict) -> services.Period:
        try:
            return services.Period.for_tenant(
                self.tenant(), query.pop("date_from", None), query.pop("date_to", None)
            )
        except ValueError as exc:
            raise ValidationError({"date_to": str(exc)}) from None


@extend_schema(tags=["reports"], parameters=[PeriodQuerySerializer], responses=SummarySerializer)
class SummaryReportView(ReportView):
    def get(self, request):
        report = services.summary(self.tenant(), self.period(self.query()))
        return Response(SummarySerializer(report).data)


@extend_schema(
    tags=["reports"], parameters=[PeriodQuerySerializer], responses=DayRowSerializer(many=True)
)
class ByDayReportView(ReportView):
    def get(self, request):
        rows = services.by_day(self.tenant(), self.period(self.query()))
        return Response(DayRowSerializer(rows, many=True).data)


@extend_schema(
    tags=["reports"], parameters=[PeriodQuerySerializer], responses=HourRowSerializer(many=True)
)
class ByHourReportView(ReportView):
    def get(self, request):
        rows = services.by_hour(self.tenant(), self.period(self.query()))
        return Response(HourRowSerializer(rows, many=True).data)


@extend_schema(
    tags=["reports"],
    parameters=[TopProductsQuerySerializer],
    responses=ProductRowSerializer(many=True),
)
class TopProductsReportView(ReportView):
    query_serializer = TopProductsQuerySerializer

    def get(self, request):
        query = self.query()
        period = self.period(query)
        rows = services.top_products(self.tenant(), period, **query)
        return Response(ProductRowSerializer(rows, many=True).data)


@extend_schema(
    tags=["reports"], parameters=[PeriodQuerySerializer], responses=CashierRowSerializer(many=True)
)
class CashiersReportView(ReportView):
    def get(self, request):
        rows = services.cashiers(self.tenant(), self.period(self.query()))
        return Response(CashierRowSerializer(rows, many=True).data)


@extend_schema(tags=["reports"], parameters=[LimitQuerySerializer], responses=DebtsSerializer)
class DebtsReportView(ReportView):
    query_serializer = LimitQuerySerializer

    def get(self, request):
        report = services.debts(self.tenant(), limit=self.query()["limit"])
        return Response(DebtsSerializer(report).data)


@extend_schema(tags=["reports"], responses=StockReportSerializer)
class StockReportView(ReportView):
    def get(self, request):
        return Response(StockReportSerializer(services.stock(self.tenant())).data)


@extend_schema(tags=["sync"], parameters=[PeriodQuerySerializer], responses=DeviceReportSerializer)
class DeviceReportView(ReportView):
    """Kassa (qurilma tokeni) uchun barcha hisobotlar bitta javobda (T-070).

    Kim ko'rishi (ega/menejer) — kassada lokal rol bilan cheklanadi.
    """

    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsDevice]

    def tenant(self) -> Tenant:
        return self.request.auth.tenant

    def get(self, request):
        tenant = self.tenant()
        period = self.period(self.query())
        data = {
            "summary": services.summary(tenant, period),
            "by_day": services.by_day(tenant, period),
            "by_hour": services.by_hour(tenant, period),
            "top_products": services.top_products(tenant, period),
            "cashiers": services.cashiers(tenant, period),
            "debts": services.debts(tenant, limit=10),
            "stock": services.stock(tenant),
        }
        return Response(DeviceReportSerializer(data).data)
