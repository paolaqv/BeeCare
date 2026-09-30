import time
import sys
sys.path.append("/firware")

from config import DHT1_PIN, DHT2_PIN, DHT3_PIN

from sensors.climate_sensor import SensorClima

sensor_1 = SensorClima(
    pin=DHT1_PIN,
    sensor_id="S1",
    location="centro_marco_5",
    sensor_type="DHT22"
)

sensor_2 = SensorClima(
    pin=DHT2_PIN,
    sensor_id="S2",
    location="costado_marco_5",
    sensor_type="DHT11"
)

sensor_3 = SensorClima(
    pin=DHT3_PIN,
    sensor_id="S3",
    location="costado_marco_1",
    sensor_type="DHT11"
)

sensors = [
    sensor_1,
    sensor_2,
    sensor_3
]


while True:
    print("------------------------------")

    for sensor in sensors:
        data = sensor.read()

        print("Sensor:", data["sensor_id"])
        print("Tipo:", data["sensor_type"])
        print("Ubicación:", data["location"])

        if data["status"] == "ok":
            print("Temperatura:", data["temperature"], "°C")
            print("Humedad:", data["humidity"], "%")
        else:
            print("Error:", data["error"])

        print()

    time.sleep(10)

