import math
import colorsys

from kivy.uix.slider import Slider
from kivy.graphics.texture import Texture
from kivy.properties import ListProperty, ObjectProperty, StringProperty
from kivy.clock import Clock
from array import array


class GradientSlider(Slider):

    colors = ListProperty()
    thumb_image_light = StringProperty()
    thumb_image_dark = StringProperty()

    _texture = ObjectProperty(None)
    _thumb_image = StringProperty()
    _thumb_color = ListProperty([1.0, 1.0, 1.0, 1.0])
    _thumb_border_color = ListProperty([1.0, 1.0, 1.0, 1.0])

    def __init__(self, **kwargs):
        super(GradientSlider, self).__init__(**kwargs)
        Clock.schedule_once(self._update_ui)

    def on_colors(self, instance, value):
        self._update_ui()

    def on_value(self, instance, value):
        self._update_thumb_color()
        self._update_thumb_image()

    def on_thumb_image_dark(self, instance, value):
        self._update_thumb_image()

    def on_thumb_image_light(self, instance, value):
        self._update_thumb_image()

    def _update_ui(self, *args, **kwargs):
        self._update_texture()
        self._update_thumb_color()

    def _update_texture(self):
        if not self.colors:
            return

        height, depth = 1, 3
        width = len(self.colors)
        size = width * height * depth

        texture = Texture.create(size=(width, height))
        texture_buffer = [int(x*255/size) for x in range(size)]
        texture_bytes = array('B', texture_buffer)

        for i, color in enumerate(self.colors):
            buffer_index = i*depth
            texture_bytes[buffer_index:buffer_index+2] = \
                array('B', [int(c * 255.0) for c in color])

        texture.blit_buffer(texture_bytes, colorfmt='rgb', bufferfmt='ubyte')

        self._texture = texture

    def _update_thumb_color(self):
        if not self.colors:
            return

        first_color_index = 0
        second_color_index = 0

        position = self.value * float(len(self.colors) - 1)
        first_color_index = math.trunc(position)
        second_color_index = first_color_index + 1
        if second_color_index > len(self.colors) - 1:
            second_color_index = first_color_index
        pos = position - float(first_color_index)

        first_color = self.colors[first_color_index]
        second_color = self.colors[second_color_index]

        r = first_color[0] + pos * (second_color[0] - first_color[0])
        g = first_color[1] + pos * (second_color[1] - first_color[1])
        b = first_color[2] + pos * (second_color[2] - first_color[2])

        self._thumb_color = (r, g, b, 1.0)

        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        self._thumb_border_color = colorsys.hsv_to_rgb(h, s, v*0.75)

    def _update_thumb_image(self):
        r, g, b, a = self._thumb_color
        cumulative = r*0.213 + g*0.715 + b*0.072

        if cumulative < 0.5:
            self._thumb_image = self.thumb_image_light
        else:
            self._thumb_image = self.thumb_image_dark
