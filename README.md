# Comics Creator - Flutter App

**Comics Creator** — это приложение, предназначенное для создания и редактирования комиксов.


## Содержание

- [Требования](#требования)
- [Установка](#установка)
- [Запуск проекта](#запуск-проекта)
- [Сборка проекта](#сборка-проекта)
- [Если сборка не удалась](#если-сборка-не-удалась)


## Требования

Для сборки и запуска проекта необходимо установить следующие компоненты:

- **Android Studio** или другой редактор, поддерживающий Flutter.
- **Flutter plugin** — установленный плагин Flutter для выбранного редактора.
- **Flutter SDK** — 3.xx.x версии или выше (рекомендумаемая версия 3.24.2).
- - Скачать Flutter SDK: https://flutter-ko.dev/development/tools/sdk/releases
- - Необходимо добавить flutter\bin в системную переменную path
- - - Пример: <Корневой каталог ФС>:\...путь до flutter sdk...\flutter\bin
- - В настройках редактора необходимо указать Flutter SDK path
- **Dart SDK** — версия 3.5.2 или выше.
- **DevTools** — версия 2.37.2.
- **Xcode** (для сборки под iOS).


### Дополнительные зависимости:

- Для Android: необходимы Android SDK и Android NDK.
- Для iOS: необходимо иметь MacOS с установленным Xcode.


## Установка

1. Клонируйте репозиторий:
- git clone https://github.com/iontrxne/comics-creator-flutter.git

2. Перейдите в каталог проекта:
- cd comics-creator

3. Установите все необходимые зависимости:
- flutter pub get


## Запуск проекта

- Для запуска проекта в эмуляторе или на реальном устройстве выполните следующую команду:
- flutter run

Для выбора устройства, используйте команду:
- flutter devices

Выберите устройство, а затем снова выполните команду flutter run.


## Сборка проекта

Чтобы собрать проект для конкретной платформы, выполните одну из следующих команд:

Для Android (APK файл):
- flutter build apk --release
- Собранный apk файл доступен по пути: build\app\outputs\flutter-apk\app-release.apk

Для iOS (необходимо подключение к MacOS и Xcode):
- flutter build ios --release


### Если сборка не удалась
Если у вас возникли проблемы при сборке, убедитесь, что:

- Все зависимости установлены правильно (проверьте с помощью flutter doctor).
- У вас настроены все необходимые компоненты (Android SDK, Xcode, и т. д.).
- Перезапустите Android Studio или используйте другие редакторы, например VS Code.

Если сборка не удалась, вы можете скачать готовый APK файл из репозитория по следующей ссылке: