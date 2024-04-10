from kivy.uix.togglebutton import ToggleButton
from kivy.properties import StringProperty, NumericProperty, ColorProperty
from kivy.clock import Clock


class LampiToggle(ToggleButton):

    image = StringProperty()
    image_size = NumericProperty(30.0)
    accent_color = ColorProperty([1.0, 1.0, 1.0])
    label_spacing = NumericProperty(5.0)

    _text_height = NumericProperty()
    _state_color = ColorProperty()

    def __init__(self, *args, **kwargs):
        super(LampiToggle, self).__init__(*args, **kwargs)
        self._update_state_color_async()

    def on_accent_color(self, instance, value):
        if len(value) != 3:
            self.value = [1.0, 1.0, 1.0]

        self._update_state_color_async()

    def on_state(self, instance, value):
        self._update_state_color_async()

    def _update_state_color_async(self):
        # state_color updates are dispatched using Clock
        # to work around a bug where bindings break
        # when updated very fast.
        # see: https://groups.google.com/forum/#!topic/kivy-users/vWfe2jfc-KE
        Clock.schedule_once(self._update_state_color)

    def _update_state_color(self, *args, **kwargs):
        if self.state == 'down':
            self._state_color = self.accent_color
        else:
            self._state_color = [0.6, 0.6, 0.6, 1.0]
