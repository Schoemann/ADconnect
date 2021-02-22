#Deploy App innerhalb eines Netzwerks

# to do
# [] check for required packages in this script

# Durch Proxy-Freigabe kann der eigene APC genutzt werden,
# innerhalb eines Netzwerks den Zugriff für Kolleginnen und Kollegen
# zu ermöglichen.
# Benötigt wird die App sowie das Package: shiny

#Pfad zur Package-Bibliothek
.libPaths()
library(shiny)
setwd('H:/activedirectory/app') # ordnerpfad zu app.R

x = system("ipconfig", intern = TRUE)
z = x[grep("IPv4", x)]
ip = gsub(".*? ([[:digit:]])", "\\1", z)

options(shiny.host = '0.0.0.0')        # standard (nicht anpassen)
options(shiny.port = 8888)             # port muss freigegeben sein (ggf. anpassen)

runApp()