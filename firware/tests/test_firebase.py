from services.wifi_service import WifiService
from services.firebase_service import FirebaseService


wifi = WifiService()

if wifi.connect():

    firebase = FirebaseService()

    if firebase.authenticate():

        colmena = firebase.get(
            "colmenas/colmena_01"
        )

        print("------------------------")
        print("Datos de Firebase:")
        print(colmena)