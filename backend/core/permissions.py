"""
Custom permissions untuk App Martabak.
"""
from rest_framework.permissions import BasePermission


class IsOwner(BasePermission):
    """
    Permission hanya untuk owner.
    """

    def has_permission(self, request, view):
        return (
            request.user.is_authenticated
            and getattr(request.user, 'role', None) == 'owner'
        )


class IsKasir(BasePermission):
    """
    Permission hanya untuk kasir.
    """

    def has_permission(self, request, view):
        return (
            request.user.is_authenticated
            and getattr(request.user, 'role', None) == 'kasir'
        )


class IsOwnerOrKasir(BasePermission):
    """
    Permission untuk owner dan kasir.
    """

    def has_permission(self, request, view):
        return (
            request.user.is_authenticated
            and getattr(request.user, 'role', None) in ['owner', 'kasir']
        )


class IsOwnerOrReadOnly(BasePermission):
    """
    Permission: read untuk semua, write untuk owner only.
    """

    def has_permission(self, request, view):
        if request.method in ['GET', 'HEAD', 'OPTIONS']:
            return True
        return (
            request.user.is_authenticated
            and getattr(request.user, 'role', None) == 'owner'
        )
