from kivy.uix.widget import Widget
from kivy.properties import ListProperty
from kivy.graphics import Rectangle, Color


class ColorBox(Widget):

    color = ListProperty([1.0, 1.0, 1.0])

    def __init__(self, **kwargs):
        super(ColorBox, self).__init__(**kwargs)

        with self.canvas:
            self.background_color = Color([1.0, 1.0, 1.0])
            self.rectangle = Rectangle(pos=self.pos, size=self.size)

    def on_size(self, instance, value):
        self.rectangle.size = self.size

    def on_pos(self, instance, value):
        self.rectangle.pos = self.pos

    def on_color(self, instance, value):
        self.background_color.rgb = self.color
