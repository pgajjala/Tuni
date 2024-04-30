from paho.mqtt.client import Client

import json
from collections import defaultdict
from typing import Callable, Optional

# MQTT Topic Names
TOPIC_SET_LAMP_CONFIG = "tuni/set_config"
TOPIC_LAMP_CHANGE_NOTIFICATION = "tuni/changed"
# TOPIC_LAMP_ASSOCIATED = "lamp/associated"

MQTT_CLIENT_ID = "tuni_bt_peripheral"

# MQTT_VERSION = paho.mqtt.client.MQTTv311
MQTT_BROKER_HOST = "localhost"
MQTT_BROKER_PORT = 1883
MQTT_BROKER_KEEP_ALIVE_SECS = 60


def client_state_topic(client_id):
    return 'lamp/connection/{}/state'.format(client_id)


class TuniState():
    def __init__(self):
        self._isOn = True
        self._current = 0
        self._desired = 0
        self._sharps = False
        self._disabled = False

        self.got_initial_state = False

        self._setup_mqtt()

        self.callbacks: Dict[str, List[Callable]] = defaultdict(list)

    def _setup_mqtt(self):
        self.mqtt = Client(client_id=MQTT_CLIENT_ID)
        self.mqtt.enable_logger()
        self.mqtt.will_set(client_state_topic(MQTT_CLIENT_ID), "0",
                           qos=2, retain=True)
        self.mqtt.on_connect = self.on_mqtt_connect
        self.mqtt.connect(MQTT_BROKER_HOST, port=MQTT_BROKER_PORT,
                          keepalive=MQTT_BROKER_KEEP_ALIVE_SECS)
        self.mqtt.loop_start()

# region Change Subscriptions
    def on(self, event: str, func: Optional[Callable] = None):
        def subscribe(func: Callable):
            if not callable(func):
                raise ValueError("Argument func must be callable.")
            self.callbacks[event].append(func)
            return func
        if func is None:
            return subscribe
        subscribe(func)

    def emit(self, event, message):
        for callback in self.callbacks[event]:
            callback(message)
# endregion

    @property
    def isOn(self):
        return self._isOn

    @property
    def current(self):
        return self._current

    @property
    def desired(self):
        return self._desired

    @property
    def sharps(self):
        return self._sharps
    
    @property
    def disabled(self):
        return self._disabled

    @isOn.setter
    def isOn(self, newIsOn):
        if newIsOn != self.isOn:
            self._isOn = newIsOn
            self.publish_state_change()
    
    @current.setter
    def current(self, newCurrent):
        if newCurrent != self.current:
            self._current = newCurrent
            self.publish_state_change()
        
    @desired.setter
    def desired(self, newDesired):
        if newDesired != self.desired:
            self._desired = newDesired
            self.publish_state_change()
    
    @sharps.setter
    def sharps(self, newSharps):
        if newSharps != self.sharps:
            self._sharps = newSharps
            self.publish_state_change()
            
    @disabled.setter
    def disabled(self, newDisabled):
        if newDisabled != self.disabled:
            self._disabled = newDisabled
            self.publish_state_change()

    def on_mqtt_connect(self, client, userdata, flags, rc):
        self.mqtt.publish(client_state_topic(MQTT_CLIENT_ID), b"1",
                          qos=2, retain=True)
        self.mqtt.message_callback_add(TOPIC_LAMP_CHANGE_NOTIFICATION,
                                       self.receive_new_lamp_state)
        self.mqtt.subscribe(TOPIC_LAMP_CHANGE_NOTIFICATION, qos=1)

    def receive_new_lamp_state(self, client, userdata, message):
        new_state = json.loads(message.payload.decode('utf-8'))

        if not self.got_initial_state or new_state.get(
                'client', 'UNKNONW') != MQTT_CLIENT_ID:
            print(f"Got new state: {new_state}")
            self.got_initial_state = True

            if new_state.get('on', False) != self._isOn:
                self._isOn = new_state.get('on', False)
                self.emit('onOffChange', self.isOn)

            if new_state.get('current', 0) != self._current:
                self.brightness = new_state.get('current', 0)
                self.emit('currentChange', self.current)
            
            if new_state.get('desired', 0) != self._desired:
                self.desired = new_state.get('desired', 0)
                self.emit('desiredChange', self.desired)

            if new_state.get('sharps', False) != self._sharps:
                self._sharps = new_state.get('sharps', False)
                self.emit('sharpsChange', self.sharps)
            
            if new_state.get('disabled', False) != self._disabled:
                self._disabled = new_state.get('disabled', False)
                self.emit('disabledChange', self.disabled)

    def publish_state_change(self):
        config = {
            'current': self.current,
            'desired': self.desired,
            'on': self.isOn,
            'sharps': self.sharps,
            'disabled': self.disabled,
            'client': MQTT_CLIENT_ID}
        print(f"Publishing new state: {config}")
        self.mqtt.publish(TOPIC_SET_LAMP_CONFIG,
                          json.dumps(config).encode('utf-8'), qos=1,
                          retain=True)
