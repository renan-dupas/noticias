# Notícias

Aplicativo Flutter simples para leitura de notícias via feeds RSS.

## Requisitos

- Flutter SDK instalado
- Android Studio (para build Android) ou dispositivo Android com depuração USB

## Como rodar

1. Instalar dependências:
	- flutter pub get
2. Executar o app:
	- flutter run
3. Rodar testes:
	- flutter test

## Gerar APK (Android)

1. Usar script do projeto:
	- powershell -ExecutionPolicy Bypass -File scripts/build_apk.ps1
2. O APK será gerado em:
	- build/app/outputs/flutter-apk/app-release.apk

## Instalar no celular via USB

1. Conecte o celular com depuração USB ativada.
2. Verifique dispositivos:
	- flutter devices
3. Instale o APK:
	- adb install -r build/app/outputs/flutter-apk/app-release.apk
