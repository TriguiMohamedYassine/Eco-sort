"""Waste classification web app — YOLOv10 inference with bounding boxes."""

from __future__ import annotations

import base64
import io
import os
from pathlib import Path

import cv2
import numpy as np
from fastapi import FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from PIL import Image
from ultralytics import YOLO

APP_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = APP_DIR.parent

(APP_DIR / "static").mkdir(exist_ok=True)
(APP_DIR / "templates").mkdir(exist_ok=True)

CLASS_NAMES = {
    0: "Biodegradable/Organic",
    1: "Cardboard",
    2: "Glass",
    3: "Metal",
    4: "Paper",
    5: "Plastic",
}

CLASS_COLORS = {
    0: (39, 174, 96),   # green
    1: (52, 152, 219),  # blue
    2: (155, 89, 182),  # purple
    3: (231, 76, 60),   # red
    4: (241, 196, 15),  # yellow
    5: (230, 126, 34),  # orange
}

MODEL_CANDIDATES = [
    APP_DIR / "testtest.pt",
    PROJECT_ROOT / "testtest.pt",
    APP_DIR / "yolov10n_best.pt",
    PROJECT_ROOT / "yolov10n_best.pt",
]

IMGSZ = 640
DEFAULT_CONF = 0.25


def resolve_model_path() -> Path:
    model_path_env = os.getenv("MODEL_PATH")
    if model_path_env:
        env_path = Path(model_path_env).expanduser()
        if not env_path.is_absolute():
            env_path = APP_DIR / env_path
        if env_path.is_file():
            return env_path.resolve()
        raise FileNotFoundError(
            f"MODEL_PATH is set but file was not found: {env_path}"
        )

    for path in MODEL_CANDIDATES:
        if path.is_file():
            return path
    tried_paths = ", ".join(str(p) for p in MODEL_CANDIDATES)
    raise FileNotFoundError(
        "No model weights found. Place testtest.pt in the app directory, "
        "or set MODEL_PATH to an absolute file path. "
        f"Tried: {tried_paths}"
    )


MODEL_PATH: Path | None = None
model: YOLO | None = None
MODEL_INIT_ERROR: str | None = None

try:
    MODEL_PATH = resolve_model_path()
    model = YOLO(str(MODEL_PATH))
except Exception as exc:
    MODEL_INIT_ERROR = str(exc)

app = FastAPI(title="K6 Waste Detector", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.mount("/static", StaticFiles(directory=APP_DIR / "static"), name="static")
templates = Jinja2Templates(directory=APP_DIR / "templates")


def ndarray_to_base64_png(image_bgr: np.ndarray) -> str:
    rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
    buffer = io.BytesIO()
    Image.fromarray(rgb).save(buffer, format="PNG")
    return base64.b64encode(buffer.getvalue()).decode("ascii")


def read_upload_as_bgr(file_bytes: bytes) -> np.ndarray:
    image = Image.open(io.BytesIO(file_bytes)).convert("RGB")
    rgb = np.array(image)
    return cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)


def get_class_name(cls_id: int) -> str:
    return CLASS_NAMES.get(cls_id, f"Unknown ({cls_id})")


def draw_detections(image_bgr: np.ndarray, detections: list[dict]) -> np.ndarray:
    annotated = image_bgr.copy()
    for detection in detections:
        cls_id = detection["class_id"]
        color = CLASS_COLORS.get(cls_id, (255, 255, 255))
        x1, y1, x2, y2 = detection["bbox_xyxy"]

        cv2.rectangle(annotated, (x1, y1), (x2, y2), color, 2)

        label_text = f'{detection["label"]} {detection["confidence"] * 100:.1f}%'
        (text_w, text_h), baseline = cv2.getTextSize(
            label_text, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1
        )
        label_top = max(y1 - text_h - baseline - 6, 0)
        label_bottom = label_top + text_h + baseline + 6
        label_right = min(x1 + text_w + 8, annotated.shape[1] - 1)

        cv2.rectangle(annotated, (x1, label_top), (label_right, label_bottom), color, -1)
        cv2.putText(
            annotated,
            label_text,
            (x1 + 4, label_bottom - baseline - 3),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.5,
            (255, 255, 255),
            1,
            cv2.LINE_AA,
        )
    return annotated


@app.get("/", response_class=HTMLResponse)
async def index(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        request,
        "index.html",
        {
            "class_names": list(CLASS_NAMES.values()),
            "model_name": MODEL_PATH.name if MODEL_PATH else "not_loaded",
            "default_conf": DEFAULT_CONF,
        },
    )


@app.get("/health")
async def health() -> dict:
    return {
        "status": "ok",
        "model_loaded": model is not None,
        "model": MODEL_PATH.name if MODEL_PATH else None,
        "classes": len(CLASS_NAMES),
        "model_error": MODEL_INIT_ERROR,
    }


@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    conf: float = Form(DEFAULT_CONF),
) -> dict:
    if model is None:
        raise HTTPException(
            status_code=503,
            detail=(
                "Model is not loaded. Add testtest.pt beside app.py "
                "or set MODEL_PATH to a valid weights file."
            ),
        )

    conf = max(0.05, min(conf, 0.95))
    file_bytes = await file.read()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")

    try:
        source_bgr = read_upload_as_bgr(file_bytes)
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Could not read image: {exc}") from exc

    results = model.predict(
        source=source_bgr,
        conf=conf,
        imgsz=IMGSZ,
        verbose=False,
    )
    result = results[0]

    detections = []
    if result.boxes is not None and len(result.boxes):
        for box in result.boxes:
            cls_id = int(box.cls.item())
            label = get_class_name(cls_id)
            confidence = float(box.conf.item())
            x1, y1, x2, y2 = (int(round(v)) for v in box.xyxy[0].tolist())
            detections.append(
                {
                    "class_id": cls_id,
                    "label": label,
                    "confidence": round(confidence, 4),
                    "bbox_xyxy": [x1, y1, x2, y2],
                    "bbox": {
                        "x1": round(x1, 1),
                        "y1": round(y1, 1),
                        "x2": round(x2, 1),
                        "y2": round(y2, 1),
                    },
                }
            )

    detections.sort(key=lambda item: item["confidence"], reverse=True)
    annotated_bgr = draw_detections(source_bgr, detections)

    response_detections = [
        {
            "class_id": det["class_id"],
            "label": det["label"],
            "confidence": det["confidence"],
            "bbox": det["bbox"],
        }
        for det in detections
    ]

    return {
        "detection_count": len(response_detections),
        "detections": response_detections,
        "annotated_image": ndarray_to_base64_png(annotated_bgr),
        "original_image": ndarray_to_base64_png(source_bgr),
        "model": MODEL_PATH.name,
        "conf_threshold": conf,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=False)
