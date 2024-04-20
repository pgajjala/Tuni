from pybleno import BlenoPrimaryService, Characteristic, Descriptor
import struct


class ManufacturerCharacteristic(Characteristic):
    def __init__(self, manufacturer):
        Characteristic.__init__(self, {
            'uuid': '2A29',
            'properties': ['read'],
            'value': bytes(manufacturer, 'utf-8'),
            'descriptors': [
                Descriptor({
                    'uuid': '2901',
                    'value': bytes('Manufacturer Name', 'utf-8')
                }),
                Descriptor({
                    'uuid': '2904',
                    # Presentation Format fields are:
                    # Format      1 octet :  0x19 - utf8 string
                    # Exponent    1 octet :  0x00
                    # Unit        2 octets:  0x2700 - unitless
                    # Name Space  1 octet :  0x01 - Bluetooth SIG
                    # Description 2 octets:  0x0000 - blank
                    'value': struct.pack("<BBHBH", 0x19, 0x00,
                                         0x2700, 0x01, 0x0000)
                })
            ]
        })


class ModelCharacteristic(Characteristic):
    def __init__(self, model):
        Characteristic.__init__(self, {
            'uuid': '2A24',
            'properties': ['read'],
            'value': bytes(model, 'utf-8'),
            'descriptors': [
                Descriptor({
                    'uuid': '2901',
                    'value': bytes('Model Number', 'utf-8')
                }),
                Descriptor({
                    'uuid': '2904',
                    # Presentation Format fields are:
                    # Format      1 octet :  0x19 - utf8 string
                    # Exponent    1 octet :  0x00
                    # Unit        2 octets:  0x2700 - unitless
                    # Name Space  1 octet :  0x01 - Bluetooth SIG
                    # Description 2 octets:  0x0000 - blank
                    'value': struct.pack("<BBHBH", 0x19, 0x00,
                                         0x2700, 0x01, 0x0000)
                })
            ]
        })


class SerialCharacteristic(Characteristic):
    def __init__(self, serial):
        Characteristic.__init__(self, {
            'uuid': '2A25',
            'properties': ['read'],
            'value': bytes(serial, 'utf-8'),
            'descriptors': [
                Descriptor({
                    'uuid': '2901',
                    'value': bytes('Serial Number', 'utf-8')
                }),
                Descriptor({
                    'uuid': '2904',
                    # Presentation Format fields are:
                    # Format      1 octet :  0x19 - utf8 string
                    # Exponent    1 octet :  0x00
                    # Unit        2 octets:  0x2700 - unitless
                    # Name Space  1 octet :  0x01 - Bluetooth SIG
                    # Description 2 octets:  0x0000 - blank
                    'value': struct.pack("<BBHBH", 0x19, 0x00,
                                         0x2700, 0x01, 0x0000)
                })
            ]
        })


class DeviceInfoService(BlenoPrimaryService):
    uuid = '180a'

    def __init__(self, manufacturer, model, serial):
        BlenoPrimaryService.__init__(self, {
            'uuid': self.uuid,
            'characteristics': [
                ManufacturerCharacteristic(manufacturer),
                ModelCharacteristic(model),
                SerialCharacteristic(serial)
            ]
        })
