import numpy as np
import matplotlib.pyplot as plt

fname = 'test2.raw'
h = 3264
w = 2464
fname = 'test_from_T20.raw'
fname = 'T20_all_0.raw'
fname = 'test_1_2_3_4_5_6_pattern.raw'
fname = 'test_1px_pattern.raw'
fname = 'test_1px_pattern600x600.raw'
#h = 800
#w = 600
with open(fname, 'rb') as fi:
    data = fi.read()

data = np.frombuffer(data, dtype=np.uint16)

data = data[:(h*w)].reshape( (w, -1) )
data = data * 50

print (data[0][:100])
            
#print (data)

plt.imshow(data)
plt.show()