from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class RevitCommand:
    id: str
    code: str

    def to_json(self) -> dict[str, str]:
        return {"id": self.id, "code": self.code}


@dataclass(frozen=True)
class RevitResponse:
    id: str
    ok: bool
    result: str | None = None
    error: str | None = None
    details: str | None = None

    @classmethod
    def from_json(cls, payload: dict[str, Any]) -> "RevitResponse":
        if not isinstance(payload.get("id"), str):
            raise ValueError("Response is missing string field 'id'.")
        if not isinstance(payload.get("ok"), bool):
            raise ValueError("Response is missing boolean field 'ok'.")

        return cls(
            id=payload["id"],
            ok=payload["ok"],
            result=_optional_str(payload.get("result")),
            error=_optional_str(payload.get("error")),
            details=_optional_str(payload.get("details")),
        )


def _optional_str(value: Any) -> str | None:
    if value is None:
        return None
    return str(value)

