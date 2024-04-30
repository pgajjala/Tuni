from pybleno import BlenoPrimaryService
from on_off_characteristic import OnOffCharacteristic
from current_note_characteristic import CurrentNoteCharacteristic
from desired_characteristic import DesiredCharacteristic
from sharps_characteristic import SharpsCharacteristic
from disabled_characteristic import DisabledCharacteristic
from tuni_state import TuniState

class TuniService(BlenoPrimaryService):
    uuid = '0001A7D3-6486-4761-87D7-B937D41781A2' #?

    def __init__(self):
        self.tuni_state = TuniState()
        print('initting tuni service')


        BlenoPrimaryService.__init__(self, {
            'uuid': self.uuid,
            'characteristics': [
                CurrentNoteCharacteristic(self.tuni_state),
                DesiredCharacteristic(self.tuni_state),
                OnOffCharacteristic(self.tuni_state),
                SharpsCharacteristic(self.tuni_state),
                DisabledCharacteristic(self.tuni_state)
            ]
        })
        print("Started Tuni Service")
