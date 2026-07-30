"""
Pytest configuration dan fixtures.
TODO: Setup di phase 1 atau phase 11.
"""
import pytest


@pytest.fixture
def api_client():
    """
    Fixture untuk API client.
    """
    from rest_framework.test import APIClient
    return APIClient()


@pytest.fixture
def owner_user(db, django_user_model):
    """
    Fixture untuk owner user.
    """
    return django_user_model.objects.create_user(
        username='owner',
        password='testpass123',
        role='owner'
    )


@pytest.fixture
def kasir_user(db, django_user_model):
    """
    Fixture untuk kasir user.
    """
    return django_user_model.objects.create_user(
        username='kasir1',
        password='testpass123',
        role='kasir'
    )
