from machine import Pin
import time


class SensorPeso:

    def __init__(
        self,
        pin_dt,
        pin_sck,
        tara,
        factor_calibracion
    ):
        self.dt = Pin(pin_dt, Pin.IN)
        self.sck = Pin(pin_sck, Pin.OUT)

        self.sck.value(0)

        self.tara = tara
        self.factor_calibracion = factor_calibracion

    def esta_listo(self):
        return self.dt.value() == 0
    
    ####leer crudo es el valor inicial Raw que el sensor de peso emite, no en kg
    def leer_crudo(self):
        tiempo_espera = 1000

        while not self.esta_listo():
            time.sleep_ms(1)
            tiempo_espera -= 1

            if tiempo_espera <= 0:
                raise RuntimeError("HX711 no responde")

        valor = 0

        for _ in range(24):
            self.sck.value(1)
            time.sleep_us(1)

            valor = valor << 1

            self.sck.value(0)
            time.sleep_us(1)

            if self.dt.value():
                valor += 1

        self.sck.value(1)
        time.sleep_us(1)

        self.sck.value(0)
        time.sleep_us(1)

        if valor & 0x800000:
            valor -= 0x1000000

        return valor

    def leer_promedio(self, muestras=20):
        total = 0

        for _ in range(muestras):
            total += self.leer_crudo()

        return total / muestras

    def obtener_peso(self, muestras=20):
        valor_crudo = self.leer_promedio(muestras)

        peso = (
            valor_crudo - self.tara
        ) / self.factor_calibracion

        return peso
    
    def estabilizar(self, lecturas_descartar=10):
        for _ in range(lecturas_descartar):
            self.leer_crudo()

        time.sleep(1)
