from math import pi, sqrt

import matplotlib.pyplot as plt
import numpy as np

N = 4096
dt = 0.001
gamma = 0.2

v = 0.0
x = []
for _ in range(N):
    v = v - gamma * v * dt + np.random.normal(0, sqrt(dt))
    x.append(v)
vw = np.fft.fft(x)
omega = np.fft.fftfreq(len(vw), d=dt)
vw = vw[1:int(N/2)]
omega = omega[1:int(N/2)]
y = np.abs(vw/(N/2)) # スペクトルの絶対値
y2 = [sqrt(gamma**2 + w**2)/(gamma**2+w**2)/(2.0*pi) for w in omega] # 理論値

for i in range(len(vw)):
    print(f"{omega[i]} {y[i]} {y2[i]}")
