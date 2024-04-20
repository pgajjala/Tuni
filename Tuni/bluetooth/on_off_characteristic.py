from pybleno import Characteristic, Descriptor
from tuni_state import TuniState

import array
import struct


class OnOffCharacteristic(Characteristic):
    def __init__(self, tuni_state: TuniState):
        print('initting on/off note characteristic')

        Characteristic.__init__(self, {
            'uuid': '0004A7D3-6486-4761-87D7-B937D41781A2',
            'properties': ['read', 'write', 'notify'],
            'value': None,
            'descriptors': [
                Descriptor({
                    'uuid': '2901',
                    'value': bytes("On / Off", 'utf-8')
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
        self.tuni_state.on('onOffChange', self.handle_on_off_change)

# region BLE Read/Write
    def onReadRequest(self, offset, callback):
        if offset:
            callback(Characteristic.RESULT_ATTR_NOT_LONG, None)
        else:
            data = [0x01] if self.tuni_state.isOn else [0x00]
            callback(Characteristic.RESULT_SUCCESS, data)

    def onWriteRequest(self, data, offset, withoutResponse, callback):
        if offset:
            callback(Characteristic.RESULT_ATTR_NOT_LONG)
        elif len(data) != 1:
            callback(Characteristic.RESULT_INVALID_ATTRIBUTE_LENGTH)
        else:

            print(f'Writing on/off: {data}')
            self.tuni_state.isOn = struct.unpack('?', data)[0]
            callback(Characteristic.RESULT_SUCCESS)
# endregion

    def handle_on_off_change(self, newValue):
        print("Handling on/off change")
        if self.updateValueCallback:
            data = data = [0x01] if self.tuni_state.isOn else [0x00]
            self.updateValueCallback(data)
