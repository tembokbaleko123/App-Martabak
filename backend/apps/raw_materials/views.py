from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Sum
from datetime import datetime
from core.permissions import IsOwner
from .models import MaterialItem, MaterialCostEntry, MaterialCostItem
from .serializers import (
    MaterialItemSerializer,
    MaterialCostEntrySerializer,
    MaterialCostEntryCreateSerializer,
    MaterialCostEntryUpdateSerializer,
)


class MaterialItemViewSet(viewsets.ModelViewSet):
    """
    ViewSet for material items (master list of material names).

    Owner only.
    """
    serializer_class = MaterialItemSerializer
    permission_classes = [IsAuthenticated, IsOwner]

    def get_queryset(self):
        return MaterialItem.objects.filter(is_active=True)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.is_active = False
        instance.save()
        return Response({'message': 'Material berhasil dihapus'}, status=status.HTTP_200_OK)


class MaterialCostEntryViewSet(viewsets.ModelViewSet):
    """
    ViewSet for material cost entries.

    Owner only.
    """
    permission_classes = [IsAuthenticated, IsOwner]

    def get_serializer_class(self):
        if self.action == 'create':
            return MaterialCostEntryCreateSerializer
        if self.action in ['update', 'partial_update']:
            return MaterialCostEntryUpdateSerializer
        return MaterialCostEntrySerializer

    def get_queryset(self):
        return MaterialCostEntry.objects.all().order_by('-date_from')

    def create(self, request):
        serializer = MaterialCostEntryCreateSerializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        entry = serializer.save()
        return Response(
            MaterialCostEntrySerializer(entry).data,
            status=status.HTTP_201_CREATED
        )

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = MaterialCostEntryUpdateSerializer(
            instance,
            data=request.data,
            partial=True,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        entry = serializer.save()
        return Response(MaterialCostEntrySerializer(entry).data)

    def partial_update(self, request, *args, **kwargs):
        return self.update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.delete()
        return Response({'message': 'Entry berhasil dihapus'}, status=status.HTTP_200_OK)
