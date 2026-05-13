import os
import pytest


@pytest.fixture(scope="module")
def api_url():
    return os.environ["API_URL"].rstrip("/")
