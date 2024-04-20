from pybleno import Characteristic, Descriptor
from tuni_state import TuniState

import array
import struct


class CurrentNoteCharacteristic(Characteristic):
    def __init__(self, tuni_state: TuniState):
        print('initting current note characteristic')
        Characteristic.__init__(self, {
            'uuid': '0002A7D3-6486-4761-87D7-B937D41781A2',
            'properties': ['read', 'write', 'notify'],
            'value': None,
            'descriptors': [
                Descriptor({
                    'uuid': '2901',
                    'value': bytes("HSV", 'utf-8')
                }),
                Descriptor({
                    'uuid': '2904',
                    # Presentation Format fields are:
                    # Format      1 octet :  0x07 - unsigned 24-bit value
                    # Exponent    1 octet :  0x00
                    # Unit        2 octets:  0x2700 - unitless
                    # Name Space  1 octet :  0x01 - Bluetooth SIG
                    # Description 2 octets:  0x0000 - blank
                    'value': struct.pack("<BBHBH", 0x04, 0x00,
                                         0x2700, 0x01, 0x0000)
                })
            ]
        })
        print('inited characteristic')
        self.updateValueCallback = None

        self.tuni_state = tuni_state
        print('set tuni state')
        self.tuni_state.on('currentChange', self.handle_current_change)
        print('handle change')

# region BLE Read/Write
    def onReadRequest(self, offset, callback):
        if offset:
            callback(Characteristic.RESULT_ATTR_NOT_LONG, None)
        else:
            data = struct.pack("<B",
                               int(self.lampi_state.current * 0xff))  #?
            callback(Characteristic.RESULT_SUCCESS, data)

    def onWriteRequest(self, data, offset, withoutResponse, callback):
        if offset:
            callback(Characteristic.RESULT_ATTR_NOT_LONG)
        elif len(data) != 1:
            callback(Characteristic.RESULT_INVALID_ATTRIBUTE_LENGTH)
        else:
            new_current = data[0] / 0xff
            print(f'New current: {new_current}')
            self.lampi_state.current = new_current #CHANGE
            callback(Characteristic.RESULT_SUCCESS)

    def handle_current_change(self, newValue): # CHANGE
        print(f"Handling current change: {newValue}")
        if self.updateValueCallback:
            data = struct.pack("<B",
                               int(self.lampi_state.current * 0xff))
            self.updateValueCallback(data)

# endregion
