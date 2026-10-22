/*
  ClubRobot - Missão 12: Roleta da Sorte
  Placa prevista: ESP32 DevKit / ESP32-WROOM
  LED externo: GPIO 18 -> resistor 220 a 330 ohms -> anodo do LED
  catodo do LED -> GND

  BLE:
    Nome anunciado: RoletaESP32
    Service UUID: 6f400001-b5a3-f393-e0a9-e50e24dcca9e
    Characteristic UUID: 6f400002-b5a3-f393-e0a9-e50e24dcca9e
    Comandos escritos pelo app: START e STOP
*/

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <string>

static const int LED_PIN = 18;
static const unsigned long LED_SAFETY_TIMEOUT_MS = 60000UL;

static const char *DEVICE_NAME = "RoletaESP32";
static const char *SERVICE_UUID = "6f400001-b5a3-f393-e0a9-e50e24dcca9e";
static const char *COMMAND_CHARACTERISTIC_UUID =
    "6f400002-b5a3-f393-e0a9-e50e24dcca9e";

BLEServer *bleServer = nullptr;
BLECharacteristic *commandCharacteristic = nullptr;
bool deviceConnected = false;
unsigned long ledStartedAt = 0;

void setLed(bool enabled) {
  digitalWrite(LED_PIN, enabled ? HIGH : LOW);
  if (enabled) {
    ledStartedAt = millis();
    Serial.println("LED ligado: desafio iniciado.");
  } else {
    ledStartedAt = 0;
    Serial.println("LED desligado: desafio encerrado.");
  }
}

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer *server) override {
    deviceConnected = true;
    Serial.println("Aplicativo conectado por BLE.");
  }

  void onDisconnect(BLEServer *server) override {
    deviceConnected = false;
    setLed(false);
    Serial.println("Aplicativo desconectado. Reiniciando anúncio BLE.");
    BLEDevice::startAdvertising();
  }
};

class CommandCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *characteristic) override {
    std::string value = characteristic->getValue();
    if (value.empty()) return;

    String command = String(value.c_str());
    command.trim();
    command.toUpperCase();

    Serial.print("Comando recebido: ");
    Serial.println(command);

    if (command == "START") {
      setLed(true);
    } else if (command == "STOP") {
      setLed(false);
    } else {
      Serial.println("Comando desconhecido. Use START ou STOP.");
    }
  }
};

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  setLed(false);

  BLEDevice::init(DEVICE_NAME);
  bleServer = BLEDevice::createServer();
  bleServer->setCallbacks(new ServerCallbacks());

  BLEService *service = bleServer->createService(SERVICE_UUID);
  commandCharacteristic = service->createCharacteristic(
      COMMAND_CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
  );
  commandCharacteristic->setCallbacks(new CommandCallbacks());
  service->start();

  BLEAdvertising *advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->setScanResponse(true);
  BLEDevice::startAdvertising();

  Serial.println("Roleta da Sorte pronta. Procure por RoletaESP32 no app.");
}

void loop() {
  // Proteção de segurança: não deixa o LED preso ligado indefinidamente.
  if (ledStartedAt != 0 && millis() - ledStartedAt >= LED_SAFETY_TIMEOUT_MS) {
    Serial.println("Tempo máximo de segurança atingido.");
    setLed(false);
  }
  delay(20);
}
