import time

from config import DHT1_PIN, DHT2_PIN
from config import DHT3_PIN

from sensors.climate_sensor import ClimateSensor


sensor_1 = ClimateSensor(
    pin=DHT1_PIN,
    sensor_id="S1",
    location="centro_marco_5",
    sensor_type="DHT22"
)

sensor_2 = ClimateSensor(
    pin=DHT2_PIN,
    sensor_id="S2",
    location="costado_marco_5",
    sensor_type="DHT11"
)

sensor_3 = ClimateSensor(
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

    time.sleep(3)