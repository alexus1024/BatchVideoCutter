BatchVideoCutter
================

Скрипт для нарезки видео-файлов по заранее заданной схеме в виде протого xml файла

Как использовать
================

открыть скрипт, там в начале заданы переменные.
в $ffmpeg  установить путь до утилиты ffmpeg (https://www.ffmpeg.org).
в переменную $rules - путь до файла конфигурации.

сохранить и запустить.

По идее, скрипт сам попытается скачать ffmpeg, если не найдёт, но там что-нибудь может сбойнуть.

Как работает
================

Берёт файл конфигурации, и для каждого элемента cut выполняет вызов ffmpeg, предварительно составив параметры так как надо. Так же производятся предварительные проверки и обработка ошибок ffmpeg с целью показа понятных сообщений.
