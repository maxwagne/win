 _______________________________ ____  __.  _____  .____    ________   
 \____    /\_   _____/\______   \    |/ _| /  _  \ |    |   \_____  \  
   /     /  |    __)_  |       _/      <  /  /_\  \|    |    /   |   \ 
  /     /_  |        \ |    |   \    |  \/    |    \    |___/    |    \
 /_______ \/_______  / |____|_  /____|__ \____|__  /_______ \_______  /
         \/        \/         \/        \/       \/        \/       \/

# Zerkalo Backup-Skript

## Einführung

Das Zerkalo-Skript ermöglicht es Ihnen, Sicherungskopien eines Quellordners auf ein externes Laufwerk zu erstellen. Das Robocopy-Dienstprogramm wird verwendet, um die Sicherung durchzuführen.

## Voraussetzungen

- Windows-Betriebssystem
- Robocopy-Dienstprogramm (in den meisten Windows-Versionen enthalten)

## Einrichtung und Starten

- Laden Sie die Datei `zerkalo.bat` auf Ihr externes Laufwerk herunter, dabei spielt es keine Rolle, wo die Datei auf dem Laufwerk platziert ist.
- Klicken Sie mit der rechten Maustaste und wählen Sie "Als Administrator ausführen", um das Batch-Skript mit Administratorrechten zu starten.

## Verwendung

- Wählen Sie einen Quellordner aus.
- Der Zielordner ist auf den Unterordner beschränkt, der im Wurzelverzeichnis des externen Laufwerks erstellt wird. Zum Beispiel wird aus "MeinDrive" der Zielordner "D:\MeinDrive", vorausgesetzt, dass die Datei `zerkalo.bat` auf dem externen Laufwerk D:\ liegt.
- Bestätigen Sie die angezeigten Informationen, um die Sicherung zu starten.

## Hinweise

- Beim erneuten Ausführen des Skripts werden Quellordner und Zielordner vorgeschlagen. Bestätigen Sie einfach die vorgeschlagenen Werte, wenn sich der Quellordner nicht geändert hat. Der Unterordner des Zielordners kann ebenfalls bestätigt werden, ohne darauf achten zu müssen, welches Laufwerk eingebunden ist. Das Skript ermittelt automatisch den Laufwerksbuchstaben und erstellt den korrekten Zielpfad.

- Das Skript verwendet Robocopy im "MIR" (Spiegel) Modus, um die Sicherung durchzuführen. Das bedeutet, dass gelöschte Dateien im Quellordner auch aus dem Zielordner gelöscht werden.

## Haftungsausschluss

Dieses Skript wird wie es ist und ohne Garantie zur Verfügung gestellt. Der Autor übernimmt keine Verantwortung für Datenverlust oder Schäden, die beim Gebrauch des Skripts auftreten können.
