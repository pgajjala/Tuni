from pybleno import Characteristic, Descriptor
from tuni_state import TuniState

import array
import struct


class DesiredCharacteristic(Characteristic):
    def __init__(self, tuni_state: TuniState):

        Characteristic.__init__(self, {
            'uuid': '0003A7D3-6486-4761-87D7-B937D41781A2',
            'properties': ['read', 'write', 'notify'],
            'value': None,
            'descriptors': [
                Descriptor({
                    'uuid': '2901',
                    'value': bytes("Desired", 'utf-8')
                }),
                Descriptor({
                    'uuid': '2904',
                    # Presentation Format fields are:
                    # Format      1 octet :  0x04 - unsigned 8-bit value
                    # Exponent    1 octet :  0x00
                    # Unit        2 octets:  0x2700 - unitless
                    # Name Space  1 octet :  0x01 - Bluetooth SIG
                    # Description 2 octets:  0x0000 - blank
                    'value': struct.pack("<BBHBH", 0x04, 0x00,
                                         0x2700, 0x01, 0x0000)
                })
            ]
        })

        self.updateValueCallback = None

        self.tuni_state = tuni_state
        self.tuni_state.on('desiredChange', self.handle_desired_change)

# region BLE Read/Write
    def onReadRequest(self, offset, callback):
        if offset:
            callback(Characteristic.RESULT_ATTR_NOT_LONG, None)
        else:
            data = struct.pack("<B",
                               int(self.tuni_state.desired * 0xff))
            print("Reading:",data)
            callback(Characteristic.RESULT_SUCCESS, data)

    def onWriteRequest(self, data, offset, withoutResponse, callback):
        if offset:
            callback(Characteristic.RESULT_ATTR_NOT_LONG)
        elif len(data) != 1:
            callback(Characteristic.RESULT_INVALID_ATTRIBUTE_LENGTH)
        else:
            print("Writing:", data)
            new_desired = data[0] / 0xff
            print(f'New desired: {new_desired}')
            self.tuni_state.desired = new_desired
            callback(Characteristic.RESULT_SUCCESS)

    def handle_desired_change(self, newValue):
        print(f"Handling desired note change: {newValue}")
        if self.updateValueCallback:
            data = struct.pack("<B",
                               int(self.tuni_state.desired * 0xff))
            self.updateValueCallback(data)

# endregion
