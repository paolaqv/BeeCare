import sys
import time

sys.path.append("/firware")

from config import HX711_DT_PIN, HX711_SCK_PIN
from sensors.weight_sensor import SensorPeso


sensor_peso = SensorPeso(
    pin_dt=HX711_DT_PIN,
    pin_sck=HX711_SCK_PIN,
    tara=0,
    factor_calibracion=1
)

print("Plataforma vacia.")
print("No tocar durante 30 segundos...")

time.sleep(30)

print("Calculando tara...")

tara = sensor_peso.leer_promedio(200)

print("TARA CALCULADA:", tara)

print()
print("Coloque los 3.5 kg.")
print("Esperando estabilizacion...")

time.sleep(20)

peso_conocido_kg = 3.5

valor_con_peso = sensor_peso.leer_promedio(200)

factor_calibracion = (
    valor_con_peso - tara
) / peso_conocido_kg

print("------------------------------")
print("VALOR CON PESO:", valor_con_peso)
print("TARA_PESO =", tara)
print("FACTOR_CALIBRACION_PESO =", factor_calibracion)
print("------------------------------")
