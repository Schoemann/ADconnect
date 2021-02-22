library(tibble)
library(dplyr)
library(shiny)
library(shinydashboard)
library(DT)
library(shinyWidgets)
library(thankr)
# to do
# [x] verlinken auf nrw connect
# [] dummy branchen
# [x] anleitung integrieren

# Pfad der App (/ Anstelle von \ im Pfadnamen)
ZIELDATEI = "H:/ActiveDirectory/match.csv"
POWERSHELL_DATEI = "H:/ActiveDirectory/app/ad_read_fun.ps1"
USER_FILE = "H:/ActiveDirectory/app/users.csv"
AD_FILE = "H:/ActiveDirectory/app/activeDirectory_gruppen.csv"

#Prüfe ob Dateien vorhanden sind
if (any(FALSE %in% file.exists(c(POWERSHELL_DATEI,USER_FILE,AD_FILE)))) {
  stop("Dateien in Zeile 13- 16 nicht gefunden")
}
# Liste der berechtigten Nutzenden
users = suppressWarnings(read.csv2(USER_FILE,fileEncoding = "UTF-8"))
thank_you = thankr::shoulders() %>%
  DT::datatable(.)								   

# Liste der AD Gruppen, die ausgelesen werden dürfen
ad_list = read.csv2(AD_FILE,fileEncoding = "UTF-8",na.strings = c("NA",""," "))
named = ad_list %>%
  mutate(Bez = ifelse(!is.na(Bezeichnung),Bezeichnung,AD_Gruppenname)) %>%
  select(Bez) %>%
  pull
ad_list = ad_list[["AD_Gruppenname"]]
names(ad_list) = named

# Funktion zum Auslesen mit Powershell
read_ad = function(
  space_name = "STALA",
  ad_group = "REF544",
  out_file = ZIELDATEI,
  path_to_ps_script = POWERSHELL_DATEI
  ) {
    shell(
      cmd = paste0(
        "powershell -executionPolicy bypass -noProfile -file ",
        path_to_ps_script,
        " ",
        space_name,
        " ",
        ad_group,
        " ",
        out_file
      )
    )
}

header = dashboardHeader(
  title = "AD.connect",
  tags$li(a(href = 'https://lv.nrw-connect.nrw.de/',
            img(src = 'nrw_connect.png',
                title = "NRW connect",
                height = "20px"
                )
            ),
  class = "dropdown")
)
sidebar = dashboardSidebar(
  textOutput(
    outputId = "user_name"
    ),
  actionButton(inputId = "login", label = "Login"),
  sidebarMenu(
    menuItem("App", tabName = "app", icon = icon("dashboard")),
    menuItem("Hilfe", tabName = "hilfe", icon = icon("comments")),
    menuItem("Danke",tabName = "thankyou",icon = icon("gratipay"))
  )
)
body = dashboardBody(
  tabItems(
    tabItem(tabName = "app",
            fluidRow(
              column(
        width = 6,
        box(
          textInput("space","Bereichsschlüssel")
        )
        ),
        column(
          width = 6,
          box(
            # <----------------------------------------------------------- Anpassen, wenn keine Liste für AD hinterlegt wurde
            # textInput(
           #   inputId = "ad_group",
           #   label = "AD-Gruppe auswählen"
           #   )
           pickerInput(
             inputId = "ad_group",
             label = "AD-Gruppe auswählen",
             choices = ad_list,
             multiple = FALSE,
             inline = F
           )
          )
        )
      ),
  fluidRow(
    column(width = 6,
    box(
      #width = 12,
      status = "danger",
      actionButton(
        inputId = "ps_go",
        label = "Start",
        icon = icon("audio-description")
        )
      )
    ),
	 column(width = 6,
    box(
      downloadButton("download")
	  )
    ),
    box(
      width = 12,
      DT::dataTableOutput(
        outputId = "data"
      )
    )
  )
    ),
    tabItem(
      tabName = "hilfe",
      p("Um eine AD-Gruppe in eine NRW connect-Gruppe zu überführen ist wie folgt vorzugehen."),
      p("1)	Anlegen einer leeren Gruppe in NRW connect. Bereichskürzel in der die Gruppe angelegt wurde kopieren."),
      p("2)	Einloggen in der App."),
      p("3)	Bereichskürzel eintragen."),
      p("4)	Name der AD-Gruppe auswählen."),
      p("Der Name der AD-Gruppe kann aus der Liste ausgewählt werden. Die Auswahl der AD-Gruppen kann über die Datei activeDirectory_gruppen.csv verwaltet werden. Da es mitunter sehr viele AD-Gruppen geben kann, kann über das Bezeichnungsfeld innerhalb der Datei eine genauere Beschreibung vorgenommen werden."),
      p("Alternativ besteht in der GUI die Möglichkeit ein freies Eingabefeld zu aktivieren, um die Pflege der Datei activeDirectory_gruppen.csv zu umgehen."),
      p("Das mitgelieferte Powershell-Skript (finde_ad_gruppen.ps1) generiert eine Übersicht aller verfügbarer AD-Gruppen."),
      p("5)	Start klicken"),
      p("6)	Datei herunterladen"),
      p("Die erzeugte Datei erfüllt bereits die Voraussetzungen um direkt in NRW connect importiert werden zu können."),
      p(),hr(),
      HTML("<a href='mailto:arne.schoemann@gmail.com'?
  body='Bitte Problem ausführlich beschreiben'&subject='Frage AD.connect'>Kontaktiere mich!</a>"
      )
    ),
    tabItem(
      tabName = "thankyou",
      "Beteiligte Packages",
      hr(),
      DT::DTOutput("shoulders"),
      "Icons entstammen Font Awesome"
    )
  )
)

