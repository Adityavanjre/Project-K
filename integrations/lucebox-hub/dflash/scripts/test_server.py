import os
import struct
import json
import asyncio
from pathlib import Path
from unittest.mock import patch, MagicMock

import pytest
from fastapi.testclient import TestClient

from server import build_app, MODEL_NAME


@pytest.fixture
def mock_tokenizer():
    tokenizer = MagicMock()
    tokenizer.encode.return_value = [1]
    tokenizer.decode.return_value = "hello"
    return tokenizer

@patch("server.subprocess.Popen")
def test_models_endpoint(mock_popen, mock_tokenizer):
    app = build_app(
        target=Path("target.gguf"),
        draft=Path("draft.safetensors"),
        bin_path=Path("test_dflash"),
        budget=22,
        max_ctx=131072,
        tokenizer=mock_tokenizer,
        stop_ids={2}
    )
    client = TestClient(app)
    response = client.get("/v1/models")
    assert response.status_code == 200
    data = response.json()
    assert data["object"] == "list"
    assert len(data["data"]) == 1
    assert data["data"][0]["id"] == MODEL_NAME

@patch("server.os.pipe")
@patch("server.subprocess.Popen")
@patch("server.os.read")
def test_chat_completions_non_streaming(mock_os_read, mock_popen, mock_pipe, mock_tokenizer):
    mock_pipe.return_value = (1, 2)
    
    app = build_app(
        target=Path("target.gguf"),
        draft=Path("draft.safetensors"),
        bin_path=Path("test_dflash"),
        budget=22,
        max_ctx=131072,
        tokenizer=mock_tokenizer,
        stop_ids={2}
    )
    
    # Mock os.read to return a single token (e.g. 10) and then -1
    mock_os_read.side_effect = [
        struct.pack("<i", 10),
        struct.pack("<i", -1)
    ]
    
    client = TestClient(app)
    response = client.post("/v1/chat/completions", json={
        "model": MODEL_NAME,
        "messages": [{"role": "user", "content": "hi"}],
        "stream": False
    })
    
    assert response.status_code == 200
    data = response.json()
    assert data["object"] == "chat.completion"
    assert data["choices"][0]["message"]["content"] == "hello"

@patch("server.os.pipe")
@patch("server.subprocess.Popen")
@patch("server.os.read")
def test_chat_completions_streaming(mock_os_read, mock_popen, mock_pipe, mock_tokenizer):
    mock_pipe.return_value = (1, 2)
    
    app = build_app(
        target=Path("target.gguf"),
        draft=Path("draft.safetensors"),
        bin_path=Path("test_dflash"),
        budget=22,
        max_ctx=131072,
        tokenizer=mock_tokenizer,
        stop_ids={2}
    )
    
    mock_os_read.side_effect = [
        struct.pack("<i", 10),
        struct.pack("<i", -1)
    ]
    
    client = TestClient(app)
    response = client.post("/v1/chat/completions", json={
        "model": MODEL_NAME,
        "messages": [{"role": "user", "content": "hi"}],
        "stream": True
    })
    
    assert response.status_code == 200
    lines = response.text.strip().split("\n\n")
    assert len(lines) >= 3
    assert lines[-1] == "data: [DONE]"
