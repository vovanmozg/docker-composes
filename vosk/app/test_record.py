import sounddevice as sd
import numpy as np

duration = 3  # секунды
samplerate = 48000
device = 10

print("Запись...")
audio = sd.rec(int(duration * samplerate), samplerate=samplerate,
               channels=1, dtype='int16', device=device)
sd.wait()
print("Готово")
