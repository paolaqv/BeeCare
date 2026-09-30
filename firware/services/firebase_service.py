import json

try:
    import urequests as requests
except ImportError:
    import requests

from firmware.config import (
    FIREBASE_API_KEY,
    FIREBASE_DATABASE_URL,
    FIREBASE_EMAIL,
    FIREBASE_PASSWORD
)


class ServicioFirebase:

    def __init__(self):
        self.token_id = None
        self.token_actualizacion = None

    def autenticar(self):
        url = (
            "https://identitytoolkit.googleapis.com/v1/"
            "accounts:signInWithPassword?key="
            + FIREBASE_API_KEY
        )

        datos = {
            "email": FIREBASE_EMAIL,
            "password": FIREBASE_PASSWORD,
            "returnSecureToken": True
        }

        respuesta = None

        try:
            respuesta = requests.post(
                url,
                data=json.dumps(datos),
                headers={
                    "Content-Type": "application/json"
                }
            )

            if respuesta.status_code == 200:
                resultado = respuesta.json()

                self.token_id = resultado["idToken"]
                self.token_actualizacion = resultado["refreshToken"]

                print("Autenticacion Firebase correcta")
                return True

            print("Error Firebase:", respuesta.status_code)
            print(respuesta.text)

            return False

        except Exception as error:
            print("Error autenticando Firebase:", error)
            return False

        finally:
            if respuesta:
                respuesta.close()

    def esta_autenticado(self):
        return self.token_id is not None

    def obtener(self, ruta):
        if not self.esta_autenticado():
            print("Firebase no autenticado")
            return None

        url = (
            FIREBASE_DATABASE_URL
            + "/"
            + ruta
            + ".json?auth="
            + self.token_id
        )

        respuesta = None

        try:
            respuesta = requests.get(url)

            if respuesta.status_code == 200:
                return respuesta.json()

            print("Error GET:", respuesta.status_code)
            print(respuesta.text)

            return None

        except Exception as error:
            print("Error leyendo Firebase:", error)
            return None

        finally:
            if respuesta:
                respuesta.close()

    def agregar(self, ruta, datos):
        """
        POST en Firebase.
        Firebase genera automáticamente el ID del registro.
        """

        if not self.esta_autenticado():
            print("Firebase no autenticado")
            return None

        url = (
            FIREBASE_DATABASE_URL
            + "/"
            + ruta
            + ".json?auth="
            + self.token_id
        )

        respuesta = None

        try:
            respuesta = requests.post(
                url,
                data=json.dumps(datos),
                headers={
                    "Content-Type": "application/json"
                }
            )

            if respuesta.status_code == 200:
                resultado = respuesta.json()

                print("Registro guardado en Firebase")
                return resultado

            print("Error POST:", respuesta.status_code)
            print(respuesta.text)

            return None

        except Exception as error:
            print("Error guardando en Firebase:", error)
            return None

        finally:
            if respuesta:
                respuesta.close()