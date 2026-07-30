"""
Custom permissions untuk accounts app.
"""
from core.permissions import IsOwner


class IsOwnerAccount(IsOwner):
    """
    Permission untuk operasi akun owner.
    """
    pass
