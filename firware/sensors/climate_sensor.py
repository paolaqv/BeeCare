from machine import Pin
import dht


class ClimateSensor:
    def __init__(self, pin, sensor_id, location, sensor_type):
        self.sensor_id = sensor_id
        self.location = location
        self.sensor_type = sensor_type

        if sensor_type == "DHT22":
            self.sensor = dht.DHT22(Pin(pin))

        elif sensor_type == "DHT11":
            self.sensor = dht.DHT11(Pin(pin))

        else:
            raise ValueError("Tipo de sensor no soportado")

    def read(self):
        try:
            self.sensor.measure()

            temperature = self.sensor.temperature()
            humidity = self.sensor.humidity()

            return {
                "sensor_id": self.sensor_id,
                "sensor_type": self.sensor_type,
                "location": self.location,
                "temperature": temperature,
                "humidity": humidity,
                "status": "ok"
            }

        except Exception as error:
            return {
                "sensor_id": self.sensor_id,
                "sensor_type": self.sensor_type,
                "location": self.location,
                "temperature": None,
                "humidity": None,
                "status": "error",
                "error": str(error)
            }

