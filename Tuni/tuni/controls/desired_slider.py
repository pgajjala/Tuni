import math
import colorsys

from kivy.uix.slider import Slider
from kivy.graphics.texture import Texture
from kivy.properties import ListProperty, ObjectProperty, StringProperty
from kivy.clock import Clock
from kivy.graphics import Color, Line
from kivy.uix.label import Label
from array import array
from kivy.core.window import Window

noteFrequencies = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]

noteNamesWithSharps = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
noteNamesWithFlats = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]

class DesiredSlider(Slider):
    colors = ListProperty()
    thumb_image_light = StringProperty()
    thumb_image_dark = StringProperty()

    _texture = ObjectProperty(None)
    _thumb_image = StringProperty()
    _thumb_color = ListProperty([1.0, 1.0, 1.0, 1.0])
    _thumb_border_color = ListProperty([1.0, 1.0, 1.0, 1.0])

    _desired_val = 0
    _desired_val_frequency = 16.35
    _note_label = Label()

    def __init__(self, **kwargs):
        super(DesiredSlider, self).__init__(**kwargs)
        Clock.schedule_once(self._draw_tick_marks)

    def on_colors(self, instance, value):
        self._update_ui()

    def on_value(self, instance, value):
        self._desired_val = round(self.value * 44) / 44
        self._desired_val_frequency = self.slider_val_to_freq(self._desired_val)
        self._update_thumb_color()
        self._update_thumb_image()
        Clock.schedule_once(self._update_label)

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

        position = self._desired_val * float(len(self.colors) - 1)

        first_color_index = math.trunc(position * (len(self.colors) - 1))
        second_color_index = first_color_index + 1
        if second_color_index > len(self.colors) - 1:
            second_color_index = first_color_index
        pos = position * (len(self.colors) - 1) - first_color_index

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

    def _draw_tick_marks(self, *args):
        # Remove existing tick marks
        self.canvas.before.clear()
        with self.canvas.after:
            # Draw tick marks
            for i in range(12):
                Color(0, 0, 1)
                Line(rectangle=(25 + i*17, 245, 1, 30))
                label = Label(text=str(noteNamesWithSharps[i]), pos=(i*17-23, 185), color=(0, 0, 0, 1), font_size=12)
                self.add_widget(label)
            Color(0,0,0)
            Line(rectangle=((Window.width - 1) / 2, 150, 1, 30))
            self._note_label = Label(
                text=self.get_tone_string_helper(self._desired_val_frequency), 
                pos=(73, 85), 
                color=(0, 0, 0, 1), 
                font_size=12)
            self.add_widget(self._note_label)

    def _update_label(self, *args):
        self._note_label.text = self.get_tone_string_helper(self._desired_val_frequency)

    def slider_val_to_freq(self, slider_val):
        #assuming slider val between 0 and 1, in increments of 0.022727...
        scaled_val = slider_val * 11
        low = math.floor(scaled_val)
        high = math.ceil(scaled_val)
        
        if low == high:
            return noteFrequencies[low]
        
        return noteFrequencies[low] + scaled_val * (noteFrequencies[high] - noteFrequencies[low])


    def get_tone_string_helper(self, scaled_tone):
        for i in range(len(noteFrequencies)):
            if scaled_tone == noteFrequencies[i]:
                return noteNamesWithSharps[i]
        
        return str(round(scaled_tone,2))