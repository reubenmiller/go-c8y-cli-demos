import json
import sys
import time
import numpy as np

# Mixed sine wave
T = 100
x = np.arange(0,T)
y = np.sin(4*np.pi*x/T)+np.cos(8*np.pi*x/T)

measurement = {
    'type': 'c8y_Generator',
    'c8y_Generator': {
        'sine': {
            'value': None,
            'unit': '°C'
        }
    }
}

def print_signal(pause: float):
    
    while True:
        for value in y:
            measurement['c8y_Generator']['sine']['value'] = round(value * 10, 4)
            print(json.dumps(measurement), flush=True)
            time.sleep(pause)



if __name__ == '__main__':
    pause = 1.0
    if len(sys.argv) > 1:
        pause = float(sys.argv[1])
    
    print_signal(pause)
