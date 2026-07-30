"""
GoQris Service - Service layer untuk GoQris API integration.

Modul ini bertanggung jawab untuk:
- Membuat order QRIS baru di GoQris
- Mengecek status pembayaran di GoQris
- Handle timeout dan error

Docs: https://goqris.web.id/docs
"""
import logging
from django.conf import settings
import requests

logger = logging.getLogger(__name__)


class GoQrisService:
    """
    Service untuk berinteraksi dengan GoQris API.

    Base URL: https://api.goqris.web.id
    Auth: apikey in body JSON (bukan Authorization header)
    """

    def __init__(self):
        self.api_base = settings.GOQRIS_API_BASE
        self.api_key = settings.GOQRIS_API_KEY
        self.timeout = 10

    def create_order(self, amount: int, ref_id: str, project_name: str) -> dict:
        """
        Buat QRIS order baru di GoQris.

        Args:
            amount: Jumlah payment dalam rupiah
            ref_id: Reference ID unik untuk order ini
            project_name: Nama project di GoQris dashboard

        Returns:
            Dict dengan qr_string, expires_at, dll

        Raises:
            GoQrisException: Jika API call gagal
        """
        url = f'{self.api_base}/order'

        payload = {
            'apikey': self.api_key,
            'nama_project': project_name,
            'ref_id': ref_id,
            'amount': amount,
        }

        logger.info(f'[GOQRIS] Creating order: apikey=REDACTED, ref_id={ref_id}, amount={amount}, project_name={project_name}')

        try:
            response = requests.post(
                url,
                json=payload,
                timeout=self.timeout
            )
            response.raise_for_status()

            data = response.json()
            logger.info(f'[GOQRIS] Order created: ref_id={ref_id}, success={data.get("status")}')

            if data.get('status', '').lower() != 'success':
                from core.exceptions import GoQrisException
                raise GoQrisException(data.get('message', 'Order creation failed'))

            return data.get('data', {})

        except requests.Timeout:
            logger.error(f'[GOQRIS] Timeout creating order: ref_id={ref_id}')
            from core.exceptions import GoQrisException
            raise GoQrisException('GoQris API timeout')

        except requests.HTTPError as e:
            logger.error(f'[GOQRIS] HTTP error: {e.response.status_code} - {e.response.text}')
            from core.exceptions import GoQrisException
            raise GoQrisException(f'GoQris API error: {e.response.status_code}')

        except Exception as e:
            logger.error(f'[GOQRIS] Unexpected error: {str(e)}')
            from core.exceptions import GoQrisException
            raise GoQrisException(f'GoQris error: {str(e)}')

    def check_status(self, ref_id: str) -> dict:
        """
        Cek status pembayaran di GoQris.

        Args:
            ref_id: Reference ID order

        Returns:
            Dict dengan status payment (paid: bool)
        """
        url = f'{self.api_base}/status'

        payload = {
            'apikey': self.api_key,
            'ref_id': ref_id,
        }

        try:
            response = requests.post(
                url,
                json=payload,
                timeout=self.timeout
            )
            response.raise_for_status()

            data = response.json()
            logger.info(f'[GOQRIS] Status check: ref_id={ref_id}, status={data.get("status")}')

            if data.get('status', '').lower() != 'success':
                from core.exceptions import GoQrisException
                raise GoQrisException(data.get('message', 'Status check failed'))

            return data.get('data', {})

        except requests.Timeout:
            logger.error(f'[GOQRIS] Timeout checking status: ref_id={ref_id}')
            from core.exceptions import GoQrisException
            raise GoQrisException('GoQris API timeout')

        except requests.HTTPError as e:
            logger.error(f'[GOQRIS] HTTP error: {e.response.status_code}')
            from core.exceptions import GoQrisException
            raise GoQrisException(f'GoQris API error: {e.response.status_code}')

        except Exception as e:
            logger.error(f'[GOQRIS] Unexpected error: {str(e)}')
            from core.exceptions import GoQrisException
            raise GoQrisException(f'GoQris error: {str(e)}')

    def get_profile(self) -> dict:
        """
        Get GoQris profile & subscription info.

        Returns:
            Dict dengan name, email, plan, usage, limit, dll
        """
        url = f'{self.api_base}/profile'

        payload = {
            'apikey': self.api_key,
        }

        try:
            response = requests.post(
                url,
                json=payload,
                timeout=self.timeout
            )
            response.raise_for_status()

            data = response.json()
            logger.info(f'[GOQRIS] Profile fetched: status={data.get("status")}')

            if data.get('status', '').lower() != 'success':
                from core.exceptions import GoQrisException
                raise GoQrisException(data.get('message', 'Profile fetch failed'))

            return data.get('data', {})

        except requests.Timeout:
            logger.error('[GOQRIS] Timeout fetching profile')
            from core.exceptions import GoQrisException
            raise GoQrisException('GoQris API timeout')

        except requests.HTTPError as e:
            logger.error(f'[GOQRIS] HTTP error: {e.response.status_code}')
            from core.exceptions import GoQrisException
            raise GoQrisException(f'GoQris API error: {e.response.status_code}')

        except Exception as e:
            logger.error(f'[GOQRIS] Unexpected error: {str(e)}')
            from core.exceptions import GoQrisException
            raise GoQrisException(f'GoQris error: {str(e)}')


goqris_service = GoQrisService()
