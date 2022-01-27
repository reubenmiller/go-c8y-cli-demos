import json
import time
import signal
import sys
from datetime import datetime, timezone

import numpy as np


# Mixed sine wave
T = 100
x = np.arange(0,T)
y = np.sin(4*np.pi*x/T)+np.cos(8*np.pi*x/T)

measurement = {
    'type': 'c8y_Generator',
    'time': '',
    'c8y_Generator': {
        'sine': {
            'value': None,
            'unit': '°C'
        }
    }
}

def print_waveform(pause: float):
    """Print out a partial measurement template.
    Note: The wave form only includes values on the Y-Axis,
    the timestamp 

    Args:
        pause (float): Pause in seconds to wait before printing
            out the next value in the wave form.
    """
    while True:
        for value in y:
            measurement['time'] = datetime.now(timezone.utc).astimezone().isoformat()
            measurement['c8y_Generator']['sine']['value'] = round(value * 10, 4)
            print(json.dumps(measurement), flush=True)
            time.sleep(pause)

def sigterm_handler(_signo, _stack_frame):
    # Raises SystemExit(0):
    sys.exit(0)


if __name__ == '__main__':
    try:
        signal.signal(signal.SIGTERM, sigterm_handler)
        signal.signal(signal.SIGINT, sigterm_handler)

        pause = 1.0
        if len(sys.argv) > 1:
            pause = float(sys.argv[1])
        
        print_waveform(pause)
    finally:
        pass