ui = dashboardPage(
  header,
  sidebar,
  body,
  shinyWidgets::useSweetAlert(
    theme = "dark"
  )
)

server <- function(input, output, session) {
  valid_login = reactiveVal(value = FALSE)
  observeEvent(input$login, {
    inputSweetAlert(
      session = session,
      inputId = "login_username",
      input = "text",
      title = "Login username?"
    )
  })
  observeEvent(input$login_username, {
    inputSweetAlert(
      session = session,
      inputId = "login_password",
      input = "password",
      title = "Login Passwort?"
    )
  })
  entered_username = reactive({
    validate(
      need(!is.null(input$login_username),"Bitte einloggen")
    )
    input$login_username
  })
  entered_password = reactive({
    validate(
      need(!is.null(input$login_password),"Bitte einloggen")
    )
    input$login_password
  })
  observeEvent(entered_password(), {
    if(
      users %>%
        filter(
          user == entered_username(),
          password == entered_password()
          ) %>%
        nrow()
      == 1
    ) {
      valid_login(TRUE)
    } else {
      sendSweetAlert(
              session,
              title = "Falscher Benutzername oder Passwort",
              type = "alert",
              text = "Falsche Kombination aus User und Passwort"
            )
      valid_login(FALSE)
      }
  })
  observeEvent(input$ps_go, {
      sendSweetAlert(
        session,
        title = "Bitte einloggen",
        type = "alert",
        text = "Bitte erst einloggen"
      )
  },ignoreNULL = T,ignoreInit = T)
  output$user_name <- renderText({
    valid_login()
    if(valid_login() == FALSE) {
      paste0("Bitte einloggen")
    } else {
      paste0("eingelogged ist: ", entered_username())
    }
  })

  launched = eventReactive(input$ps_go, {
    if (!valid_login()) {
      NULL
    } else {
      progressSweetAlert(
        session = session,
        id = "loading",
        title = "Lese Active Directory für Gruppenmitglieder",
        display_pct = TRUE, value = 0
      )
      read_ad(space_name = input$space,ad_group = input$ad_group)
      updateProgressBar(
        session,
        id = "loading",
        value = 100,
        total = 100,
        title = "Lese AD-Gruppenmitglieder",
        status = "info",
        unit_mark = "%"
      )
      Sys.sleep(0.5)
      closeSweetAlert(session = session)
      sendSweetAlert(
        session = session,
        title =" Active Directory ausgelesen !",
        type = "success"
      )
      df = read.csv(
        file = ZIELDATEI,
        header = F,
        encoding = "UTF-8"
        )
      # entferne temp datei
      file.remove(ZIELDATEI)
      return(df)
    }
  })

  # download
  output$download <- downloadHandler(
    filename = function() {
      paste(Sys.Date(),"-",input$space,"-",input$ad_group,".csv", sep = "")
    },
    content = function(file) {
      readr::write_csv(
        x = launched(),
        file,
        na = "",
        col_names = FALSE,
        quote_escape = "none"
      )
    }
  )

  # show data in window
  output$data = renderDataTable({
    DT::datatable(
      data = launched(),
      rownames = F,
      colnames = c("Name","Gruppe"),
      options = list(
        pageLength = 5,
        language = list(
          search = "Finde",
          lengthMenu = "Zeige _MENU_ Einträge",
          info = "Zeige _START_ bis _END_ von _TOTAL_ Einträgen",
          paginate = list(previous = 'Zurück', `next` = 'Weiter')
          )
        )
    )
  })
  output$shoulders = renderDT({
    thank_you
  })	
}

shinyApp(ui, server)
