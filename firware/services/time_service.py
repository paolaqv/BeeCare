import ntptime
import time


class ServicioTiempo:
    
    def sincronizar(self):
        try:
            ntptime.settime()
            print("Hora sincronizada correctamente")
            return True

        except Exception as error:
            print("Error sincronizando hora:", error)
            return False

    def obtener_fecha_hora(self):
        fecha = time.localtime()

        return "{:04d}-{:02d}-{:02d}T{:02d}:{:02d}:{:02d}Z".format(
            fecha[0],
            fecha[1],
            fecha[2],
            fecha[3],
            fecha[4],
            fecha[5]
        )