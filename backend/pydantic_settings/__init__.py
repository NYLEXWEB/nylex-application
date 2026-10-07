"""
Pydantic Settings module for NYLEX Backend.
Automatically uses real site-packages pydantic_settings if installed, otherwise uses local fallback.
"""
import sys
import os

_real_loaded = False
try:
    _curr_dir = os.path.dirname(os.path.abspath(__file__))
    _parent_dir = os.path.dirname(_curr_dir)
    _saved_path = list(sys.path)
    sys.path = [p for p in sys.path if os.path.abspath(p) not in (_curr_dir, _parent_dir)]
    try:
        import pydantic_settings as _real_settings
        if hasattr(_real_settings, "BaseSettings"):
            for _k, _v in _real_settings.__dict__.items():
                if not _k.startswith("__"):
                    globals()[_k] = _v
            _real_loaded = True
    except ImportError:
        pass
    finally:
        sys.path = _saved_path
except Exception:
    _real_loaded = False

if not _real_loaded:
    from typing import Any
    from pydantic import BaseModel, ConfigDict

    class BaseSettings(BaseModel):
        model_config = ConfigDict(extra="allow")

        def __init__(self, **values: Any):
            super().__init__(**values)
            for key in getattr(self.__class__, "__annotations__", {}):
                env_val = os.getenv(key)
                if env_val is not None:
                    setattr(self, key, env_val)

    __all__ = ["BaseSettings"]
