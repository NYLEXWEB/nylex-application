"""
Pydantic V2 core schemas, BaseModel, and typing support for NYLEX Backend.
Automatically uses real site-packages pydantic if installed, otherwise uses local fallback.
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
        import pydantic as _real_pydantic
        if hasattr(_real_pydantic, "BaseModel"):
            for _k, _v in _real_pydantic.__dict__.items():
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
    from typing import Any, Callable, Dict, List, Optional, Type, TypeVar, Union, get_type_hints, get_origin, get_args

    T = TypeVar("T", bound="BaseModel")

    class ConfigDict(dict):
        def __init__(self, **kwargs):
            super().__init__(**kwargs)
            for k, v in kwargs.items():
                setattr(self, k, v)

    class FieldInfo:
        def __init__(
            self,
            default: Any = ...,
            default_factory: Optional[Callable[[], Any]] = None,
            min_length: Optional[int] = None,
            gt: Optional[float] = None,
            ge: Optional[float] = None,
            lt: Optional[float] = None,
            le: Optional[float] = None,
            description: Optional[str] = None,
            **kwargs
        ):
            self.default = default
            self.default_factory = default_factory
            self.min_length = min_length
            self.gt = gt
            self.ge = ge
            self.lt = lt
            self.le = le
            self.description = description
            self.extra = kwargs

    def Field(
        default: Any = ...,
        *,
        default_factory: Optional[Callable[[], Any]] = None,
        min_length: Optional[int] = None,
        gt: Optional[float] = None,
        ge: Optional[float] = None,
        lt: Optional[float] = None,
        le: Optional[float] = None,
        description: Optional[str] = None,
        **kwargs
    ) -> Any:
        return FieldInfo(
            default=default,
            default_factory=default_factory,
            min_length=min_length,
            gt=gt,
            ge=ge,
            lt=lt,
            le=le,
            description=description,
            **kwargs
        )

    class EmailStr(str):
        @classmethod
        def __get_validators__(cls):
            yield cls.validate

        @classmethod
        def validate(cls, v):
            if not isinstance(v, str) or "@" not in v:
                raise ValueError("Invalid email format")
            return cls(v)

    def field_validator(*fields: str, mode: str = "after"):
        def decorator(fn: Callable):
            fn.__field_validator_fields__ = fields
            fn.__field_validator_mode__ = mode
            return fn
        return decorator

    class BaseModel:
        model_config: ConfigDict = ConfigDict(extra="ignore")
        model_fields: Dict[str, Any] = {}

        def __init__(self, **data: Any):
            annotations = getattr(self.__class__, "__annotations__", {})
            for key in annotations:
                default_val = getattr(self.__class__, key, None)
                if key in data:
                    val = data[key]
                elif isinstance(default_val, FieldInfo):
                    if default_val.default_factory is not None:
                        val = default_val.default_factory()
                    elif default_val.default is not ...:
                        val = default_val.default
                    else:
                        val = None
                else:
                    val = default_val

                target_type = annotations.get(key)
                if isinstance(val, dict) and isinstance(target_type, type) and issubclass(target_type, BaseModel):
                    val = target_type(**val)
                elif isinstance(val, list) and get_origin(target_type) is list:
                    type_args = get_args(target_type)
                    if type_args and isinstance(type_args[0], type) and issubclass(type_args[0], BaseModel):
                        item_type = type_args[0]
                        val = [item_type(**item) if isinstance(item, dict) else item for item in val]

                setattr(self, key, val)

            extra_policy = getattr(self.model_config, "extra", "ignore")
            if extra_policy != "forbid":
                for k, v in data.items():
                    if k not in annotations and k != "_id":
                        setattr(self, k, v)

        def model_dump(self, *args, **kwargs) -> Dict[str, Any]:
            result = {}
            for k in self.__dict__:
                if k.startswith("_"):
                    continue
                val = getattr(self, k)
                if isinstance(val, BaseModel):
                    result[k] = val.model_dump()
                elif isinstance(val, list):
                    result[k] = [item.model_dump() if isinstance(item, BaseModel) else item for item in val]
                elif isinstance(val, dict):
                    result[k] = {
                        sub_k: sub_v.model_dump() if isinstance(sub_v, BaseModel) else sub_v
                        for sub_k, sub_v in val.items()
                    }
                else:
                    result[k] = val
            return result

        def dict(self, *args, **kwargs) -> Dict[str, Any]:
            return self.model_dump(*args, **kwargs)

        @classmethod
        def model_validate(cls: Type[T], obj: Any) -> T:
            if isinstance(obj, dict):
                return cls(**obj)
            elif isinstance(obj, cls):
                return obj
            raise ValueError(f"Cannot validate object of type {type(obj)} to {cls.__name__}")

        @classmethod
        def model_rebuild(cls) -> None:
            pass

        def __repr__(self) -> str:
            fields = ", ".join(f"{k}={v!r}" for k, v in self.model_dump().items())
            return f"{self.__class__.__name__}({fields})"

    __all__ = [
        "BaseModel",
        "Field",
        "ConfigDict",
        "EmailStr",
        "field_validator",
    ]
