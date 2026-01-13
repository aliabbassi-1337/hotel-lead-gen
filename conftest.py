"""Pytest configuration and shared fixtures."""

import pytest
import asyncio
from db.client import init_db, close_db


@pytest.fixture(scope="function", autouse=True)
async def setup_db():
    """Initialize database connection pool for all tests."""
    await init_db()
    yield
    await close_db()
