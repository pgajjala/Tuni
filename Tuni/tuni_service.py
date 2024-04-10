#!/usr/bin/env python3
import time
import json
import pigpio
import paho.mqtt.client as mqtt
import shelve
import colorsys

from tuni_common import *

PIN_R = 19
PIN_G = 26
PIN_B = 13
PINS = [PIN_R, PIN_G, PIN_B]
PWM_RANGE = 1000
PWM_FREQUENCY = 1000

LAMP_STATE_FILENAME = "lamp_state"

# MQTT_CLIENT_ID = "lamp_service"

FP_DIGITS = 2

MAX_STARTUP_WAIT_SECS = 10.0


class InvalidTuniConfig(Exception):
    pass


class TuniDriver(object):

    def __init__(self):
        self._gpio = pigpio.pi()
        for color_pin in PINS:
            self._gpio.set_mode(color_pin, pigpio.OUTPUT)
            self._gpio.set_PWM_dutycycle(color_pin, 0)
            self._gpio.set_PWM_frequency(color_pin, PWM_FREQUENCY)
            self._gpio.set_PWM_range(color_pin, PWM_RANGE)

    def change_color(self, *args):
        pins_values = zip(PINS, args)
        for pin, value in pins_values:
            self._gpio.set_PWM_dutycycle(pin, value)


class TuniService(object):
    def __init__(self):
        self.lamp_driver = TuniDriver()
        # self._client = self._create_and_configure_broker_client()
        self.db = shelve.open(LAMP_STATE_FILENAME, writeback=True)
        if 'color' not in self.db:
            self.db['color'] = {'h': round(1.0, FP_DIGITS),
                                's': round(1.0, FP_DIGITS)}
        if 'brightness' not in self.db:
            self.db['brightness'] = round(1.0, FP_DIGITS)
        if 'on' not in self.db:
            self.db['on'] = True
        if 'client' not in self.db:
            self.db['client'] = ''
        self.write_current_settings_to_hardware()

    # def _create_and_configure_broker_client(self):
    #     client = mqtt.Client(client_id=MQTT_CLIENT_ID, protocol=MQTT_VERSION)
    #     client.will_set(client_state_topic(MQTT_CLIENT_ID), "0",
    #                     qos=2, retain=True)
    #     client.enable_logger()
    #     client.on_connect = self.on_connect
    #     client.message_callback_add(TOPIC_SET_LAMP_CONFIG,
    #                                 self.on_message_set_config)
    #     client.on_message = self.default_on_message
    #     return client

    # def serve(self):
    #     start_time = time.time()
    #     while True:
    #         try:
    #             self._client.connect(MQTT_BROKER_HOST,
    #                                  port=MQTT_BROKER_PORT,
    #                                  keepalive=MQTT_BROKER_KEEP_ALIVE_SECS)
    #             print("Connnected to broker")
    #             break
    #         except ConnectionRefusedError as e:
    #             current_time = time.time()
    #             delay = current_time - start_time
    #             if (delay) < MAX_STARTUP_WAIT_SECS:
    #                 print("Error connecting to broker; delaying and "
    #                       "will retry; delay={:.0f}".format(delay))
    #                 time.sleep(1)
    #             else:
    #                 raise e
    #     self._client.loop_forever()

    # def on_connect(self, client, userdata, rc, unknown):
    #     self._client.publish(client_state_topic(MQTT_CLIENT_ID), "1",
    #                          qos=2, retain=True)
    #     self._client.subscribe(TOPIC_SET_LAMP_CONFIG, qos=1)
    #     # publish current lamp state at startup
    #     self.publish_config_change()

    # def default_on_message(self, client, userdata, msg):
    #     print("Received unexpected message on topic " +
    #           msg.topic + " with payload '" + str(msg.payload) + "'")

    # def on_message_set_config(self, client, userdata, msg):
    #     try:
    #         new_config = json.loads(msg.payload.decode('utf-8'))
    #         if 'client' not in new_config:
    #             raise InvalidTuniConfig()
    #         self.set_last_client(new_config['client'])
    #         if 'on' in new_config:
    #             self.set_current_onoff(new_config['on'])
    #         if 'color' in new_config:
    #             self.set_current_color(new_config['color'])
    #         if 'brightness' in new_config:
    #             self.set_current_brightness(new_config['brightness'])
    #         self.publish_config_change()
    #     except InvalidTuniConfig:
    #         print("error applying new settings " + str(msg.payload))

    # def publish_config_change(self):
    #     config = {'color': self.get_current_color(),
    #               'brightness': self.get_current_brightness(),
    #               'on': self.get_current_onoff(),
    #               'client': self.get_last_client()}
    #     self._client.publish(TOPIC_LAMP_CHANGE_NOTIFICATION,
    #                          json.dumps(config).encode('utf-8'), qos=1,
    #                          retain=True)

    # def get_last_client(self):
    #     return self.db['client']

    # def set_last_client(self, new_client):
    #     self.db['client'] = new_client

    # def get_current_brightness(self):
    #     return self.db['brightness']

    # def set_current_brightness(self, new_brightness):
    #     if new_brightness < 0 or new_brightness > 1.0:
    #         raise InvalidTuniConfig()
    #     self.db['brightness'] = round(new_brightness, FP_DIGITS)
    #     self.write_current_settings_to_hardware()

    # def get_current_onoff(self):
    #     return self.db['on']

    # def set_current_onoff(self, new_onoff):
    #     if new_onoff not in [True, False]:
    #         raise InvalidTuniConfig()
    #     self.db['on'] = new_onoff
    #     self.write_current_settings_to_hardware()

    # def get_current_color(self):
    #     return self.db['color'].copy()

    # def set_current_color(self, new_color):
    #     for ch in ['h', 's']:
    #         if new_color[ch] < 0 or new_color[ch] > 1.0:
    #             raise InvalidTuniConfig()
    #     for ch in ['h', 's']:
    #         self.db['color'][ch] = round(new_color[ch], FP_DIGITS)
    #     self.write_current_settings_to_hardware()

    def write_current_settings_to_hardware(self):
        onoff = self.get_current_onoff()
        brightness = self.get_current_brightness()
        color = self.get_current_color()

        r, g, b = self.calculate_rgb(color['h'], color['s'], brightness, onoff)
        self.lamp_driver.change_color(r, g, b)
        self.db.sync()

    def calculate_rgb(self, hue, saturation, brightness, is_on):
        pwm = float(PWM_RANGE)
        r, g, b = 0.0, 0.0, 0.0

        if is_on:
            rgb = colorsys.hsv_to_rgb(hue, saturation, 1.0)
            r, g, b = tuple(channel * pwm * brightness
                            for channel in rgb)
        return r, g, b


if __name__ == '__main__':
    lamp = TuniService().serve()