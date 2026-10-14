from django.urls import path

from . import views

urlpatterns = [
    path("reports/summary/", views.SummaryReportView.as_view(), name="report-summary"),
    path("reports/by-day/", views.ByDayReportView.as_view(), name="report-by-day"),
    path("reports/by-hour/", views.ByHourReportView.as_view(), name="report-by-hour"),
    path(
        "reports/top-products/", views.TopProductsReportView.as_view(), name="report-top-products"
    ),
    path("reports/cashiers/", views.CashiersReportView.as_view(), name="report-cashiers"),
    path("reports/debts/", views.DebtsReportView.as_view(), name="report-debts"),
    path("reports/stock/", views.StockReportView.as_view(), name="report-stock"),
]
