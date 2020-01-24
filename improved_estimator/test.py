import random

N = 100000
x1 = 0.0
x2 = 0.0
for _ in range(N):
    x = random.randint(1, 6)
    x1 += x
    x2 += x*x

x1 /= N
x2 /= N

print(x1,x2)
print(x2 - x1**2)
