"""Foydalanuvchilar: platforma admini va do'kon xodimlari (qaror 0006)."""

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.models import PermissionsMixin
from django.core.exceptions import ValidationError
from django.db import models
from django.db.models import Q
from django.utils.translation import gettext_lazy as _

from apps.core.models import TenantQuerySet, TimeStampedModel
from apps.core.phone import normalize_phone, validate_phone

from .pins import hash_pin, verify_pin


class Role(models.TextChoices):
    PLATFORM_ADMIN = "platform_admin", _("platforma admini")
    OWNER = "owner", _("ega")
    MANAGER = "manager", _("menejer")
    CASHIER = "cashier", _("kassir")


# Telefon + parol bilan kiradigan rollar. Kassir faqat PIN bilan.
PASSWORD_ROLES = frozenset({Role.PLATFORM_ADMIN, Role.OWNER, Role.MANAGER})


class UserQuerySet(TenantQuerySet):
    pass


class UserManager(BaseUserManager.from_queryset(UserQuerySet)):
    use_in_migrations = True

    def create_user(self, phone=None, password=None, **extra_fields):
        extra_fields.setdefault("role", Role.CASHIER)
        user = self.model(phone=normalize_phone(phone) if phone else None, **extra_fields)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.full_clean(exclude=["password"])
        user.save(using=self._db)
        return user

    def create_superuser(self, phone, password=None, **extra_fields):
        extra_fields.update(role=Role.PLATFORM_ADMIN, tenant=None, is_superuser=True)
        return self.create_user(phone, password, **extra_fields)


class User(TimeStampedModel, AbstractBaseUser, PermissionsMixin):
    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="users",
        verbose_name=_("tenant"),
    )
    phone = models.CharField(
        _("telefon"),
        max_length=13,
        unique=True,
        null=True,
        blank=True,
        validators=[validate_phone],
    )
    full_name = models.CharField(_("ism"), max_length=200)
    role = models.CharField(_("rol"), max_length=20, choices=Role.choices)
    pin_hash = models.CharField(_("PIN hash"), max_length=128, blank=True)
    is_active = models.BooleanField(_("faol"), default=True)

    objects = UserManager()

    USERNAME_FIELD = "phone"
    REQUIRED_FIELDS = ["full_name"]

    class Meta:
        verbose_name = _("foydalanuvchi")
        verbose_name_plural = _("foydalanuvchilar")
        ordering = ["created_at"]
        constraints = [
            models.CheckConstraint(
                name="user_tenant_matches_role",
                condition=(Q(role=Role.PLATFORM_ADMIN) & Q(tenant__isnull=True))
                | (~Q(role=Role.PLATFORM_ADMIN) & Q(tenant__isnull=False)),
            ),
            models.CheckConstraint(
                name="user_phone_required_for_login_roles",
                condition=Q(role=Role.CASHIER) | Q(phone__isnull=False),
            ),
        ]

    def __str__(self):
        return f"{self.full_name} ({self.phone or self.get_role_display()})"

    @property
    def is_staff(self) -> bool:
        """Django admin'ga faqat platforma admini kiradi."""
        return self.role == Role.PLATFORM_ADMIN

    @property
    def can_use_password(self) -> bool:
        return self.role in PASSWORD_ROLES

    def clean(self):
        super().clean()
        if self.phone == "":
            self.phone = None
        if self.role == Role.PLATFORM_ADMIN and self.tenant_id is not None:
            raise ValidationError({"tenant": _("Platforma adminida tenant bo'lmaydi.")})
        if self.role and self.role != Role.PLATFORM_ADMIN and self.tenant_id is None:
            raise ValidationError({"tenant": _("Xodim tenantga tegishli bo'lishi kerak.")})
        if self.role in PASSWORD_ROLES and not self.phone:
            raise ValidationError({"phone": _("Bu rol uchun telefon raqami majburiy.")})

    def set_pin(self, pin: str) -> None:
        self.pin_hash = hash_pin(pin)

    def check_pin(self, pin: str) -> bool:
        return verify_pin(pin, self.pin_hash)
