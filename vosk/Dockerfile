FROM python:3.10-slim

RUN apt-get update && \
    apt-get install -y portaudio19-dev libsndfile1 ffmpeg && \
    pip install vosk sounddevice

WORKDIR /app
COPY app /app

CMD ["python", "main.py"]
