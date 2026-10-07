"""
Pydantic Settings module for NYLEX Backend.
"""
from typing import Any
import os
from pydantic import BaseModel, ConfigDict

class BaseSettings(BaseModel):
    model_config = ConfigDict(extra="allow")

    def __init__(self, **values: Any):
        super().__init__(**values)
        for key in getattr(self.__class__, "__annotations__", {}):
            env_val = os.getenv(key)
            if env_val is not None:
                setattr(self, key, env_val)
