import sys
import time

sys.path.append("/firware")

from config import (
    HX711_DT_PIN,
    HX711_SCK_PIN,
    TARA_PESO,
    FACTOR_CALIBRACION_PESO
)

from sensors.weight_sensor import SensorPeso


sensor_peso = SensorPeso(
    pin_dt=HX711_DT_PIN,
    pin_sck=HX711_SCK_PIN,
    tara=TARA_PESO,
    factor_calibracion=FACTOR_CALIBRACION_PESO
)

print("Estabilizando sensor de peso...")
time.sleep(3)
# Descartar lecturas iniciales del HX711
sensor_peso.estabilizar(10)

# descartar la primera lectura promedio
sensor_peso.leer_promedio(50)
print("Sensor estabilizado.")
print("Iniciando lectura de peso...")
print("------------------------------")


while True:
    valor_crudo = sensor_peso.leer_promedio(50)

    peso = (
        valor_crudo - TARA_PESO
    ) / FACTOR_CALIBRACION_PESO

    print("RAW:", valor_crudo)
    print("TARA:", TARA_PESO)
    print("Peso:", round(peso, 2), "kg")
    print("------------------------------")

    time.sleep(2)
