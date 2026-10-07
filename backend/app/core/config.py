import os
from typing import List, Union
from pydantic_settings import BaseSettings
from pydantic import Field, field_validator

class Settings(BaseSettings):
    APP_NAME: str = "NYLEX Management API"
    APP_ENV: str = "development"
    API_PREFIX: str = "/api"
    API_BASE_URL: str = "http://localhost:8000"

    # MongoDB Atlas
    MONGODB_URI: str = Field(default="mongodb://localhost:27017/nylex_db")
    DATABASE_NAME: str = "nylex_db"

    # JWT Authentication
    JWT_SECRET: str = "nylex_super_secret_jwt_key_2026_production_safe"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_EXPIRE_MINUTES: int = 43200  # 30 days for mobile convenience
    JWT_REFRESH_SECRET: str = "nylex_super_secret_refresh_key_2026_production_safe"
    JWT_REFRESH_EXPIRE_DAYS: int = 60

    # CORS
    CORS_ORIGINS: Union[List[str], str] = ["*"]

    @field_validator("CORS_ORIGINS", mode="before")
    def assemble_cors_origins(cls, v):
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        return ["*"]

    # Firebase Cloud Messaging (Optional)
    FIREBASE_PROJECT_ID: str = ""
    FIREBASE_CLIENT_EMAIL: str = ""
    FIREBASE_PRIVATE_KEY: str = ""

    class Config:
        env_file = ".env"
        extra = "allow"

settings = Settings()
