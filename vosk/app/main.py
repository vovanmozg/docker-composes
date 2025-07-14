import sounddevice as sd
import queue
import vosk
import sys
import json

q = queue.Queue()

def audio_callback(indata, frames, time, status):
    if status:
        print(f"Status: {status}", file=sys.stderr)
    q.put(bytes(indata))

def main():
    samplerate = 48000
    device = 10  # USB PnP Audio Device
    model = vosk.Model(lang="ru")  # или "ru" для русского
    recognizer = vosk.KaldiRecognizer(model, 44100)

    with sd.RawInputStream(
        samplerate=samplerate,
        blocksize=8000,
        dtype='int16',
        channels=1,
        device=device,
        callback=audio_callback
    ):
        print("Listening...")
        while True:
            data = q.get()
            if recognizer.AcceptWaveform(data):
                result = json.loads(recognizer.Result())
                print(result.get("text", ""))
            else:
                partial = json.loads(recognizer.PartialResult())
                print(f"\r{partial.get('partial', '')}", end="")

if __name__ == "__main__":
    main()
