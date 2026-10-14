from django.contrib.auth.models import update_last_login
from drf_spectacular.utils import extend_schema
from rest_framework import generics
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView

from apps.core.tenancy import TenantScopedReadOnlyViewSet

from .models import User
from .permissions import IsManagerOrOwner
from .serializers import LoginResponseSerializer, LoginSerializer, MeSerializer, UserSerializer


class LoginView(APIView):
    """Telefon + parol → JWT (ega, menejer, platforma admini)."""

    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def get_authenticate_header(self, request):
        # Xato 401 bo'lib qaytishi uchun (aks holda DRF 403 qiladi).
        return 'Bearer realm="api"'

    @extend_schema(request=LoginSerializer, responses=LoginResponseSerializer, tags=["auth"])
    def post(self, request):
        serializer = LoginSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data["user"]
        refresh = RefreshToken.for_user(user)
        update_last_login(None, user)
        return Response(
            {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": MeSerializer(user).data,
            }
        )


@extend_schema(tags=["auth"])
class RefreshView(TokenRefreshView):
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"


class MeView(generics.RetrieveAPIView):
    serializer_class = MeSerializer
    permission_classes = [IsAuthenticated]

    @extend_schema(tags=["auth"])
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    def get_object(self):
        return User.objects.select_related("tenant").get(pk=self.request.user.pk)


@extend_schema(tags=["users"])
class UserViewSet(TenantScopedReadOnlyViewSet):
    """O'z tenanti xodimlari (ega va menejer)."""

    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsManagerOrOwner]
