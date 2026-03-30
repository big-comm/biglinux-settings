"""
Base handler interface for biglinux sleep manager.
Each handler implements pre_suspend() and post_resume().
"""
import logging
from abc import ABC, abstractmethod

log = logging.getLogger(__name__)


class SleepHandler(ABC):
    """Abstract base class for sleep/resume handlers."""

    name: str = "base"
    enabled: bool = True

    @abstractmethod
    def pre_suspend(self, sleep_type: str) -> None:
        """Called before system enters sleep. Must be fast and non-blocking."""

    @abstractmethod
    def post_resume(self, sleep_type: str) -> None:
        """Called after system resumes. May do async work via subprocess."""

    def is_available(self) -> bool:
        """Return True if this handler should run on this system."""
        return True
