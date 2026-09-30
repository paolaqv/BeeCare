import network
import time

from config import WIFI_SSID, WIFI_PASSWORD


class ServicioWifi:

    def __init__(self):
        self.wlan = network.WLAN(network.STA_IF)

    def conectar(self):
        self.wlan.active(True)

        if self.wlan.isconnected():
            print("Wi-Fi ya conectado")
            print("IP:", self.wlan.ifconfig()[0])
            return True

        print("Conectando a Wi-Fi...")
        self.wlan.connect(WIFI_SSID, WIFI_PASSWORD)

        tiempo_espera = 20

        while tiempo_espera > 0:
            if self.wlan.isconnected():
                print("Wi-Fi conectado")
                print("IP:", self.wlan.ifconfig()[0])
                return True

            time.sleep(1)
            tiempo_espera -= 1

        print("No se pudo conectar al Wi-Fi")
        return False

    def esta_conectado(self):
        return self.wlan.isconnected()

    def desconectar(self):
        if self.wlan.isconnected():
            self.wlan.disconnect()

        self.wlan.active(False)
        print("Wi-Fi desconectado")
