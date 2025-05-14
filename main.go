package main

import (
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"time"
)

const (
	author = "Agnieszka Marzęda"
	port   = "8080"
)

var tmpl = template.Must(template.ParseFiles("templates/index.html"))

var locations = map[string][]string{
	"Polska":  {"Warszawa", "Kraków"},
	"Niemcy": {"Berlin"},
	"USA":     {"Chicago"},
}

type WeatherData struct {
	Main struct {
		Temp float64 `json:"temp"`
	} `json:"main"`
	Weather []struct {
		Description string `json:"description"`
	} `json:"weather"`
	Name string `json:"name"`
}

func main() {
	startTime := time.Now().Format(time.RFC1123)
	log.Printf("App started at: %s", startTime)
	log.Printf("Author: %s", author)
	log.Printf("Listening on port: %s", port)

	http.HandleFunc("/", handler)
	http.HandleFunc("/weather", weatherHandler)

	log.Fatal(http.ListenAndServe("0.0.0.0:"+port, nil))
}

func handler(w http.ResponseWriter, r *http.Request) {
	tmpl.Execute(w, locations)
}

func weatherHandler(w http.ResponseWriter, r *http.Request) {
	apiKey := os.Getenv("OPENWEATHER_API_KEY")
	if apiKey == "" {
		http.Error(w, "API key not set", http.StatusInternalServerError)
		return
	}

	city := r.FormValue("city")
	url := fmt.Sprintf("https://api.openweathermap.org/data/2.5/weather?q=%s&appid=%s&units=metric", city, apiKey)

	resp, err := http.Get(url)
	if err != nil || resp.StatusCode != 200 {
		http.Error(w, "Error fetching weather data", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	var data WeatherData
	if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
		http.Error(w, "Error decoding weather data", http.StatusInternalServerError)
		return
	}

	result := fmt.Sprintf(
		"Pogoda w %s: %.1f°C, %s",
		data.Name, data.Main.Temp, data.Weather[0].Description,
	)
	fmt.Fprintf(w, "<p>%s</p><a href='/'>Wróć</a>", result)
}
