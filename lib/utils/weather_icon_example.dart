import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherIconExample extends StatelessWidget {
  final String conditionText;

  const WeatherIconExample({required this.conditionText});

  @override
  Widget build(BuildContext context) {
    IconData weatherIcon = _getWeatherIcon(conditionText);

    return Icon(
      weatherIcon,
      size: 40.0, // Taille de l'icône, légèrement plus petite
    );
  }

  // Fonction pour associer une icône en fonction de la condition météo
  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return WeatherIcons.day_sunny;
      case 'cloudy':
      case 'overcast':
        return WeatherIcons.cloud;
      case 'partly cloudy':
        return WeatherIcons.cloudy;
      case 'mostly cloudy':
        return WeatherIcons.cloudy;
      case 'light rain':
      case 'light rain shower':
        return WeatherIcons
            .rain_mix; // Choisissez l'icône appropriée pour light rain
      case 'patchy rain nearby':
        return WeatherIcons.raindrops;
      case 'rain':
      case 'rainy':
        return WeatherIcons.rain;
      case 'fog':
        return WeatherIcons.fog;
      case 'snow':
      case 'moderate snow':
        return WeatherIcons.snow;
      case 'mist': // Nouvelle condition pour 'mist'
        return WeatherIcons.sprinkle; // Icône pour 'mist'
      case 'moderate rain': // Nouvelle condition pour 'moderate rain'
        return WeatherIcons.showers; // Icône pour 'moderate rain'

      case 'snow':
        return WeatherIcons.snow;
      case 'thunderstorm':
        return WeatherIcons.thunderstorm;
      case 'windy':
        return WeatherIcons.wind;
      default:
        return WeatherIcons.na; // Icône par défaut
    }
  }
}
