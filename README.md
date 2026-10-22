# Roleta da Sorte — Missão 12

Aplicativo Flutter do ClubRobot para a atividade física **Roleta da Sorte**. A criança gira a roleta física, seleciona no app a cor em que ela parou e recebe um desafio aleatório para realizar em 20 segundos.

## O que está incluído

- **Aplicativo Flutter:** oito categorias de cores, desafios aleatórios e cronômetro de 20 segundos.
- **Bluetooth BLE:** o app envia `START` ao iniciar um desafio e `STOP` ao concluir ou quando o tempo termina.
- **Firmware ESP32:** arquivo Arduino em `esp32/roleta_missao12.ino`.
- **GitHub Actions:** compila o APK Android em pushes, pull requests e quando executado manualmente.

## Estrutura

```text
Roleta-da-Sorte-Missao12/
├── .github/workflows/build-apk.yml
├── esp32/roleta_missao12.ino
├── lib/
│   ├── main.dart
│   └── services/ble_service.dart
├── tool/patch_android.py
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```

## 1. Rodar o app localmente

Instale Flutter e Android Studio/Android SDK. Na pasta do projeto, execute:

```bash
flutter create . --platforms=android --project-name=roleta_missao12 --org=br.clubrobot
python3 tool/patch_android.py
flutter pub get
flutter run
```

O projeto não inclui a pasta `android/` gerada pelo Flutter; o workflow do GitHub Actions a cria automaticamente antes da compilação.

## 2. Preparar o ESP32

1. Abra `esp32/roleta_missao12.ino` na Arduino IDE.
2. Selecione a placa ESP32 adequada e instale o suporte ESP32 para Arduino.
3. Conecte um LED externo ao **GPIO 18** por meio de um resistor de **220–330 Ω**; o outro terminal do LED vai ao GND.
4. Carregue o sketch e abra o Monitor Serial em **115200 baud**.
5. No aplicativo, toque no botão Bluetooth para procurar `RoletaESP32`.

> **Importante:** confirme o modelo da placa e os pinos disponíveis antes de montar o circuito. O exemplo assume uma ESP32 DevKit/ESP32-WROOM e usa GPIO 18. Não conecte um LED diretamente sem resistor.

## 3. Protocolo BLE

O app e o firmware precisam usar os mesmos UUIDs:

| Elemento | UUID |
|---|---|
| Serviço | `6f400001-b5a3-f393-e0a9-e50e24dcca9e` |
| Característica de comando | `6f400002-b5a3-f393-e0a9-e50e24dcca9e` |

A característica aceita os comandos de texto `START` e `STOP`. O LED acende com `START` e apaga com `STOP`, ao desconectar o aplicativo ou após o limite de segurança de 60 segundos.

## 4. Baixar o APK pelo GitHub

1. Envie os arquivos deste projeto para a branch `main` do repositório.
2. Abra a aba **Actions** no GitHub.
3. Entre na execução **Build APK Android** e aguarde todas as etapas ficarem verdes.
4. Na parte inferior da execução, baixe o artefato **`roleta-da-sorte-missao12-apk`**.
5. Descompacte o artefato para encontrar `app-release.apk`.

O workflow também pode ser iniciado manualmente em **Actions → Build APK Android → Run workflow**.

## Observações

- A roleta continua sendo física; não há sensor de cor. A criança seleciona manualmente a cor no aplicativo.
- O LED é um indicador de que o desafio está em andamento; não precisa ter a mesma cor da roleta.
- A compilação não foi executada neste ambiente. O primeiro resultado real do build será mostrado na aba **Actions** depois do envio ao GitHub.
